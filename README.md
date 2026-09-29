# dotfiles - cross-platform dev environment

Declarative, reproducible development environment. One branch, shared config,
three supported setups. **Pick the one that matches your machine and follow only
that section:**

| | [Windows + WSL](#windows--wsl-setup) | [Windows (no WSL)](#windows-no-wsl-setup) | [Ubuntu](#ubuntu-setup) |
|---|---|---|---|
| What Nix manages | whole NixOS-WSL OS (`nixosConfigurations.wsl`) | nothing | user profile only (`homeConfigurations."joe@ubuntu"`) |
| Installer | `nixos-rebuild` (inside WSL) + `install-windows.sh` (Windows) | `install-windows.sh` | `bootstrap-ubuntu.sh` |
| Shell / editor tooling | Nix (zsh, Neovim, LSPs) | pwsh, install tools yourself | Nix (zsh, Neovim, LSPs) |
| WezTerm | Windows app, asks WSL or pwsh at launch | Windows app, opens pwsh | native (Nix) |
| Claude / opencode config | Nix (WSL) + script (Windows) | script | Nix |
| VSCode | Remote-WSL | - | - |

Nix-managed tooling (WSL and Ubuntu):

- **Editor:** Neovim + LSPs/formatters via Nix
- **Shell:** zsh (+ starship, zoxide, fzf)
- **Terminal:** WezTerm, one shared platform-aware `wezterm.lua`

---

## Windows + WSL setup

Nix manages the whole NixOS-WSL distro. The Windows side (WezTerm, pwsh
profile, Claude Code config) is set up separately by `install-windows.sh`, so
this setup uses **two clones** of the repo: one inside WSL, one on Windows.

### 1. Prerequisites (Windows)

- [Git for Windows](https://git-scm.com/download/win) (provides Git Bash, which
  Claude Code also uses for its status line).
- **Developer Mode** on (Settings > System > For developers), or an admin shell.
  The Windows installer creates real symlinks.
- `winget` (ships with Windows 11).
- A recent WSL (the `.wsl` import format needs WSL >= 2.4.4). In PowerShell:

  ```powershell
  wsl --update
  wsl --version   # confirm WSL version 2.x
  wsl --set-default-version 2
  ```

### 2. Install the NixOS-WSL distro (Windows)

Download the latest `nixos.wsl` from
<https://github.com/nix-community/NixOS-WSL/releases>, then import it.

**WSL 2.4.4+** - just run the file, or:

```powershell
wsl --install --from-file nixos.wsl
```

**Older WSL** - import manually into a folder you control:

```powershell
wsl --import NixOS C:\WSL\NixOS .\nixos.wsl --version 2
```

Either way the distro must be named **`NixOS`** (the name WezTerm targets; see
[WezTerm on Windows](#wezterm-on-windows) to change it). Open it:

```powershell
wsl -d NixOS
```

### 3. Clone and edit (inside WSL)

```bash
# Get git if it isn't already available
nix-shell -p git

# Clone to ~/dotfiles (the paths in the config assume this location)
git clone https://github.com/NorskJoe/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

Edit the templates you own:

- `home/git.nix` - set `userName` / `userEmail`.
- `config/nvim/init.lua` - your Neovim config (starts minimal).

### 4. Build and switch (inside WSL)

Flakes aren't enabled until this config is applied, so pass the flag once:

```bash
sudo nixos-rebuild switch --flake ~/dotfiles#wsl \
  --option experimental-features "nix-command flakes"
```

Then restart the distro from PowerShell:

```powershell
wsl --shutdown
wsl -d NixOS
```

Your zsh shell, Neovim, and CLI tooling are now live.

### 5. Set up the Windows side (Git Bash)

Clone a second copy on the Windows filesystem and run the installer:

```bash
git clone https://github.com/NorskJoe/dotfiles.git /c/dev/dotfiles   # any path works
bash /c/dev/dotfiles/scripts/install-windows.sh
```

It installs WezTerm and PowerShell 7 and links their config plus Claude Code's
(details in [Windows installer](#windows-installer)). Restart WezTerm and Claude
Code afterwards. WezTerm now asks at launch whether to open WSL or PowerShell
(see [WezTerm on Windows](#wezterm-on-windows)).

### 6. VSCode (Remote-WSL)

NixOS needs a little help because VSCode downloads dynamically-linked server
binaries. This repo already handles that via:

- `services.vscode-server.enable = true;` (from `nixos-vscode-server`) - patches
  the server so it runs on NixOS.
- `programs.nix-ld.enable = true;` - lets other prebuilt binaries (LSPs, etc.) run.
  `programs.nix-ld.libraries` includes `icu` for the C# Dev Kit's Roslyn language
  server, which needs it at runtime.

To use it:

1. Install the **WSL** extension in VSCode on Windows
   (`ms-vscode-remote.remote-wsl`).
2. From WSL, open a folder in VSCode:

   ```bash
   cd ~/some-project
   code .
   ```

   The `code` command is available because `wsl.interop.includePath` exposes the
   Windows PATH inside WSL.

3. VSCode installs and patches its server automatically; extensions install into
   the WSL side.

### 7. Day-to-day (inside WSL)

```bash
rebuild        # sudo nixos-rebuild switch --flake ~/dotfiles#wsl
update         # update flake inputs, then rebuild
sudo nixos-rebuild switch --rollback   # roll back to the previous generation
```

Re-run `install-windows.sh` on Windows after pulling changes to the Windows-side
config (it is idempotent).

---

## Windows (no WSL) setup

No Nix. The installer sets up WezTerm, the PowerShell profile and Claude Code
config. CLI tooling (Neovim, LSPs, etc.) is not managed here; install it
yourself.

### 1. Prerequisites

- [Git for Windows](https://git-scm.com/download/win) (provides Git Bash, which
  Claude Code also uses for its status line).
- **Developer Mode** on (Settings > System > For developers), or an admin shell.
  The installer creates real symlinks.
- `winget` (ships with Windows 11).

### 2. Install (Git Bash)

```bash
git clone https://github.com/NorskJoe/dotfiles.git /c/dev/dotfiles   # any path works
bash /c/dev/dotfiles/scripts/install-windows.sh
```

See [Windows installer](#windows-installer) for what it does.

### 3. Finish

Restart WezTerm and Claude Code. With no WSL distro installed, WezTerm opens
pwsh straight away (see [WezTerm on Windows](#wezterm-on-windows)).

To update, `git pull` and re-run the installer (it is idempotent).

---

## Ubuntu setup

On a native Ubuntu install, Nix manages **only your user profile** via
standalone Home Manager; apt still owns the base OS. This is fully reversible
(Home Manager generations + uninstalling Nix).

### 1. Clone and edit

```bash
sudo apt-get update && sudo apt-get install -y git
git clone https://github.com/NorskJoe/dotfiles.git ~/dotfiles   # config paths assume this location
```

Edit the templates you own:

- `home/git.nix` - set `userName` / `userEmail`.
- `config/nvim/init.lua` - your Neovim config (starts minimal).
- `flake.nix` - change `username` if your Ubuntu login is not `joe`; the config
  key then becomes `<username>@ubuntu` in every command below.

### 2. Run the bootstrap

```bash
~/dotfiles/scripts/bootstrap-ubuntu.sh
```

The script is idempotent and safe to re-run. It:

1. Installs Nix via the Determinate Systems installer (flakes on by default).
2. Runs `home-manager switch --flake ~/dotfiles#joe@ubuntu`.
3. Optionally sets zsh as your login shell.
4. Optionally installs the Docker engine via apt (see [Docker](#docker)).

Open a new terminal afterwards. Your zsh, Neovim, WezTerm, and CLI tooling are
live.

<details>
<summary>Manual equivalent of the bootstrap</summary>

```bash
# Install Nix (flakes enabled by default)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# New shell, then apply the config
nix run home-manager/release-26.05 -- switch --flake ~/dotfiles#joe@ubuntu

# (optional) make zsh your login shell
chsh -s "$HOME/.nix-profile/bin/zsh"
```

</details>

### 3. Day-to-day

The `rebuild` / `update` aliases are wired to Home Manager here (not
`nixos-rebuild`):

```bash
rebuild        # home-manager switch --flake ~/dotfiles#joe@ubuntu
update         # update flake inputs, then switch
home-manager generations   # list generations; run one's activate script to roll back
```

### WezTerm

WezTerm is installed by Nix (`home/wezterm.nix`) and runs **natively** - there is
no WSL and no `WSL:NixOS` domain involved. Its config at `~/.config/wezterm` is a
live symlink to `config/wezterm/wezterm.lua`, the same file used on Windows; it
detects the platform at runtime (`wezterm.target_triple`) and only enables the
WSL domain on Windows. Launch WezTerm from your desktop environment.

### Docker

Home Manager cannot run a system daemon or manage the `docker` group, so the
Docker **engine** comes from apt while the `docker-compose` CLI comes from Nix.
The bootstrap script offers to do this; to set it up manually:

```bash
sudo apt-get update && sudo apt-get install -y docker.io
sudo usermod -aG docker "$USER"
# Log out and back in (or run `newgrp docker`) to pick up the group.
```

---

## Reference

### Windows installer

`scripts/install-windows.sh` is used by both Windows setups and runs from Git
Bash. It is idempotent (re-run any time; replaced files are moved to
`*.bak.<time>`):

1. Installs WezTerm and PowerShell 7 with winget, plus the `posh-git` module.
   (WezTerm bundles JetBrains Mono and the Nerd Font symbols.)
2. Links `~/.wezterm.lua` to `config/wezterm/wezterm.lua`.
3. Asks for the pwsh start directory and writes `~/.wezterm.local.lua` (see
   [WezTerm on Windows](#wezterm-on-windows)).
4. Links the pwsh `$PROFILE` to `config/powershell/`.
5. Links `~/.claude/CLAUDE.md` to `config/agents/AGENTS.md` and merges the
   `statusLine` key into `~/.claude/settings.json` (other keys untouched).
   See `config/claude/README.md`.

### WezTerm on Windows

WezTerm asks which host to open every time it launches:

```
Open host
  1. WSL (NixOS)
  2. PowerShell
```

- Press `1` / `2` (or arrows + Enter). `Esc` keeps PowerShell.
- **No WSL distro installed:** no prompt, it opens pwsh straight away.
- `Leader+w` opens a tab in WSL and `Leader+p` a tab in pwsh (Leader is `Ctrl+b`).
- `Ctrl+Shift+T` opens a new tab on the same host as the current pane.
- Linux has no prompt; WezTerm opens the local shell.

Machine-specific values live in an **untracked** file,
`%USERPROFILE%\.wezterm.local.lua`, created by the installer:

```lua
return {
  wsl_domain = "WSL:NixOS",    -- optional; must match a distro from `wsl -l`
  default_cwd = "D:/Projects", -- optional; starting directory for pwsh
}
```

- If your distro is not named `NixOS`, set `wsl_domain` (e.g. `"WSL:Ubuntu"`).
- Edit the file (WezTerm reloads it), or delete it and re-run the installer.
- Without the file, the defaults are `WSL:NixOS` and your home directory.

### Repository layout

```
dotfiles/
├── flake.nix                  # entry point: nixosConfigurations.wsl + homeConfigurations."joe@ubuntu"
├── hosts/
│   └── wsl/
│       └── configuration.nix  # system-level NixOS config (WSL, users, VSCode support)
├── home/
│   ├── common.nix             # shared Home Manager base (imports + shared packages)
│   ├── home.nix               # WSL entrypoint (imports common.nix)
│   ├── ubuntu.nix             # native Ubuntu entrypoint (imports common.nix, allowUnfree)
│   ├── shell.nix              # zsh + prompt config (platform-aware aliases)
│   ├── git.nix                # git identity/config  <- EDIT your name/email
│   ├── agents.nix             # opencode + Claude Code: AGENTS.md link, statusLine
│   ├── wezterm.nix            # Ubuntu only: installs WezTerm, symlinks config/wezterm
│   └── neovim.nix             # installs Neovim + LSPs, symlinks config/nvim
├── scripts/
│   ├── bootstrap-ubuntu.sh    # one-shot setup for a fresh native Ubuntu box
│   └── install-windows.sh     # Windows side (pure Windows or WSL host), run from Git Bash
└── config/
    ├── agents/AGENTS.md       # global agent instructions (Claude CLAUDE.md, opencode)
    ├── claude/                # status bar script + README
    ├── nvim/                  # Neovim config
    ├── powershell/            # pwsh profile (Windows)
    └── wezterm/
        └── wezterm.lua        # shared WezTerm config (Linux native / Windows)
```

The shared Home Manager modules in `home/` are imported by both Nix targets.
OS-specific behaviour (rebuild aliases, WSL inotify workaround) is branched on a
`platform` argument passed from `flake.nix`.

> **NixOS-WSL vs native Ubuntu.** Ubuntu is not NixOS, so `nixosConfigurations`
> cannot manage it. On Ubuntu you install the Nix package manager and apply the
> standalone Home Manager config, which reuses every module under `home/`.
> Because Ubuntu is a normal glibc/FHS system, the `nix-ld` and `vscode-server`
> shims that WSL/NixOS needs are not required there.

### Common tasks

| Task                             | Command                                        |
| -------------------------------- | ---------------------------------------------- |
| Rebuild after editing config     | `rebuild` (WSL, Ubuntu)                        |
| Update all inputs + rebuild      | `update` (WSL, Ubuntu)                         |
| Roll back (WSL)                  | `sudo nixos-rebuild switch --rollback`         |
| Roll back (Ubuntu)               | `home-manager generations` then activate one   |
| Free old generations (WSL)       | `sudo nix-collect-garbage -d`                  |
| Free old generations (Ubuntu)    | `nix-collect-garbage --delete-older-than 7d`   |
| Re-apply Windows config          | `bash scripts/install-windows.sh` (Git Bash)   |
| Format Nix files                 | `nix fmt` (add a formatter to the flake first) |

---

## SSH keys for multiple accounts

This environment uses **one SSH key per account**, selected automatically per
remote by the `Host` matched in `~/.ssh/config`. This file is **not** managed by
this repo (it lives outside version control), so set it up manually per machine.

Three accounts are in use:

| Account            | Service           | Key                     |
| ------------------ | ----------------- | ----------------------- |
| Personal GitHub    | github.com        | `~/.ssh/personal`       |
| Work Azure DevOps  | ssh.dev.azure.com | `~/.ssh/woolies`        |
| Work GitHub (org `woolworthslimited`) | github.com | `~/.ssh/woolies-github` |

Personal and work GitHub share the same host (`github.com`), so the work account
uses a **host alias** (`github-work`) to pick the right key.

### 1. Generate the keys

```bash
ssh-keygen -t ed25519 -f ~/.ssh/personal       -C "personal-github"
ssh-keygen -t ed25519 -f ~/.ssh/woolies        -C "woolies-azure-devops"
ssh-keygen -t ed25519 -f ~/.ssh/woolies-github -C "work-github-woolworthslimited"
```

(Only generate the ones you don't already have.)

### 2. Configure `~/.ssh/config`

```
# Personal GitHub Account
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/personal
    IdentitiesOnly yes

# Woolies Azure DevOps Account
Host ssh.dev.azure.com
    User git
    IdentityFile ~/.ssh/woolies
    IdentitiesOnly yes
    WarnWeakCrypto no-pq-kex

# Woolies Work GitHub Account (org: woolworthslimited)
# Use the alias `github-work` in remote URLs to select this key.
Host github-work
    HostName github.com
    User git
    IdentityFile ~/.ssh/woolies-github
    IdentitiesOnly yes
```

### 3. Register the public keys

- **Personal GitHub:** add `~/.ssh/personal.pub` at
  <https://github.com/settings/keys>.
- **Work GitHub:** add `~/.ssh/woolies-github.pub` to the work GitHub account at
  <https://github.com/settings/keys>.
- **Azure DevOps:** add `~/.ssh/woolies.pub` under *User settings > SSH public keys*.

Print a key to copy it:

```bash
cat ~/.ssh/woolies-github.pub
```

### 4. Clone with the right identity

The host in the URL decides which key is used:

```bash
# Personal
git clone git@github.com:<you>/<repo>.git

# Work GitHub (note the github-work alias)
git clone git@github-work:woolworthslimited/<repo>.git

# Azure DevOps
git clone git@ssh.dev.azure.com:v3/<org>/<project>/<repo>
```

For an existing work GitHub repo, point its remote at the alias:

```bash
git remote set-url origin git@github-work:woolworthslimited/<repo>.git
```

### 5. Verify

```bash
ssh -T git@github.com     # personal account greeting
ssh -T git@github-work    # work account greeting
ssh -T git@ssh.dev.azure.com
```

---

## Adding a new language to Neovim

Applies to the WSL and Ubuntu setups. Neovim's IDE features live in
[`config/nvim/lua/plugins/ide.lua`](config/nvim/lua/plugins/ide.lua),
and all tooling binaries are installed via Nix in
[`home/neovim.nix`](home/neovim.nix). **Mason is intentionally not used** -
its prebuilt binaries don't run on NixOS, so servers/formatters come from Nix.

Adding a language is up to four small steps. Do only the ones you need.

1. **Syntax (Treesitter):** add the parser name to the `ensure_installed`
   list at the top of `ide.lua`. Parser names differ from filetypes
   (e.g. `c_sharp`, not `cs`); browse them with `:TSInstall <Tab>`.

2. **LSP server:** install the server with Nix, then enable it.
   - Add the package to `home.packages` in `home/neovim.nix`. Verify the
     attribute exists first:

     ```bash
     nix eval --impure --raw --expr 'let f = builtins.getFlake (toString /home/joe/dotfiles); \
       p = import f.inputs.nixpkgs { system = "x86_64-linux"; }; \
       in if builtins.hasAttr "PACKAGE_NAME" p then "OK" else "MISSING"'
     ```

   - Add the server's lspconfig name to the `vim.lsp.enable({ ... })` list in
     `ide.lua`. Find the correct name in `:help lspconfig-all` (e.g. the Go
     server is `gopls`, Rust is `rust_analyzer`). Servers that speak a
     non-standard protocol (like C#'s `roslyn`) may need a dedicated plugin
     instead - see the `roslyn.nvim` block for the pattern.

3. **Formatter (conform.nvim):** install the formatter with Nix
   (step 2's package list), then add a `filetype = { 'formatter' }` entry under
   `formatters_by_ft` in the `conform.nvim` spec. Format-on-save then applies
   automatically; manual format is `<leader>cf`.

4. **Apply:** rebuild, then sync plugins:

   ```bash
   rebuild
   nvim +Lazy sync +qa   # or run :Lazy sync inside Neovim
   ```

   Check things loaded with `:checkhealth vim.lsp` and `:ConformInfo`.

---

## Troubleshooting

### (WSL) Corporate VPN breaks `localhost:3000` between Windows and WSL

**Symptoms**

- A service started inside WSL (e.g. a Next.js dev server on port 3000) is no
  longer reachable from a service running on the Windows host, even though it was
  working earlier.
- On opening WSL you see:

  ```
  wsl: A localhost proxy configuration was detected but not mirrored into WSL.
  WSL in NAT mode does not support localhost proxies.
  ```

- `WSL_PAC_URL=http://127.0.0.1:9000/systemproxy-*.pac` shows up in `env`, even
  after the VPN is disconnected (stale leftover).

**Cause**

A corporate VPN reconfigures Windows loopback/proxy routing when it connects. In
WSL2 **NAT mode**, Windows and WSL have different `127.0.0.1`, so the Windows
localhost proxy is meaningless inside WSL, and NAT's IPv4 loopback forwarding to
the WSL service gets mangled. Disconnecting the VPN often leaves it half-broken.

**How to confirm**

```bash
# Service is actually up? (bind + local reachability via IPv6 / eth0 IP)
ss -tlnp | grep 3000
curl -s -o /dev/null -w "%{http_code}\n" http://[::1]:3000        # works -> 200
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:3000    # broken -> 000

# Windows-side view (these honor Windows proxy settings)
curl.exe -s -o NUL -w "%{http_code}\n" http://127.0.0.1:3000      # broken -> 000
reg.exe query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable
netsh.exe winhttp show proxy
```

If IPv6 `::1` and the eth0 IP work but IPv4 `127.0.0.1` returns `000`, it's the
broken NAT loopback, not an application bug.

**Quick workaround (no restart)**

Point the Windows service at the WSL IP directly instead of `localhost`:

```bash
ip addr show eth0   # e.g. 172.29.129.214
# Windows service -> http://172.29.129.214:3000
```

Note: this NAT IP can change when WSL restarts.

**Durable fix - mirrored networking mode**

Switch WSL to mirrored networking, which shares the Windows network stack (stable
`localhost` both directions) and tolerates VPN localhost proxies. Create
`C:\Users\<you>\.wslconfig`:

```ini
[wsl2]
networkingMode=mirrored

[experimental]
autoProxy=true
hostAddressLoopback=true
```

Then from **Windows** (PowerShell/CMD, not the WSL shell):

```powershell
wsl --shutdown
```

Reopen WSL and verify - the boot warning should be gone and
`curl http://127.0.0.1:3000` should return `200`. In mirrored mode `ip addr`
shows your Windows LAN IP rather than a `172.x` NAT address, and `autoProxy=true`
lets WSL pull the Windows proxy correctly when the VPN reconnects.

> If mirrored mode ever conflicts with the corporate VPN, delete `.wslconfig` and
> run `wsl --shutdown` to revert to NAT mode.

### (WSL, Ubuntu) Roslyn doesn't see newly created C# files

When you create a new `.cs` file inside Neovim, Roslyn may not recognise the
new type from other files (no completion or code actions referencing it) until
a restart. This is a side effect of `filewatching = "roslyn"` in the
`roslyn.nvim` block (`ide.lua`), which we use for performance because Neovim's
own file watcher is slow on Linux. With it enabled, Neovim no longer tells
Roslyn when a file is created, so the new file stays outside the project's
compilation.

The `RoslynNewFile` autocmd in `ide.lua` handles this automatically: the first
time a new `.cs` file is written, it sends Roslyn a `didChangeWatchedFiles`
"Created" event so the file joins the project immediately - no restart needed.

If a file is ever still missing, `<leader>cr` (`:LspRestart`) forces a full
Roslyn solution reload as a fallback.

### (WSL) Webpack / Vite dev server: `ENOSPC: System limit for number of file watchers reached`

**Symptoms**

Running a JS dev server (e.g. `npm run dev`) fails with:

```
Watchpack Error (watcher): Error: ENOSPC: System limit for number of file
watchers reached, watch '/home/joe/...'
```

The error repeats for every parent directory, down to a single directory like
`/home`.

**Cause**

WSL2's inotify is broken. `inotify_add_watch` returns `ENOSPC` even when the
watch count is far below `fs.inotify.max_user_watches` (it can fail to add even
one watch). This is **not** a watch-count exhaustion issue - raising
`max_user_watches`/`max_user_instances` (e.g. `524288`) does **not** fix it.

**How to confirm**

```bash
cat /proc/sys/fs/inotify/max_user_watches  # already 524288 on WSL2 - still fails
```

**Fix**

Force file-watchers to poll instead of using inotify. This is set globally in
`home/shell.nix` (zsh `initContent`):

```sh
export WATCHPACK_POLLING=true
export CHOKIDAR_USEPOLLING=true
```

After editing, `rebuild` and open a fresh shell. Or, for a one-off:

```bash
CHOKIDAR_USEPOLLING=true WATCHPACK_POLLING=true npm run dev
```

Polling is more CPU-intensive than inotify, but it works reliably on WSL2.

---

## Notes & decisions

- **Flakes + Home Manager:** on WSL, one `nixos-rebuild` applies both system and
  user config; on native Ubuntu, standalone `home-manager switch` applies the
  user config only. Both share the modules in `home/`.
- **Neovim config is a live symlink** (`mkOutOfStoreSymlink`) to
  `config/nvim/`, so you can iterate without a rebuild.
- **WezTerm lives on Windows in the WSL setup** because the terminal emulator is
  a host GUI app; only its target distro references WSL. On Ubuntu it runs
  natively.
- **`stateVersion` is pinned to `26.05`.** Leave it as-is after first install; it
  is not the same as your package versions.
