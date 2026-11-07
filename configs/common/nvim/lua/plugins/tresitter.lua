return {
  {
    "nvim-treesitter/nvim-treesitter",
    init = function()
      -- ```pwsh fences in markdown (```powershell and ```ps1 already resolve)
      vim.treesitter.language.register("powershell", "pwsh")
    end,
    opts = {
      ensure_installed = {
        "c_sharp",
        "html",
        -- languages used in markdown code fences
        "powershell",
        "sql",
        "mermaid",
        "bicep",
        "hcl",
        "dockerfile",
        -- ESP-IDF projects: CMakeLists.txt, Kconfig / Kconfig.projbuild, *.ld
        "cmake",
        "kconfig",
        "linkerscript",
      },
      highlight = { enable = true },
    },
  },
}
