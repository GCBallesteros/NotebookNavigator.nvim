local _, iron = pcall(require, "iron.core")
local commenter = require "notebook-navigator.commenters"

local M = {}

M.miniai_spec = function(opts, cell_marker)
  local start_line = vim.fn.search("^" .. cell_marker, "bcnW")

  -- Just in case the notebook is malformed and doesnt  have a cell marker at the start.
  if start_line == 0 then
    start_line = 1
  else
    if opts == "i" then
      start_line = start_line + 1
    end
  end

  local end_line = vim.fn.search("^" .. cell_marker, "nW") - 1
  if end_line == -1 then
    end_line = vim.fn.line "$"
  end

  local last_col = math.max(vim.fn.getline(end_line):len(), 1)

  local from = { line = start_line, col = 1 }
  local to = { line = end_line, col = last_col }

  return { from = from, to = to }
end

M.all_cell_positions = function(cell_marker)
  local vim_cmd = vim.api.nvim_parse_cmd("ilist! /^"..cell_marker.."/", {})
  vim_cmd.args = {table.concat(vim_cmd.args, " ")} -- Fix space in args (if multiple)
  local has_output, cmd_output = pcall(vim.api.nvim_cmd, vim_cmd, {output=true})
  local cell_lines = {}
  if has_output then
    for k,_ in string.gmatch(cmd_output, "%s%d+%s") do
      table.insert(cell_lines,tonumber(k))
    end
  end
  return cell_lines
end

M.move_cell = function(dir, cell_marker)
  local search_res
  local result

  if dir == "d" then
    search_res = vim.fn.search("^" .. cell_marker, "W")
    if search_res == 0 then
      result = "last"
    end
  else
    search_res = vim.fn.search("^" .. cell_marker, "bW")
    if search_res == 0 then
      result = "first"
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
    end
  end

  return result
end

M.run_cell = function(cell_marker)
  local cell_object = M.miniai_spec("i", cell_marker)

  -- protect ourselves against the case with no actual lines of code
  local n_lines = cell_object.to.line - cell_object.from.line + 1
  if n_lines < 1 then
    return nil
  end

  local lines = vim.api.nvim_buf_get_lines(0, cell_object.from.line - 1, cell_object.to.line, 0)

  iron.send(nil, lines)
end

M.run_and_move = function(cell_marker)
  M.run_cell(cell_marker)
  local is_last_cell = M.move_cell("d", cell_marker) == "last"

  -- insert a new cell to replicate the behaviour of jupyter notebooks
  if is_last_cell then
    vim.api.nvim_buf_set_lines(0, -1, -1, false, { cell_marker, "" })
    -- and move to it
    M.move_cell("d", cell_marker)
  end
end

M.comment_cell = function(cell_marker)
  local cell_object = M.miniai_spec("i", cell_marker)

  -- protect against empty cells
  local n_lines = cell_object.to.line - cell_object.from.line + 1
  if n_lines < 1 then
    return nil
  end
  commenter(cell_object)
end

M.add_cell_before = function(cell_marker)
  local cell_object = M.miniai_spec("a", cell_marker)

  -- What to do on malformed notebooks? I.e. with no upper cell marker? are they malformed?
  -- What if we have a jupytext header? Code doesn't start at top of buffer.
  vim.api.nvim_buf_set_lines(
    0,
    cell_object.from.line - 1,
    cell_object.from.line - 1,
    false,
    { cell_marker, "" }
  )
  M.move_cell("u", cell_marker)
end

M.add_cell_after = function(cell_marker)
  local cell_object = M.miniai_spec("a", cell_marker)

  vim.api.nvim_buf_set_lines(0, cell_object.to.line, cell_object.to.line, false, { cell_marker, "" })
  M.move_cell("d", cell_marker)
end

return M
