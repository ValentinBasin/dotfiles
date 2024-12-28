{
  description = "Example Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    # home-manager.url = "github:nix-community/home-manager";
    # home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, darwin, nixpkgs, nix-homebrew, ... }: {
    darwinConfigurations."Valentins-MacBook-Pro" = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        ./configuration.nix
        # home-manager.darwinModules.home-manager
        # {
        #   home-manager.useGlobalPkgs = true;
        #   home-manager.useUserPackages = true;
        #   home-manager.users.basin = import ./home.nix;
        # }
      ];
    };
    darwinPackages = self.darwinConfigurations."Valentins-MacBook-Pro".pkgs;
  };
}
