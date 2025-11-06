local M = {}

M.options = {
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