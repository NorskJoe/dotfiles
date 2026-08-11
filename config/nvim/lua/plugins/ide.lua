-- Parsers to keep installed. These are parser names, not filetypes.
local ensure_installed = {
  'bash', 'c', 'lua', 'markdown', 'nix',
  'vim', 'angular', 'css', 'c_sharp',
  'go', 'html', 'javascript', 'typescript',
  'json', 'prisma', 'python', 'razor', 'scss', 'sql',
  'vue', 'xml', 'gitcommit'
}

return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',        -- the master branch is deprecated
    lazy = false,           -- main does not support lazy-loading
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter').install(ensure_installed)

      -- The main branch has no highlight/indent modules; you start them yourself.
      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          local ft = vim.bo[args.buf].filetype
          -- skip oil.nvim and neogit buffers
          if ft == "oil" or ft:match("^Neogit") then
              return
          end
          local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
          if lang and vim.tbl_contains(ensure_installed, lang)
            and pcall(vim.treesitter.language.add, lang) then
            vim.treesitter.start()
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
            vim.wo[0][0].foldmethod = 'expr'
          end
        end,
      })
    end,
  },

  -- LSP client config. Servers are Nix-provided (see home/neovim.nix) and enabled
  -- with the native vim.lsp API. Neovim 0.11+ ships default LSP keymaps
  -- (K = hover, grn = rename, gra = code action, grr = references, gri = impl).
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = { 'saghen/blink.cmp' },
    config = function()
      -- Advertise blink.cmp's completion capabilities to every server.
      vim.lsp.config('*', {
        capabilities = require('blink.cmp').get_lsp_capabilities(nil, true),
      })

      vim.lsp.config('lua_ls', {
        settings = { Lua = { diagnostics = { globals = { 'vim' } } } },
      })

      vim.lsp.enable({
        'lua_ls', 'nil_ls', 'ts_ls', 'vue_ls', 'angularls',
        'html', 'cssls', 'jsonls', 'yamlls', 'gopls', 'pyright',
        'clangd', 'sqls', 'bashls',
      })
    end,
  },

  -- C#. roslyn-ls speaks a non-standard LSP dialect, so it needs this dedicated
  -- plugin instead of a plain lspconfig entry. Binary is Nix-provided.
  {
    'seblj/roslyn.nvim',
    ft = 'cs',
    opts = {},
    config = function(_, opts)
      vim.lsp.config('roslyn', {
        cmd = {
          'Microsoft.CodeAnalysis.LanguageServer',
          '--logLevel=Information',
          '--extensionLogDirectory=' .. vim.fs.joinpath(vim.fn.stdpath('log'), 'roslyn'),
          '--stdio',
        },
      })
      require('roslyn').setup(opts)
    end,
  },

  -- Formatting. Formatters are Nix-installed; conform just runs them.
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      { '<leader>cf', function() require('conform').format({ async = true }) end, desc = 'Format Buffer' },
    },
    opts = {
      formatters_by_ft = {
        lua = { 'stylua' },
        nix = { 'nixfmt' },
        javascript = { 'prettierd' },
        javascriptreact = { 'prettierd' },
        typescript = { 'prettierd' },
        typescriptreact = { 'prettierd' },
        vue = { 'prettierd' },
        html = { 'prettierd' },
        css = { 'prettierd' },
        scss = { 'prettierd' },
        json = { 'prettierd' },
        yaml = { 'prettierd' },
        go = { 'gofumpt' },
        python = { 'ruff_format' },
        cs = { 'csharpier' },
        c = { 'clang_format' },
        cpp = { 'clang_format' },
        sql = { 'sql_formatter' },
        sh = { 'shfmt' },
        bash = { 'shfmt' },
      },
      format_on_save = { timeout_ms = 1000, lsp_format = 'fallback' },
    },
  },

  -- Autocompletion. blink.cmp provides LSP-driven completion, snippets and a
  -- signature-help popup. The default fuzzy matcher ships as a prebuilt Rust
  -- binary that won't run on NixOS, so we use the pure-Lua implementation.
  {
    'saghen/blink.cmp',
    event = { 'InsertEnter', 'CmdlineEnter' },
    version = '*',
    opts = {
      fuzzy = { implementation = 'lua' },
      keymap = {
        preset = 'default',
        ['<Tab>'] = { 'select_and_accept', 'fallback' },
      },
      appearance = { nerd_font_variant = 'mono' },
      completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
      },
      signature = { enabled = true },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
      },
    },
    opts_extend = { 'sources.default' },
  },

  -- Auto-close brackets, braces, quotes, etc. as you type.
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    opts = {},
  },
}
