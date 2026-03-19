-- Tokyo Dark+
-- Ported from VSCode theme of the same name
-- Drop this file into: ~/.config/nvim/lua/colors/tokyo-dark-plus.lua
-- Then in your LazyVim plugins, add:
--   { "rktjmp/lush.nvim" } (optional, this file works without it)
-- Or just call: vim.cmd("colorscheme tokyo-dark-plus")
-- To load without a plugin, place in ~/.config/nvim/colors/tokyo-dark-plus.lua

vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") then
  vim.cmd("syntax reset")
end
vim.g.colors_name = "tokyo-dark-plus"
vim.o.termguicolors = true

local hi = vim.api.nvim_set_hl

-- ============================================================
-- Palette (sourced directly from your VSCode theme)
-- ============================================================
local c = {
  bg = "#24283b", -- editor.background
  bg_dark = "#1d1f2d", -- panel.background / widget bg
  bg_darker = "#141520", -- suggest / hover widget
  bg_darkest = "#11121b", -- peekView bg
  bg_sidebar = "#2a2e43", -- sideBar.background
  bg_float = "#1a1b26", -- input / dropdown bg
  bg_highlight = "#202437", -- lineHighlight
  bg_visual = "#383e5c", -- selection
  bg_search = "#414868", -- find match / badge bg

  fg = "#c0caf5", -- editor.foreground
  fg_dark = "#b7bccf", -- titleBar active fg
  fg_dim = "#8c8c8c", -- ignored git files
  fg_gutter = "#484b5c", -- line numbers

  -- Syntax colors (from your tokenColors)
  keyword = "#7AA2F7", -- control flow (if/for/while etc.)
  keyword2 = "#BB9AF7", -- storage/type/modifier
  func = "#E5C07B", -- function declarations
  type = "#36C0C0", -- types and classes
  string = "#F7768E", -- strings
  number = "#b5cea8", -- numeric literals
  constant = "#7DCFFF", -- constants / enum members
  variable = "#ACCFD7", -- variables and parameters
  comment = "#9ECE6A", -- comments
  operator = "#d4d4d4", -- operators
  tag = "#BB9AF7", -- HTML/XML tags
  attribute = "#ACCFD7", -- HTML attributes
  regexp = "#EB6572", -- regex character classes

  -- UI colors
  red = "#f7768e", -- errors / deleted
  red_dark = "#f44747", -- invalid
  orange = "#e0af68", -- warnings
  orange2 = "#D19A66", -- CSS tags / quantifiers
  green = "#9ECE6A", -- added (gutter/git)
  blue = "#7aa2f7", -- info / links
  blue_light = "#3794ff", -- textLink
  purple = "#BB9AF7", -- markup bold/heading
  cyan = "#36C0C0", -- types

  -- Diagnostics
  error = "#f77676",
  warn = "#d79a42",
  info = "#7aa2f7",
  hint = "#1abc9c",

  -- Git gutter
  git_add = "#5b8430",
  git_mod = "#5a7abf", -- #7aa2f797 blended on #24283b
  git_del = "#d54242",

  none = "NONE",
}

-- ============================================================
-- Editor UI
-- ============================================================
hi(0, "Normal", { fg = c.fg, bg = c.none })
hi(0, "NormalFloat", { fg = c.fg, bg = c.none })
hi(0, "NormalNC", { fg = c.fg, bg = c.none })
hi(0, "FloatBorder", { fg = c.bg_search, bg = c.none })
hi(0, "FloatTitle", { fg = c.fg, bg = c.none })

hi(0, "Cursor", { fg = c.bg, bg = c.fg })
hi(0, "CursorLine", { bg = c.bg_highlight })
hi(0, "CursorLineNr", { fg = c.fg, bold = true })
hi(0, "LineNr", { fg = c.fg_gutter })
hi(0, "SignColumn", { fg = c.fg_gutter, bg = c.none })
hi(0, "ColorColumn", { bg = c.none })

hi(0, "Visual", { bg = c.bg_visual })
hi(0, "VisualNOS", { bg = c.bg_visual })
hi(0, "Search", { fg = c.fg, bg = c.bg_search })
hi(0, "IncSearch", { fg = c.bg, bg = c.orange })
hi(0, "CurSearch", { fg = c.bg, bg = c.orange })

hi(0, "StatusLine", { fg = c.fg_dark, bg = c.bg_dark })
hi(0, "StatusLineNC", { fg = c.fg_dim, bg = c.bg_dark })
hi(0, "WinBar", { fg = c.fg_dark, bg = c.none })
hi(0, "WinBarNC", { fg = c.fg_dim, bg = c.none })
hi(0, "WinSeparator", { fg = "#2e3347" })

hi(0, "TabLine", { fg = "#908fa8", bg = c.none }) -- #ffffff80 blended on #2a2e43
hi(0, "TabLineSel", { fg = "#ffffff", bg = c.none })
hi(0, "TabLineFill", { bg = c.none })

hi(0, "Pmenu", { fg = c.fg, bg = c.none })
hi(0, "PmenuSel", { fg = c.fg, bg = "#2a2f41" }) -- #2e334793 blended on #141520
hi(0, "PmenuSbar", { bg = c.none })
hi(0, "PmenuThumb", { bg = c.none })

hi(0, "MatchParen", { fg = c.none, bg = "#1a2a1a", sp = "#888888", underline = true }) -- #0064001a blended
hi(0, "Whitespace", { fg = "#50556f" })
hi(0, "NonText", { fg = "#50556f" })
hi(0, "SpecialKey", { fg = "#50556f" })
hi(0, "EndOfBuffer", { fg = c.bg })

hi(0, "Folded", { fg = c.fg_dim, bg = c.none })
hi(0, "FoldColumn", { fg = "#627082", bg = c.none })

hi(0, "Directory", { fg = c.blue })
hi(0, "Title", { fg = c.purple, bold = true })

hi(0, "DiffAdd", { bg = "#242e25" }) -- #59db1012 blended on #24283b
hi(0, "DiffChange", { bg = "#2a2428" }) -- #ff00001a blended on #24283b
hi(0, "DiffDelete", { bg = "#2a2428" })
hi(0, "DiffText", { bg = "#414868" })

hi(0, "SpellBad", { sp = c.error, undercurl = true })
hi(0, "SpellCap", { sp = c.warn, undercurl = true })
hi(0, "SpellRare", { sp = c.info, undercurl = true })
hi(0, "SpellLocal", { sp = c.hint, undercurl = true })

hi(0, "MsgArea", { fg = c.fg_dark })
hi(0, "MsgSeparator", { fg = "#2e3347" })
hi(0, "MoreMsg", { fg = c.green })
hi(0, "Question", { fg = c.blue })
hi(0, "ErrorMsg", { fg = c.red })
hi(0, "WarningMsg", { fg = c.warn })

-- ============================================================
-- Syntax (Treesitter + classic groups)
-- ============================================================

-- Comments
hi(0, "Comment", { fg = c.comment })
hi(0, "SpecialComment", { fg = c.comment, italic = true })

-- Keywords
hi(0, "Keyword", { fg = c.keyword })
hi(0, "Statement", { fg = c.keyword })
hi(0, "Conditional", { fg = c.keyword })
hi(0, "Repeat", { fg = c.keyword })
hi(0, "Exception", { fg = c.keyword })
hi(0, "Label", { fg = c.keyword })
hi(0, "StorageClass", { fg = c.keyword2 })
hi(0, "Structure", { fg = c.keyword2 })
hi(0, "Typedef", { fg = c.keyword2 })

-- Operators
hi(0, "Operator", { fg = c.operator })

-- Functions
hi(0, "Function", { fg = c.func })
hi(0, "PreProc", { fg = c.keyword2 })
hi(0, "Include", { fg = c.keyword2 })
hi(0, "Define", { fg = c.keyword2 })
hi(0, "Macro", { fg = c.keyword2 })
hi(0, "PreCondit", { fg = c.keyword2 })

-- Types
hi(0, "Type", { fg = c.type })

-- Identifiers
hi(0, "Identifier", { fg = c.variable })

-- Constants
hi(0, "Constant", { fg = c.constant })
hi(0, "Boolean", { fg = c.keyword2 })
hi(0, "Number", { fg = c.number })
hi(0, "Float", { fg = c.number })

-- Strings
hi(0, "String", { fg = c.string })
hi(0, "Character", { fg = c.keyword2 })
hi(0, "SpecialChar", { fg = c.orange2 })

-- Misc
hi(0, "Special", { fg = c.orange2 })
hi(0, "Tag", { fg = c.tag })
hi(0, "Delimiter", { fg = c.operator })
hi(0, "Debug", { fg = c.red })
hi(0, "Underlined", { underline = true })
hi(0, "Bold", { bold = true })
hi(0, "Italic", { italic = true })
hi(0, "Todo", { fg = c.bg, bg = c.orange, bold = true })
hi(0, "Error", { fg = c.red_dark })

-- ============================================================
-- Treesitter highlight groups (@-prefixed, nvim 0.8+)
-- ============================================================
hi(0, "@comment", { link = "Comment" })
hi(0, "@comment.documentation", { fg = c.comment, italic = true })

hi(0, "@keyword", { fg = c.keyword })
hi(0, "@keyword.function", { fg = c.keyword })
hi(0, "@keyword.operator", { fg = c.keyword2 })
hi(0, "@keyword.return", { fg = c.keyword })
hi(0, "@keyword.import", { fg = c.operator })
hi(0, "@keyword.modifier", { fg = c.keyword2 })
hi(0, "@keyword.repeat", { fg = c.keyword })
hi(0, "@keyword.conditional", { fg = c.keyword })
hi(0, "@keyword.exception", { fg = c.keyword })

hi(0, "@function", { fg = c.func })
hi(0, "@function.call", { fg = c.func })
hi(0, "@function.builtin", { fg = c.func })
hi(0, "@function.method", { fg = c.func })
hi(0, "@function.method.call", { fg = c.func })
hi(0, "@constructor", { fg = c.type })

hi(0, "@type", { fg = c.type })
hi(0, "@type.builtin", { fg = c.keyword2 })
hi(0, "@type.qualifier", { fg = c.keyword2 })
hi(0, "@type.definition", { fg = c.type })
-- Tokyo Dark+
-- Ported from VSCode theme of the same name
-- Faithful port matching VSCode tokenColors + semanticTokenColors
-- Place in: ~/.config/nvim/colors/tokyo-dark-plus.lua

vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") then
  vim.cmd("syntax reset")
end
vim.g.colors_name = "tokyo-dark-plus"
vim.o.termguicolors = true

local hi = vim.api.nvim_set_hl

-- ============================================================
-- Palette (sourced directly from your VSCode theme JSON)
-- ============================================================
local c = {
  bg = "#24283b",
  bg_dark = "#1d1f2d",
  bg_darker = "#141520",
  bg_darkest = "#11121b",
  bg_sidebar = "#2a2e43",
  bg_float = "#1a1b26",
  bg_highlight = "#202437",
  bg_visual = "#383e5c",
  bg_search = "#414868",

  fg = "#c0caf5",
  fg_dark = "#b7bccf",
  fg_dim = "#8c8c8c",
  fg_gutter = "#484b5c",

  -- VSCode token mapping (comments reference the scope)
  -- storage, storage.type, storage.modifier, keyword, keyword.control (base)
  --   → #BB9AF7
  purple = "#BB9AF7",

  -- keyword.control (control flow: if/for/while/using/return), keyword.other.using
  --   → #7AA2F7
  blue = "#7aa2f7",

  -- entity.name.function, support.function → #E5C07B
  func = "#E5C07B",

  -- entity.name.type, entity.name.class, entity.name.namespace (via "Types declaration"),
  -- support.class, support.type, storage.type.cs, storage.type.generic.cs → #36C0C0
  type = "#36C0C0",

  -- string → #F7768E
  string = "#F7768E",

  -- constant.numeric → #b5cea8
  number = "#b5cea8",

  -- variable.other.constant → #7DCFFF
  constant = "#7DCFFF",

  -- variable, variable.parameter, variable.other.property → #ACCFD7
  variable = "#ACCFD7",

  -- comment → #9ECE6A
  comment = "#9ECE6A",

  -- keyword.operator → #d4d4d4
  operator = "#d4d4d4",

  -- entity.name.tag → #BB9AF7
  tag = "#BB9AF7",

  -- entity.other.attribute-name → #ACCFD7
  attribute = "#ACCFD7",

  -- string.regexp character classes → #EB6572
  regexp = "#EB6572",

  -- entity.name (base, before function/type overrides) → #C8C8C8
  entity_name = "#C8C8C8",

  -- variable (base, before specific overrides) → #C8C8C8
  -- Note: the more specific "Variable and parameter name" scope overrides to #ACCFD7

  -- constant.character.escape → #D19A66
  escape = "#D19A66",

  -- constant.language → #BB9AF7
  -- keyword.operator.new → #BB9AF7
  -- variable.language (self/this) → #BB9AF7

  red = "#f7768e",
  red_dark = "#f44747",
  orange = "#e0af68",
  orange2 = "#D19A66",
  green = "#9ECE6A",
  blue_light = "#3794ff",
  cyan = "#36C0C0",

  error = "#f77676",
  warn = "#d79a42",
  info = "#7aa2f7",
  hint = "#1abc9c",

  git_add = "#5b8430",
  git_mod = "#5a7abf",
  git_del = "#d54242",

  none = "NONE",
}

-- ============================================================
-- Editor UI
-- ============================================================
hi(0, "Normal", { fg = c.fg, bg = c.none })
hi(0, "NormalFloat", { fg = c.fg, bg = c.none })
hi(0, "NormalNC", { fg = c.fg, bg = c.none })
hi(0, "FloatBorder", { fg = c.bg_search, bg = c.none })
hi(0, "FloatTitle", { fg = c.fg, bg = c.none })

hi(0, "Cursor", { fg = c.bg, bg = c.fg })
hi(0, "CursorLine", { bg = c.bg_highlight })
hi(0, "CursorLineNr", { fg = c.fg, bold = true })
hi(0, "LineNr", { fg = c.fg_gutter })
hi(0, "SignColumn", { fg = c.fg_gutter, bg = c.none })
hi(0, "ColorColumn", { bg = c.none })

hi(0, "Visual", { bg = c.bg_visual })
hi(0, "VisualNOS", { bg = c.bg_visual })
hi(0, "Search", { fg = c.fg, bg = c.bg_search })
hi(0, "IncSearch", { fg = c.bg, bg = c.orange })
hi(0, "CurSearch", { fg = c.bg, bg = c.orange })

hi(0, "StatusLine", { fg = c.fg_dark, bg = c.bg_dark })
hi(0, "StatusLineNC", { fg = c.fg_dim, bg = c.bg_dark })
hi(0, "WinBar", { fg = c.fg_dark, bg = c.none })
hi(0, "WinBarNC", { fg = c.fg_dim, bg = c.none })
hi(0, "WinSeparator", { fg = "#2e3347" })

hi(0, "TabLine", { fg = "#908fa8", bg = c.none })
hi(0, "TabLineSel", { fg = "#ffffff", bg = c.none })
hi(0, "TabLineFill", { bg = c.none })

hi(0, "Pmenu", { fg = c.fg, bg = c.none })
hi(0, "PmenuSel", { fg = c.fg, bg = "#2a2f41" })
hi(0, "PmenuSbar", { bg = c.none })
hi(0, "PmenuThumb", { bg = c.none })

hi(0, "MatchParen", { fg = c.none, bg = "#1a2a1a", sp = "#888888", underline = true })
hi(0, "Whitespace", { fg = "#50556f" })
hi(0, "NonText", { fg = "#50556f" })
hi(0, "SpecialKey", { fg = "#50556f" })
hi(0, "EndOfBuffer", { fg = c.bg })

hi(0, "Folded", { fg = c.fg_dim, bg = c.none })
hi(0, "FoldColumn", { fg = "#627082", bg = c.none })

hi(0, "Directory", { fg = c.blue })
hi(0, "Title", { fg = c.purple, bold = true })

hi(0, "DiffAdd", { bg = "#242e25" })
hi(0, "DiffChange", { bg = "#2a2428" })
hi(0, "DiffDelete", { bg = "#2a2428" })
hi(0, "DiffText", { bg = "#414868" })

hi(0, "SpellBad", { sp = c.error, undercurl = true })
hi(0, "SpellCap", { sp = c.warn, undercurl = true })
hi(0, "SpellRare", { sp = c.info, undercurl = true })
hi(0, "SpellLocal", { sp = c.hint, undercurl = true })

hi(0, "MsgArea", { fg = c.fg_dark })
hi(0, "MsgSeparator", { fg = "#2e3347" })
hi(0, "MoreMsg", { fg = c.green })
hi(0, "Question", { fg = c.blue })
hi(0, "ErrorMsg", { fg = c.red })
hi(0, "WarningMsg", { fg = c.warn })

-- ============================================================
-- Syntax (classic Vim groups)
-- ============================================================
-- These map to VSCode's TextMate scopes as follows:
--
-- "keyword" (base)          → #BB9AF7 (purple)
-- "keyword.control"         → #7AA2F7 (blue) for control flow
-- But VSCode has LATER rules that override keyword.control → #7AA2F7
-- and keyword.operator.new  → #BB9AF7
-- So: base Keyword = purple, control flow Statement = blue

-- comment → #9ECE6A
hi(0, "Comment", { fg = c.comment })
hi(0, "SpecialComment", { fg = c.comment, italic = true })

-- storage, storage.type, storage.modifier → #BB9AF7
-- keyword (base) → #BB9AF7
-- keyword.control → #BB9AF7, THEN overridden to #7AA2F7 by "Control flow" rule
hi(0, "Keyword", { fg = c.purple }) -- keyword (base) = #BB9AF7
hi(0, "Statement", { fg = c.blue }) -- keyword.control (control flow) = #7AA2F7
hi(0, "Conditional", { fg = c.blue }) -- if/else/switch
hi(0, "Repeat", { fg = c.blue }) -- for/while/do
hi(0, "Exception", { fg = c.blue }) -- try/catch/throw
hi(0, "Label", { fg = c.blue }) -- case/default
hi(0, "StorageClass", { fg = c.purple }) -- storage.modifier (private/readonly/static)
hi(0, "Structure", { fg = c.purple }) -- storage (struct/class keyword)
hi(0, "Typedef", { fg = c.purple }) -- storage.type

-- keyword.operator → #d4d4d4
hi(0, "Operator", { fg = c.operator })

-- entity.name.function, support.function → #E5C07B
hi(0, "Function", { fg = c.func })

-- storage, storage.type → #BB9AF7 (preprocessor etc.)
hi(0, "PreProc", { fg = c.purple })
hi(0, "Include", { fg = c.blue }) -- keyword.other.using → #7AA2F7
hi(0, "Define", { fg = c.purple })
hi(0, "Macro", { fg = c.purple })
hi(0, "PreCondit", { fg = c.purple })

-- entity.name.type, support.type, support.class → #36C0C0
hi(0, "Type", { fg = c.type })

-- variable → #ACCFD7
hi(0, "Identifier", { fg = c.variable })

-- variable.other.constant → #7DCFFF
hi(0, "Constant", { fg = c.constant })
-- constant.language → #BB9AF7
hi(0, "Boolean", { fg = c.purple })
-- constant.numeric → #b5cea8
hi(0, "Number", { fg = c.number })
hi(0, "Float", { fg = c.number })

-- string → #F7768E
hi(0, "String", { fg = c.string })
-- constant.character → #BB9AF7
hi(0, "Character", { fg = c.purple })
-- constant.character.escape → #D19A66
hi(0, "SpecialChar", { fg = c.escape })

hi(0, "Special", { fg = c.escape })
hi(0, "Tag", { fg = c.tag })
hi(0, "Delimiter", { fg = c.operator })
hi(0, "Debug", { fg = c.red })
hi(0, "Underlined", { underline = true })
hi(0, "Bold", { bold = true })
hi(0, "Italic", { italic = true })
hi(0, "Todo", { fg = c.bg, bg = c.orange, bold = true })
hi(0, "Error", { fg = c.red_dark })

-- ============================================================
-- Treesitter highlight groups (@-prefixed, nvim 0.8+)
-- ============================================================
-- Mapping rationale from VSCode JSON:
--
-- keyword (base)                     → #BB9AF7
-- keyword.control (control flow)     → #7AA2F7 (overridden by "Control flow" rule)
-- keyword.other.using                → #7AA2F7 (in "Control flow" rule)
-- keyword.operator.new               → #BB9AF7 (explicit rule)
-- keyword.operator                   → #d4d4d4
-- storage / storage.type / modifier  → #BB9AF7
-- entity.name.function               → #E5C07B
-- entity.name.type / .class          → #36C0C0
-- entity.name.namespace              → #36C0C0 (via "Types declaration" rule)
-- variable                           → #ACCFD7
-- variable.language (self/this)      → #BB9AF7

-- Comments
hi(0, "@comment", { link = "Comment" })
hi(0, "@comment.documentation", { fg = c.comment, italic = true })

-- Keywords
-- Base keyword → purple (#BB9AF7)
hi(0, "@keyword", { fg = c.purple })
-- keyword.function (function/class keyword in JS/TS/Python) → purple (storage)
hi(0, "@keyword.function", { fg = c.purple })
-- keyword.operator (typeof, instanceof, new, delete, etc.) → purple
-- VSCode: keyword.operator.new/expression/cast/sizeof → #BB9AF7
hi(0, "@keyword.operator", { fg = c.purple })
-- keyword.return → blue (control flow)
hi(0, "@keyword.return", { fg = c.blue })
-- keyword.other.using / import → blue (control flow rule includes keyword.other.using)
hi(0, "@keyword.import", { fg = c.blue })
-- storage.modifier → purple
hi(0, "@keyword.modifier", { fg = c.purple })
-- keyword.control repeat/conditional/exception → blue (control flow)
hi(0, "@keyword.repeat", { fg = c.blue })
hi(0, "@keyword.conditional", { fg = c.blue })
hi(0, "@keyword.exception", { fg = c.blue })
-- keyword.type (C# contextual: var, dynamic) → purple (storage.type)
hi(0, "@keyword.type", { fg = c.purple })
-- "keyword.other.using" in the "Control flow" rule → blue
hi(0, "@keyword.directive", { fg = c.blue })

-- Functions
-- entity.name.function / support.function → #E5C07B
hi(0, "@function", { fg = c.func })
hi(0, "@function.call", { fg = c.func })
hi(0, "@function.builtin", { fg = c.func })
hi(0, "@function.method", { fg = c.func })
hi(0, "@function.method.call", { fg = c.func })
-- constructor → type color (new ClassName → the ClassName part)
hi(0, "@constructor", { fg = c.type })

-- Types
-- entity.name.type, entity.name.class, support.class, support.type → #36C0C0
hi(0, "@type", { fg = c.type })
-- storage.type builtin (int, string as keyword in some langs) → purple
hi(0, "@type.builtin", { fg = c.purple })
hi(0, "@type.qualifier", { fg = c.purple })
hi(0, "@type.definition", { fg = c.type })

-- Variables
-- variable, variable.parameter → #ACCFD7
hi(0, "@variable", { fg = c.variable })
-- variable.language (self/this) → #BB9AF7
hi(0, "@variable.builtin", { fg = c.purple })
hi(0, "@variable.parameter", { fg = c.variable })
-- variable.other.property → #ACCFD7
hi(0, "@variable.member", { fg = c.variable })

-- Constants
-- variable.other.constant → #7DCFFF
hi(0, "@constant", { fg = c.constant })
-- constant.language (true/false/null) → #BB9AF7
hi(0, "@constant.builtin", { fg = c.purple })
hi(0, "@constant.macro", { fg = c.purple })

-- Strings
hi(0, "@string", { fg = c.string })
-- constant.character.escape → #D19A66
hi(0, "@string.escape", { fg = c.escape })
hi(0, "@string.regexp", { fg = c.regexp })
hi(0, "@string.special", { fg = c.escape })
-- punctuation.definition.template-expression → #BB9AF7
hi(0, "@string.special.symbol", { fg = c.purple })

-- Numbers
hi(0, "@number", { fg = c.number })
hi(0, "@number.float", { fg = c.number })
-- constant.language → #BB9AF7
hi(0, "@boolean", { fg = c.purple })

-- Operators
-- keyword.operator → #d4d4d4
hi(0, "@operator", { fg = c.operator })
hi(0, "@punctuation.delimiter", { fg = c.operator })
hi(0, "@punctuation.bracket", { fg = c.operator })
-- punctuation.definition.template-expression, punctuation.section.embedded → #BB9AF7
hi(0, "@punctuation.special", { fg = c.purple })

-- Tags (HTML/XML)
hi(0, "@tag", { fg = c.tag })
hi(0, "@tag.attribute", { fg = c.attribute })
hi(0, "@tag.delimiter", { fg = "#808080" })

-- Namespaces: entity.name.namespace → #36C0C0 (via "Types declaration" rule)
hi(0, "@namespace", { fg = c.type })
hi(0, "@module", { fg = c.type })
hi(0, "@label", { fg = c.entity_name })
hi(0, "@attribute", { fg = c.attribute })

-- Markup (Markdown etc.)
hi(0, "@markup.heading", { fg = c.purple, bold = true })
hi(0, "@markup.bold", { fg = c.purple, bold = true })
hi(0, "@markup.italic", { italic = true })
hi(0, "@markup.strikethrough", { strikethrough = true })
hi(0, "@markup.underline", { underline = true })
hi(0, "@markup.link", { fg = c.blue_light })
hi(0, "@markup.link.url", { fg = c.blue_light, underline = true })
hi(0, "@markup.raw", { fg = c.string })
hi(0, "@markup.list", { fg = "#6796e6" })
hi(0, "@markup.quote", { fg = c.comment })

-- Diffs
hi(0, "@diff.plus", { fg = c.green })
hi(0, "@diff.minus", { fg = c.red })
hi(0, "@diff.delta", { fg = c.purple })

-- ============================================================
-- Diagnostics
-- ============================================================
hi(0, "DiagnosticError", { fg = c.error })
hi(0, "DiagnosticWarn", { fg = c.warn })
hi(0, "DiagnosticInfo", { fg = c.info })
hi(0, "DiagnosticHint", { fg = c.hint })
hi(0, "DiagnosticUnnecessary", { fg = c.fg_dim })

hi(0, "DiagnosticUnderlineError", { sp = c.error, undercurl = true })
hi(0, "DiagnosticUnderlineWarn", { sp = c.warn, undercurl = true })
hi(0, "DiagnosticUnderlineInfo", { sp = c.info, undercurl = true })
hi(0, "DiagnosticUnderlineHint", { sp = c.hint, undercurl = true })

hi(0, "DiagnosticSignError", { fg = c.error })
hi(0, "DiagnosticSignWarn", { fg = c.warn })
hi(0, "DiagnosticSignInfo", { fg = c.info })
hi(0, "DiagnosticSignHint", { fg = c.hint })

-- ============================================================
-- Git signs (gitsigns.nvim)
-- ============================================================
hi(0, "GitSignsAdd", { fg = c.git_add })
hi(0, "GitSignsChange", { fg = c.git_mod })
hi(0, "GitSignsDelete", { fg = c.git_del })

-- ============================================================
-- Telescope
-- ============================================================
hi(0, "TelescopeBorder", { fg = "#2e3347", bg = c.none })
hi(0, "TelescopeNormal", { fg = c.fg, bg = c.none })
hi(0, "TelescopePromptNormal", { fg = c.fg, bg = c.none })
hi(0, "TelescopePromptBorder", { fg = c.bg_float, bg = c.none })
hi(0, "TelescopePromptTitle", { fg = c.bg, bg = c.red })
hi(0, "TelescopePreviewTitle", { fg = c.bg, bg = c.green })
hi(0, "TelescopeResultsTitle", { fg = c.bg, bg = c.blue })
hi(0, "TelescopeSelection", { fg = c.fg, bg = "#2e3347" })
hi(0, "TelescopeMatching", { fg = c.red })

-- ============================================================
-- nvim-cmp (completion)
-- ============================================================
hi(0, "CmpItemAbbr", { fg = c.fg })
hi(0, "CmpItemAbbrMatch", { fg = c.red, bold = true })
hi(0, "CmpItemAbbrMatchFuzzy", { fg = c.red })
hi(0, "CmpItemAbbrDeprecated", { fg = c.fg_dim, strikethrough = true })
hi(0, "CmpItemKind", { fg = c.blue })
hi(0, "CmpItemMenu", { fg = c.fg_dim })

-- ============================================================
-- indent-blankline
-- ============================================================
hi(0, "IblIndent", { fg = "#2e3347" })
hi(0, "IblScope", { fg = c.bg_search })

-- ============================================================
-- neo-tree / nvim-tree
-- ============================================================
hi(0, "NeoTreeNormal", { fg = c.fg, bg = c.none })
hi(0, "NeoTreeNormalNC", { fg = c.fg, bg = c.none })
hi(0, "NeoTreeWinSeparator", { fg = c.bg_sidebar })
hi(0, "NvimTreeNormal", { fg = c.fg, bg = c.none })

-- ============================================================
-- Lualine custom highlights
-- ============================================================
hi(0, "LualineBranch", { fg = "#73daca", bg = c.bg_dark, bold = true })

-- ============================================================
-- LSP semantic tokens (nvim 0.9+)
-- These are CRITICAL for C# and similar languages where
-- Treesitter alone can't distinguish types/namespaces/methods.
-- ============================================================

-- Base type mappings
hi(0, "@lsp.type.class", { fg = c.type }) -- entity.name.class → #36C0C0
hi(0, "@lsp.type.struct", { fg = c.type }) -- entity.name.type → #36C0C0
hi(0, "@lsp.type.enum", { fg = c.type }) -- entity.name.type → #36C0C0
hi(0, "@lsp.type.interface", { fg = c.type }) -- entity.name.type → #36C0C0
hi(0, "@lsp.type.typeParameter", { fg = c.type }) -- entity.name.type → #36C0C0
hi(0, "@lsp.type.namespace", { fg = c.type }) -- entity.name.namespace → #36C0C0
hi(0, "@lsp.type.type", { fg = c.type }) -- entity.name.type → #36C0C0

-- Functions and methods
hi(0, "@lsp.type.function", { fg = c.func }) -- entity.name.function → #E5C07B
hi(0, "@lsp.type.method", { fg = c.func }) -- entity.name.function → #E5C07B
hi(0, "@lsp.type.decorator", { fg = c.attribute })

-- Variables and parameters
hi(0, "@lsp.type.variable", { fg = c.variable }) -- variable → #ACCFD7
hi(0, "@lsp.type.parameter", { fg = c.variable }) -- variable.parameter → #ACCFD7
hi(0, "@lsp.type.property", { fg = c.variable }) -- variable.other.property → #ACCFD7
hi(0, "@lsp.type.enumMember", { fg = c.constant }) -- variable.other.enummember → #7DCFFF

-- Keywords and operators
hi(0, "@lsp.type.keyword", { fg = c.purple }) -- keyword → #BB9AF7
hi(0, "@lsp.type.operator", { fg = c.operator }) -- keyword.operator → #d4d4d4
hi(0, "@lsp.type.number", { fg = c.number })
hi(0, "@lsp.type.string", { fg = c.string })
hi(0, "@lsp.type.macro", { fg = c.purple })

-- Semantic token modifiers
hi(0, "@lsp.mod.constant", { fg = c.constant }) -- variable.other.constant → #7DCFFF
hi(0, "@lsp.mod.defaultLibrary", { fg = c.func })
hi(0, "@lsp.mod.static", {}) -- don't override color for static
hi(0, "@lsp.typemod.function.defaultLibrary", { fg = c.func })
hi(0, "@lsp.typemod.method.defaultLibrary", { fg = c.func })
hi(0, "@lsp.typemod.variable.readonly", {}) -- don't change color just for readonly

-- C# specific: ensure storage types like "string", "int" as keywords get purple
-- OmniSharp/roslyn semantic tokens mark these as "keyword" type
hi(0, "@lsp.typemod.keyword.controlFlow", { fg = c.blue }) -- if/for/while → #7AA2F7

-- Ensure class/struct/namespace names are always #36C0C0 even in declarations
hi(0, "@lsp.typemod.class.declaration", { fg = c.type })
hi(0, "@lsp.typemod.struct.declaration", { fg = c.type })
hi(0, "@lsp.typemod.enum.declaration", { fg = c.type })
hi(0, "@lsp.typemod.interface.declaration", { fg = c.type })
hi(0, "@lsp.typemod.namespace.declaration", { fg = c.type })

-- Ensure function declarations also stay #E5C07B
hi(0, "@lsp.typemod.function.declaration", { fg = c.func })
hi(0, "@lsp.typemod.method.declaration", { fg = c.func })
