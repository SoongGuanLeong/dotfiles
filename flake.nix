{
  description = "WSL2 Agentic Dev Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      homeConfigurations.default = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        extraSpecialArgs = {
          username = builtins.getEnv "DOTFILES_USERNAME";
          homeDirectory = builtins.getEnv "DOTFILES_HOME";
          dotfilesDirectory = builtins.getEnv "DOTFILES_DIRECTORY";
        };

        modules = [ ./home.nix ];
      };
    };
}
