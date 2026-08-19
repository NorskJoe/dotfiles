-- C# indentation to match csharpier (4 spaces, expand tabs).
-- Loaded automatically for `cs` buffers, after global options in init.lua.
local opt_local = vim.opt_local

opt_local.expandtab = true
opt_local.shiftwidth = 4
opt_local.tabstop = 4
opt_local.softtabstop = 4

-- Use Neovim's built-in cindent-based C# indenter (runtime/indent/cs.vim).
-- Treesitter's main-branch indenter is disabled for cs (see plugins/ide.lua),
-- so re-assert this after all FileType autocmds have run.
vim.schedule(function()
  if vim.api.nvim_get_current_buf() and vim.bo.filetype == "cs" then
    vim.bo.indentexpr = "GetCSIndent(v:lnum)"
    vim.bo.indentkeys = "0{,0},0),0],:,!^F,o,O,e"
  end
end)

-- Format a visually-selected raw SQL block through sql-formatter.
-- Roslyn/csharpier never touch string-literal contents, so this is a manual,
-- on-demand filter: select the SQL inside the @"..." string, then <leader>cs.
-- `:!sql-formatter` pipes the selected lines through the external formatter and
-- replaces them with the result. Output is flush-left (not re-indented to the
-- string's C# nesting) -- adjust indentation after if desired.
vim.keymap.set("x", "<leader>cs", ":!sql-formatter<CR>", {
  buffer = true,
  silent = true,
  desc = "Format SQL selection",
})
