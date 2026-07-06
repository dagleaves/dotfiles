# PLACEHOLDER - replace with the real file from the laptop:
#
#   cp /etc/nixos/hardware-configuration.nix ~/dotfiles/hosts/laptop/hardware-configuration.nix
#   git -C ~/dotfiles add hosts/laptop/hardware-configuration.nix   # flakes only see tracked files
#
# The throw below makes the build fail loudly until you do.
throw ''
  hosts/laptop/hardware-configuration.nix is a placeholder.
  Copy the real one from /etc/nixos/hardware-configuration.nix on the laptop
  and `git add` it, then rebuild.
''
