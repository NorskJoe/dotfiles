{ config, lib, pkgs, ... }:
let
  repo = "${config.home.homeDirectory}/dotfiles";
  agentsMd = config.lib.file.mkOutOfStoreSymlink "${repo}/config/agents/AGENTS.md";
in
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
  # live without a rebuild. Add more targets here for other tools later.
  xdg.configFile."opencode/AGENTS.md".source = agentsMd;
  home.file.".claude/CLAUDE.md".source = agentsMd;
  home.file.".claude/keybindings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${repo}/config/claude/keybindings.json";

  # Claude Code writes to ~/.claude/settings.json itself, so it can't be a
  # read-only link. Merge just the statusLine, model, env.ANTHROPIC_MODEL and
  # permissions.defaultMode keys and leave everything else alone. opusplan = Opus in
  # plan mode, Sonnet in every other mode; sessions start in plan mode. /model
  # overwrites .model, so env.ANTHROPIC_MODEL (which outranks it) pins opusplan.
  home.activation.claudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings="$HOME/.claude/settings.json"
    mkdir -p "$HOME/.claude"
    [ -s "$settings" ] || echo '{}' > "$settings"
    tmp=$(mktemp)
    ${pkgs.jq}/bin/jq --arg cmd "bash ${repo}/config/claude/scripts/status-bar.sh" \
      '.statusLine = {type: "command", command: $cmd} | .model = "opusplan" | .env.ANTHROPIC_MODEL = "opusplan" | .permissions.defaultMode = "plan"' "$settings" > "$tmp" \
      && mv "$tmp" "$settings"
  '';
}
