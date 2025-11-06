local Config = require("floating-terminal.config")

local M = {}

local state = {
  floating = { buf = -1, win = -1 },
  bottom = { buf = -1, win = -1 },
}

local function floating_defaults()
  return {
    width = math.floor(vim.o.columns * 0.8),
    height = math.floor(vim.o.lines * 0.8),
  }
end

local function bottom_defaults()
  return {
    height = math.floor(vim.o.lines * 0.3),
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
  local height = opts.height or defaults.height
  local width = vim.o.columns

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
-- Terminal Toggle Logic
------------------------------------------------------------

local function toggle_terminal(state_entry, create_window, command, width, height)
  if not vim.api.nvim_win_is_valid(state_entry.win) then
    -- open new terminal
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
-- Setup (with overridable defaults)
------------------------------------------------------------

function M.setup(opts)
  local conf = Config.apply(opts)

  -- Set default keymaps unless overridden
  local map = function(mode, lhs, rhs, desc)
    if lhs == false then return end -- disable mapping
    vim.keymap.set(mode, lhs, rhs, { desc = desc, noremap = true, silent = true })
  end

  map("n", conf.keymaps.toggle_floating, M.toggle_floating_terminal, "[T]oggle [F]loating Terminal")
  map("t", conf.keymaps.toggle_floating, M.toggle_floating_terminal, "[T]oggle [F]loating Terminal")

  map("n", conf.keymaps.toggle_bottom, M.toggle_bottom_terminal, "[T]oggle [B]ottom Terminal")
  map("t", conf.keymaps.toggle_bottom, M.toggle_bottom_terminal, "[T]oggle [B]ottom Terminal")
end

return M
