local utils = {}

utils.get_cell_marker = function(bufnr, cell_markers)
  local ft = vim.bo[bufnr].filetype

  if ft == nil or ft == "" then
    print "[NotebookNavigator] utils.lua: Empty filetype"
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

local find_supported_repls = function()
  local supported_repls = {
    { name = "iron", module = "iron" },
    { name = "toggleterm", module = "toggleterm" },
  }

  local available_repls = {}
  for _, repl in pairs(supported_repls) do
    if pcall(require, repl.module) then
      available_repls[#available_repls + 1] = repl.name
    end
  end

  return available_repls
end

utils.available_repls = find_supported_repls()

return utils
