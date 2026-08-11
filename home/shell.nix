{ config, pkgs, lib, ... }:
let
  # nvm has no nixpkgs package; pin the release source into the Nix store and
  # source it from zsh. Node versions still install into $NVM_DIR at runtime,
  # and nix-ld (enabled in the WSL host config) lets those prebuilt binaries run.
  nvm = pkgs.fetchFromGitHub {
    owner = "nvm-sh";
    repo = "nvm";
    rev = "v0.40.3";
    sha256 = "0flfx69r1hzx92590b8w7k7yfxny89crwx4dqywajd77i1188zmk";
  };
in
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    initContent = lib.mkAfter ''
      export NVM_DIR="$HOME/.nvm"
      mkdir -p "$NVM_DIR"
      source ${nvm}/nvm.sh
      source ${nvm}/bash_completion
    '';

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
      ".." = "cd ..";
      # Rebuild the system from this flake. Assumes the repo lives at ~/dotfiles.
      rebuild = "sudo nixos-rebuild switch --flake ~/dotfiles#wsl";
      # Update flake inputs then rebuild.
      update = "nix flake update ~/dotfiles && sudo nixos-rebuild switch --flake ~/dotfiles#wsl";
    };
  };

  # Prompt + navigation helpers. Remove any you don't want.
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$cmd_duration$line_break$character";
      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
      };
      cmd_duration.format = "[$duration]($style) ";
    };
  };
  
  programs.zoxide.enable = true;
  programs.fzf.enable = true;
}
