# NixOS desktop: nvidia/cuda ML box, KDE Plasma, hostname internal-dev-daniel.
{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/desktop.nix
    ../../modules/nvidia.nix
  ];

  networking.hostName = "internal-dev-daniel";

  # This machine runs long ML jobs - never let it sleep.
  systemd.sleep.settings.Sleep = {
    AllowSuspend = "no";
    AllowHibernation = "no";
    AllowHybridSleep = "no";
    AllowSuspendThenHibernate = "no";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data were taken. Leave it at the release this
  # machine was first installed with.
  system.stateVersion = "25.05";
}
