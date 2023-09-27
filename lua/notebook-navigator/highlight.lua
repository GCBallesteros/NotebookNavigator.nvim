local core = require "notebook-navigator.core"

local highlight = {}

function highlight.highlight_cell_markers(cell_marker, hl_group, ns)
  local cell_lines = core.all_cell_positions(cell_marker)
  vim.api.nvim_buf_clear_namespace(0,ns,0,-1)
  for _,line in ipairs(cell_lines) do
    highlight.highlight_cell_marker(line, hl_group, ns)
  end
  return cell_lines
end

function highlight.highlight_cell_marker(line, hl_group, ns)
    local ext_opts = {hl_eol=true,line_hl_group=hl_group}
    vim.api.nvim_buf_set_extmark(0, ns, line-1, -1, ext_opts)
end

return highlight
