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
}
