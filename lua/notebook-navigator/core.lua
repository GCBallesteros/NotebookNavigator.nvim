local commenter = require "notebook-navigator.commenters"
local get_repl = require "notebook-navigator.repls"
local miniai_spec = require("notebook-navigator.miniai_spec").miniai_spec

local M = {}

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

M.run_cell = function(cell_marker, repl_provider, repl_args)
  repl_args = repl_args or nil
  repl_provider = repl_provider or "auto"
  local cell_object = miniai_spec("i", cell_marker)

  -- protect ourselves against the case with no actual lines of code
  local n_lines = cell_object.to.line - cell_object.from.line + 1
  if n_lines < 1 then
    return nil
  end

  local repl = get_repl(repl_provider)
  return repl(cell_object.from.line, cell_object.to.line, repl_args, cell_marker)
end

M.run_and_move = function(cell_marker, repl_provider, repl_args)
  local success = M.run_cell(cell_marker, repl_provider, repl_args)

  if success then
    local is_last_cell = M.move_cell("d", cell_marker) == "last"

    -- insert a new cell to replicate the behaviour of jupyter notebooks
    if is_last_cell then
      vim.api.nvim_buf_set_lines(0, -1, -1, false, { cell_marker, "" })
      -- and move to it
      M.move_cell("d", cell_marker)
    end
  end
end

M.comment_cell = function(cell_marker)
  local cell_object = miniai_spec("i", cell_marker)

  -- protect against empty cells
  local n_lines = cell_object.to.line - cell_object.from.line + 1
  if n_lines < 1 then
    return nil
  end
  commenter(cell_object)
end

M.add_cell_before = function(cell_marker)
  local cell_object = miniai_spec("a", cell_marker)

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
  local cell_object = miniai_spec("a", cell_marker)

  vim.api.nvim_buf_set_lines(0, cell_object.to.line, cell_object.to.line, false, { cell_marker, "" })
  M.move_cell("d", cell_marker)
end

return M
