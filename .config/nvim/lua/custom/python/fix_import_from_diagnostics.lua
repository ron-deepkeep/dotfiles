-- lua/custom/python/fix_import_from_diagnostics.lua
local M = {}

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = 'FixImportTrans' })
end

local function normalize_msg(msg)
  msg = msg:gsub('\194\160', ' ')
  msg = msg:gsub('[\226\128\156\226\128\157]', '"')
  msg = msg:gsub('[\226\128\152\226\128\153]', "'")
  return msg
end

local function parse_pyright_import_suggestion(msg)
  msg = normalize_msg(msg)

  local name = msg:match '[\'"]([%w_]+)[\'"]%s+is%s+not%s+exported' or msg:match '^([%w_]+)%s+is%s+not%s+exported'

  local mod = msg:match 'Import%s+from%s+[\'"]([^\'"]+)[\'"]%s+instead' or msg:match 'Import%s+from%s+([%w_%.]+)%s+instead'

  if name and mod then
    return name, mod
  end
  return nil, nil
end

local function parse_from_import_line(line)
  local base, rest = line:match '^%s*from%s+([%w_%.]+)%s+import%s+(.+)%s*$'
  if not base or not rest then
    return nil
  end

  local names = {}
  for part in rest:gmatch '([^,]+)' do
    local s = vim.trim(part)
    if #s > 0 then
      local n, a = s:match '^([%w_]+)%s+as%s+([%w_]+)$'
      if n then
        names[n] = a
      else
        n = s:match '^([%w_]+)$'
        if n then
          names[n] = false
        end
      end
    end
  end
  return { base = base, names = names }
end

local function render(grouped, unchanged, original_base)
  local out = {}

  if #unchanged > 0 then
    table.sort(unchanged, function(a, b)
      return a.name < b.name
    end)
    local parts = {}
    for _, it in ipairs(unchanged) do
      parts[#parts + 1] = it.alias and ('%s as %s'):format(it.name, it.alias) or it.name
    end
    out[#out + 1] = ('from %s import %s'):format(original_base, table.concat(parts, ', '))
  end

  local mods = {}
  for mod, _ in pairs(grouped) do
    mods[#mods + 1] = mod
  end
  table.sort(mods)

  for _, mod in ipairs(mods) do
    local items = grouped[mod]
    table.sort(items, function(a, b)
      return a.name < b.name
    end)
    local parts = {}
    for _, it in ipairs(items) do
      parts[#parts + 1] = it.alias and ('%s as %s'):format(it.name, it.alias) or it.name
    end
    out[#out + 1] = ('from %s import %s'):format(mod, table.concat(parts, ', '))
  end

  return out
end

function M.fix_import_from_diagnostics(opts)
  opts = opts or {}
  local debug = opts.debug == true

  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local line = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1] or ''
  if line == '' then
    return
  end

  local spec = parse_from_import_line(line)
  if not spec then
    if debug then
      notify("Not a 'from X import ...' line", vim.log.levels.WARN)
    end
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local diags = vim.diagnostic.get(bufnr, { lnum = row }) or {}
  if #diags == 0 then
    if debug then
      notify('No diagnostics on this exact line', vim.log.levels.WARN)
    end
    return
  end

  if debug then
    notify(('Found %d diagnostics on this line'):format(#diags))
    for i, d in ipairs(diags) do
      notify(('diag[%d]: %s'):format(i, normalize_msg(d.message or '')))
    end
  end

  local suggestions = {}
  for _, d in ipairs(diags) do
    local name, mod = parse_pyright_import_suggestion(d.message or '')
    if name and mod then
      suggestions[name] = mod
    end
  end

  local any = false
  for name, _ in pairs(spec.names) do
    if suggestions[name] then
      any = true
      break
    end
  end
  if not any then
    if debug then
      notify('Parsed 0 actionable suggestions', vim.log.levels.WARN)
    end
    return
  end

  local grouped, unchanged = {}, {}
  for name, alias in pairs(spec.names) do
    local mod = suggestions[name]
    if mod then
      grouped[mod] = grouped[mod] or {}
      table.insert(grouped[mod], { name = name, alias = alias })
    else
      table.insert(unchanged, { name = name, alias = alias })
    end
  end

  local new_lines = render(grouped, unchanged, spec.base)
  vim.api.nvim_buf_set_lines(bufnr, row, row + 1, false, new_lines)
  vim.api.nvim_win_set_cursor(0, { row + 1, 0 })
end

function M.setup()
  vim.api.nvim_create_user_command('FixImportTrans', function()
    M.fix_import_from_diagnostics()
  end, {})
  vim.api.nvim_create_user_command('FixImportTransDebug', function()
    M.fix_import_from_diagnostics { debug = true }
  end, {})
  vim.keymap.set('n', '<leader>p', function()
    M.fix_import_from_diagnostics()
  end, { noremap = true, silent = true, desc = 'Fix import using LSP diagnostic suggestion' })
end

return M
