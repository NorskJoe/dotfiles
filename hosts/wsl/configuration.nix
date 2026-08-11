{ config, lib, pkgs, inputs, username, ... }:
{
  # --- WSL integration (provided by NixOS-WSL) ---
  wsl.enable = true;
  wsl.defaultUser = username;
  # Use the Windows PATH inside WSL so `code`, `explorer.exe`, etc. work.
  wsl.interop.includePath = true;
  # Register the binfmt_misc handler so Windows .exe files (e.g. Code.exe) are
  # routed through /init instead of being exec'd as native binaries. Without
  # this, `code .` fails with "cannot execute binary file: Exec format error".
  wsl.interop.register = true;

  # --- Nix / flakes ---
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # --- VSCode Remote-WSL support ---
  # nixos-vscode-server patches the downloaded server so it runs on NixOS.
  services.vscode-server.enable = true;
  # nix-ld lets other dynamically-linked prebuilt binaries run (LSP servers, etc.).
  programs.nix-ld.enable = true;
  # Libraries exposed to nix-ld binaries. Node (installed via nvm) and many
  # native npm modules need libstdc++/zlib/openssl at runtime.
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    zlib
    openssl
  ];

  # --- User ---
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
  };
  programs.zsh.enable = true;

  # --- Base system packages ---
  environment.systemPackages = with pkgs; [
    git
    wget
    curl
    gnumake
    unzip
  ];

  # Passwordless sudo for the wheel group is convenient in a single-user WSL box.
  # Remove this if you prefer to type your password.
  security.sudo.wheelNeedsPassword = false;

  # Do not change after first install unless you know why. Match your NixOS release.
  system.stateVersion = "26.05";
}
