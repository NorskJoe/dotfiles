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
