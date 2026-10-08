-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.filetype.add({ extension = { razor = "html" } })

-- Tie all on-save file fixes to LazyVim's autoformat toggle (<leader>uf / <leader>uF).
-- When autoformat is off, files are written back with the same line endings and
-- final newline they had on disk, and trailing whitespace is left alone.
-- When it's on, .editorconfig's trim_trailing_whitespace, insert_final_newline
-- and end_of_line are applied at save time.
local editorconfig = require("editorconfig")
for _, prop in ipairs({ "trim_trailing_whitespace", "insert_final_newline", "end_of_line" }) do
  editorconfig.properties[prop] = function() end -- still recorded in vim.b.editorconfig
end

local file_fixes = vim.api.nvim_create_augroup("autoformat_file_fixes", {})

vim.api.nvim_create_autocmd("BufWritePre", {
  group = file_fixes,
  callback = function(ev)
    local buf = ev.buf
    local bo = vim.bo[buf]
    local on_disk = vim.b[buf].on_disk or { ff = bo.fileformat, eol = bo.endofline }

    if not LazyVim.format.enabled(buf) then
      bo.fixendofline = false
      bo.fileformat = on_disk.ff
      bo.endofline = on_disk.eol
      return
    end

    local ec = type(vim.b[buf].editorconfig) == "table" and vim.b[buf].editorconfig or {}
    bo.fixendofline = vim.go.fixendofline
    if ec.insert_final_newline then
      bo.fixendofline = ec.insert_final_newline == "true"
      bo.endofline = ec.insert_final_newline == "true"
    end
    if ec.end_of_line then
      bo.fileformat = ({ lf = "unix", crlf = "dos", cr = "mac" })[ec.end_of_line] or bo.fileformat
    end
    if ec.trim_trailing_whitespace == "true" then
      local view = vim.fn.winsaveview()
      vim.cmd("silent! undojoin")
      vim.cmd("silent keepjumps keeppatterns %s/\\s\\+$//e")
      vim.fn.winrestview(view)
    end
  end,
})

-- Remember what was actually written, so a later save with autoformat off keeps it
vim.api.nvim_create_autocmd("BufWritePost", {
  group = file_fixes,
  callback = function(ev)
    local bo = vim.bo[ev.buf]
    vim.b[ev.buf].on_disk = { ff = bo.fileformat, eol = bo.fixendofline or bo.endofline }
  end,
})

-- Only y/p use the system clipboard (see keymaps.lua); d/x/c stay in Vim's own
-- registers, so the last delete is in "" and older ones in "1-"9 (<leader>s" to pick).
vim.opt.clipboard = ""
