return {
  {
    'folke/which-key.nvim',
    lazy = false,
    opts = {
      spec = {
        { '<leader>c', group = 'Code' },  -- popup that shows what my leader keys do
        { '<leader>d', group = 'Debug' },
        { '<leader>x', group = 'Diagnostics' },
      },
    },
  },
}
