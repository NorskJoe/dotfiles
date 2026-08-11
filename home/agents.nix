{ config, pkgs, ... }:
{
  home.packages = [ pkgs.opencode ];
  home.shellAliases.oc = "opencode";

  # opencode is installed via nixpkgs (pinned by the flake lock); its self-updater
  # can't overwrite the read-only Nix store binary, so disable it. Update opencode
  # with `nix flake update` + rebuild instead.
  xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    autoupdate = false;
  };

  # Shared agent instructions (AGENTS.md standard). Single source of truth in the
  # repo, symlinked out-of-store to where each tool expects it so it can be edited
  # live without a rebuild. Add more targets here for other tools later,
  # e.g. Claude Code -> home.file.".claude/CLAUDE.md".
  xdg.configFile."opencode/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/home/AGENTS.md";
}
