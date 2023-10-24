local repls = {}

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
  local repl_providers = { "iron", "toggleterm" }
  if repl_provider == "auto" then
    for _, r in ipairs(repl_providers) do
      if pcall(require, r) then
        return repls[r]
      end
      vim.notify "[Notebook Navigator] None of the supported REPL providers is available. Please install iron or toggleterm"
    end
  else
    if pcall(require, repl_provider) then
      return repls[repl_provider]
    else
      vim.notify("[Notebook Navigator] The " .. repl_provider .. " REPL provider is not available.")
    end
  end
  return repls["no_repl"]
end

return get_repl
