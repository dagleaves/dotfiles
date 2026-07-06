# PLACEHOLDER - replace with the real file from the desktop:
#
#   cp /etc/nixos/hardware-configuration.nix ~/dotfiles/hosts/desktop/hardware-configuration.nix
#   git -C ~/dotfiles add hosts/desktop/hardware-configuration.nix   # flakes only see tracked files
#
# The throw below makes the build fail loudly until you do.
throw ''
  hosts/desktop/hardware-configuration.nix is a placeholder.
  Copy the real one from /etc/nixos/hardware-configuration.nix on the desktop
  and `git add` it, then rebuild.
''
