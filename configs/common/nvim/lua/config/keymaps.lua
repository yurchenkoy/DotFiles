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
