# Claude Code

## Global instructions (AGENTS.md), keybindings, model and status line setup

`config/agents/AGENTS.md` holds the global agent instructions. It is named
`AGENTS.md` because other harnesses read it too; Claude Code only reads
`~/.claude/CLAUDE.md`, so that path is a symlink to it. Likewise
`~/.claude/keybindings.json` is a symlink to `config/claude/keybindings.json`
(plain `tab` cycles permission modes; shift+tab still works). The `statusLine`,
`model`, `env.ANTHROPIC_MODEL` and `permissions.defaultMode` keys in
`~/.claude/settings.json` are merged in as well (other keys are left alone).
`model` is `opusplan`: Opus in plan mode, Sonnet in every other mode (always the
latest of each). Sessions start in plan mode (`permissions.defaultMode`), so one tab
reaches auto mode on Sonnet.
Saving a default via `/model` overwrites `model`, so `env.ANTHROPIC_MODEL` is also set
to `opusplan`. It outranks `model`, so `/model` only changes the current session and
new sessions start on `opusplan` again.
Caveat: once a session's context exceeds 200k tokens, `opusplan` stops upgrading plan
mode to Opus and plan mode stays on Sonnet (Opus has a 200k window). This is built in
and not configurable, and `opusplan[1m]` behaves the same. It shows up on resumed
sessions because they are usually large. Run `/compact` to get back under 200k and
plan mode returns to Opus.

| Setup | How it is applied |
|---|---|
| Windows (pure, or the Windows side of WSL) | `bash scripts/install-windows.sh` from Git Bash |
| WSL (inside NixOS) and Ubuntu | `home/agents.nix` via `rebuild` / home-manager switch |

- Edit `config/agents/AGENTS.md`; the link means no re-run is needed.
- Idempotent. An existing `CLAUDE.md` is moved to `CLAUDE.md.bak.<timestamp>`.
- Windows: symlinks need Developer Mode (Settings > System > For developers) or an admin shell.
- WSL has its own `~/.claude`, separate from the Windows one; each side is set up by its own tool.
- Other harnesses: add another link in `home/agents.nix` and `scripts/install-windows.sh`.

## Status bar

`scripts/status-bar.sh` renders the Claude Code status line:

```
Opus 5.5 │ ctx ▓▓▓░░░░░░░ 31% │ 5h 42% (resets 14:30) │ 7d 18% (resets Tue 09:00) │ spend 63% (resets Oct 01) │  master │ ~/Projects/dotfiles
```

| Segment | Source (JSON Claude Code sends on stdin) |
|---|---|
| Model | `model.display_name` |
| Context bar and % | `context_window.used_percentage` |
| Session (5-hour) usage and reset time | `rate_limits.five_hour.used_percentage` / `resets_at` |
| Weekly (7-day) usage and reset time | `rate_limits.seven_day.used_percentage` / `resets_at` |
| Spend limit usage and reset date | `rate_limits.spend_limit.used_percentage` / `resets_at` |
| Git branch (short SHA if detached) | `git branch --show-current` in the working dir |
| Directory (`~` shortened) | `workspace.current_dir` (falls back to `cwd`) |

Claude Code exposes no monthly window. `spend_limit` is the closest thing: it only
appears behind a Claude apps gateway that sets a spend limit, and its percentage can
exceed 100. Pro/Max accounts get `5h` and `7d` instead.

Segments with no data are hidden. For example, `rate_limits` only appears for
Claude.ai subscribers after the first API response, and the branch is hidden
outside a git repo.

## Requirements

- `bash` and `git`. No `jq` or `node` is needed.
  - Windows: Git for Windows provides Git Bash. Claude Code runs status line
    commands through it.
  - Linux and macOS: works as-is.
- A Nerd Font for the branch glyph. WezTerm's bundled `Symbols Nerd Font Mono` fallback
  in `config/wezterm/wezterm.lua` covers this.

## Customising

- Accent colour: change `COLOR` at the top of the script
  (`blue`, `orange`, `teal`, `green`, `lavender`, `rose`, `gold`, `slate`, `cyan`, `gray`).
- Reorder or remove segments by editing the `segments+=` blocks.

## Testing without Claude

```bash
echo '{"model":{"display_name":"Opus 5.5"},"workspace":{"current_dir":"C:/dev/dotfiles"},"context_window":{"used_percentage":31},"rate_limits":{"five_hour":{"used_percentage":42,"resets_at":1790000000},"seven_day":{"used_percentage":18,"resets_at":1790300000},"spend_limit":{"used_percentage":63,"resets_at":1791000000}}}' \
  | bash config/claude/scripts/status-bar.sh
```
