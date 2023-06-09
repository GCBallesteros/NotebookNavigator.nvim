--- *NotebookNavigator.doc* Easily navigate and work with code cells
--- *NotebookNavigator*
---
--- MIT License Copyright (c) 2023 Guillem Ballesteros
---
--- ==============================================================================
---
--- Jupyter notebooks are great for prototyping and quickly iterating on an idea
--- but the are hard to version control and track how code has been executed. Both
--- issues are much less problematic when working with scripts. VSCode does this
--- better. This plugin attempts to bring the functionality of Jupyter and VSCode
--- style to neovim.
---
--- # What is a code cell?
--- A code cell is any code between a cell marker, usually a specially designated comment
--- and the next cell marker or the end of the buffer. The first line of a buffer has an
--- implicit cell marker before it.
---
--- # What comes bundled?~
--- - Jump up/down between cells
--- - Execute cell (with and without jumping to the next one)
--- - Create cells before/after the current one
--- - Comment whole cells
--- - A mini.ai textobject specification that you can use standalone.
--- - A Hydra mode to quickly manipulate and execute cells.
---
--- # Setup~
--- Just run `require("notebook-navigator").setup(opts)` as you would with most Lua
--- nvim packages. Any options that are left unspecified will take on their default
--- values.

local M = {}

-- TODO before publish
-- Organize commenters better into another function
-- test documentation install itself correct.y

local got_iron, iron = pcall(require, "iron.core")
local got_hydra, hydra = pcall(require, "hydra")
local commenter = require "notebook-navigator.commenters"

local function activate_hydra()
    hydra({
        name = "NotebookNavigator",
        mode = { "n" },
        config = {
            invoke_on_body = true,
            color = "pink",
        },
        body = M.config.activate_hydra_keys,
        heads = {
            {
                M.config.hydra_keys.move_up,
                function()
                    M.move_cell "u"
                end,
                { desc = "Move up" },
            },
            {
                M.config.hydra_keys.move_down,
                function()
                    M.move_cell "d"
                end,
                { desc = "Move down" },
            },
            {
                M.config.hydra_keys.comment,
                M.comment_cell,
                { desc = "Comment" },
            },
            {
                M.config.hydra_keys.execute,
                M.execute_cell,
                { desc = "Execute", nowait = true },
            },
            {
                M.config.hydra_keys.execute_and_move,
                M.execute_and_move,
                { desc = "Execute & Move", nowait = true },
            },
            {
                M.config.hydra_keys.add_cell_after,
                M.add_cell_after,
                { desc = "Add cell after", nowait = true },
            },
            {
                M.config.hydra_keys.add_cell_before,
                M.add_cell_before,
                { desc = "Add cell after", nowait = true },
            },
            { "q",     nil, { exit = true, nowait = true, desc = "exit" } },
            { "<esc>", nil, { exit = true, nowait = true, desc = "exit" } },
        },
    })
end

--- Module config
---
--- Default values:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
M.config = {
    -- Code cell marker. Cells start with the marker and end either at the beginning
    -- of the next cell or at the end of the file.
    cell_marker = "# %%",
    -- If not `nil` the keymap defined in the string will activate the hydra head
    activate_hydra_keys = nil,
    -- If `true` a hint panel will be shown when the hydra head is active
    show_hydra_hint = true,
    -- Mappings while the hydra head is active.
    hydra_keys = {
        comment = "c",
        execute = "X",
        execute_and_move = "x",
        move_up = "k",
        move_down = "j",
        add_cell_before = "a",
        add_cell_after = "b",
    },
}
--minidoc_afterlines_end

--- Module setup
---
---@param config table|nil Module config table. See |NotebookNavigator.config|.
---
---@usage `require('cell-navigator').setup({})` (replace `{}` with your `config` table)
---    any config parameter which you not pass will take on its default value.
M.setup = function(config)
    vim.validate({ config = { config, "table", true } })
    M.config = vim.tbl_deep_extend("force", M.config, config or {})

    vim.validate({
        cell_marker = { M.config.cell_marker, "string" },
        activate_hydra_keys = { M.config.activate_hydra_keys, "string", true },
        show_hydra_hint = { M.config.show_hydra_hint, "boolean" },
        hydra_keys = { M.config.hydra_keys, "table" },
    })

    vim.validate({
        ["config.hydra_keys.comment"] = { M.config.hydra_keys.comment, "string" },
        ["config.hydra_keys.execute"] = { M.config.hydra_keys.execute, "string" },
        ["config.hydra_keys.execute_and_move"] = { M.config.hydra_keys.execute_and_move, "string" },
        ["config.hydra_keys.move_up"] = { M.config.hydra_keys.move_up, "string" },
        ["config.hydra_keys.move_down"] = { M.config.hydra_keys.move_down, "string" },
        ["config.hydra_keys.add_cell_before"] = { M.config.hydra_keys.add_cell_before, "string" },
        ["config.hydra_keys.add_cell_after"] = { M.config.hydra_keys.add_cell_after, "string" },
    })

    if (not got_hydra) and (M.config.activate_hydra_keys ~= nil) then
        vim.notify "[NotebookNavigator] Hydra is not available.\nHydra will not be available."
    end

    if not got_iron then
        vim.notify "[NotebookNavigator] Iron is not available.\nMost functionality will error out."
    end

    if (M.config.activate_hydra_keys ~= nil) and got_hydra then
        activate_hydra()
    end
end

--- Returns the boundaries of the current code cell.
---
---@param opts string Either "i" to select the inner lines of the cell or "a" for
---   the outer cell.
---
---@return table Table with keys from/to indicating the start and end of the cell.
---   The from/to fields themselves have a line and col field.
M.miniai_spec = function(opts)
    local start_line = vim.fn.search("^" .. M.config.cell_marker, "bcnW")

    -- Just in case the notebook is malformed and doesnt  have a cell marker at the start.
    if start_line == 0 then
        start_line = 1
    else
        if opts == "i" then
            start_line = start_line + 1
        end
    end

    local end_line = vim.fn.search("^" .. M.config.cell_marker, "nW") - 1
    if end_line == -1 then
        end_line = vim.fn.line "$"
    end

    local last_col = math.max(vim.fn.getline(end_line):len(), 1)

    local from = { line = start_line, col = 1 }
    local to = { line = end_line, col = last_col }

    return { from = from, to = to }
end

--- Move between cells
---
--- Move between cells and indicate wheter we are at the first or last cell via the
--- string output.
---
---@param dir string Movement direction. "d" for down and "u" for up.
---
---@return string If movement failed return "first" or "last" if we where at the
---   first/last cell.
M.move_cell = function(dir)
    local search_res
    local result

    if dir == "d" then
        search_res = vim.fn.search("^" .. M.config.cell_marker, "W")
        if search_res == 0 then
            result = "last"
        end
    else
        search_res = vim.fn.search("^" .. M.config.cell_marker, "bW")
        if search_res == 0 then
            result = "first"
        end
    end

    return result
end

--- Execute the current cell under the cursor
M.execute_cell = function()
    local cell_object = M.miniai_spec "i"

    -- protect ourselves against the case with no actual lines of code
    local n_lines = cell_object.to.line - cell_object.from.line + 1
    if n_lines < 1 then
        return nil
    end

    local lines = vim.api.nvim_buf_get_lines(0, cell_object.from.line - 1, cell_object.to.line, 0)

    iron.send(nil, lines)
end

--- Execute the current cell under the cursor and jump to next cell. If no next cell
--- is available it will create one like Jupyter notebooks.
M.execute_and_move = function()
    M.execute_cell()
    local is_last_cell = M.move_cell "d" == "last"

    -- insert a new cell to replicate the behaviour of jupyter notebooks
    if is_last_cell then
        vim.api.nvim_buf_set_lines(0, -1, -1, false, { M.config.cell_marker, "" })
        -- and move to it
        M.move_cell "d"
    end
end

--- Comment all the contents of the cell under the cursor
---
--- The commenting functionality is supported by external plugins. Currently the
---- following are supported:
--- - mini.comment
--- - comment.nvim
M.comment_cell = function()
    local cell_object = M.miniai_spec "i"

    -- protect against empty cells
    local n_lines = cell_object.to.line - cell_object.from.line + 1
    if n_lines < 1 then
        return nil
    end
    commenter(cell_object)
end

--- Create a cell on top of the current one and move to it
M.add_cell_before = function()
    local cell_object = M.miniai_spec "a"

    -- What to do on malformed notebooks? I.e. with no upper cell marker? are they malformed?
    -- What if we have a jupytext header? Code doesn't start at top of buffer.
    vim.api.nvim_buf_set_lines(
        0,
        cell_object.from.line - 1,
        cell_object.from.line - 1,
        false,
        { M.config.cell_marker, "" }
    )
    M.move_cell "u"
end

--- Create a cell under the current one and move to it
M.add_cell_after = function()
    local cell_object = M.miniai_spec "a"

    vim.api.nvim_buf_set_lines(0, cell_object.to.line, cell_object.to.line, false, { M.config.cell_marker, "" })
    M.move_cell "d"
end

return M
