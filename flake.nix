{
  description = "NixOS on WSL2 dev environment (WezTerm + Neovim + VSCode)";

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
    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, nixos-wsl, home-manager, vscode-server, ... }@inputs:
    let
      system = "x86_64-linux";
      # Default user for the WSL distro. Change here if you want a different login.
      username = "joe";
    in
    {
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
            home-manager.extraSpecialArgs = { inherit username; };
            home-manager.users.${username} = import ./home/home.nix;
          }
        ];
      };
    };
}
