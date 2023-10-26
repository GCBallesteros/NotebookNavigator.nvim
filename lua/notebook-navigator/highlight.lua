local core = require "notebook-navigator.core"

local highlight = {}

highlight.minihipatterns_spec = function(cell_markers, hl_group)
  local notebook_cells = {
    pattern = function(buf_id)
      local buf_ft = vim.bo[buf_id].filetype
      local cell_marker = cell_markers[buf_ft]
      if cell_marker then
        local regex_cell_marker = string.gsub("^" .. cell_marker, "%%", "%%%%")
        return regex_cell_marker
      else
        return nil
      end
    end,
    group = "",
    extmark_opts = {
      virt_text = {
        {
          "───────────────────────────────────────────────────────────────",
          hl_group,
        },
      },
      line_hl_group = hl_group,
      hl_eol = true,
    },
  }
  return notebook_cells
end

highlight.setup_autocmd_syntax_highlights = function(cell_markers, hl_group)
  vim.api.nvim_create_augroup("NotebookNavigator", { clear = true })

  -- Create autocmd for every language
  for ft, marker in pairs(cell_markers) do
    local syntax_rule = [[ /^\s*]] .. marker .. [[.*$/]]
    local syntax_cmd = "syntax match CodeCell" .. syntax_rule
    vim.api.nvim_create_autocmd("FileType", {
      pattern = ft,
      group = "NotebookNavigator",
      command = syntax_cmd,
    })
  end
  vim.api.nvim_set_hl(0, "CodeCell", { link = hl_group })
  vim.api.nvim_exec_autocmds("FileType", { group = "NotebookNavigator" })
end

return highlight
