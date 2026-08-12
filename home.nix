{ config, pkgs, username, homeDirectory, dotfilesDirectory, ... }:

let
  # Single mapping list for symlinked files: target path on the left-hand
  # side, source path relative to the dotfiles directory on the right.
  #
  # Fan-out: home/AGENTS.md is symlinked to two coding-tool instruction
  # targets (.claude/CLAUDE.md and .codex/AGENTS.md) deliberately, so it is
  # listed here twice with the same source.
  symlinks = [
    { target = ".pi/agent/settings.json"; source = "home/.pi/agent/settings.json"; }
    { target = ".pi/agent/themes"; source = "home/.pi/agent/themes"; }
    { target = ".pi/agent/extensions"; source = "home/.pi/agent/extensions"; }
    { target = ".config/nvim"; source = "home/.config/nvim"; }
    { target = ".config/herdr"; source = "home/.config/herdr"; }
    { target = ".config/wezterm/wezterm.lua"; source = "home/.config/wezterm/wezterm.lua"; }
    { target = ".claude/CLAUDE.md"; source = "home/AGENTS.md"; }
    { target = ".codex/AGENTS.md"; source = "home/AGENTS.md"; }
  ];

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
