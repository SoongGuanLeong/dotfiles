{ config, pkgs, username, homeDirectory, dotfilesDirectory, ... }:

let
  symlinks = builtins.filter (s: s.target != "none") (builtins.fromJSON (builtins.readFile ./registry.json));

  toSymlink = { target, source }:
    {
      name = target;
      value = {
        source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDirectory}/${source}";
      };
    };

in {
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
  ];

  home.file = builtins.listToAttrs (map toSymlink symlinks);

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  programs.starship = {
    enable = true;

    settings = {
      add_newline = false;

      format = "$directory$git_branch$git_status$cmd_duration$line_break$character";

      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
      };

      cmd_duration.format = "[$duration]($style) ";
    };
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    initContent = ''
        source "${dotfilesDirectory}/home/.zshrc"
    '';
  };

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    icons = "auto";
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
}
