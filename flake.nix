{
  description = "Daniel's dotfiles - one flake for NixOS (desktop/laptop) and WSL (standalone home-manager)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Determinate Nix on NixOS, so the Nix daemon behaves the same as the
    # Determinate installer used on WSL / other distros.
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, home-manager, determinate }:
    let
      system = "x86_64-linux";

      # Exposes bleeding-edge packages as pkgs.unstable.* (used for some CUDA libs).
      unstableOverlay = final: prev: {
        unstable = import nixpkgs-unstable {
          system = prev.stdenv.hostPlatform.system;
          config.allowUnfree = true;
        };
      };

      mkNixos = { hostModule, username }: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          { nixpkgs.overlays = [ unstableOverlay ]; }
          determinate.nixosModules.default
          hostModule
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${username} = import ./home/home.nix;
          }
        ];
      };
    in
    {
      # NixOS desktop with nvidia / cuda (hostname: internal-dev-daniel)
      nixosConfigurations.desktop = mkNixos {
        hostModule = ./hosts/desktop;
        username = "danielg";
      };

      # NixOS laptop - no GPU, so no nvidia/cuda module
      nixosConfigurations.laptop = mkNixos {
        hostModule = ./hosts/laptop;
        username = "danielg";
      };

      # WSL (Ubuntu + Determinate Nix) - home-manager only, no NixOS.
      # CUDA comes from the Windows driver on WSL, so nothing GPU-related here.
      homeConfigurations."dgleaves@wsl" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ unstableOverlay ];
        };
        modules = [
          ./home/home.nix
          {
            home.username = "dgleaves";
            home.homeDirectory = "/home/dgleaves";
          }
        ];
      };
    };
}
