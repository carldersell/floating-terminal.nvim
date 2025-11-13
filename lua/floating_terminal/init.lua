local Config = require("floating_terminal.config")

-- Helper for correctly closing a process
-- cross-platform process start time fetchers --------------------

local function get_process_start_time_unix(pid)
  local out = vim.fn.system({ "ps", "-o", "lstart=", "-p", tostring(pid) })
  if not out or out == "" then
    return nil
  end
  local t = vim.trim(out)
  local epoch = vim.fn.strptime("%c", t)
  return epoch > 0 and epoch or nil
end

local function get_process_start_time_windows(pid)
  local ps_cmd = string.format(
    "(Get-Process -Id %d).StartTime.ToUniversalTime().ToFileTimeUtc()",
    pid
  )
  local out = vim.fn.system({ "powershell", "-NoProfile", "-Command", ps_cmd })
  if not out or out == "" then
    return nil
  end
  -- Windows FILETIME is 100-nanosecond intervals since 1601-01-01
  local ft = tonumber((out:gsub("%s+", "")))
  if not ft then
    return nil
  end
  -- convert FILETIME to Unix epoch
  return math.floor(ft / 10000000 - 11644473600)
end

local function get_process_start_time(pid)
  if vim.fn.has("win32") == 1 then
    return get_process_start_time_windows(pid)
  else
    return get_process_start_time_unix(pid)
  end
end

-- verification --------------------------------------------------

local function is_same_process(pid, saved_start_time)
  if not (pid and saved_start_time) then
    return false
  end
  local actual = get_process_start_time(pid)
  if not actual then
    return false
  end
  -- allow small rounding difference
  return math.abs(actual - saved_start_time) < 10
end

local function cleanup(state_entry)
  if state_entry and state_entry.pid then
    local same = is_same_process(state_entry.pid, state_entry.start_time)
    if same then
      if state_entry.buf
        and state_entry.buf >= 0
        and vim.api.nvim_get_option_value('buftype', {["buf"] = state_entry.buf}) == 'terminal'
      then
        vim.cmd("bd! ".. state_entry.buf)
      end
      vim.notify("Killing running process PID: " .. state_entry.pid, vim.log.levels.WARN)
      pcall(vim.uv.kill, state_entry.pid)
    end
  end
end


local M = {}

local state = {
  floating = { buf = -1, win = -1 , id = -1, pid = nil, start_time = nil},
  bottom = { buf = -1, win = -1 , id = -1, pid = nil, start_time = nil},
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
      state_entry.id = vim.b.terminal_job_id
      state_entry.pid = vim.b.terminal_job_pid
      state_entry.start_time = os.time()
    end

    if command then
      vim.fn.chansend(state_entry.id, command .. "\r\n")
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

function M.run_in_floating_terminal(command)
  if not vim.api.nvim_win_is_valid(state.floating.win) then
    toggle_terminal(state.floating, create_floating_window, command, nil, nil)
  elseif (command) then
    vim.fn.chansend(state.floating.id, command .."\r\n")
  end
end

function M.toggle_bottom_terminal(command, height)
  toggle_terminal(state.bottom, function(opts)
    opts.height = height
    return create_bottom_window(opts)
  end, command, nil, height)
end

function M.run_in_bottom_terminal(command)
  if not vim.api.nvim_win_is_valid(state.bottom.win) then
    toggle_terminal(state.bottom, function(opts)
      return create_bottom_window(opts)
    end, command, nil, nil)
  elseif command then
    vim.fn.chansend(state.bottom.id, command .."\r\n")
  end
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


  -- Kill process and clean windows
  vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    cleanup(state.floating)
    cleanup(state.bottom)
  end,
})
end

return M
