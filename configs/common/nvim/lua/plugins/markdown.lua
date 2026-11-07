-- Note navigation with marksman, in markdown only (other filetypes keep the stock pickers):
--   gr on a link or heading lists the references to it. Anywhere else it lists the
--      backlinks to the current note: marksman only returns those for references on the
--      note's title (its first H1), so ask from that line instead.
--   gd on a link goes to its target. Anywhere else it lists the notes this one links to.
-- Nothing runs until a key is pressed: one or two references requests for gr, and for gd
-- one definition request per link, sent together.

local picker_opts = { format = "file", auto_confirm = true, jump = { tagstack = true, reuse_win = true } }

local function marksman(buf)
  return vim.lsp.get_clients({ bufnr = buf, name = "marksman" })[1]
end

-- The buffer's lines outside frontmatter and fenced code blocks, as { 0-based line, text }.
local function text_lines(buf)
  local lines, frontmatter, fence = {}, false, nil
  for i, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    local marker = line:match("^ ? ? ?(```+)") or line:match("^ ? ? ?(~~~+)")
    if i == 1 and line == "---" then
      frontmatter = true
    elseif frontmatter then
      frontmatter = line ~= "---"
    elseif fence then
      -- Only a run of the same character, at least as long and with nothing after it,
      -- closes the block (```` can hold ```).
      local close = line:match("^ ? ? ?([`~]+)%s*$")
      if close and close:sub(1, 1) == fence:sub(1, 1) and #close >= #fence then
        fence = nil
      end
    elseif marker then
      fence = marker
    else
      lines[#lines + 1] = { i - 1, line }
    end
  end
  return lines
end

-- 0-based line of the note's title, its first H1: "# Title", or "Title" over "===".
local function title_line(buf)
  local prev
  for _, l in ipairs(text_lines(buf)) do
    if l[2]:match("^ ? ? ?#%s") or l[2]:match("^ ? ? ?#$") then
      return l[1]
    end
    if prev and prev[1] == l[1] - 1 and prev[2]:match("%S") and l[2]:match("^ ? ? ?=+%s*$") then
      return prev[1]
    end
    prev = l
  end
end

local function request(client, buf, method, position, cb)
  local params = {
    textDocument = { uri = vim.uri_from_bufnr(buf) },
    position = position,
    context = { includeDeclaration = false },
  }
  client:request(method, params, function(_, result)
    -- definition may return a single location
    cb(result and (vim.islist(result) and result or { result }) or {})
  end, buf)
end

-- Picker items for LSP locations, one per line.
local function to_items(locations, encoding, skip)
  local items, seen = {}, {}
  for _, loc in ipairs(vim.lsp.util.locations_to_items(locations, encoding)) do
    local key = loc.filename .. ":" .. loc.lnum
    if not seen[key] and not (skip and skip(loc)) then
      seen[key] = true
      items[#items + 1] = {
        text = loc.filename .. " " .. loc.text,
        file = loc.filename,
        pos = { loc.lnum, loc.col - 1 },
        line = loc.text,
      }
    end
  end
  return items
end

local function pick(title, items)
  Snacks.picker(vim.tbl_extend("force", picker_opts, { title = title, items = items }))
end

local function note_name(buf)
  return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t:r")
end

local function note_references(client, buf)
  local name = note_name(buf)
  local file = vim.api.nvim_buf_get_name(buf)
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local cursor = vim.lsp.util.make_position_params(0, client.offset_encoding).position

  request(client, buf, "textDocument/references", cursor, function(refs)
    if #refs > 0 then
      -- The link under the cursor is one of the references; leave it out.
      local items = to_items(refs, client.offset_encoding, function(loc)
        return loc.filename == file and loc.lnum == row
      end)
      if #items == 0 then
        return vim.notify("No other references")
      end
      return pick(title_line(buf) == row - 1 and "Backlinks to " .. name or "References", items)
    end

    local title = title_line(buf)
    if not title then
      return vim.notify("No references here, and the note has no title to find backlinks for")
    end
    -- Ask from the title's first character: an indented title's leading spaces don't count.
    local indent = vim.api.nvim_buf_get_lines(buf, title, title + 1, false)[1]:find("%S") - 1
    request(client, buf, "textDocument/references", { line = title, character = indent }, function(backlinks)
      if #backlinks == 0 then
        return vim.notify("No backlinks to " .. name)
      end
      pick("Backlinks to " .. name, to_items(backlinks, client.offset_encoding))
    end)
  end)
end

-- Links in the note as { line, col, text }, col being the 0-based byte column of a spot
-- inside the link that marksman resolves. Skips URLs, images and code.
local function note_links(buf)
  local links = {}
  for _, l in ipairs(text_lines(buf)) do
    -- Blank out `code` spans, keeping the columns.
    local line = l[2]:gsub("(`+)(.-)%1", function(ticks, code)
      return (" "):rep(2 * #ticks + #code)
    end)
    for s, text in line:gmatch("()(%[%[.-%]%])") do
      links[#links + 1] = { l[1], s + 1, text }
    end
    for s, text, dest in line:gmatch("()(%[[^%]]*%]%(([^%)]+)%))") do
      if line:sub(s - 1, s - 1) ~= "!" and not dest:match("^%a[%w+.-]*:") then
        links[#links + 1] = { l[1], s, text }
      end
    end
  end
  return links
end

local function note_links_picker(client, buf)
  local name = note_name(buf)
  local file = vim.api.nvim_buf_get_name(buf)
  local links = note_links(buf)
  if #links == 0 then
    return vim.notify("No links in " .. name)
  end

  -- Responses arrive in any order: collect them by link so the list is stable. Targets
  -- come out sorted by path (locations_to_items sorts them), then broken links in note order.
  table.sort(links, function(a, b)
    return a[1] < b[1] or (a[1] == b[1] and a[2] < b[2])
  end)
  local results, pending = {}, #links
  local function done()
    local targets, broken = {}, {}
    for i, link in ipairs(links) do
      vim.list_extend(targets, results[i])
      if #results[i] == 0 then
        -- Jumps to the broken link in this note, to fix it.
        broken[#broken + 1] = {
          text = "broken " .. link[3],
          file = file,
          pos = { link[1] + 1, link[2] },
          line = "broken link: " .. link[3],
        }
      end
    end
    pick("Links from " .. name, vim.list_extend(to_items(targets, client.offset_encoding), broken))
  end

  for i, link in ipairs(links) do
    local character = vim.lsp.util.character_offset(buf, link[1], link[2], client.offset_encoding)
    request(client, buf, "textDocument/definition", { line = link[1], character = character }, function(locs)
      results[i] = locs
      pending = pending - 1
      if pending == 0 then
        done()
      end
    end)
  end
end

local function markdown_or(fn, default)
  return function()
    local buf = vim.api.nvim_get_current_buf()
    local client = vim.bo[buf].filetype == "markdown" and marksman(buf)
    if not client then
      return default()
    end
    fn(client, buf)
  end
end

local function note_definition(client, buf)
  local cursor = vim.lsp.util.make_position_params(0, client.offset_encoding).position
  request(client, buf, "textDocument/definition", cursor, function(locs)
    if #locs == 0 then
      return note_links_picker(client, buf)
    end
    vim.lsp.util.show_document(locs[1], client.offset_encoding, { focus = true })
  end)
end

return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      -- Set for every server (marksman-only keys would race the "*" ones), falling back to
      -- the snacks pickers LazyVim maps by default.
      ["*"] = {
        keys = {
          {
            "gd",
            markdown_or(note_definition, function()
              Snacks.picker.lsp_definitions()
            end),
            desc = "Goto Definition (links in notes)",
            has = "definition",
          },
          {
            "gr",
            markdown_or(note_references, function()
              Snacks.picker.lsp_references()
            end),
            nowait = true,
            desc = "References (backlinks in notes)",
          },
        },
      },
    },
  },
}
