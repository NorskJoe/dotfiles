#!/usr/bin/env bash
#
# Bootstrap this dotfiles repo on a fresh native Ubuntu install (NOT WSL).
#
# It installs the Nix package manager (with flakes), then applies the
# standalone home-manager configuration `#<user>@ubuntu` from this flake.
# Nix only manages your user profile here; apt still owns the base OS.
#
# Safe to re-run: every step is idempotent.
#
# Usage:
#   ./scripts/bootstrap-ubuntu.sh
#
set -euo pipefail

REPO_DIR="$HOME/dotfiles"
FLAKE_REF="$REPO_DIR#$(whoami)@ubuntu"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==>\033[0m %s\n' "$*"; }

# 1. Ensure the repo is present at ~/dotfiles.
if [ ! -d "$REPO_DIR" ]; then
  warn "Expected the repo at $REPO_DIR but it is missing."
  warn "Clone it first, e.g.: git clone git@github.com:NorskJoe/dotfiles.git ~/dotfiles"
  exit 1
fi

# 2. Install Nix (Determinate Systems installer: flakes enabled by default).
if ! command -v nix >/dev/null 2>&1; then
  info "Installing Nix via the Determinate Systems installer..."
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
    | sh -s -- install --no-confirm
else
  info "Nix already installed, skipping."
fi

# 3. Make nix available in the current shell (the installer adds it to future
#    login shells; this profile script wires it up for this run).
if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

if ! command -v nix >/dev/null 2>&1; then
  warn "nix is not on PATH yet. Open a new terminal and re-run this script."
  exit 1
fi

# 4. Apply the home-manager configuration for this machine.
info "Applying home-manager configuration: $FLAKE_REF"
nix run home-manager/release-26.05 -- switch --flake "$FLAKE_REF" -b backup

# 5. Offer to make zsh the login shell.
ZSH_BIN="$HOME/.nix-profile/bin/zsh"
if [ -x "$ZSH_BIN" ]; then
  if [ "${SHELL:-}" != "$ZSH_BIN" ]; then
    info "Setting zsh as your login shell..."
    if ! grep -qx "$ZSH_BIN" /etc/shells; then
      echo "$ZSH_BIN" | sudo tee -a /etc/shells >/dev/null
    fi
    chsh -s "$ZSH_BIN" || warn "chsh failed; set your shell manually with: chsh -s $ZSH_BIN"
  fi
fi

info "Done. Open a new terminal to start using your environment."
info "Rebuild later with:  rebuild   (alias for home-manager switch)"
