if vim.g.loaded_floating_terminal then
  return
end
vim.g.loaded_floating_terminal = true

local terminal = require("floating-terminal")

vim.api.nvim_create_user_command("ToggleFloatingTerminal", function(opts)
  terminal.toggle_floating_terminal(opts.args)
end, { nargs = "?" })

vim.api.nvim_create_user_command("ToggleBottomTerminal", function(opts)
  terminal.toggle_bottom_terminal(opts.args)
end, { nargs = "?" })

vim.api.nvim_create_user_command("ResizeFloatingTerminal", function(opts)
  local args = vim.split(opts.args, " ")
  local width = tonumber(args[1])
  local height = tonumber(args[2])
  terminal.toggle_floating_terminal(nil, width, height)
end, { nargs = "?" })

vim.api.nvim_create_user_command("ResizeBottomTerminal", function(opts)
  local height = tonumber(opts.args)
  terminal.toggle_bottom_terminal(nil, height)
end, { nargs = "?" })
