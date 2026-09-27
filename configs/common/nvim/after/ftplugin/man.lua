-- Neovim's man plugin paints manBold/manUnderline on top of syntax, so bold
-- headings and refs (and the underlined header) would take those colors.
-- Re-apply them one level higher.
-- Colors live in colors/tokyo-dark-plus.lua; this only decides what sits on top.
local ns = vim.api.nvim_create_namespace("user.man")
vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)

local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
local footer = #lines -- last non-blank line (:Man leaves a trailing blank, MANPAGER doesn't)
while footer > 1 and lines[footer]:match("^%s*$") do
  footer = footer - 1
end

local function paint(row, s, e, group)
  vim.api.nvim_buf_set_extmark(0, ns, row, s, { end_col = e, hl_group = group, priority = 4200 })
end

for i, line in ipairs(lines) do
  local row = i - 1
  if i == 1 then
    paint(row, 0, #line, "manHeader")
  elseif i == footer then
    paint(row, 0, #line, "manFooter")
  else
    if line:match("^%S") then
      paint(row, 0, #line, "manSectionHeading")
    elseif line:match("^   %S") then
      paint(row, 3, #line, "manSubHeading")
    end
    for s, e in line:gmatch("()[^()%s]+%(%w+%)()") do -- refs like fuzzel(1)
      paint(row, s - 1, e - 1, "manReference")
    end
  end
end
