describe("notebook-navigator.miniai_spec", function()
  local M = require "notebook-navigator.miniai_spec"

  describe("miniai_spec", function()
    local cell_marker = "# %%"

    before_each(function()
      vim.api.nvim_buf_set_lines(0, 0, 0, false, {
        "print('hello')",
        "# %%",
        "print('world')",
        "# %%",
        "print('foo')",
        "print('bar')",
        "# %%",
        "print('hoge')",
      })
    end)

    after_each(function()
      require("vusted.helper").cleanup()
    end)

    describe("should return the nearest cell from current position", function()
      describe("when opts is 'a'", function()
        local opts = "a"

        it("when the cell is at the start of the buffer", function()
          vim.api.nvim_win_set_cursor(0, { 1, 0 })

          local expected = {
            from = { line = 1, col = 1 },
            to = { line = 1, col = 14 },
          }
          local actual = M.miniai_spec(opts, cell_marker)

          assert.are.same(expected, actual)
        end)

        it("when the cell is after cell marker", function()
          vim.api.nvim_win_set_cursor(0, { 5, 0 })

          local expected = {
            from = { line = 4, col = 1 },
            to = { line = 6, col = 12 },
          }
          local actual = M.miniai_spec(opts, cell_marker)

          assert.are.same(expected, actual)
        end)

        it("when the cell is at the end of the buffer", function()
          vim.api.nvim_win_set_cursor(0, { 8, 0 })

          local expected = {
            from = { line = 7, col = 1 },
            to = { line = 9, col = 1 },
          }
          local actual = M.miniai_spec(opts, cell_marker)

          assert.are.same(expected, actual)
        end)
      end)

      describe("without cell markers when opts is 'i'", function()
        local opts = "i"

        it("when the cell is at the start of the buffer", function()
          vim.api.nvim_win_set_cursor(0, { 1, 0 })

          local expected = {
            from = { line = 1, col = 1 },
            to = { line = 1, col = 14 },
          }
          local actual = M.miniai_spec(opts, cell_marker)

          assert.are.same(expected, actual)
        end)

        it("when the cell is after cell marker", function()
          vim.api.nvim_win_set_cursor(0, { 5, 0 })

          local expected = {
            from = { line = 5, col = 1 },
            to = { line = 6, col = 12 },
          }
          local actual = M.miniai_spec(opts, cell_marker)

          assert.are.same(expected, actual)
        end)

        it("when the cell is at the end of the buffer", function()
          vim.api.nvim_win_set_cursor(0, { 8, 0 })

          local expected = {
            from = { line = 8, col = 1 },
            to = { line = 8, col = 13 },
          }
          local actual = M.miniai_spec(opts, cell_marker)

          assert.are.same(expected, actual)
        end)
      end)
    end)

    describe("should return the cell", function()
      before_each(function()
        vim.api.nvim_buf_set_lines(0, 0, 0, false, {
          "# %%",
          "print('hello')",
          "print('world')",
          "",
          "",
          "# %%",
        })
        vim.api.nvim_win_set_cursor(0, { 2, 0 })
      end)

      it("with trailing blank lines at the end when opts is 'a'", function()
        local opts = "a"

        local expected = {
          from = { line = 1, col = 1 },
          to = { line = 5, col = 1 },
        }
        local actual = M.miniai_spec(opts, cell_marker)

        assert.are.same(expected, actual)
      end)

      it("without trailing blank lines at the end when opts is 'i'", function()
        local opts = "i"

        local expected = {
          from = { line = 2, col = 1 },
          to = { line = 3, col = 14 },
        }
        local actual = M.miniai_spec(opts, cell_marker)

        assert.are.same(expected, actual)
      end)
    end)
  end)
end)
