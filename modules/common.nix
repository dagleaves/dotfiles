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
      "kvm"
    ];
  };

  # Shell itself is enabled system-wide; all zsh configuration (oh-my-zsh,
  # powerlevel10k, aliases) lives in home/home.nix.
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  virtualisation.docker.enable = true;
  virtualisation.kvmgt.enable = true;

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

  # Antivirus: clamd daemon, freshclam signature updates, and a weekly
  # clamdscan of the module's default directories (/home, /var/lib, /tmp,
  # /etc, /var/tmp). Weekly rather than the daily default because the root
  # disk holds hundreds of GB of ML data and the scan uses up to 10 cores.
  # Results: journalctl -u clamdscan; the unit exits non-zero on a hit.
  services.clamav = {
    daemon.enable = true;
    updater.enable = true;
    scanner = {
      enable = true;
      interval = "Sun *-*-* 04:00:00";
    };
  };

  # Firewall on. Default policy drops inbound except loopback, established
  # connections and ICMP. Docker-published ports (-p) bypass this chain via
  # DNAT/FORWARD, so they are neither protected nor affected by it.
  networking.firewall = {
    enable = true;
    # Tailnet peers reach host-network services (go2rtc, dev servers); access
    # is governed by Tailscale ACLs.
    trustedInterfaces = [ "tailscale0" ];
    # Containers reach host services via host.docker.internal / the bridge
    # gateway, so accept from docker0 and every compose bridge (br-*). The
    # trailing "+" is iptables' prefix wildcard. This keeps container->host
    # traffic working while still blocking the LAN.
    extraCommands = ''
      ip46tables -A nixos-fw -i docker0 -j nixos-fw-accept
      ip46tables -A nixos-fw -i br-+ -j nixos-fw-accept
    '';
  };
}
