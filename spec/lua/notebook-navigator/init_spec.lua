describe("init", function()
  local M = require "notebook-navigator"

  before_each(function()
    M.setup({
      cell_markers = { python = "# %%" },
    })

    vim.bo.filetype = "python"
  end)

  after_each(function()
    require("vusted.helper").cleanup()
  end)

  describe("move_cell", function()
    before_each(function()
      vim.api.nvim_buf_set_lines(0, 0, 0, false, {
        "# %%",
        "print('hello')",
        "# %%",
        "print('world')",
      })
    end)

    it("should move to the cell marker of current cell when dir is 'u' and cursor is in the cell", function()
      vim.api.nvim_win_set_cursor(0, { 4, 0 })

      M.move_cell "u"
      local actual = vim.api.nvim_win_get_cursor(0)[1]
      local expected = 3

      assert.are.same(expected, actual)
    end)

    it("should move to upper cell when dir is 'u'", function()
      vim.api.nvim_win_set_cursor(0, { 3, 0 })

      M.move_cell "u"
      local actual = vim.api.nvim_win_get_cursor(0)[1]
      local expected = 1

      assert.are.same(expected, actual)
    end)

    it("should move to lower cell when dir is 'd'", function()
      vim.api.nvim_win_set_cursor(0, { 1, 0 })

      M.move_cell "d"
      local actual = vim.api.nvim_win_get_cursor(0)[1]
      local expected = 3

      assert.are.same(expected, actual)
    end)
  end)

  describe("swap_cell", function()
    before_each(function()
      vim.api.nvim_buf_set_lines(0, 0, 0, false, {
        "# %%",
        "print('hello')",
        "# %%",
        "print('world')",
        "# %%",
        "print('foo')",
        "# %%",
        "print('bar')",
      })
    end)

    it("should swap current cell with the previous cell when dir is 'u'", function()
      vim.api.nvim_win_set_cursor(0, { 6, 0 })

      M.swap_cell "u"
      local actual = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      local expected = {
        "# %%",
        "print('hello')",
        "# %%",
        "print('foo')",
        "# %%",
        "print('world')",
        "# %%",
        "print('bar')",
        "",
      }

      assert.are.same(expected, actual)
    end)

    it("should swap current cell with the next cell when dir is 'd'", function()
      vim.api.nvim_win_set_cursor(0, { 4, 0 })
      M.swap_cell "d"

      local actual = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      local expected = {
        "# %%",
        "print('hello')",
        "# %%",
        "print('foo')",
        "# %%",
        "print('world')",
        "# %%",
        "print('bar')",
        "",
      }

      assert.are.same(expected, actual)
    end)
  end)

  describe("split_cell", function()
    before_each(function()
      vim.api.nvim_buf_set_lines(0, 0, 0, false, {
        "# %%",
        "print('hello')",
        "print('world')",
      })
    end)

    it("should split the current cell at the cursor position", function()
      vim.api.nvim_win_set_cursor(0, { 3, 0 })

      M.split_cell()
      local actual = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      local expected = {
        "# %%",
        "print('hello')",
        "# %%",
        "print('world')",
        "",
      }

      assert.are.same(expected, actual)
    end)
  end)

  describe("merge_cell", function()
    before_each(function()
      vim.api.nvim_buf_set_lines(0, 0, 0, false, {
        "# %%",
        "print('hello')",
        "# %%",
        "print('world')",
        "# %%",
        "print('foo')",
        "# %%",
        "print('bar')",
      })
    end)

    it("should merge current cell with the previous cell when dir is 'u'", function()
      vim.api.nvim_win_set_cursor(0, { 6, 0 })

      M.merge_cell "u"
      local actual = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      local expected = {
        "# %%",
        "print('hello')",
        "# %%",
        "print('world')",
        "",
        "print('foo')",
        "# %%",
        "print('bar')",
        "",
      }

      assert.are.same(expected, actual)
    end)

    it("should merge current cell with the next cell when dir is 'd'", function()
      vim.api.nvim_win_set_cursor(0, { 4, 0 })

      M.merge_cell "d"
      local actual = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      local expected = {
        "# %%",
        "print('hello')",
        "# %%",
        "print('world')",
        "",
        "print('foo')",
        "# %%",
        "print('bar')",
        "",
      }

      assert.are.same(expected, actual)
    end)
  end)
end)
