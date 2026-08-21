{ config, pkgs, username, ... }:
{
  # Shared home configuration used by every machine (WSL, native Ubuntu, ...).
  # OS-specific bits live in the per-host entrypoints (home.nix, ubuntu.nix) and
  # are branched on the `platform` argument inside individual modules.
  imports = [
    ./shell.nix
    ./git.nix
    ./neovim.nix
    ./agents.nix
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";

  # User-level CLI tooling shared across all machines. Add your own here.
  home.packages = with pkgs; [
    ripgrep
    fd
    fzf
    bat
    eza
    jq
    tree
    htop
    dotnet-sdk_9
    docker-compose
  ];

  # Let Home Manager manage itself.
  programs.home-manager.enable = true;

  # Do not change after first install. Match your NixOS release.
  home.stateVersion = "26.05";
}
