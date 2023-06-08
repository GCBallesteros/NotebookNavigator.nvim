local commenters = {}

-- comment.nvim
commenters.comment_nvim = function(cell_object)
  local comment = require "Comment.api"
  local curr_pos = vim.api.nvim_win_get_cursor(0)
  local n_lines = cell_object.to.line - cell_object.from.line + 1

  vim.api.nvim_win_set_cursor(0, { cell_object.from.line, 0 })
  comment.toggle.linewise.count(n_lines)
  vim.api.nvim_win_set_cursor(0, curr_pos)
end

-- mini.comment
commenters.mini_comment = function(cell_object)
  local comment = require "mini.comment"
  comment.toggle_lines(cell_object.from.line, cell_object.to.line)
end

-- no recognized comment plugin
commenters.no_comments = function(_)
  vim.notify "[Notebook Navigator] No supported comment plugin available"
end

local has_mini_comment, _ = pcall(require, "mini.comment")
local has_comment_nvim, _ = pcall(require, "Comment.api")
local commenter
if has_mini_comment then
  commenter = commenters["mini_comment"]
elseif has_comment_nvim then
  commenter = commenters["comment_nvim"]
else
  commenter = commenters["no_comments"]
end

return commenter
