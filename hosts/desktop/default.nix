# NixOS desktop: nvidia/cuda ML box, KDE Plasma, hostname internal-dev-daniel.
{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/desktop.nix
    ../../modules/nvidia.nix
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  networking.hostName = "internal-dev-daniel";

  # Secure Boot: lanzaboote replaces systemd-boot and signs UKIs with the
  # sbctl keys ("sbctl create-keys" must be run once before switching).
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
    configurationLimit = 8; # UKIs are large; keep the 1 GB ESP from filling
  };
  environment.systemPackages = [ pkgs.sbctl ];

  # systemd-based initrd - required for TPM2 LUKS unlock
  boot.initrd.systemd.enable = true;

  # Root disk is LUKS2-encrypted in place (nvme0n1p3). PARTUUID survives the
  # encryption, so fileSystems."/" keeps its ext4 UUID unchanged.
  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-partuuid/0dccb69a-3574-4981-b554-48ca9c061539";
    allowDiscards = true; # SSD TRIM through dm-crypt
    crypttabExtraOpts = [ "tpm2-device=auto" ]; # falls back to passphrase until enrolled
  };

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
