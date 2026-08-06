return {
  'polarmutex/git-worktree.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim',
  },
  config = function()
    -- NO setup() in this fork

    -- Load Telescope extension
    require('telescope').load_extension 'git_worktree'

    -- Keymaps
    vim.keymap.set('n', '<leader>gwc', function()
      require('telescope').extensions.git_worktree.create_git_worktree()
    end, { desc = 'Git Worktree: Create (Telescope)' })

    vim.keymap.set('n', '<leader>gws', function()
      require('telescope').extensions.git_worktree.git_worktree()
    end, { desc = 'Git Worktree: Switch (Telescope)' })
  end,
}
