local M = {}

local parse_foldexpr_output = function(fold_info)
  local parsed_fold_info
  if type(fold_info) == "number" then
    if fold_info == 0 then
      parsed_fold_info = { type = "no", value = 0 }
    elseif parsed_fold_info == -1 then
      parsed_fold_info = { type = "undefined", value = -1 }
    elseif parsed_fold_info > 0 then
      parsed_fold_info = { type = "number", value = fold_info }
    else
      print "Not valid treesitter_foldlevel"
    end
  elseif type(fold_info) == "string" then
    local fold_type = string.sub(fold_info, 1, 1)
    -- Check if the fold_type can casted to a number
    local fold_info_as_number = tonumber(fold_type)

    if fold_info_as_number then
      parsed_fold_info = { type = "number", value = fold_info_as_number }
    else
      local number_part = string.sub(fold_info, 2)
      parsed_fold_info = { type = fold_type, value = tonumber(number_part) }
    end
  end

  return parsed_fold_info
end

local unparse_foldexpr_output = function(fold_info)
  if fold_info.type == "no" then
    return "0"
  elseif fold_info.type == "undefined" then
    return "-1"
  elseif fold_info.type == "number" then
    return tostring(fold_info.value)
  else
    -- one of { "<", ">", "="}
    return fold_info.type .. fold_info.value
  end
end

-- this is currently just a passthrough of the expr and ignores the pattern
M.create_foldexpr_function = function(pattern)
  local foldexpr = function(lnum)
    -- here we just used the expr set by the user
    local treesitter_foldlevel = vim.treesitter.foldexpr(lnum)
    local parsed_fold_info = parse_foldexpr_output(treesitter_foldlevel)

    -- Somehow check if we are inside a cell or start of cell and then modify the parsed_fold_info
    -- and then unparse it
    -- One way to do the first thing is to regex match to the top
    -- but then performance...
    -- Plan b is to just query the extmarks created by hipattenrs! We can even
    -- give them a namespace if that is allowed otherwise just check them all against
    -- the regex
    local new_fold_info
    local inside_cell = false -- ????
    if inside_cell then
      -- Do clever stuff to modify parsed_fold_info
      parsed_fold_info = parsed_fold_info

      new_fold_info = unparse_foldexpr_output(parsed_fold_info)
    else
      new_fold_info = treesitter_foldlevel
    end

    return new_fold_info
  end

  return foldexpr
end

return M
