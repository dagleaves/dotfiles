# NixOS laptop: GUI but no GPU, so no nvidia/cuda module.
{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/desktop.nix
  ];

  networking.hostName = "daniel-laptop";

  # Set to the NixOS release the laptop is first installed with, then never change.
  system.stateVersion = "26.05";
}
