{ config, pkgs, ... }:
{
  # Shared agent instructions (AGENTS.md standard). Single source of truth in the
  # repo, symlinked out-of-store to where each tool expects it so it can be edited
  # live without a rebuild. Add more targets here for other tools later,
  # e.g. Claude Code -> home.file.".claude/CLAUDE.md".
  xdg.configFile."opencode/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/home/AGENTS.md";
}
