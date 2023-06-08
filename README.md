# 🚢 Notebook Navigator 🚢

Notebook Navigator lets you manipulate and send code cells to a REPL.

A great feature that comes on by default with VSCode is the ability to define
code cells and send them to a REPL like you would do in a Jupyter notebook but
without the hassle of notebook files. Notebook Navigator brings you back that
functionality and more!

Notebook Navigator comes with the following functions and features:
- Jump up/down between cells
- Execute cell (with and without jumping to the next one)
- Create cells before/after the current one
- Comment whole cells
- A [mini.ai](https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-ai.md) textobject
  specification that you can use standalone.
- A [Hydra](https://github.com/anuvyklack/hydra.nvim) mode to quickly manipulate and execute
  cells.

This plugin also pairs really well with tools like Jupytext that allow you to
convert easily between `ipynb` and `py` files. For this you may want to use a
plugin such as [jupytext.vim](GCBallesteros/jupytext.vim)  (my fork with some
extras) or the [original repo](goerz/jupytext.vim).

Here is the video everybody is waiting for!

This plugin is an evolution of my previous setup which you can find
[here](https://www.maxwellrules.com/misc/nvim_jupyter.html).

## What is a code cell?
A code cell is any code between a cell marker, usually a specially designated comment
and the next cell marker or the end of the buffer. The first line of a buffer has an 
implicit cell marker before it.

For example here are a bunch of cells on a Python script
```python
print("Cell 1")
# %%
print("This is cell 2!")
# %%
print("This is the last cell!")
```


## Installation
Here is my [lazy.nvim](https://github.com/folke/lazy.nvim) specification for Notebook
Navigator.

I personally like to have the moving between cell commands and cell executing functions
available through leader keymaps but will turn to the Hydra head when many cells need to
be executed (just by smashing `x`) or for less commonly used functionality.
```lua
{
  "GBallesteros/notebook-navigator.nvim",
  keys = {
    { "]h", function() require("notebook-navigator").move_cell "d" end },
    { "[h", function() require("notebook-navigator").move_cell "u" end },
    { "<leader>X", "<cmd>lua require('notebook-navigator').execute_cell()<cr>" },
    { "<leader>x", "<cmd>lua require('notebook-navigator').execute_and_move()<cr>" },
  },
  dependencies = {
    "echasnovski/mini.comment",
    "hkupty/iron.nvim",
    "anuvyklack/hydra.nvim",
  },
  event = "VeryLazy",
  config = function()
    local nn = require "notebook-navigator"
    nn.setup({ activate_hydra_keys = "<leader>h" })
  end,
}
```

## Detailed configuration
Any options that are not specified when calling `setup` will take on their default values.
This is the default config:
```lua
{
  -- Code cell marker. Cells start with the marker and end either at the beginning
  -- of the next cell or at the end of the file.
  cell_marker = "# %%",
  -- If not `nil` the keymap defined in the string will activate the hydra head.
  -- If you don't want to use hydra you don't need to install it either.
  activate_hydra_keys = nil,
  -- If `true` a hint panel will be shown when the hydra head is active. If `false`
  -- you get a minimalistic hint on the command line.
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
```

## Dependencies
The only hard dependency is on `iron.nvim` which provides the REPL, although
support for others like `conjure` or `yarepl` may be added if people want them
or are willing to send in PRs.

Commenting cells of code depends on an external plugin. Either
[comment.nvim](https://github.com/numToStr/Comment.nvim) or
[mini.comment](https://github.com/echasnovski/mini.comment) the two most
popular choices by quite a bit. If you want support for more PRs are welcome.

Finally, 'mini.ai' is not a dependency but if you want to use the provided
textobject specification (highly recommended) you will then need to have it
installed.


## Yanking/Deleting cells
If you setup the mini.ai integration (see below) you can then do things like,
`dah` to delete a cell, `yih` to copy just the code or `vah` to select the full
cell in visual mode. (y)ank, (d)elete and (v)isual also work while inside the
Hydra mode!

## Mini.ai integration
The `miniai_spec` function is also a valid mini.ai textobject specification.
Just add it to the custom_textobjects and of you are of to the races!

All you need is to add the textobject specification to the 'mini.ai' `custom_textobjects`

```lua
local nn = require "notebook-navigator"
local ai = require "mini.ai"

ai.setup(
  {
    custom_textobjects = {
      h = nn.miniai_spec,
    },
  }
)
```
