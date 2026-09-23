-- Overrides for LazyVim's ai.claudecode extra: focus the Claude window on toggle
-- but keep it in Normal mode so regular Vim motions work.

-- Claude's TUI can render garbled after its window is hidden and re-shown.
-- Nudge the pty size (shrink by one column, then restore) so it gets SIGWINCH
-- and does a full redraw.
local function redraw_claude(buf)
  local win = vim.fn.win_findbuf(buf)[1]
  local chan = vim.bo[buf].channel
  if not win or not chan or chan == 0 then
    return
  end
  local info = vim.fn.getwininfo(win)[1]
  local w, h = info.width - info.textoff, info.height
  pcall(vim.fn.jobresize, chan, w - 1, h)
  vim.defer_fn(function()
    pcall(vim.fn.jobresize, chan, w, h)
  end, 50)
end

return {
  "coder/claudecode.nvim",
  opts = {
    -- The global `"tui": "fullscreen"` setting draws Claude on the alternate screen,
    -- leaving the Neovim terminal buffer with no scrollback. Use the inline TUI here
    -- so Normal-mode motions (j/k, <C-u>/<C-d>, /search, y) work in the Claude window.
    terminal_cmd = [[claude --settings '{"tui":"default"}']],
    terminal = {
      -- Don't auto-enter terminal mode when the Claude window is opened/focused.
      -- Press `i` (or `a`) in the Claude window to type a prompt.
      auto_insert = false,
    },
  },
  keys = {
    {
      "<leader>ac",
      function()
        local term = require("claudecode.terminal")
        local buf = term.get_active_terminal_bufnr()
        local win = buf and vim.fn.win_findbuf(buf)[1]
        -- Focused -> hide.
        if win and win == vim.api.nvim_get_current_win() then
          term.simple_toggle()
          return
        end
        -- Hidden/not started -> show. Then focus and jump into the prompt; plain window
        -- moves (<C-l>) still land in Normal mode because auto_insert = false.
        local was_hidden = not win
        if was_hidden then
          term.simple_toggle()
        end
        vim.schedule(function()
          buf = term.get_active_terminal_bufnr()
          win = buf and vim.fn.win_findbuf(buf)[1]
          if win then
            vim.api.nvim_set_current_win(win)
            vim.cmd("startinsert") -- TermEnter autocmd below redraws Claude
          end
        end)
      end,
      desc = "Toggle Claude",
    },
  },
  init = function()
    -- <Esc> leaves terminal mode in the Claude window; <C-q> sends a real Esc to Claude
    -- (interrupt, dismiss menus, <C-q><C-q> to rewind).
    vim.api.nvim_create_autocmd("TermOpen", {
      callback = function(ev)
        if vim.api.nvim_buf_get_name(ev.buf):match("claude") then
          vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { buffer = ev.buf, desc = "Terminal normal mode" })
          vim.keymap.set("t", "<C-q>", "<Esc>", { buffer = ev.buf, desc = "Send Esc to Claude" })
          -- The inline TUI sometimes draws its prompt a line too high; force a full
          -- redraw every time we enter the prompt (i, a, <leader>ac).
          vim.api.nvim_create_autocmd("TermEnter", {
            buffer = ev.buf,
            callback = function()
              redraw_claude(ev.buf)
            end,
          })
          vim.keymap.set("t", "<C-h>", [[<C-\><C-n><C-w>h]], { buffer = ev.buf, desc = "Go to left window" })
        end
      end,
    })
  end,
}
