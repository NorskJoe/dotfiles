{ config, pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withNodeJs = true; # many LSP servers / plugins expect node
  };

  # Mutable symlink: ~/.config/nvim -> your repo's config/nvim.
  # This means you can edit your Neovim config live without running a rebuild.
  # Assumes the repo is cloned at ~/dotfiles. Adjust the path if you cloned elsewhere.
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/config/nvim";
}
