-- =============================================================================
--  Neovim configuration template
--  This file is symlinked to ~/.config/nvim/init.lua by Home Manager
--  (see home/neovim.nix). Edit it freely — no rebuild needed.
-- =============================================================================

-- Leader keys (set before plugins load).
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ---------------------------------------------------------------------------
--  Sensible defaults
-- ---------------------------------------------------------------------------
local opt = vim.opt

opt.expandtab = true
opt.shiftwidth = 2
opt.scrolloff = 16
opt.number = true
opt.relativenumber = true
opt.mouse = "a"
opt.clipboard = "unnamedplus" -- share clipboard with Windows/host
opt.ignorecase = true
opt.smartcase = true
opt.termguicolors = true
opt.signcolumn = "yes"
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.smartindent = true
opt.wrap = false
opt.scrolloff = 8
opt.updatetime = 250
opt.undofile = true
opt.foldlevelstart = 99 -- open files with all folds expanded

-- ---------------------------------------------------------------------------
--  Basic keymaps
-- ---------------------------------------------------------------------------
local map = vim.keymap.set
map("n", "<leader>w", "<cmd>write<cr>", { desc = "Save" })
-- save by pressing Escape
map('n', '<Esc>', ':w<CR>', { desc = 'Save' })
-- select all
map('n', '<C-a>', 'ggVG', { desc = 'Select All' })
-- pasting over a selection no longer clobbers your clipboard
vim.cmd([[ xnoremap <expr> p 'pgv"'.v:register.'y' ]])

-- ---------------------------------------------------------------------------
--  Plugin manager (lazy.nvim) — TODO
--  Uncomment the bootstrap below to start adding plugins.
-- ---------------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)
require("lazy").setup('plugins')
