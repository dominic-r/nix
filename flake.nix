{
  description = "Unified Nix configuration for Mac and servers";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    authentik-platform = {
      url = "github:goauthentik/platform/sdko/nix-pkg";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, disko, authentik-platform, claude-code, rust-overlay, nur, ... }:
    let
      # Helper to create baremetal NixOS server configurations
      # Note: docker-based servers are in infra/cluster/
      mkServer = { name, system ? "x86_64-linux", diskDevice ? "/dev/sda", modules ? [] }: nixpkgs.lib.nixosSystem {
        modules = [
          { nixpkgs.hostPlatform = system; }
          disko.nixosModules.disko
          (import ./modules/disk-lvm.nix { device = diskDevice; })
          ./modules/common.nix
          ./hosts/${name}/configuration.nix
        ] ++ modules;
      };
    in {
      # macOS configuration
      darwinConfigurations.dominic = nix-darwin.lib.darwinSystem {
        modules = [
          { nixpkgs.hostPlatform = "aarch64-darwin"; }
          ./hosts/darwin/configuration.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.dominic = import ./home;
          }
          authentik-platform.darwinModules.default
          {
            nixpkgs.overlays = [
              authentik-platform.overlays.default
              claude-code.overlays.default
              rust-overlay.overlays.default
              nur.overlays.default
            ];
            services.authentik.enable = true;
          }
        ];
      };

      # NixOS server configurations
      nixosConfigurations = {
        cgit = mkServer { name = "cgit"; };
        timemachine = mkServer { name = "timemachine"; };

        # myserver = mkServer { name = "myserver"; };
        # myserver-arm = mkServer { name = "myserver"; system = "aarch64-linux"; };
      };

      # Formatters
      formatter = {
        aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixpkgs-fmt;
        x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
      };
    };
}
