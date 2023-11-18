local repls = {}

utils = require "notebook-navigator.utils"

-- iron.nvim
repls.iron = function(start_line, end_line, repl_args)
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, 0)
  require("iron.core").send(nil, lines)
end

-- toggleterm
repls.toggleterm = function(start_line, end_line, repl_args)
  local id = 1
  local trim_spaces = true
  if repl_args then
    id = repl_args.id or 1
    trim_spaces = (repl_args.trim_spaces == nil) or repl_args.trim_spaces
  end
  local current_window = vim.api.nvim_get_current_win()
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, 0)

  if not lines or not next(lines) then
    return
  end

  for _, line in ipairs(lines) do
    local l = trim_spaces and line:gsub("^%s+", ""):gsub("%s+$", "") or line
    require("toggleterm").exec(l, id)
  end

  -- Jump back with the cursor where we were at the beginning of the selection
  local cursor_line, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_set_current_win(current_window)

  vim.api.nvim_win_set_cursor(current_window, { cursor_line, cursor_col })
end

-- no repl
repls.no_repl = function(_) end

local get_repl = function(repl_provider)
  local available_repls = utils.available_repls
  local chosen_repl = nil
  if repl_provider == "auto" then
    for _, r in ipairs(available_repls) do
      chosen_repl = repls[r]
    end
  else
    chosen_repl = repls[repl_provider]
  end

  -- Check if we actuall got out a supported repl
  if chosen_repl == nil then
    vim.notify("[NotebookNavigator] The provided repl, " .. repl_provider .. ", is not supported.")
    chosen_repl = repls["no_repl"]
  end

  return chosen_repl
end

return get_repl
