return {
  'Soyuz0/99',
  branch = 'refactor-language-prompts',
  config = function()
    local _99 = require '99'

    local cwd = vim.uv.cwd()
    local basename = vim.fs.basename(cwd)
    _99.setup {
      model = 'anthropic/claude-sonnet-4-5',

      logger = {
        level = _99.DEBUG,
        path = '/tmp/' .. basename .. '.99.debug',
        print_on_error = true,
      },

      completion = {
        custom_rules = {
          'scratch/custom_rules/',
        },
        source = nil, -- set to "cmp" if using nvim-cmp
      },

      md_files = {
        'AGENT.md',
      },
    }

    -- Fill in function (no prompt)
    vim.keymap.set('n', '<leader>9F', function()
      _99.fill_in_function()
    end, { desc = '[99] Fill in function' })

    -- Fill in function with prompt
    vim.keymap.set('n', '<leader>9f', function()
      _99.fill_in_function_prompt()
    end, { desc = '[99] Fill in function (with prompt)' })

    -- Visual selection (no prompt)
    vim.keymap.set('v', '<leader>9F', function()
      _99.visual()
    end, { desc = '[99] Visual AI replace' })

    -- Visual selection with prompt
    vim.keymap.set('v', '<leader>9f', function()
      _99.visual_prompt {}
    end, { desc = '[99] Visual AI replace (with prompt)' })

    -- Stop all requests
    vim.keymap.set('n', '<leader>9s', function()
      _99.stop_all_requests()
    end, { desc = '[99] Stop all requests' })

    -- Helper: Get diagnostics for current buffer or range
    local function get_diagnostics_text(start_line, end_line)
      local bufnr = vim.api.nvim_get_current_buf()
      local diagnostics = vim.diagnostic.get(bufnr)
      local lines = {}

      for _, d in ipairs(diagnostics) do
        -- Filter by line range if provided
        if not start_line or (d.lnum >= start_line and d.lnum <= end_line) then
          local severity = vim.diagnostic.severity[d.severity] or 'UNKNOWN'
          local source = d.source or 'unknown'
          local msg = string.format('[%s] Line %d: %s (%s)', severity, d.lnum + 1, d.message, source)
          table.insert(lines, msg)
        end
      end

      if #lines == 0 then
        return nil
      end

      return 'Fix the following errors/warnings:\n' .. table.concat(lines, '\n')
    end

    -- Fill in function and fix diagnostics
    vim.keymap.set('n', '<leader>9e', function()
      local diag_text = get_diagnostics_text()
      if diag_text then
        _99.fill_in_function { additional_prompt = diag_text }
      else
        vim.notify('[99] No diagnostics found', vim.log.levels.INFO)
      end
    end, { desc = '[99] Fill in function (fix errors)' })

    -- Visual selection and fix diagnostics in range
    vim.keymap.set('v', '<leader>9e', function()
      -- Get visual selection range (0-indexed for diagnostic API)
      local start_line = vim.fn.line 'v' - 1
      local end_line = vim.fn.line '.' - 1
      -- Ensure start <= end
      if start_line > end_line then
        start_line, end_line = end_line, start_line
      end
      local diag_text = get_diagnostics_text(start_line, end_line)
      if diag_text then
        _99.visual(nil, { additional_prompt = diag_text })
      else
        vim.notify('[99] No diagnostics in selection', vim.log.levels.INFO)
      end
    end, { desc = '[99] Visual AI replace (fix errors)' })
  end,
}
