local matrix = {
  columns_row = {},
  columns_active = {},
}
local chars =
  "A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z 0 1 2 3 4 5 6 7 8 9 ! @ # $ % ^ & * ( ) _ + - = { } [ ] | : ; < > , . ｱ ｲ ｳ ｴ ｵ ｶ ｷ ｸ ｹ ｺ ｻ ｼ ｽ ｾ ｿ ﾀ ﾁ ﾂ ﾃ ﾄ ﾅ ﾆ ﾇ ﾈ ﾉ ﾊ ﾋ ﾌ ﾍ ﾎ ﾏ ﾐ ﾑ ﾒ ﾓ ﾔ ﾕ ﾖ ﾗ ﾘ ﾙ"

local max_shades = 8
local r_min, r_max = 0x21, 0xB0
local g_min, g_max = 0x21, 0xC0
local b_min, b_max = 0x70, 0xFF

local ns = vim.api.nvim_create_namespace("screensaver-matrix")
local uv = vim.loop
local timer
local grid = {}

local function split(inp)
  local t = {}
  for str in inp:gmatch("%S+") do
    table.insert(t, str)
  end
  return t
end

local function gen_random_char(bool)
  if bool == 0 then
    return " "
  end
  return matrix.t[math.random(#matrix.t)]
end

local function render(fake_buf, id)
  for j = 1, vim.o.columns, 2 do
    if matrix.columns_row[j] == -1 then
      matrix.columns_row[j] = math.random(#grid)
      matrix.columns_active[j] = math.random(2) - 1
    end
  end

  for j = 1, vim.o.columns, 2 do
    local row = matrix.columns_row[j]
    grid[row][j] = { gen_random_char(matrix.columns_active[j]), "MyColor" .. max_shades }

    for i = 1, max_shades - 1 do
      local prev_row = row - i
      if prev_row > 0 and grid[prev_row] and grid[prev_row][j] then
        grid[prev_row][j][2] = "MyColor" .. math.max(max_shades - i, 1)
      end
    end

    matrix.columns_row[j] = matrix.columns_row[j] + 1

    if matrix.columns_row[j] > #grid then
      matrix.columns_row[j] = -1
    end
    if math.random(1000) == 0 then
      matrix.columns_active[j] = matrix.columns_active[j] == 0 and 1 or 0
    end
  end

  vim.api.nvim_buf_set_extmark(fake_buf, ns, 0, 0, { virt_lines = grid, id = id })
end

function matrix.start(fake_buf, config)
  local tick_time = config.tick_time or 50
  for i = 1, max_shades do
    local r = math.floor(r_min + ((r_max - r_min) / (max_shades - 1)) * (i - 1))
    local g = math.floor(g_min + ((g_max - g_min) / (max_shades - 1)) * (i - 1))
    local b = math.floor(b_min + ((b_max - b_min) / (max_shades - 1)) * (i - 1))
    vim.cmd(string.format([[hi MyColor%d guifg=#%02x%02x%02x]], i, r, g, b))
  end
  vim.cmd([[hi Black guifg=#000000 ctermbg=0]])

  matrix.t = split(chars)
  grid = {}

  for i = 1, vim.o.lines do
    grid[i] = {}
    for j = 1, vim.o.columns do
      grid[i][j] = { " ", "Black" }
      matrix.columns_row[j] = -1
      matrix.columns_active[j] = 0
    end
  end

  local id = vim.api.nvim_buf_set_extmark(fake_buf, ns, 0, 0, { virt_lines = grid })

  ---@diagnostic disable-next-line: undefined-field
  timer = uv.new_timer()
  timer:start(
    10,
    tick_time,
    vim.schedule_wrap(function()
      render(fake_buf, id)
    end)
  )
end

function matrix.stop()
  if timer then
    timer:stop()
    timer:close()
    timer = nil
  end
end

return matrix
