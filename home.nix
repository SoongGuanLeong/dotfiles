{ config, pkgs, username, homeDirectory, dotfilesDirectory, ... }:

let
  symlinks = builtins.filter
    (s: s.target != "none")
    (builtins.fromJSON (builtins.readFile ./registry.json));

  toSymlink = { target, source }: {
    name = target;
    value = {
      source = config.lib.file.mkOutOfStoreSymlink
        "${dotfilesDirectory}/${source}";
    };
  };
in
{
  imports = [
    ./modules/shell.nix
    ./modules/screenshot-cleanup.nix
  ];

  home.username = username;
  home.homeDirectory = homeDirectory;
  home.stateVersion = "26.05";

  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    neovim
    git
    ripgrep
    fd
    fzf
    jq
    lazygit
    bat
    uv
    wezterm
  ];

  home.file = builtins.listToAttrs (map toSymlink symlinks);

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  home.sessionPath = [
    "$HOME/.local/bin"
  ];
}