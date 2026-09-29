#!/usr/bin/env bash
# Set up the Windows side of this repo (pure Windows, or Windows hosting WSL).
# Run from Git Bash. Idempotent: safe to re-run.
#
# Does:
#   1. winget: WezTerm, PowerShell 7 (and posh-git module)
#   2. ~/.wezterm.lua            -> config/wezterm/wezterm.lua
#   3. ~/.wezterm.local.lua      -> per-machine WSL distro + pwsh cwd (only created if missing)
#   4. pwsh $PROFILE             -> config/powershell/Microsoft.PowerShell_profile.ps1
#   5. ~/.claude/CLAUDE.md       -> config/agents/AGENTS.md
#   6. ~/.claude/settings.json   -> statusLine key merged in (other keys untouched)
#
# Symlinks need Developer Mode (Settings > System > For developers) or an admin shell.

set -euo pipefail

# Git Bash's `ln -s` silently copies unless told to make real NTFS symlinks.
export MSYS=winsymlinks:nativestrict

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CLAUDE_DIR=${CLAUDE_CONFIG_DIR:-$HOME/.claude}

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==>\033[0m %s\n' "$*" >&2; }

link() {
    local src=$1 dest=$2
    mkdir -p "$(dirname "$dest")"

    if [[ -L $dest && $(readlink "$dest") == "$src" ]]; then
        echo "ok      $dest (already linked)"
        return
    fi

    if [[ -e $dest || -L $dest ]]; then
        local backup="$dest.bak.$(date +%Y%m%d%H%M%S)"
        mv "$dest" "$backup"
        echo "backup  $dest -> $backup"
    fi

    if ln -s "$src" "$dest"; then
        echo "linked  $dest -> $src"
    else
        warn "failed  $dest"
        warn "Enable Developer Mode (Settings > System > For developers) or run as admin."
        return 1
    fi
}

winget_install() {
    local id=$1
    if winget.exe list --exact --id "$id" --accept-source-agreements >/dev/null 2>&1; then
        echo "ok      $id (installed)"
    else
        winget.exe install --exact --id "$id" \
            --accept-package-agreements --accept-source-agreements
    fi
}

# 1. Packages ------------------------------------------------------------------
info "Packages"
if command -v winget.exe >/dev/null; then
    # WezTerm bundles JetBrains Mono and Symbols Nerd Font Mono, so no fonts needed.
    winget_install wez.wezterm
    winget_install Microsoft.PowerShell
else
    warn "winget not found; install WezTerm and PowerShell 7 manually."
fi

if command -v pwsh.exe >/dev/null || [[ -x "/c/Program Files/PowerShell/7/pwsh.exe" ]]; then
    PWSH=$(command -v pwsh.exe || echo "/c/Program Files/PowerShell/7/pwsh.exe")
    "$PWSH" -NoProfile -Command \
        'if (-not (Get-Module -ListAvailable posh-git)) { Install-Module posh-git -Scope CurrentUser -Force }'
else
    PWSH=
    warn "pwsh not found on PATH (open a new Git Bash after installing PowerShell 7 and re-run)."
fi

# 2. WezTerm config ------------------------------------------------------------
info "WezTerm"
link "$REPO/config/wezterm/wezterm.lua" "$HOME/.wezterm.lua"

# 3. Per-machine WezTerm settings (WezTerm asks WSL or pwsh at launch) ----------
LOCAL_CFG="$HOME/.wezterm.local.lua"
if [[ -e $LOCAL_CFG ]]; then
    echo "ok      $LOCAL_CFG (exists; edit or delete it to change)"
else
    read -r -p "Default directory for pwsh [$(cygpath -m "$HOME")]: " cwd
    cwd=${cwd:-$(cygpath -m "$HOME")}

    cat > "$LOCAL_CFG" <<LUA
-- Per-machine WezTerm settings (untracked). Read by config/wezterm/wezterm.lua.
return {
  wsl_domain = "WSL:NixOS",    -- must match a distro from \`wsl -l\`
  default_cwd = "${cwd//\/\\}", -- used for pwsh
}
LUA
    echo "wrote   $LOCAL_CFG"
fi

# 4. PowerShell profile --------------------------------------------------------
info "PowerShell profile"
if [[ -n $PWSH ]]; then
    profile=$("$PWSH" -NoProfile -Command '$PROFILE' | tr -d '\r')
    link "$REPO/config/powershell/Microsoft.PowerShell_profile.ps1" "$(cygpath -u "$profile")"
fi

# 5. Claude Code ---------------------------------------------------------------
info "Claude Code"
link "$REPO/config/agents/AGENTS.md" "$CLAUDE_DIR/CLAUDE.md"

if [[ -n $PWSH ]]; then
    SETTINGS=$(cygpath -m "$CLAUDE_DIR/settings.json") \
    STATUS_CMD="bash $(cygpath -m "$REPO")/config/claude/scripts/status-bar.sh" \
    "$PWSH" -NoProfile -Command '
        $Settings = $env:SETTINGS; $Command = $env:STATUS_CMD
        $s = if ((Test-Path $Settings) -and (Get-Item $Settings).Length -gt 0) {
            Get-Content $Settings -Raw | ConvertFrom-Json
        } else { [pscustomobject]@{} }
        $s | Add-Member -NotePropertyName statusLine -Force -NotePropertyValue ([pscustomobject]@{
            type = "command"; command = $Command })
        New-Item -ItemType Directory -Force (Split-Path $Settings) | Out-Null
        $s | ConvertTo-Json -Depth 20 | Set-Content $Settings -Encoding utf8NoBOM
    '
    echo "ok      $CLAUDE_DIR/settings.json (statusLine set)"
fi

info "Done. Restart WezTerm and Claude Code."
