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
opt.laststatus = 3 -- single global statusline (cleaner)
opt.showmode = false -- mode shown in statusline, hide the -- INSERT -- text
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.smartindent = true
opt.wrap = true
opt.linebreak = true
opt.scrolloff = 8
opt.updatetime = 250
opt.undofile = true
opt.foldlevelstart = 99 -- open files with all folds expanded

-- ---------------------------------------------------------------------------
--  Diagnostics
--  Errors render inline on their own lines automatically (virtual_lines).
--  Warnings/Info are only signalled by signs/underline; read them on demand
--  with <leader>d (open_float).
-- ---------------------------------------------------------------------------
vim.diagnostic.config({
	virtual_lines = { severity = vim.diagnostic.severity.ERROR },
	virtual_text = false,
	signs = true,
	underline = true,
	severity_sort = true,
	float = { border = "rounded", source = true },
})

-- ---------------------------------------------------------------------------
--  Basic keymaps
-- ---------------------------------------------------------------------------
local map = vim.keymap.set
map("n", "<leader>w", "<cmd>write<cr>", { desc = "Save" })
-- save by pressing Escape
map("n", "<Esc>", ":wa<CR>", { desc = "Save All" })
-- select all
map("n", "<C-a>", "ggVG", { desc = "Select All" })
-- show full diagnostic message (all severities) under the cursor
map("n", "<leader>xd", vim.diagnostic.open_float, { desc = "Diagnostic Float" })
-- pasting over a selection no longer clobbers your clipboard
vim.cmd([[ xnoremap <expr> p 'pgv"'.v:register.'y' ]])
-- move lines / selections up and down
map("n", "<A-j>", ":m .+1<CR>==", { desc = "Move line down" })
map("n", "<A-k>", ":m .-2<CR>==", { desc = "Move line up" })
map("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })
-- move by visual (screen) lines so j/k navigate wrapped lines
map("n", "j", "gj", { desc = "Move down by visual line" })
map("n", "k", "gk", { desc = "Move up by visual line" })

-- ---------------------------------------------------------------------------
--  Plugin manager (lazy.nvim) — TODO
--  Uncomment the bootstrap below to start adding plugins.
-- ---------------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)
require("lazy").setup("plugins")
