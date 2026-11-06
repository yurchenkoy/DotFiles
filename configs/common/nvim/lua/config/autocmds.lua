-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown" },
  callback = function()
    vim.opt_local.spell = false
  end,
})

-- No smooth scrolling in markdown or the CodeCompanion chat (which renders as markdown).
-- render-markdown draws wide table rows as virtual lines, and snacks.scroll's animation
-- keeps snapping back over them, so <C-d>/<C-u> get stuck.
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "codecompanion" },
  callback = function(ev)
    vim.b[ev.buf].snacks_scroll = false
  end,
})
