local core = require "notebook-navigator.core"

local highlight = {}

function highlight.highlight_cells(cell_marker, hl_group)
  local cell_lines = core.all_cell_positions(cell_marker)
  local ns_id = vim.api.nvim_create_namespace('cells')
  vim.api.nvim_buf_clear_namespace(0,ns_id,0,-1)
  for _,line in ipairs(cell_lines) do
      vim.api.nvim_buf_set_extmark(0,ns_id,line-1,-1,{hl_eol=true,line_hl_group=hl_group})
  end
end

return highlight
