{ config, pkgs, ... }:
{
  # Install Neovim as a plain package. We deliberately do NOT use
  # `programs.neovim.enable`, because that makes Home Manager manage
  # ~/.config/nvim/init.lua and collides with the whole-directory symlink below.
  home.packages = [
    pkgs.neovim
    pkgs.nodejs # required by many LSP servers / Neovim plugins
    pkgs.gcc # C compiler used by nvim-treesitter to build parsers
    pkgs.tree-sitter # tree-sitter CLI required by nvim-treesitter (main branch)

    # LSP servers. Mason's downloaded binaries don't run on NixOS, so the servers
    # are installed here and wired up by nvim-lspconfig (see config/nvim/.../ide.lua).
    pkgs.lua-language-server
    pkgs.nil # Nix
    pkgs.typescript-language-server
    pkgs.typescript # tsserver, needed by the TS and Vue language servers
    pkgs.vue-language-server
    pkgs.angular-language-server
    pkgs.vscode-langservers-extracted # html, css, json (+ eslint)
    pkgs.yaml-language-server
    pkgs.gopls
    pkgs.pyright
    pkgs.roslyn-ls # C# (used via roslyn.nvim)
    pkgs.inotify-tools # inotifywait: lets Neovim use event-based LSP file watching (roslyn new-file detection) instead of polling
    pkgs.clang-tools # clangd + clang-format
    pkgs.sqls
    pkgs.bash-language-server

    # Debug adapters, driven by nvim-dap (see config/nvim/.../dap.lua).
    pkgs.netcoredbg # CoreCLR debugger for .NET/C# stepping

    # Formatters, orchestrated by conform.nvim.
    pkgs.stylua
    pkgs.nixfmt
    pkgs.prettierd
    pkgs.gofumpt
    pkgs.ruff
    pkgs.csharpier
    pkgs.sql-formatter
    pkgs.shfmt
  ];

  home.sessionVariables.EDITOR = "nvim";
  home.shellAliases = {
    vi = "nvim";
    vim = "nvim";
  };

  # Mutable symlink: ~/.config/nvim -> your repo's config/nvim.
  # This means you can edit your Neovim config live without running a rebuild.
  # Assumes the repo is cloned at ~/dotfiles. Adjust the path if you cloned elsewhere.
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/config/nvim";
}
