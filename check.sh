#!/usr/bin/env bash
# Evaluate every target without building or applying it. This is what CI runs
# on PRs and before opening the weekly flake.lock PR; run it locally to catch
# eval errors (typos, removed packages, broken inputs) before a rebuild.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

targets=(
  'nixosConfigurations.desktop.config.system.build.toplevel'
  'homeConfigurations."dgleaves@wsl".activationPackage'
)

# The laptop only evaluates once its real hardware-configuration.nix is in place.
if ! grep -q PLACEHOLDER "$DIR/hosts/laptop/hardware-configuration.nix"; then
  targets+=('nixosConfigurations.laptop.config.system.build.toplevel')
else
  echo "skip: nixosConfigurations.laptop (hardware-configuration.nix is a placeholder)"
fi

for target in "${targets[@]}"; do
  echo "check: $target"
  nix build --dry-run "$DIR#$target"
done
