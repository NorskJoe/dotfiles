{ config, pkgs, username, ... }:
{
  # WSL (NixOS) home configuration. Shared config lives in ./common.nix; this
  # file only adds WSL-specific home settings (currently none beyond the platform
  # flag, which is passed in via extraSpecialArgs from flake.nix).
  imports = [ ./common.nix ];
}
