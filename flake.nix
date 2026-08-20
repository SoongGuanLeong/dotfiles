{
  description = "Ubuntu Agentic Dev Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Environment variables the home configuration requires. The wrapper
      # scripts (bootstrap.sh/rebuild.sh) set these before calling nix.
      requiredEnvVars = [
        "DOTFILES_USERNAME"
        "DOTFILES_HOME"
        "DOTFILES_DIRECTORY"
      ];

      # builtins.getEnv returns "" for both unset and empty variables, so
      # an empty string is treated as missing.
      missingEnvVars = builtins.filter
        (name: builtins.getEnv name == "")
        requiredEnvVars;

      # Fail fast on direct evaluation instead of flowing an empty
      # username/homeDirectory into evaluation.
      requiredEnvVarsSet =
        missingEnvVars == []
        || builtins.abort
          ("missing required DOTFILES_* environment variable(s): "
            + builtins.concatStringsSep ", " missingEnvVars);
    in {
      packages.${system} = {
        home-manager = home-manager.packages.${system}.default;
      };

      # Environment contract consumed by scripts/lib.sh and check-security.sh.
      # Raw values (not derivations) — flake check does not validate non-standard outputs.
      envContract = {
        requiredEnvVars = requiredEnvVars;
        nixpkgsMinAgeDays = builtins.toString 14;
      };

      checks.${system}.registry = pkgs.runCommand "registry-check" { buildInputs = [ pkgs.jq ]; } ''
        cp ${./check-registry.sh} check-registry.sh
        cp ${./registry.json} registry.json
        cp ${./skip-list.json} skip-list.json
        cp -r ${./home} home
        chmod +x check-registry.sh
        ./check-registry.sh
        touch $out
      '';

      homeConfigurations.default = assert requiredEnvVarsSet;
        home-manager.lib.homeManagerConfiguration {
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
