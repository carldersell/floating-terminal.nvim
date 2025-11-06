local Config = require("floating-terminal.config")

local M = {}

local state = {
  floating = { buf = -1, win = -1 },
  bottom = { buf = -1, win = -1 },
}

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function resolve_size(value, max)
  if type(value) == "number" then
    if value <= 1 then
      return math.floor(max * value)
    else
      return math.floor(value)
    end
  end
  return max
end

local function floating_defaults()
  return {
    width = resolve_size(Config.options.floating.width, vim.o.columns),
    height = resolve_size(Config.options.floating.height, vim.o.lines),
  }
end

local function bottom_defaults()
  return {
    height = resolve_size(Config.options.bottom.height, vim.o.lines),
  }
end

------------------------------------------------------------
-- Window Creation
------------------------------------------------------------

local function create_floating_window(opts)
  opts = opts or {}
  local defaults = floating_defaults()

  local width = opts.width or defaults.width
  local height = opts.height or defaults.height

  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)
  local buf = vim.api.nvim_buf_is_valid(opts.buf) and opts.buf or vim.api.nvim_create_buf(false, true)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
  })

  return { buf = buf, win = win }
end

local function create_bottom_window(opts)
  opts = opts or {}
  local defaults = bottom_defaults()

  local width = vim.o.columns
  local height = opts.height or defaults.height
  local buf = vim.api.nvim_buf_is_valid(opts.buf) and opts.buf or vim.api.nvim_create_buf(false, true)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = 0,
    row = vim.o.lines - height,
    style = "minimal",
    border = "single",
  })

  return { buf = buf, win = win }
end

------------------------------------------------------------
-- Toggle Logic
------------------------------------------------------------

local function toggle_terminal(state_entry, create_window, command, width, height)
  if not vim.api.nvim_win_is_valid(state_entry.win) then
    local tmp = create_window({
      buf = state_entry.buf,
      width = width,
      height = height,
    })

    state_entry.buf = tmp.buf
    state_entry.win = tmp.win

    if vim.bo[state_entry.buf].buftype ~= "terminal" then
      vim.cmd("terminal")
    end

    if command then
      vim.fn.chansend(vim.b.terminal_job_id, command .. "\r\n")
    end
  else
    vim.api.nvim_win_hide(state_entry.win)
  end
end

------------------------------------------------------------
-- Public API
------------------------------------------------------------

function M.toggle_floating_terminal(command, width, height)
  toggle_terminal(state.floating, create_floating_window, command, width, height)
end

function M.toggle_bottom_terminal(command, height)
  toggle_terminal(state.bottom, function(opts)
    opts.height = height
    return create_bottom_window(opts)
  end, command, nil, height)
end

------------------------------------------------------------
-- Setup
------------------------------------------------------------

function M.setup(opts)
  local conf = Config.apply(opts)

  if conf.default_keymaps then
    vim.keymap.set("n", conf.keymaps.toggle_floating, M.toggle_floating_terminal, { desc = "Toggle Floating Terminal" })
    vim.keymap.set("t", conf.keymaps.toggle_floating, M.toggle_floating_terminal, { desc = "Toggle Floating Terminal" })

    vim.keymap.set("n", conf.keymaps.toggle_bottom, M.toggle_bottom_terminal, { desc = "Toggle Bottom Terminal" })
    vim.keymap.set("t", conf.keymaps.toggle_bottom, M.toggle_bottom_terminal, { desc = "Toggle Bottom Terminal" })
  end
end

return M
