#!/usr/bin/env bash
# Re-apply the config after editing. NixOS hosts take an optional host name
# (desktop|laptop, default desktop); WSL needs no argument.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
if [ "$DIR" != "$HOME/dotfiles" ]; then
  ln -sfn "$DIR" "$HOME/dotfiles"
fi

if [ -f /etc/NIXOS ]; then
  HOST="${1:-desktop}"
  exec sudo nixos-rebuild switch --flake "$HOME/dotfiles#$HOST"
else
  home-manager switch --flake "$HOME/dotfiles#dgleaves@wsl"

  # On WSL the terminal runs on the Windows side and can't follow WSL
  # symlinks, so push the wezterm config to the Windows home directory.
  if command -v cmd.exe >/dev/null 2>&1; then
    WINHOME="$(wslpath "$(cd /mnt/c && cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')")"
    if [ -d "$WINHOME" ]; then
      cp "$DIR/home/wezterm.lua" "$WINHOME/.wezterm.lua"
      echo "wezterm config copied to $WINHOME/.wezterm.lua"
    fi
  fi
fi
