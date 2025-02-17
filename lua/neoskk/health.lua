local M = {}

M.check = function()
  local neoskk = require("neoskk").instance

  vim.health.start "neoskk report"
  -- make sure setup function parameters are ok
  if neoskk.dict then
    vim.health.ok "Setup is correct"

    local n = 0
    for k, v in pairs(neoskk.dict.map) do
      n = n + 1
    end
    vim.health.info(("%d chars"):format(n))
  else
    vim.health.error "Setup is incorrect"
  end
  -- do some more checking
  -- ...
end

return M
