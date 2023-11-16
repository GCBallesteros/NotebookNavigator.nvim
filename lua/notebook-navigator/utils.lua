local utils = {}

utils.get_cell_marker = function(bufnr, cell_markers)
  local ft = vim.bo[bufnr].filetype

  if ft == nil or ft == "" then
    error "Empty filetype"
  end

  local user_opt_cell_marker = cell_markers[ft]
  if user_opt_cell_marker then
    return user_opt_cell_marker
  end

  -- use double percent markers as default for cell markers
  -- DOCS https://jupytext.readthedocs.io/en/latest/formats-scripts.html#the-percent-format
  if not vim.bo.commentstring then
    error("There's no cell marker and no commentstring defined for filetype " .. ft)
  end
  local double_percent_cell_marker = vim.bo.commentstring:format "%%"
  return double_percent_cell_marker
end

utils.get_valid_filetypes = function(cell_markers)
  local valid_filetypes = {}
  for k, _ in pairs(cell_markers) do
    table.insert(valid_filetypes, k)
  end
  return valid_filetypes
end

return utils
