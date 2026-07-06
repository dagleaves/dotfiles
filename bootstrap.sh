#!/usr/bin/env bash
# Takes a fresh machine to a fully applied config.
# Run once; after that use ./rebuild.sh for every change.
#
# Usage:
#   ./bootstrap.sh            # WSL / non-NixOS: standalone home-manager
#   ./bootstrap.sh desktop    # NixOS: build nixosConfigurations.desktop
#   ./bootstrap.sh laptop     # NixOS: build nixosConfigurations.laptop
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

echo "==> Step 1: Determinate Nix"
if command -v nix >/dev/null 2>&1; then
  echo "    nix already installed, skipping"
else
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
    | sh -s -- install --no-confirm
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

echo "==> Step 2: symlink this repo to ~/dotfiles"
# home.nix resolves its mkOutOfStoreSymlink paths through ~/dotfiles, so this
# has to exist before the first switch.
if [ "$DIR" != "$HOME/dotfiles" ]; then
  ln -sfn "$DIR" "$HOME/dotfiles"
fi

if [ -f /etc/NIXOS ]; then
  HOST="${1:-desktop}"
  echo "==> Step 3: nixos-rebuild switch (host: $HOST)"
  sudo nixos-rebuild switch --flake "$HOME/dotfiles#$HOST"
else
  echo "==> Step 3: first home-manager switch (WSL / non-NixOS)"
  # home-manager isn't installed yet, so run it straight from the flake this
  # once. After this, `home-manager` is on PATH and rebuild.sh works normally.
  # -b backup: back up existing dotfiles (e.g. an old ~/.zshrc) instead of
  # refusing to overwrite them; look for *.backup files afterwards.
  nix run github:nix-community/home-manager/release-26.05 -- \
    switch --flake "$HOME/dotfiles#dgleaves@wsl" -b backup
fi

echo "==> Done. Use ./rebuild.sh for future changes."
