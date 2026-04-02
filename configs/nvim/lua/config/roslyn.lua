return {
  "seblyng/roslyn.nvim",
  ft = { "cs", "razor" },
  init = function()
    -- Ensure Neovim recognizes .razor and .cshtml files
    vim.filetype.add({
      extension = {
        razor = "razor",
        cshtml = "razor",
      },
    })
  end,
  opts = {},
}
