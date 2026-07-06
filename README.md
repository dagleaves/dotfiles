# dotfiles

One flake for every machine: the NixOS desktop (nvidia/cuda ML box), a
future NixOS laptop (no GPU), and WSL (Ubuntu + Determinate Nix,
home-manager only). One repo, one command, and each machine ends up
configured the same way every time.

## Layout

- `flake.nix` — entry point. Declares three targets:
  - `nixosConfigurations.desktop` — NixOS + Plasma + nvidia/cuda (`internal-dev-daniel`)
  - `nixosConfigurations.laptop` — NixOS + Plasma, no GPU
  - `homeConfigurations."dgleaves@wsl"` — standalone home-manager for WSL
- `modules/common.nix` — system config shared by all NixOS hosts (locale, docker, tailscale, zsh as default shell, nix-ld, …)
- `modules/desktop.nix` — GUI-only config (Plasma, pipewire, printing, GUI apps)
- `modules/nvidia.nix` — nvidia drivers + CUDA toolchain (desktop only; WSL uses the Windows driver, laptop has no GPU)
- `hosts/desktop/`, `hosts/laptop/` — per-machine config + `hardware-configuration.nix`
- `home/home.nix` — user config shared everywhere: packages, git, zsh (oh-my-zsh + powerlevel10k + fzf-tab), tmux (rose-pine), neovim
- `home/p10k.zsh` — the real powerlevel10k config; `~/.p10k.zsh` is a symlink into this repo, so `p10k configure` edits it in place
- `home/wezterm.lua` — WezTerm config (rose-pine moon, Hack Nerd Font). `~/.wezterm.lua` symlinks into the repo; on WSL `rebuild.sh` additionally copies it to `C:\Users\<user>\.wezterm.lua`, since Windows WezTerm can't follow WSL symlinks
- `home/claude/` — Claude Code `settings.json` and `statusline-command.sh`; `~/.claude/settings.json` and `~/.claude/statusline-command.sh` symlink into the repo, so changes made through Claude Code land here too
- `bootstrap.sh` — first-time setup on a fresh machine
- `rebuild.sh` — re-apply after any edit

## Fresh-machine setup

```sh
git clone <this-repo> ~/dotfiles
cd ~/dotfiles
```

**WSL / Ubuntu:**

```sh
./bootstrap.sh
```

Installs Determinate Nix if missing, then runs the first
`home-manager switch`. Existing conflicting files (old `~/.zshrc`, …) are
saved as `*.backup`. Afterwards `home-manager` is on PATH and `./rebuild.sh`
is the daily driver.

**NixOS (desktop or laptop):**

1. Copy the machine's hardware scan into the repo (flakes only see tracked files):

   ```sh
   cp /etc/nixos/hardware-configuration.nix ~/dotfiles/hosts/desktop/hardware-configuration.nix
   git -C ~/dotfiles add hosts/desktop/hardware-configuration.nix
   ```

2. ```sh
   ./bootstrap.sh desktop   # or: ./bootstrap.sh laptop
   ```

This also switches the machine onto Determinate Nix via the
`determinate` NixOS module, so Nix behaves identically to WSL.

### Validate without applying

```sh
# WSL / home-manager config
nix build ~/dotfiles#homeConfigurations.'"dgleaves@wsl"'.activationPackage --dry-run

# NixOS hosts (works once the real hardware-configuration.nix is in place)
nix eval ~/dotfiles#nixosConfigurations.desktop.config.system.build.toplevel.drvPath
```

`nix flake check` evaluates *every* host, so it fails with the placeholder
message until both `hardware-configuration.nix` files are real.

## Daily use

Edit the config files, then:

```sh
./rebuild.sh            # WSL: home-manager switch
./rebuild.sh desktop    # NixOS desktop
./rebuild.sh laptop     # NixOS laptop
```

The `update` shell alias runs the same script.

## What's managed where

| Concern | Where |
|---|---|
| GUI apps (chrome, vlc, bruno, beekeeper, kate, wezterm) | `modules/desktop.nix` (NixOS only) |
| CUDA / nvidia drivers | `modules/nvidia.nix` (desktop only) |
| CLI tools (uv, node, bun, gh, lazygit, ripgrep, nmap, ffmpeg, claude-code, …) | `home/home.nix` (everywhere) |
| zsh: oh-my-zsh (git, docker, z), powerlevel10k, fzf-tab, autosuggestions, aliases | `home/home.nix` (everywhere) |
| tmux: C-a prefix, vi copy-mode, rose-pine moon, vim-aware pane nav | `home/home.nix` (everywhere) |
| git identity + aliases | `home/home.nix` (everywhere) |
| wezterm config | `home/wezterm.lua` (symlinked on Linux, copied to Windows by `rebuild.sh` on WSL) |
| Claude Code settings + statusline | `home/claude/` (symlinked everywhere) |

oh-my-zsh, powerlevel10k, fzf-tab, and the tmux plugins all come from
nixpkgs now — no more git-cloning into `~/.oh-my-zsh` or TPM. The generated
`~/.zshrc` and `~/.config/tmux/tmux.conf` are read-only store symlinks;
change them by editing `home/home.nix` and rebuilding.

## Migration notes

- Replaces the old `~/.dotfiles` repo (zsh/tmux/git) and the desktop's
  `/etc/nixos/configuration.nix`. The old `~/.zshrc`, `~/.tmux.conf`, and
  `~/.gitconfig` symlinks into `~/.dotfiles` are superseded on first switch.
- The system's `nix.channel`-based unstable overlay became the
  `nixpkgs-unstable` flake input (`pkgs.unstable.*`), currently used for
  `libcublas`.
- `zsh-patina` isn't in nixpkgs; it comes from its own flake input
  (`github:michel-kraemer/zsh-patina`) and is installed via `home.packages`,
  then activated in the generated `.zshrc`.
