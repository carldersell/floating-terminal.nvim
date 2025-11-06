local M = {}

M.options = {
  default_keymaps = false,

  floating = {
    width = 0.8,  -- percentage of screen, or absolute number
    height = 0.8,
  },

  bottom = {
    height = 0.3, -- percent or number
  },

  keymaps = {
    toggle_floating = "<leader>tf",
    toggle_bottom = "<leader>tb",
  },
}

function M.apply(user_opts)
  user_opts = user_opts or {}
  M.options = vim.tbl_deep_extend("force", M.options, user_opts)
  return M.options
end

return M
