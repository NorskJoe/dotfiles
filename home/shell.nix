{ config, pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 10000;
      save = 10000;
      ignoreDups = true;
      share = true;
    };

    shellAliases = {
      ll = "eza -l --icons --git";
      la = "eza -la --icons --git";
      ls = "eza --icons";
      cat = "bat";
      # Rebuild the system from this flake. Assumes the repo lives at ~/dotfiles.
      rebuild = "sudo nixos-rebuild switch --flake ~/dotfiles#wsl";
      # Update flake inputs then rebuild.
      update = "nix flake update ~/dotfiles && sudo nixos-rebuild switch --flake ~/dotfiles#wsl";
    };
  };

  # Prompt + navigation helpers. Remove any you don't want.
  programs.starship.enable = true;
  programs.zoxide.enable = true;
  programs.fzf.enable = true;
}
