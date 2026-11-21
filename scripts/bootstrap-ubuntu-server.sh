#!/usr/bin/env bash
#
# Bootstrap this dotfiles repo on a fresh headless Ubuntu Server (VM).
#
# It installs the Nix package manager (with flakes), then applies the
# standalone home-manager configuration `#<user>@ubuntu-server` from this flake.
# That profile installs Neovim plus its LSPs/formatters only: no desktop shell,
# GUI apps, Docker, or .NET stack.
#
# Safe to re-run: every step is idempotent.
#
# Usage:
#   ./scripts/bootstrap-ubuntu-server.sh
#
set -euo pipefail

REPO_DIR="$HOME/dotfiles"
FLAKE_REF="$REPO_DIR#$(whoami)@ubuntu-server"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==>\033[0m %s\n' "$*"; }

# 1. Ensure the repo is present at ~/dotfiles.
if [ ! -d "$REPO_DIR" ]; then
  warn "Expected the repo at $REPO_DIR but it is missing."
  warn "Clone it first, e.g.: git clone git@github.com:NorskJoe/dotfiles.git ~/dotfiles"
  exit 1
fi

# 2. Install the few base packages the bootstrap needs.
if ! command -v git >/dev/null 2>&1 || ! command -v curl >/dev/null 2>&1; then
  info "Installing git and curl via apt..."
  sudo apt-get update && sudo apt-get install -y git curl
fi

# 3. Install Nix (Determinate Systems installer: flakes enabled by default).
if ! command -v nix >/dev/null 2>&1; then
  info "Installing Nix via the Determinate Systems installer..."
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
    | sh -s -- install --no-confirm
else
  info "Nix already installed, skipping."
fi

# 4. Make nix available in the current shell (the installer adds it to future
#    login shells; this profile script wires it up for this run).
if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

if ! command -v nix >/dev/null 2>&1; then
  warn "nix is not on PATH yet. Open a new terminal and re-run this script."
  exit 1
fi

# 5. Apply the Neovim-only home-manager configuration for this machine.
info "Applying home-manager configuration: $FLAKE_REF"
nix run home-manager/release-26.05 -- switch --flake "$FLAKE_REF" -b backup

info "Done. Open a new terminal, then run: nvim"
info "Rebuild later with: nix run home-manager/release-26.05 -- switch --flake ~/dotfiles#$(whoami)@ubuntu-server -b backup"
