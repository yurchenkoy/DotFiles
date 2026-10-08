-- Trial of codecompanion.nvim, using Claude Code over ACP (needs `claude-agent-acp`
-- on PATH). It reuses the existing `claude` CLI login, so no token is needed.

-- Your prompts in a Claude Code session transcript, oldest first. Each carries the uuid
-- of the assistant message that ends the turn before it: where `--resume-session-at`
-- has to resume to drop that prompt and everything after it.
local function session_prompts(file)
  local entries, leaf, cwd = {}, nil, nil
  for line in io.lines(file) do
    local ok, entry = pcall(vim.json.decode, line, { luanil = { object = true, array = true } })
    if ok and type(entry) == "table" and entry.uuid and not entry.isSidechain then
      entries[entry.uuid] = entry
      cwd = cwd or entry.cwd
      if entry.type == "user" or entry.type == "assistant" then
        leaf = entry
      end
    end
  end

  -- A native rewind (Esc Esc in the TUI) leaves the abandoned branch in the file, so
  -- walk parentUuid back from the latest message to get only the active conversation.
  -- (The walk stops at a compaction boundary, whose parentUuid is empty.)
  local chain, seen = {}, {}
  local entry = leaf
  while entry and not seen[entry.uuid] do
    seen[entry.uuid] = true
    table.insert(chain, 1, entry)
    entry = entry.parentUuid and entries[entry.parentUuid]
  end

  local prompts, last_assistant = {}, nil
  for _, e in ipairs(chain) do
    if e.type == "assistant" then
      last_assistant = e.uuid
    elseif e.type == "user" and not e.isMeta and e.message then
      local content, text = e.message.content, nil
      if type(content) == "string" then
        text = content
      elseif type(content) == "table" then
        -- Tool results are user messages too; they have no text blocks.
        local parts = {}
        for _, block in ipairs(content) do
          if block.type == "text" then
            table.insert(parts, block.text)
          end
        end
        text = table.concat(parts, "\n")
      end
      -- Skip slash-command and other harness wrappers (<command-name>, ...).
      if text and text ~= "" and not text:match("^%s*<") then
        table.insert(prompts, { text = text, resume_at = last_assistant })
      end
    end
  end
  return prompts, cwd
end

-- Open a new chat and call on_ready(chat, conn) once its ACP connection is up, which
-- happens asynchronously after the chat opens.
local function new_chat(on_ready)
  local chat = require("codecompanion").chat()
  if not chat then
    return vim.notify("Couldn't open a CodeCompanion chat", vim.log.levels.ERROR)
  end
  local timer = assert(vim.uv.new_timer())
  local waited = 0
  timer:start(
    100,
    100,
    vim.schedule_wrap(function()
      if timer:is_closing() then
        return
      end
      waited = waited + 100
      local conn = chat.acp_connection
      if conn and conn.session_id then
        timer:close()
        on_ready(chat, conn)
      elseif waited >= 15000 then
        timer:close()
        vim.notify("Claude Code didn't connect in time", vim.log.levels.WARN)
      end
    end)
  )
end

-- Delete sessions through a connection. A session must not be loaded in a live
-- connection: its Claude process writes the file back on exit, leaving a broken stub.
local function delete_sessions(conn, ids)
  for _, id in ipairs(ids) do
    if not conn:send_rpc_request("session/delete", { sessionId = id }) then
      vim.notify("Failed to delete session " .. id, vim.log.levels.ERROR)
    end
  end
end

-- Open a new chat and load an existing Claude Code session into it, like /resume does.
-- opts.title: chat title; opts.on_loaded(conn): runs only once the session really loaded.
local function open_session(session_id, opts)
  opts = opts or {}
  new_chat(function(chat, conn)
    local updates = {}
    local ok = conn:load_session(session_id, {
      on_session_update = function(update)
        table.insert(updates, update)
      end,
    })
    -- A failed session/load falls back to a brand-new session and still returns true.
    if not ok or conn.session_id ~= session_id then
      return vim.notify("Failed to load session " .. session_id, vim.log.levels.ERROR)
    end
    require("codecompanion.interactions.chat.acp.commands").link_buffer_to_session(chat.bufnr, conn.session_id)
    require("codecompanion.interactions.chat.acp.render").restore_session(chat, updates)
    if opts.title then
      chat:set_title(opts.title)
    end
    if opts.on_loaded then
      opts.on_loaded(conn)
    end
  end)
end

-- The open chat with a live Claude Code connection, or nil (with a warning).
local function connected_chat()
  local chat = require("codecompanion").last_chat()
  if not (chat and chat.acp_connection) then
    vim.notify("Open a chat with <leader>ac first", vim.log.levels.WARN)
    return nil
  end
  return chat
end

local function oneline(text)
  return vim.trim((text:gsub("%s+", " ")))
end

-- Fork or rewind: pick an earlier prompt, write a new one, and continue from just before
-- the picked prompt in a forked session. A rewind then deletes the original session, a
-- fork keeps it. claude-agent-acp can't do this yet, so it runs `claude -p` with the
-- undocumented --resume-session-at. Being headless, the answer arrives all at once and
-- tools needing approval are refused.
local function branch(opts)
  local chat = connected_chat()
  local session_id = chat and chat.acp_connection.session_id
  if not session_id then
    return
  end
  if chat.current_request then
    return vim.notify("Wait for the response to finish (or stop it with <C-c>)", vim.log.levels.WARN)
  end
  if vim.fn.executable("claude") ~= 1 then
    return vim.notify("`claude` isn't on PATH", vim.log.levels.ERROR)
  end
  local file = vim.fn.glob("~/.claude/projects/*/" .. session_id .. ".jsonl", false, true)[1]
  if not file then
    return vim.notify("Nothing to go back to yet", vim.log.levels.WARN)
  end

  local prompts, cwd = session_prompts(file)
  if not (cwd and vim.fn.isdirectory(cwd) == 1) then
    cwd = vim.fn.getcwd()
  end
  -- Newest first. The first prompt has no earlier turn to resume to; start a new chat instead.
  local choices = {}
  for i = #prompts, 1, -1 do
    if prompts[i].resume_at then
      table.insert(choices, prompts[i])
    end
  end
  if #choices == 0 then
    return vim.notify("Nothing to go back to; quit the chat to start over", vim.log.levels.WARN)
  end

  vim.ui.select(choices, {
    prompt = (opts.delete_original and "Rewind" or "Fork") .. " to before",
    format_item = function(p)
      return oneline(p.text):sub(1, 100)
    end,
  }, function(choice)
    if not choice then
      return
    end
    vim.ui.input({ prompt = "New prompt: ", default = oneline(choice.text) }, function(input)
      if not input or vim.trim(input) == "" then
        return
      end
      local cmd = {
        "claude",
        "-p",
        "--resume",
        session_id,
        "--resume-session-at",
        choice.resume_at,
        "--fork-session",
        "--output-format",
        "json",
      }
      if not opts.delete_original then
        -- A fork inherits the original's title; name it so /resume can tell them apart.
        vim.list_extend(cmd, { "--name", "↶ " .. vim.fn.strcharpart(oneline(input), 0, 60) })
      end

      -- Close the old chat now, so nothing new lands in the original while `claude -p`
      -- runs (a rewind deletes it afterwards). On failure, the original is reopened.
      chat:close()
      local function failed(err)
        vim.notify("Failed: " .. err, vim.log.levels.ERROR)
        open_session(session_id)
      end

      vim.notify((opts.delete_original and "Rewinding" or "Forking") .. ", Claude is answering…")
      local spawned, spawn_err = pcall(
        vim.system,
        cmd,
        { cwd = cwd, stdin = input, text = true },
        vim.schedule_wrap(function(res)
          local ok, out = pcall(vim.json.decode, res.stdout or "")
          if res.code ~= 0 or not ok or type(out) ~= "table" or not out.session_id then
            return failed((ok and type(out) == "table" and out.result) or res.stderr or "")
          end
          open_session(out.session_id, {
            -- Only delete the original once the new session is safely loaded.
            on_loaded = opts.delete_original and function(conn)
              delete_sessions(conn, { session_id })
            end or nil,
          })
        end)
      )
      if not spawned then
        failed(tostring(spawn_err))
      end
    end)
  end)
end

-- Sessions for this folder: <CR> resumes one, <Tab> selects, <C-x> deletes the selection
-- (or the one under the cursor). Uses the open chat's connection to list and delete.
local function sessions_picker()
  local chat = connected_chat()
  if not chat then
    return
  end
  local conn = chat.acp_connection
  local utils = require("codecompanion.utils")

  local items = {}
  for _, s in ipairs(conn:session_list()) do
    local ts = s.updatedAt and utils.timestamp_from_iso(s.updatedAt)
    table.insert(items, {
      text = s.title or s.sessionId,
      -- Snacks tracks selection by text (+ key); sessions can share a title.
      key = s.sessionId,
      age = ts and utils.make_relative(ts) or "",
      session = s,
    })
  end
  if #items == 0 then
    return vim.notify("No previous sessions found", vim.log.levels.INFO)
  end

  Snacks.picker({
    title = "Claude Code sessions",
    items = items,
    layout = { preset = "select" },
    format = function(item)
      return { { ("%-10s "):format(item.age), "Comment" }, { item.text } }
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        chat:close()
        open_session(item.session.sessionId, { title = item.session.title })
      end
    end,
    actions = {
      delete_sessions = function(picker)
        local selected = picker:selected({ fallback = true })
        if #selected == 0 then
          return
        end
        local what = #selected == 1 and ('"' .. selected[1].text .. '"') or (#selected .. " sessions")
        if vim.fn.confirm("Delete " .. what .. "?", "&Yes\n&No", 2) ~= 1 then
          return
        end
        local ids, current = {}, false
        for _, item in ipairs(selected) do
          table.insert(ids, item.session.sessionId)
          current = current or item.session.sessionId == conn.session_id
        end
        picker:close()
        if current then
          -- The open chat's own session is among them: close it first, then delete
          -- from a fresh chat.
          chat:close()
          new_chat(function(_, new_conn)
            delete_sessions(new_conn, ids)
            sessions_picker()
          end)
        else
          delete_sessions(conn, ids)
          sessions_picker()
        end
      end,
    },
    win = {
      input = { keys = { ["<C-x>"] = { "delete_sessions", mode = { "n", "i" } } } },
      list = { keys = { ["<C-x>"] = "delete_sessions" } },
    },
  })
end

-- <leader>av shows the chat in the current window instead of a split. CodeCompanion's own
-- "buffer" layout hides it with `:buffer #` in whichever window has focus, and closing a chat
-- deletes its buffer, which closes the window showing it. So track the window the chat
-- borrowed, and hand that window its previous buffer back ourselves.
local function give_back(win)
  local prev = vim.w[win].codecompanion_prev_buf
  vim.w[win].codecompanion_prev_buf = nil
  if prev and vim.api.nvim_buf_is_valid(prev) then
    vim.api.nvim_win_set_buf(win, prev)
  else
    vim.api.nvim_win_call(win, vim.cmd.enew)
  end
end

-- Hide the chat if it's visible (returns true), wherever it is and whichever window has focus.
local function hide_chat()
  local chat = require("codecompanion").last_chat()
  if not (chat and chat.ui:is_visible()) then
    return false
  end
  local win = chat.ui.winnr
  if vim.w[win].codecompanion_prev_buf then
    give_back(win)
    chat.ui:hide({ keep_window = true }) -- only fires the ChatHidden event
  else
    chat.ui:hide()
  end
  return true
end

local function toggle_chat(in_this_window)
  if hide_chat() then
    return
  end
  local win, buf = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
  local window_opts = in_this_window and { layout = "buffer" } or { default = true }
  require("codecompanion").toggle_chat({ window_opts = window_opts })
  if in_this_window then
    vim.w[win].codecompanion_prev_buf = buf
  end
end

return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions" },
  init = function()
    -- Before a chat buffer is deleted (new chat, resume, rewind, fork), give any window it
    -- borrowed through <leader>av its previous buffer, so the window isn't closed with it.
    vim.api.nvim_create_autocmd("User", {
      pattern = "CodeCompanionChatClosed",
      callback = function(ev)
        for _, win in ipairs(vim.fn.win_findbuf(ev.data.bufnr)) do
          if vim.w[win].codecompanion_prev_buf then
            give_back(win)
          end
        end
      end,
    })
  end,
  opts = {
    adapters = {
      acp = {
        -- The stock adapter passes the literal string "CLAUDE_CODE_OAUTH_TOKEN" as the
        -- token when that env var is unset (-> 401). Only forward a real token, and
        -- otherwise let claude-agent-acp use the `claude` CLI login.
        claude_code = function()
          return require("codecompanion.adapters").extend("claude_code", {
            env = {
              CLAUDE_CODE_OAUTH_TOKEN = function()
                return vim.env.CLAUDE_CODE_OAUTH_TOKEN
              end,
            },
            handlers = {
              auth = function()
                return true
              end,
            },
          })
        end,
      },
    },
    display = {
      chat = {
        -- Width 0 skips CodeCompanion's resize, so 'equalalways' gives every window
        -- equal width instead of squashing the neighbouring split.
        window = { width = 0 },
      },
    },
    interactions = {
      chat = {
        adapter = "claude_code",
        roles = { llm = "Code" },
        keymaps = {
          -- Send only with <C-s> (not <CR>). <C-c> stops a response instead of closing
          -- the chat; <leader>ac hides it and <leader>an replaces it with a new one.
          send = { modes = { n = "<C-s>", i = "<C-s>" } },
          stop = { modes = { n = "<C-c>", i = "<C-c>" } },
          close = false,
        },
      },
    },
  },
  keys = {
    -- which-key group label, as LazyVim's ai extras define it.
    { "<leader>a", "", desc = "+ai", mode = { "n", "v" } },
    -- Either key hides a visible chat; when hidden, each opens it in its own layout.
    {
      "<leader>ac",
      function()
        toggle_chat(false)
      end,
      mode = { "n", "v" },
      desc = "Toggle chat",
    },
    {
      "<leader>av",
      function()
        toggle_chat(true)
      end,
      mode = { "n", "v" },
      desc = "Toggle chat (in this window)",
    },
    {
      "<leader>an",
      function()
        -- Close the chat (stopping its Claude process; the session stays resumable) and
        -- start a fresh one.
        local chat = require("codecompanion").last_chat()
        if chat then
          chat:close()
        end
        require("codecompanion").chat()
      end,
      desc = "New chat",
    },
    { "<leader>ar", sessions_picker, desc = "Resume session" },
    {
      "<leader>ab",
      function()
        branch({ delete_original = true })
      end,
      desc = "Rewind",
    },
    {
      "<leader>af",
      function()
        branch({ delete_original = false })
      end,
      desc = "Fork",
    },
    {
      "<leader>ao",
      function()
        local chat = require("codecompanion").last_chat()
        if not chat then
          return vim.notify("No CodeCompanion chat open", vim.log.levels.WARN)
        end
        -- Same picker as the /acp_session_options slash command (mode, model, effort...).
        require("codecompanion.interactions.chat.slash_commands.builtin.acp_session_options")
          .new({ Chat = chat })
          :execute()
      end,
      desc = "Session options",
    },
  },
}
