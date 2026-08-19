return {
  -- Icon provider for the statusline's fileinfo section. Mocking devicons
  -- also gives oil.nvim and the snacks pickers file icons (they had none).
  {
    "echasnovski/mini.icons",
    version = false,
    lazy = false, -- needed at startup by snacks (lazy=false) and oil
    config = function()
      require("mini.icons").setup()
      MiniIcons.mock_nvim_web_devicons()
    end,
  },

  -- Minimal statusline. Default sections already wire up git/diff (via
  -- gitsigns fallback), attached-LSP count, diagnostics and file icons
  -- (via mini.icons). We override content to trim the noisy bits.
  {
    "echasnovski/mini.statusline",
    version = false,
    event = "VeryLazy",
    dependencies = { "echasnovski/mini.icons" },
    opts = {
      use_icons = true,
      content = {
        active = function()
          local S = MiniStatusline
          local mode, mode_hl = S.section_mode({ trunc_width = 120 })
          local git = S.section_git({ trunc_width = 40 })
          local diff = S.section_diff({ trunc_width = 75 })
          local diagnostics = S.section_diagnostics({ trunc_width = 75 })
          local lsp = S.section_lsp({ trunc_width = 75 })
          local filename = S.section_filename({ trunc_width = 140 })
          -- Trimmed: icon + filetype only (no encoding/format/size).
          local fileinfo = S.section_fileinfo({ trunc_width = math.huge })
          -- Trimmed: short line:col instead of line|total│col|total.
          local location = "%2l:%-2v"

          return S.combine_groups({
            { hl = mode_hl, strings = { mode } },
            { hl = "MiniStatuslineDevinfo", strings = { git, diff, diagnostics, lsp } },
            "%<", -- truncate from here when narrow
            { hl = "MiniStatuslineFilename", strings = { filename } },
            "%=", -- right-align what follows
            { hl = "MiniStatuslineFileinfo", strings = { fileinfo } },
            { hl = mode_hl, strings = { location } },
          })
        end,
      },
    },
  },
}
