{ config, pkgs, username, ... }:
{
  # Native Ubuntu home configuration (standalone home-manager, no NixOS).
  # Shared config lives in ./common.nix; add Ubuntu-only home settings here.
  imports = [ ./common.nix ];

  # Standalone home-manager evaluates its own nixpkgs, so unfree must be allowed
  # here (on WSL this came from the NixOS host config). Needed for dotnet,
  # vscode-langservers-extracted, opencode, etc.
  nixpkgs.config.allowUnfree = true;
}
