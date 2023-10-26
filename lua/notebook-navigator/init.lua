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
--- - Run cells (with and without jumping to the next one)
--- - Create cells before/after the current one
--- - Comment whole cells
--- - A mini.ai textobject specification that you can use standalone
--- - A Hydra mode to quickly manipulate and run cells
--- - Support for multiple languages
---
--- # Setup~
--- Just run `require("notebook-navigator").setup(opts)` as you would with most Lua
--- nvim packages. Any options that are left unspecified will take on their default
--- values.

local M = {}

local got_iron, _ = pcall(require, "iron.core")
local got_toggleterm, _ = pcall(require, "toggleterm")
local got_hydra, hydra = pcall(require, "hydra")

local core = require "notebook-navigator.core"
local utils = require "notebook-navigator.utils"

local cell_marker = function()
  return utils.get_cell_marker(0, M.config.cell_markers)
end

-- Export directly the core functions specialized for cell markers

--- Returns the boundaries of the current code cell.
---
---@param opts string Either "i" to select the inner lines of the cell or "a" for
---   the outer cell.
---
---@return table Table with keys from/to indicating the start and end of the cell.
---   The from/to fields themselves have a line and col field.
M.miniai_spec = function(opts)
  return core.miniai_spec(opts, cell_marker())
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
  return core.move_cell(dir, cell_marker())
end

--- Run the current cell under the cursor
---
---@param repl_args table|nil Optional config for the repl.
M.run_cell = function(repl_args)
  core.run_cell(cell_marker(), M.config.repl_provider, repl_args)
end

--- Run the current cell under the cursor and jump to next cell. If no next cell
--- is available it will create one like Jupyter notebooks.
---
---@param repl_args table|nil Optional config for the repl.
M.run_and_move = function(repl_args)
  core.run_and_move(cell_marker(), M.config.repl_provider, repl_args)
end

--- Comment all the contents of the cell under the cursor
---
--- The commenting functionality is supported by external plugins. Currently the
--- following are supported:
--- - mini.comment
--- - comment.nvim
M.comment_cell = function()
  core.comment_cell(cell_marker())
end

--- Create a cell under the current one and move to it
M.add_cell_after = function()
  core.add_cell_after(cell_marker())
end

--- Create a cell on top of the current one and move to it
M.add_cell_before = function()
  core.add_cell_before(cell_marker())
end

local hydra_hint = [[
_j_/_k_: move down/up  _c_: comment  _a_/_b_: add cell before/after
_x_: run & move down ^^          _X_: run
^^                _<esc>_/_q_: exit
]]

local function activate_hydra(config)
  -- `hydra_heads` contains all the potential actions that our hydra will be able
  -- to execute. After these definitions the list will get filtered down by checking
  -- if the mapped key is nil
  local hydra_heads = {
    {
      config.hydra_keys.move_up,
      function()
        M.move_cell "u"
      end,
      { desc = "Move up" },
    },
    {
      config.hydra_keys.move_down,
      function()
        M.move_cell "d"
      end,
      { desc = "Move down" },
    },
    {
      config.hydra_keys.comment,
      M.comment_cell,
      { desc = "Comment" },
    },
    {
      config.hydra_keys.run,
      M.run_cell,
      { desc = "Run", nowait = true },
    },
    {
      config.hydra_keys.run_and_move,
      M.run_and_move,
      { desc = "Run & Move", nowait = true },
    },
    {
      config.hydra_keys.add_cell_after,
      M.add_cell_after,
      { desc = "Add cell after", nowait = true },
    },
    {
      config.hydra_keys.add_cell_before,
      M.add_cell_before,
      { desc = "Add cell after", nowait = true },
    },
    { "q", nil, { exit = true, nowait = true, desc = "exit" } },
    { "<esc>", nil, { exit = true, nowait = true, desc = "exit" } },
  }

  local active_hydra_heads = {}
  for _, h in ipairs(hydra_heads) do
    if h[1] ~= "nil" then
      table.insert(active_hydra_heads, h)
    end
  end

  local hydra_config = {
    name = "NotebookNavigator",
    mode = { "n" },
    config = {
      invoke_on_body = true,
      color = "pink",
      hint = { border = "rounded" },
    },
    body = config.activate_hydra_keys,
    heads = active_hydra_heads,
  }
  if config.show_hydra_hint then
    hydra_config.hint = hydra_hint
  end

  hydra(hydra_config)
end

--- Module config
---
--- Default values:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
M.config = {
  -- Code cell marker. Cells start with the marker and end either at the beginning
  -- of the next cell or at the end of the file.
  cell_markers = { python = "# %%", lua = "-- %%", julia = "# %%", fennel = ";; %%" },
  -- If not `nil` the keymap defined in the string will activate the hydra head
  activate_hydra_keys = nil,
  -- If `true` a hint panel will be shown when the hydra head is active
  show_hydra_hint = true,
  -- Mappings while the hydra head is active.
  hydra_keys = {
    comment = "c",
    run = "X",
    run_and_move = "x",
    move_up = "k",
    move_down = "j",
    add_cell_before = "a",
    add_cell_after = "b",
  },
  -- The repl plugin with which to interface
  -- Current options: "iron" for iron.nvim, "toggleterm" for toggleterm.nvim,
  -- or "auto" which checks which of the above are installed
  repl_provider = "auto",
  -- If `true`, folding will be based on expression for buffers with a valid
  -- cell marker and cells will be folded on entering the buffer
  -- * NOTE: This will replace any previously set foldmethod for those buffers
  cell_folding = true
}
--minidoc_afterlines_end

--- Module setup
---
--- Any of the `hydra_keys` mappings can be set to `nil` in order to stop them
--- from being mapped.
---@param config table|nil Module config table. See |NotebookNavigator.config|.
---
---@usage `require('cell-navigator').setup({})` (replace `{}` with your `config` table)
---    any config parameter which you not pass will take on its default value.
M.setup = function(config)
  vim.validate({ config = { config, "table", true } })
  M.config = vim.tbl_deep_extend("force", M.config, config or {})

  vim.validate({
    cell_markers = { M.config.cell_markers, "table" },
    activate_hydra_keys = { M.config.activate_hydra_keys, "string", true },
    show_hydra_hint = { M.config.show_hydra_hint, "boolean" },
    hydra_keys = { M.config.hydra_keys, "table" },
  })

  vim.validate({
    ["config.hydra_keys.comment"] = { M.config.hydra_keys.comment, "string" },
    ["config.hydra_keys.run"] = { M.config.hydra_keys.run, "string" },
    ["config.hydra_keys.run_and_move"] = { M.config.hydra_keys.run_and_move, "string" },
    ["config.hydra_keys.move_up"] = { M.config.hydra_keys.move_up, "string" },
    ["config.hydra_keys.move_down"] = { M.config.hydra_keys.move_down, "string" },
    ["config.hydra_keys.add_cell_before"] = { M.config.hydra_keys.add_cell_before, "string" },
    ["config.hydra_keys.add_cell_after"] = { M.config.hydra_keys.add_cell_after, "string" },
  })

  for ft, marker in pairs(M.config.cell_markers) do
    vim.validate({
      ["config.cell_markers." .. ft] = { marker, "string" },
    })
  end

  if (not got_hydra) and (M.config.activate_hydra_keys ~= nil) then
    vim.notify "[NotebookNavigator] Hydra is not available.\nHydra will not be available."
  end

  if not got_iron and not got_toggleterm then
    vim.notify "[NotebookNavigator] REPL is not available.\nMost functionality will error out."
  end

  if (M.config.activate_hydra_keys ~= nil) and got_hydra then
    activate_hydra(M.config)
  end

  local cell_group = vim.api.nvim_create_augroup("Cells", {clear=true})
  if M.config.cell_folding then
    vim.api.nvim_create_autocmd("BufEnter", {
      pattern = {"*"},
      group = cell_group,
      callback = function(ev)
        local ft = vim.api.nvim_get_option_value("filetype", {buf = ev.buf})
        if M.config.cell_markers[ft] then
          local marker = M.config.cell_markers[ft]
          local vim_marker = string.gsub(marker, " ", "\\ ")
          vim.cmd[[setlocal foldmethod=expr]]
          local expr = "setlocal foldexpr=(getline(v:lnum)=~'^"..vim_marker.."')==0"
          vim.cmd(expr)
        end
      end
    })
  end
end

return M
