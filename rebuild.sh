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
  exec home-manager switch --flake "$HOME/dotfiles#dgleaves@wsl"
fi
