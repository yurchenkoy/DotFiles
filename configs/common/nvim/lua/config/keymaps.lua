-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- y/p go through the system clipboard unless a register is given ("ay, "1p, ...)
local function clipboard(keys)
  return function()
    return (vim.v.register == '"' and '"+' or "") .. keys
  end
end
vim.keymap.set({ "n", "x" }, "y", clipboard("y"), { expr = true, desc = "Yank to clipboard" })
vim.keymap.set("n", "Y", clipboard("y$"), { expr = true, desc = "Yank to end of line to clipboard" })
vim.keymap.set("x", "Y", clipboard("Y"), { expr = true, desc = "Yank lines to clipboard" })
vim.keymap.set({ "n", "x" }, "p", clipboard("p"), { expr = true, desc = "Paste from clipboard" })
vim.keymap.set({ "n", "x" }, "P", clipboard("P"), { expr = true, desc = "Paste from clipboard" })

-- Copy the current file's path to the clipboard: <leader>fy relative to the project root,
-- <leader>fY absolute. In visual mode the selected lines are added: src/foo.lua:12-20
local function copy_path(absolute)
  return function()
    local file = vim.api.nvim_buf_get_name(0)
    if file == "" then
      return vim.notify("Buffer has no file", vim.log.levels.WARN)
    end
    local path = absolute and file or vim.fs.relpath(LazyVim.root(), file) or vim.fn.fnamemodify(file, ":~")
    if vim.fn.mode():match("^[vV\22]") then
      local first, last = vim.fn.line("v"), vim.fn.line(".")
      if first > last then
        first, last = last, first
      end
      path = path .. ":" .. first .. (last ~= first and "-" .. last or "")
      vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "n", false)
    end
    vim.fn.setreg("+", path)
    vim.notify("Copied " .. path)
  end
end
vim.keymap.set({ "n", "x" }, "<leader>fy", copy_path(false), { desc = "Copy Path (Root Dir)" })
vim.keymap.set({ "n", "x" }, "<leader>fY", copy_path(true), { desc = "Copy Path (Absolute)" })

-- Git pickers for the repo of the file being edited. Neovim's cwd may be a folder holding
-- several repos (not a repo itself), where LazyVim's cwd-based git pickers find nothing.
-- From a buffer without a file (the CodeCompanion chat, ...), use the last file visited.
local function git_root()
  local file = vim.bo.buftype == "" and vim.api.nvim_buf_get_name(0) or ""
  if file == "" then
    local bufs = vim.tbl_filter(function(b)
      return b.name ~= "" and vim.bo[b.bufnr].buftype == ""
    end, vim.fn.getbufinfo({ buflisted = 1 }))
    table.sort(bufs, function(a, b)
      return a.lastused > b.lastused
    end)
    file = bufs[1] and bufs[1].name or ""
  end
  local root = file ~= "" and Snacks.git.get_root(file) or nil
  if not root then
    vim.notify("Not in a git repo", vim.log.levels.WARN)
  end
  return root
end

-- The GitHub pickers run `gh` in Neovim's cwd unless given the repo, as owner/name.
local function github_repo(root)
  local url = vim.fn.system({ "git", "-C", root, "remote", "get-url", "origin" })
  local repo = vim.v.shell_error == 0 and vim.trim(url):match("github%.com[:/]([^/]+/[^/]+)$")
  if not repo then
    vim.notify("origin isn't a GitHub repo", vim.log.levels.WARN)
    return nil
  end
  return (repo:gsub("%.git$", ""))
end

local function git_map(lhs, desc, fn)
  vim.keymap.set("n", lhs, function()
    local root = git_root()
    if root then
      fn(root)
    end
  end, { desc = desc })
end

local function gh_map(lhs, desc, picker, opts)
  git_map(lhs, desc, function(root)
    local repo = github_repo(root)
    if repo then
      Snacks.picker[picker](vim.tbl_extend("force", { cwd = root, repo = repo }, opts or {}))
    end
  end)
end

git_map("<leader>gd", "Git Diff (hunks)", function(root)
  Snacks.picker.git_diff({ cwd = root })
end)
git_map("<leader>gD", "Git Diff (origin)", function(root)
  Snacks.picker.git_diff({ cwd = root, base = "origin", group = true })
end)
git_map("<leader>gs", "Git Status", function(root)
  Snacks.picker.git_status({ cwd = root })
end)
git_map("<leader>gS", "Git Stash", function(root)
  Snacks.picker.git_stash({ cwd = root })
end)
git_map("<leader>gl", "Git Log", function(root)
  Snacks.picker.git_log({ cwd = root })
end)
gh_map("<leader>gi", "GitHub Issues (open)", "gh_issue")
gh_map("<leader>gI", "GitHub Issues (all)", "gh_issue", { state = "all" })
gh_map("<leader>gp", "GitHub Pull Requests (open)", "gh_pr")
gh_map("<leader>gP", "GitHub Pull Requests (all)", "gh_pr", { state = "all" })
