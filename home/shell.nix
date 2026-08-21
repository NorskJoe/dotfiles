{
  config,
  pkgs,
  lib,
  platform ? "wsl",
  ...
}:
let
  isWSL = platform == "wsl";
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
      # Local secrets (see home/secrets.template.env). Source if present.
      [ -r "$HOME/.secrets.env" ] && source "$HOME/.secrets.env"
${lib.optionalString isWSL ''
      # WSL2's inotify is unreliable: webpack/Vite watchers fail with
      # "ENOSPC: System limit for number of file watchers reached" even when the
      # watch count is far below fs.inotify.max_user_watches (it fails to watch
      # even a single directory). Force file-watchers to poll instead, which
      # bypasses inotify entirely. See dotfiles README troubleshooting.
      export WATCHPACK_POLLING=true
      export CHOKIDAR_USEPOLLING=true
''}
      export NVM_DIR="$HOME/.nvm"
      mkdir -p "$NVM_DIR"
      source ${nvm}/nvm.sh
      source ${nvm}/bash_completion

      # Report the working directory to the terminal via OSC 7 so WezTerm opens
      # new panes/tabs (CurrentPaneDomain) in the current pane's directory.
      _wezterm_osc7() { printf '\033]7;file://%s%s\033\\' "''${HOST}" "''${PWD}"; }
      autoload -Uz add-zsh-hook
      add-zsh-hook chpwd _wezterm_osc7
      _wezterm_osc7
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
      glg = "git log --oneline -10";
      ".." = "cd ..";
    } // (
      if isWSL then {
        # Rebuild the whole NixOS system from this flake. Assumes the repo lives
        # at ~/dotfiles.
        rebuild = "sudo nixos-rebuild switch --flake ~/dotfiles#wsl";
        # Update flake inputs then rebuild.
        update = "nix flake update ~/dotfiles && sudo nixos-rebuild switch --flake ~/dotfiles#wsl";
      } else {
        # Native Ubuntu: standalone home-manager manages the user profile only.
        rebuild = "home-manager switch --flake ~/dotfiles#${config.home.username}@ubuntu";
        # Update flake inputs then rebuild.
        update = "nix flake update ~/dotfiles && home-manager switch --flake ~/dotfiles#${config.home.username}@ubuntu";
      }
    );
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
