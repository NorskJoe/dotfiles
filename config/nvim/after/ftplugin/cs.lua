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
