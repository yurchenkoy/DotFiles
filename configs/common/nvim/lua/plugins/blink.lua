return {
  "saghen/blink.cmp",
  opts = {
    sources = {
      per_filetype = {
        -- No "buffer" source in markdown
        markdown = { "lsp", "path", "snippets" },
      },
    },
  },
}
