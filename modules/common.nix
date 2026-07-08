# System config shared by every NixOS machine (desktop, laptop).
{ config, pkgs, ... }:

{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nixpkgs.config.allowUnfree = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
  };

  time.timeZone = "America/New_York";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  users.users.danielg = {
    isNormalUser = true;
    description = "Daniel Gleaves";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "dialout"
    ];
  };

  # Shell itself is enabled system-wide; all zsh configuration (oh-my-zsh,
  # powerlevel10k, aliases) lives in home/home.nix.
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  virtualisation.docker.enable = true;

  # Pin container DNS to Tailscale MagicDNS. Without this, containers
  # snapshot /etc/resolv.conf at start; on boot Docker races tailscaled and
  # can capture the pre-Tailscale fallback resolvers, breaking tailnet
  # hostname resolution until the container is restarted.
  virtualisation.docker.daemon.settings = {
    dns = [
      "100.100.100.100"
      "1.1.1.1" # fallback so container DNS survives tailscaled being down
    ];
    dns-search = [ "tail0922b0.ts.net" ];
  };

  # Lets non-nix binaries (e.g. pythons downloaded by uv) find their libraries.
  programs.nix-ld.enable = true;
  environment.localBinInPath = true;

  # Fix uv python ssl.SSLCertVerificationError
  environment.etc.certfile = {
    source = "/etc/ssl/certs/ca-bundle.crt";
    target = "ssl/cert.pem";
  };

  environment.systemPackages = with pkgs; [
    home-manager
    nix-index
    vim
    git
    glibc
  ];

  networking.firewall.enable = false;
}
