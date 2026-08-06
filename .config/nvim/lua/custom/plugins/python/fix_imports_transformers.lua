-- lua/custom/plugins/python/fix_imports_transformers.lua
return {
  -- "config-only" plugin spec (no external repo needed)
  dir = vim.fn.stdpath 'config',
  name = 'fix-imports-transformers',
  lazy = false,
  config = function()
    require('custom.python.fix_import_from_diagnostics').setup()
  end,
}
