return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        explorer = {
          actions = {
            -- With clipboard sync off (options.lua), the explorer's y only fills the unnamed
            -- register. Keep that (the explorer's p pastes files from it) and also put the
            -- paths on the system clipboard.
            explorer_yank_clipboard = function(picker)
              require("snacks.explorer.actions").actions.explorer_yank(picker)
              if vim.v.register == '"' then
                vim.fn.setreg("+", (vim.fn.getreg('"'):gsub("\n$", "")))
              end
            end,
          },
          win = { list = { keys = { ["y"] = { "explorer_yank_clipboard", mode = { "n", "x" } } } } },
        },
      },
    },
  },
}
