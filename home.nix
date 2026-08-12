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
    chromium
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

    shellAliases = {
      g = "git";
      ga = "git add";
      gb = "git branch";
      gc = "git commit";
      gco = "git checkout";
      gd = "git diff";
      gf = "git fetch";
      gl = "git pull";
      gp = "git push";
      gst = "git status";
    };

    initContent = ''
      # Optional: Node.js via NVM.
      export NVM_DIR="$HOME/.nvm"
      if [[ -s "$NVM_DIR/nvm.sh" ]]; then
        . "$NVM_DIR/nvm.sh"
        [[ -s "$NVM_DIR/bash_completion" ]] && . "$NVM_DIR/bash_completion"
      fi

      export BROWSER=wslview

      # Optional: Java/Scala via SDKMAN.
      export SDKMAN_DIR="$HOME/.sdkman"
      if [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
        source "$SDKMAN_DIR/bin/sdkman-init.sh"
      fi
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
