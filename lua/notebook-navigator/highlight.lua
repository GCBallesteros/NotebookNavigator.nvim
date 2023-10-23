local core = require "notebook-navigator.core"

local highlight = {}

highlight.minihipatterns_spec = function(cell_markers, hl_group)
  local notebook_cells = {
      pattern = function(buf_id)
        local buf_ft = vim.bo[buf_id].filetype
          local cell_marker = cell_markers[buf_ft]
          if cell_marker then
            local regex_cell_marker = string.gsub("^"..cell_marker, "%%", "%%%%")
            return regex_cell_marker
         else
           return nil
         end
      end,
      group = '',
      extmark_opts = { line_hl_group = hl_group, hl_eol = true}
    }
  return notebook_cells
end

return highlight
