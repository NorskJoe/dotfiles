# dotfiles - cross-platform dev environment

Declarative, reproducible development environment built on **Nix** with
**Flakes** and **Home Manager**. Two **independent** targets, one branch, shared
config:

- **NixOS on WSL2** - Nix manages the whole OS (`nixosConfigurations.wsl`).
- **Native Ubuntu** - stock Ubuntu, Nix manages only your user profile via
  standalone Home Manager (`homeConfigurations."joe@ubuntu"`). This does **not**
  use WSL - WSL is only relevant on the Windows side of the WSL target.

Common tooling on both:

- **Editor:** Neovim (config template you fill in) + LSPs/formatters via Nix
- **Shell:** zsh (+ starship, zoxide, fzf)
- **Terminal:** WezTerm - runs **natively** on Ubuntu (installed via Nix); on the
  WSL target it runs on **Windows** and connects into the distro. One shared,
  platform-aware `wezterm.lua`.
- **VSCode** Remote-WSL support (WSL target only)

The shared Home Manager modules live in `home/` and are imported by both
targets. OS-specific behaviour (rebuild aliases, WSL inotify workaround) is
branched on a `platform` argument passed from `flake.nix`.

---

## Repository layout

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
│   ├── git.nix                # git identity/config  ← EDIT your name/email
│   ├── agents.nix             # opencode + shared AGENTS.md
│   ├── wezterm.nix            # Ubuntu only: installs WezTerm, symlinks config/wezterm
│   └── neovim.nix             # installs Neovim + LSPs, symlinks config/nvim
├── scripts/
│   └── bootstrap-ubuntu.sh    # one-shot setup for a fresh native Ubuntu box
└── config/
    ├── nvim/
    │   └── init.lua           # Neovim template  ← YOURS to fill in
    └── wezterm/
        └── wezterm.lua        # shared WezTerm config (native on Linux / Windows-side for WSL)
```

> **NixOS-WSL vs native Ubuntu.** Ubuntu is not NixOS, so `nixosConfigurations`
> cannot manage it. On Ubuntu you install the Nix package manager and apply the
> standalone Home Manager config, which reuses every module under `home/`.
> Because Ubuntu is a normal glibc/FHS system, the `nix-ld` and `vscode-server`
> shims that WSL/NixOS needs are not required there.

---

## Part 1 — Install NixOS on WSL2 (Windows side)

### 0. Prerequisites

Update WSL to a recent version (the modern `.wsl` import format needs WSL ≥ 2.4.4):

```powershell
wsl --update
wsl --version   # confirm WSL version 2.x and set default to 2
wsl --set-default-version 2
```

### 1. Get the NixOS-WSL image

Download the latest `nixos.wsl` from the releases page:
<https://github.com/nix-community/NixOS-WSL/releases>

### 2. Import the distro

**Modern WSL (2.4.4+)** — just run the file, or:

```powershell
wsl --install --from-file nixos.wsl
```

**Older WSL** — import manually into a folder you control:

```powershell
wsl --import NixOS C:\WSL\NixOS .\nixos.wsl --version 2
```

This registers a distro named **`NixOS`** (the name WezTerm targets below).

### 3. First boot

```powershell
wsl -d NixOS
```

You are dropped into a working NixOS shell

---

## Part 2 — Apply this configuration (inside WSL)

### 1. Enable flakes for the initial bootstrap

Flakes aren't enabled by default until this config is applied, so pass the flag
once:

```bash
# Get git if it isn't already available
nix-shell -p git

# Clone this repo to ~/dotfiles (the paths in the config assume this location)
git clone <your-repo-url> ~/dotfiles
cd ~/dotfiles
```

### 2. Edit the templates you own

- `home/git.nix` — set `userName` / `userEmail`.
- `config/nvim/init.lua` — your Neovim config (starts minimal).
- Optionally change `username` in `flake.nix` if you don't want `nixos`.

### 3. Build & switch

```bash
sudo nixos-rebuild switch --flake ~/dotfiles#wsl \
  --option experimental-features "nix-command flakes"
```

After the first switch, flakes are enabled system-wide and you can just use the
`rebuild` alias:

```bash
rebuild        # sudo nixos-rebuild switch --flake ~/dotfiles#wsl
update         # update flake inputs, then rebuild
```

### 4. Restart the distro

```powershell
wsl --shutdown
wsl -d NixOS
```

Your zsh shell, Neovim, and CLI tooling are now live.

---

## Part 3 — WezTerm (WSL target, Windows side)

For the WSL target, WezTerm is a Windows GUI app that opens a session into your
WSL distro. (On native Ubuntu, WezTerm runs directly - see Part 5.)

1. Install WezTerm on Windows: <https://wezfurlong.org/wezterm/install/windows.html>
   (or `winget install wez.wezterm`).
2. Point WezTerm at this repo's config. In an **elevated** PowerShell:

   ```powershell
   New-Item -ItemType SymbolicLink `
     -Path "$env:USERPROFILE\.wezterm.lua" `
     -Target "C:\dev\dotfiles\config\wezterm\wezterm.lua"
   ```

   (Or copy the file if you prefer not to symlink.)

3. Launch WezTerm — it opens straight into the `NixOS` distro
   (`config.default_domain = "WSL:NixOS"`).

> If you named the distro something other than `NixOS`, update
> `default_domain` in `config/wezterm/wezterm.lua`.

---

## Part 4 — VSCode (Remote-WSL)

NixOS needs a little help because VSCode downloads dynamically-linked server
binaries. This repo already handles that via:

- `services.vscode-server.enable = true;` (from `nixos-vscode-server`) — patches
  the server so it runs on NixOS.
- `programs.nix-ld.enable = true;` — lets other prebuilt binaries (LSPs, etc.) run.
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

---

## Part 5 — Native Ubuntu (not WSL)

On a full Ubuntu install, Nix manages **only your user profile** via standalone
Home Manager; apt still owns the base OS. This is fully reversible (Home Manager
generations + uninstalling Nix).

### Quick start (bootstrap script)

```bash
# 1. Get the repo to ~/dotfiles (the config paths assume this location).
sudo apt-get update && sudo apt-get install -y git
git clone <your-repo-url> ~/dotfiles

# 2. Run the bootstrap: installs Nix (flakes), applies the config, offers zsh.
~/dotfiles/scripts/bootstrap-ubuntu.sh
```

The script is idempotent and safe to re-run. It:

1. Installs Nix via the Determinate Systems installer (flakes on by default).
2. Runs `home-manager switch --flake ~/dotfiles#joe@ubuntu`.
3. Optionally sets zsh as your login shell.
4. Optionally installs the Docker engine via apt (see below).

Open a new terminal afterwards. Your zsh, Neovim, WezTerm, and CLI tooling are
live.

### WezTerm on Ubuntu

WezTerm is installed by Nix (`home/wezterm.nix`) and runs **natively** - there is
no WSL and no `WSL:NixOS` domain involved. Its config at `~/.config/wezterm` is a
live symlink to `config/wezterm/wezterm.lua`, the same file used on Windows; it
detects the platform at runtime (`wezterm.target_triple`) and only enables the
WSL domain on Windows. Just launch WezTerm from your desktop environment.

### Docker on Ubuntu

Home Manager cannot run a system daemon or manage the `docker` group, so the
Docker **engine** comes from apt while the `docker-compose` CLI comes from Nix.
The bootstrap script offers to do this; to set it up manually:

```bash
sudo apt-get update && sudo apt-get install -y docker.io
sudo usermod -aG docker "$USER"
# Log out and back in (or run `newgrp docker`) to pick up the group.
```

### Manual steps (equivalent)

```bash
# Install Nix (flakes enabled by default)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# New shell, then apply the config
nix run home-manager/release-26.05 -- switch --flake ~/dotfiles#joe@ubuntu

# (optional) make zsh your login shell
chsh -s "$HOME/.nix-profile/bin/zsh"
```

### Day-to-day on Ubuntu

The `rebuild` / `update` aliases are automatically wired to Home Manager here
(not `nixos-rebuild`):

```bash
rebuild        # home-manager switch --flake ~/dotfiles#joe@ubuntu
update         # update flake inputs, then switch
```

> Change `username` in `flake.nix` if your Ubuntu login is not `joe`; the config
> key becomes `<username>@ubuntu`.

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
- **Azure DevOps:** add `~/.ssh/woolies.pub` under *User settings → SSH public keys*.

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

Neovim's IDE features live in [`config/nvim/lua/plugins/ide.lua`](config/nvim/lua/plugins/ide.lua),
and all tooling binaries are installed via Nix in
[`home/neovim.nix`](home/neovim.nix). **Mason is intentionally not used** —
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
     instead — see the `roslyn.nvim` block for the pattern.

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

## Common tasks

| Task                             | Command                                        |
| -------------------------------- | ---------------------------------------------- |
| Rebuild after editing config     | `rebuild`                                      |
| Update all inputs + rebuild      | `update`                                       |
| Roll back (WSL)                  | `sudo nixos-rebuild switch --rollback`         |
| Roll back (Ubuntu)               | `home-manager generations` then activate one   |
| Free old generations             | `sudo nix-collect-garbage -d` (`--delete-older-than 7d` for user profile on Ubuntu) |
| Format Nix files                 | `nix fmt` (add a formatter to the flake first) |

## Troubleshooting

### Corporate VPN breaks `localhost:3000` between Windows and WSL

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

**Durable fix — mirrored networking mode**

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

Reopen WSL and verify — the boot warning should be gone and
`curl http://127.0.0.1:3000` should return `200`. In mirrored mode `ip addr`
shows your Windows LAN IP rather than a `172.x` NAT address, and `autoProxy=true`
lets WSL pull the Windows proxy correctly when the VPN reconnects.

> If mirrored mode ever conflicts with the corporate VPN, delete `.wslconfig` and
> run `wsl --shutdown` to revert to NAT mode.

### Roslyn doesn't see newly created C# files

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

### Webpack / Vite dev server: `ENOSPC: System limit for number of file watchers reached`

**Symptoms**

Running a JS dev server (e.g. `npm run dev`) in this repo fails with:

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
- **WezTerm lives on Windows** because the terminal emulator is a host GUI app;
  only its target distro references WSL.
- **`stateVersion` is pinned to `26.05`.** Leave it as-is after first install; it
  is not the same as your package versions.
