{ config, pkgs, ... }:

{
  home.username = "weeboppa";
  home.homeDirectory = "/home/weeboppa";

  home.stateVersion = "26.05";

  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    neovim
    git
    ripgrep
    fd
    fzf
    jq
    nodejs
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
  };

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
        source "${config.home.homeDirectory}/projects/dotfiles/home/.zshrc"
    '';
  };
}
