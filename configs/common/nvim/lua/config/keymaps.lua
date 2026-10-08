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
