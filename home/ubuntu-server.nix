{ pkgs, username, ... }:
{
  # Headless Ubuntu Server (VM): Neovim and its tooling only.
  # No desktop shell, GUI apps, agents, Docker, or .NET stack.
  imports = [ ./neovim.nix ];

  home.username = username;
  home.homeDirectory = "/home/${username}";

  nixpkgs.config.allowUnfree = true;

  programs.home-manager.enable = true;

  # Runtime tools Neovim shells out to. The LSP servers and formatters
  # themselves come from neovim.nix.
  home.packages = with pkgs; [
    git # lazy.nvim plugin bootstrap
    ripgrep # snacks.picker grep
    fd # snacks.picker files
    fzf # snacks.picker
    jq # kulala JSON formatting
    curl # kulala HTTP requests
    unzip
  ];

  home.stateVersion = "26.05";
}
