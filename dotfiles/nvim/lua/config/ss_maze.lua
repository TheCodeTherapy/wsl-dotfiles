local maze = {
  timer = nil,
}

local debugInfo = false

local MAP_WIDTH, MAP_HEIGHT = 60, 60
local anticipation_distance = 6.0
local speed = 0.125
local ROTATION_STEPS = 12
local ROTATION_INCREMENT = (math.pi / 2) / ROTATION_STEPS

local shading_string = ".-':_,^=;><+!rc*/z?sLTv)J7(|Fi{C}fI31tlu[neoZ5Yxjya]2ESwqkP6h9d4VpOGbUAKXHm8RD#$Bg0MNWQ%&@"

local max_shades = 64
local dark_gray_min, dark_gray_max = 0x03, 0x12
local light_gray_min, light_gray_max = 0x07, 0x17
local blue_min, blue_max = 0x12, 0xBB

local playerX, playerY = 3.0, 3.0
local dirX, dirY = 1.0, 0.0
local angle, rotating, rotationProgress = 0.0, 0, 0
local last_rotation = 0
local worldMap = {}

local ns = vim.api.nvim_create_namespace("screensaver-maze")

local fake_buf
local extmark_id = nil

local last_notified_turn = nil

local turn_delay_counter = 0
local TURN_DELAY_THRESHOLD = 4
local dice_rolled = false
local rng = -1

local function generate_shades()
  for i = 1, max_shades do
    -- Ceiling
    local d = math.floor(dark_gray_min + ((dark_gray_max - dark_gray_min) / (max_shades - 1)) * (i - 1))
    vim.cmd(string.format([[hi Ceiling%d guibg=#%02x%02x%02x]], i, d, d, d))

    -- Floor
    local l = math.floor(light_gray_min + ((light_gray_max - light_gray_min) / (max_shades - 1)) * (i - 1))
    vim.cmd(string.format([[hi Floor%d guibg=#%02x%02x%02x]], i, l, l, l))

    -- Walls
    local b = math.floor(blue_min + ((blue_max - blue_min) / (max_shades - 1)) * (i - 1))
    local fg_r = math.min(0xFF, math.floor(b * 0.7))
    local fg_g = math.min(0xFF, math.max(0x00, math.floor(b * 0.9)))
    local fg_b = math.min(0xFF, math.floor(b * 1.2))
    vim.cmd(string.format([[hi Wall%d guibg=#%02x%02x%02x guifg=#%02x%02x%02x]], i, 0x00, 0x00, 0x20, fg_r, fg_g, fg_b))
  end
end

local function split_string(input)
  local t = {}
  for c in input:gmatch(".") do
    table.insert(t, c)
  end
  return t
end

local shading_chars = split_string(shading_string)

local function is_wall(x, y)
  local mapX, mapY = math.floor(x), math.floor(y)
  return worldMap[mapY] and worldMap[mapY][mapX] == "1"
end

local function generate_maze()
  worldMap = {}

  -- Initialize maze with walls
  for y = 1, MAP_HEIGHT do
    worldMap[y] = {}
    for x = 1, MAP_WIDTH do
      worldMap[y][x] = "1" -- Fill with walls
    end
  end

  -- Define maze carving function using Recursive Backtracking
  local function carve_maze(x, y)
    worldMap[y][x] = "0" -- Open the path

    local directions = {
      { x = 0, y = -2 },
      { x = 0, y = 2 },
      { x = -2, y = 0 },
      { x = 2, y = 0 },
    }

    -- Shuffle directions
    for i = #directions, 2, -1 do
      local j = math.random(i)
      directions[i], directions[j] = directions[j], directions[i]
    end

    for _, dir in ipairs(directions) do
      local nx, ny = x + dir.x, y + dir.y
      if nx > 1 and ny > 1 and nx < MAP_WIDTH and ny < MAP_HEIGHT and worldMap[ny][nx] == "1" then
        worldMap[ny - dir.y / 2][nx - dir.x / 2] = "0" -- Break wall between cells
        carve_maze(nx, ny)
      end
    end
  end

  -- Ensure outer walls
  for x = 1, MAP_WIDTH do
    worldMap[1][x], worldMap[MAP_HEIGHT][x] = "1", "1"
  end

  for y = 1, MAP_HEIGHT do
    worldMap[y][1], worldMap[y][MAP_WIDTH] = "1", "1"
  end

  -- Generate the maze starting from (3,3)
  carve_maze(3, 3)

  -- Set player start position
  repeat
    playerX, playerY = 3 + math.random(MAP_WIDTH - 6), 3 + math.random(MAP_HEIGHT - 6)
  until not is_wall(playerX, playerY)
  if debugInfo then
    vim.notify(string.format("Player start position: (%d, %d)", playerX, playerY))
  end
end

local function rotate_player()
  if rotating ~= 0 then
    angle = angle + rotating * ROTATION_INCREMENT
    dirX, dirY = math.cos(angle), math.sin(angle)
    rotationProgress = rotationProgress + 1

    if rotationProgress >= ROTATION_STEPS then
      last_rotation = rotating -- Store last rotation
      rotating, rotationProgress = 0, 0
    end
  end
end

local function get_valid_rotations()
  local possible_rotations = {}

  -- Try turning right
  local right_angle = angle + (math.pi / 2)
  local right_dirX, right_dirY = math.cos(right_angle), math.sin(right_angle)
  if not is_wall(playerX + right_dirX, playerY + right_dirY) then
    table.insert(possible_rotations, 1)
  end

  -- Try turning left
  local left_angle = angle - (math.pi / 2)
  local left_dirX, left_dirY = math.cos(left_angle), math.sin(left_angle)
  if not is_wall(playerX + left_dirX, playerY + left_dirY) then
    table.insert(possible_rotations, -1)
  end

  return possible_rotations
end

local function cast_ray(x, y, dx, dy)
  local dist = 0
  while not is_wall(x + dx * dist, y + dy * dist) do
    dist = dist + 1
  end
  return dist
end

---@diagnostic disable-next-line: unused-local, unused-function
local function draw_rays()
  if not vim.api.nvim_buf_is_valid(fake_buf) then
    return
  end

  -- Get real-time ray distances
  local forward_dist = cast_ray(playerX, playerY, dirX, dirY)
  local backward_dist = cast_ray(playerX, playerY, -dirX, -dirY)
  local right_dist = cast_ray(playerX, playerY, dirY, -dirX)
  local left_dist = cast_ray(playerX, playerY, -dirY, dirX)

  -- Format as a single-line string
  local ray_text = string.format(
    "→ Forward: %d | ← Backward: %d | ↓ Right: %d | ↑ Left: %d",
    forward_dist,
    backward_dist,
    right_dist,
    left_dist
  )

  -- Clear previous virtual text
  vim.api.nvim_buf_clear_namespace(fake_buf, ns, 0, -1)

  -- Set virtual text at the first line, single entry
  ---@diagnostic disable-next-line: deprecated
  vim.api.nvim_buf_set_virtual_text(fake_buf, ns, 0, { { ray_text, "Comment" } }, {})
end

local function check_turns()
  local forward_dist = cast_ray(playerX, playerY, dirX, dirY)
  local backward_dist = cast_ray(playerX, playerY, -dirX, -dirY)
  local left_dist = cast_ray(playerX, playerY, dirY, -dirX)
  local right_dist = cast_ray(playerX, playerY, -dirY, dirX)

  local is_near_corner = (forward_dist <= 2 or backward_dist <= 2) -- Detect if we are at a corner
  local new_turn = nil

  -- Detect a valid side corridor (not a corner)
  if not is_near_corner then
    if right_dist > 2 then
      new_turn = "Right"
    elseif left_dist > 2 then
      new_turn = "Left"
    end
  end

  if new_turn and new_turn ~= last_notified_turn then
    if debugInfo then
      vim.notify(string.format("Detected a %s passage!", new_turn))
    end
    last_notified_turn = new_turn
  end

  return new_turn
end

local function update_movement()
  if rotating ~= 0 then
    rotate_player()
    return
  end

  local futureX = playerX + dirX * anticipation_distance * speed
  local futureY = playerY + dirY * anticipation_distance * speed

  local detected_turn = check_turns() -- Check for possible turns

  if detected_turn then
    -- **Only roll for turning ONCE per corridor detection**
    if not dice_rolled then
      rng = math.random(2)
      if debugInfo then
        vim.notify(string.format("Rolling for turn: %d", rng))
      end
      dice_rolled = true
    end

    -- **Delay turn execution until the center of the corridor**
    turn_delay_counter = turn_delay_counter + 1
    if rng == 1 and turn_delay_counter >= TURN_DELAY_THRESHOLD then
      dice_rolled = false -- Reset turn roll after turning
      local new_turn_dir = detected_turn == "Left" and -1 or 1
      rotating = new_turn_dir
      turn_delay_counter = 0
      return
    end
  else
    -- Reset turn delay and roll once we're past the corridor
    turn_delay_counter = 0
    dice_rolled = false
  end

  if is_wall(futureX, futureY) then
    local possible_rotations = get_valid_rotations()

    -- Remove immediate reversal from options
    for i = #possible_rotations, 1, -1 do
      if possible_rotations[i] == -last_rotation then
        table.remove(possible_rotations, i)
      end
    end

    if #possible_rotations > 0 then
      rotating = possible_rotations[math.random(#possible_rotations)] -- Pick a valid rotation
      last_side_corridor = nil -- Reset when forced to turn around
      turn_delay_counter = 0 -- Reset counter
      dice_rolled = false
    else
      rotating = -last_rotation -- If no valid turns, force a reversal
      last_side_corridor = nil -- Reset when forced to turn around
      turn_delay_counter = 0 -- Reset counter
      dice_rolled = false
    end
  else
    playerX = playerX + dirX * speed
    playerY = playerY + dirY * speed
  end
end
--
-- **Rendering**
--

local function render(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local screenHeight = vim.o.lines
  local screenWidth = vim.o.columns

  local grid = {}
  for y = 1, screenHeight do
    grid[y] = {}
    for x = 1, screenWidth do
      grid[y][x] = { " ", "Black" }
    end
  end

  local FOV = math.pi / 2
  local projection_height = screenHeight / 2

  for x = 1, screenWidth do
    local cameraX = (2.0 * x / screenWidth - 1.0) * math.tan(FOV / 2)
    local rayDirX, rayDirY = dirX + cameraX * -dirY, dirY + cameraX * dirX

    local mapX, mapY = math.floor(playerX), math.floor(playerY)
    local deltaDistX = (rayDirX == 0) and 1e30 or math.abs(1 / rayDirX)
    local deltaDistY = (rayDirY == 0) and 1e30 or math.abs(1 / rayDirY)

    local stepX, stepY = (rayDirX < 0) and -1 or 1, (rayDirY < 0) and -1 or 1
    local sideDistX = (rayDirX < 0) and (playerX - mapX) * deltaDistX or (mapX + 1 - playerX) * deltaDistX
    local sideDistY = (rayDirY < 0) and (playerY - mapY) * deltaDistY or (mapY + 1 - playerY) * deltaDistY

    local hit, side = false, 0
    while not hit do
      if mapX < 1 or mapX > MAP_WIDTH or mapY < 1 or mapY > MAP_HEIGHT then
        break
      end
      if sideDistX < sideDistY then
        sideDistX, mapX, side = sideDistX + deltaDistX, mapX + stepX, 0
      else
        sideDistY, mapY, side = sideDistY + deltaDistY, mapY + stepY, 1
      end
      if worldMap[mapY] and worldMap[mapY][mapX] == "1" then
        hit = true
      end
    end

    local perpWallDist = (side == 0) and (mapX - playerX + (1 - stepX) / 2) / rayDirX
      or (mapY - playerY + (1 - stepY) / 2) / rayDirY

    local lineHeight = math.floor(projection_height / perpWallDist)
    local shadeIndex = math.max(1, math.min(#shading_chars, math.floor(lineHeight / screenHeight * #shading_chars)))
    local shadeChar = shading_chars[shadeIndex]

    -- **Determine Wall Wall Shade**
    local wallShadeIndex =
      math.max(1, math.min(max_shades, math.floor((1 - math.min(1, perpWallDist / 10)) * max_shades)) - 1)

    local wallShade = { shadeChar, "Wall" .. wallShadeIndex }

    for y = 1, screenHeight do
      -- Determine Floor & Ceiling Colors
      local ceilingOrFloor
      if y < screenHeight / 2 then
        -- Ceiling
        local ceilingShadeIndex =
          math.max(1, math.min(max_shades, math.floor(((screenHeight - y) / screenHeight) * max_shades)))
        ceilingOrFloor = "Ceiling" .. ceilingShadeIndex
      else
        -- Floor
        local floorShadeIndex = math.max(1, math.min(max_shades, math.floor((y / screenHeight) * max_shades)))
        ceilingOrFloor = "Floor" .. floorShadeIndex
      end

      -- Walls
      grid[y][x] = (y >= screenHeight / 2 - lineHeight / 2 and y <= screenHeight / 2 + lineHeight / 2) and wallShade
        or { " ", ceilingOrFloor }
    end
  end

  if vim.api.nvim_buf_is_valid(fake_buf) then
    extmark_id = vim.api.nvim_buf_set_extmark(fake_buf, ns, 0, 0, { virt_lines = grid, id = extmark_id })
  end
end

function maze.start(buf, config, effect_timer)
  fake_buf = buf

  if not effect_timer then
    if debugInfo then
      vim.notify("ERROR: No valid timer provided to maze.start()!", vim.log.levels.ERROR)
    end
    return
  end

  generate_shades()
  generate_maze()

  effect_timer:start(
    10,
    config.tick_time,
    vim.schedule_wrap(function()
      update_movement()
      render(fake_buf)
    end)
  )
end

function maze.stop()
  -- nothing to cleanup here
end

return maze
