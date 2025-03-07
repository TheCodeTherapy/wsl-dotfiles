---@diagnostic disable: undefined-field
local screensaver = {}

local uv = vim.loop

local debugInfo = false

local state = {
  timer = nil,
  effect_timer = nil,
  is_running = false,
  fake_buf = nil,
  fake_win = nil,
}

local effects = {
  matrix = require("config.ss_matrix"),
  maze = require("config.ss_maze"),
}

local default_opts = {
  style = "maze",
  customcmd = "",
  after = 300,
  offset = 0,
  exclude_filetypes = {
    "TelescopePrompt",
    "NvimTree",
    "dashboard",
    "lir",
    "neo-tree",
    "help",
  },
  exclude_buftypes = { "terminal" },
  matrix = {
    tick_time = 50,
    headache = false,
  },
  maze = {
    tick_time = 50,
  },
}

local opts = default_opts

local function create_floating_window()
  local w = vim.opt.numberwidth:get() + vim.opt.foldcolumn:get() + 2

  local win_opts = {
    relative = "win",
    width = vim.o.columns - w,
    height = vim.o.lines - vim.opt.cmdheight:get() - 2,
    border = "none",
    row = 0,
    col = w,
    style = "minimal",
  }

  state.fake_buf = vim.api.nvim_create_buf(false, true)
  state.fake_win = vim.api.nvim_open_win(state.fake_buf, false, win_opts)

  vim.defer_fn(function()
    if vim.api.nvim_win_is_valid(state.fake_win) then
      vim.api.nvim_set_option_value("cursorline", false, { win = state.fake_win })
      vim.api.nvim_set_option_value("cursorcolumn", false, { win = state.fake_win })
      vim.api.nvim_set_option_value(
        "winhl",
        "Normal:Normal,CursorLine:Normal,CursorColumn:Normal,Cursor:Normal",
        { win = state.fake_win }
      )
    end
  end, 100)

  return state.fake_buf, state.fake_win
end

local function start_screensaver()
  if state.is_running then
    return
  end

  state.is_running = true

  if pcall(require, "zen-mode") and vim.fn.exists(":ZenMode") == 2 then
    require("zen-mode").toggle(true)
  end

  create_floating_window()

  local style = opts.style or "matrix"
  local effect_module = "config.ss_" .. style

  package.loaded[effect_module] = nil
  local ok, effect = pcall(require, effect_module)

  if ok and effect then
    if debugInfo then
      vim.notify("Starting screensaver effect: " .. style)
    end

    -- Stop any previous effect timer before starting a new one
    if state.effect_timer then
      if state.effect_timer:is_active() then
        state.effect_timer:stop()
      end
      if not state.effect_timer:is_closing() then
        state.effect_timer:close()
      end
    end

    state.effect_timer = uv.new_timer()

    effect.start(state.fake_buf, opts[style], state.effect_timer)
  elseif style == "customcmd" then
    vim.cmd(opts.customcmd)
  end
end

local function stop_screensaver()
  if state.is_running then
    state.is_running = false
    local style = opts.style

    if effects[style] and effects[style].stop then
      if debugInfo then
        vim.notify("Stopping screensaver effect: " .. style)
      end
      effects[style].stop()
    end

    if state.fake_win and vim.api.nvim_win_is_valid(state.fake_win) then
      vim.api.nvim_win_close(state.fake_win, true)
    end

    if state.fake_buf and vim.api.nvim_buf_is_valid(state.fake_buf) then
      vim.api.nvim_buf_delete(state.fake_buf, { force = true })
    end

    -- Stop and clean up effect timer
    if state.effect_timer then
      if state.effect_timer:is_active() then
        state.effect_timer:stop()
      end
      if not state.effect_timer:is_closing() then
        state.effect_timer:close()
      end
      state.effect_timer = nil
    end

    if debugInfo then
      vim.notify("Screensaver fully stopped")
    end
  end
end

local function reset_activity()
  if state.timer then
    stop_screensaver()
    if state.timer:is_active() then
      state.timer:stop()
    end
    if not state.timer:is_closing() then
      state.timer:close()
    end
  end

  local cooldown_time = 3000

  state.timer = uv.new_timer()
  state.timer:start(
    cooldown_time,
    0,
    vim.schedule_wrap(function()
      state.timer = uv.new_timer()
      state.timer:start(opts.after * 1000, 0, vim.schedule_wrap(start_screensaver))
    end)
  )
end

function screensaver.start_now()
  stop_screensaver()
  start_screensaver()
end

function screensaver.setup(user_opts)
  opts = vim.tbl_deep_extend("force", default_opts, user_opts or {})

  local grp = vim.api.nvim_create_augroup("screensaver", { clear = true })
  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "InsertEnter", "TextChanged" }, {
    group = grp,
    callback = reset_activity,
  })

  vim.keymap.set(
    "n",
    "<leader>rm",
    screensaver.start_now,
    { noremap = true, silent = true, desc = "Start Screensaver" }
  )
end
return screensaver
