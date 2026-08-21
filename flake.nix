{
  description = "Cross-platform dev environment (NixOS-WSL + native Ubuntu) - WezTerm + Neovim + VSCode";

  inputs = {
    # Pinned to the latest stable NixOS release.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Makes VSCode Remote-WSL server run correctly on NixOS.
    # Note: this flake has no `nixpkgs` input, so there's nothing to `follows`.
    vscode-server.url = "github:nix-community/nixos-vscode-server";
  };

  outputs =
    { self, nixpkgs, nixos-wsl, home-manager, vscode-server, ... }@inputs:
    let
      system = "x86_64-linux";
      # Default user. Change here if you want a different login.
      username = "joe";
    in
    {
      # --- NixOS-WSL: manages the whole OS ---
      nixosConfigurations.wsl = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs username; };
        modules = [
          nixos-wsl.nixosModules.default
          vscode-server.nixosModules.default
          ./hosts/wsl/configuration.nix

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {
              inherit username;
              platform = "wsl";
            };
            home-manager.users.${username} = import ./home/home.nix;
          }
        ];
      };

      # --- Native Ubuntu: standalone home-manager, manages the user profile only ---
      # Apply with: home-manager switch --flake ~/dotfiles#joe@ubuntu
      homeConfigurations."${username}@ubuntu" =
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          extraSpecialArgs = {
            inherit username;
            platform = "ubuntu";
          };
          modules = [ ./home/ubuntu.nix ];
        };
    };
}
