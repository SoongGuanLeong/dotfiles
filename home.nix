{ config, pkgs, username, homeDirectory, dotfilesDirectory, ... }:

{
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
  ];

  home.file.".pi/agent/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink
    "${dotfilesDirectory}/home/.pi/agent/settings.json";

  home.file.".pi/agent/themes".source =
    config.lib.file.mkOutOfStoreSymlink
    "${dotfilesDirectory}/home/.pi/agent/themes";

  home.file.".pi/agent/extensions".source =
    config.lib.file.mkOutOfStoreSymlink
    "${dotfilesDirectory}/home/.pi/agent/extensions";

  home.file.".pi/agent/models.json".source =
    config.lib.file.mkOutOfStoreSymlink
    "${dotfilesDirectory}/home/.pi/agent/models.json";

  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink
    "${dotfilesDirectory}/home/.config/nvim";

  home.file.".config/herdr".source =
    config.lib.file.mkOutOfStoreSymlink
    "${dotfilesDirectory}/home/.config/herdr";

  home.file.".config/wezterm/wezterm.lua".source =
    config.lib.file.mkOutOfStoreSymlink
    "${dotfilesDirectory}/home/.config/wezterm/wezterm.lua";

  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink
    "${dotfilesDirectory}/home/AGENTS.md";

  home.file.".codex/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink
    "${dotfilesDirectory}/home/AGENTS.md";

  home.file.".config/opencode/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink
    "${dotfilesDirectory}/home/AGENTS.md";

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
        source "${dotfilesDirectory}/home/.zshrc"
    '';
  };
}
