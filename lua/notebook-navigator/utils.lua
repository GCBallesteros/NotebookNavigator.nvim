local utils = {}

utils.get_cell_marker = function(bufnr, cell_markers)
  local ft = vim.bo[bufnr].filetype

  if ft == nil or ft == "" then
    error "Empty filetype"
  elseif cell_markers[ft] == nil then
    error("There's no cell marker defined for filetype " .. ft)
  end

  return cell_markers[ft]
end

return utils
