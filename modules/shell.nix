{ ... }:

{
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
      dothelp = "cat $HOME/projects/dotfiles/docs/commands.md";
    };

    initContent = ''
      # Optional: Node.js via NVM.
      export NVM_DIR="$HOME/.nvm"
      if [[ -s "$NVM_DIR/nvm.sh" ]]; then
        . "$NVM_DIR/nvm.sh"
        [[ -s "$NVM_DIR/bash_completion" ]] && . "$NVM_DIR/bash_completion"
      fi

      # Optional: Java/Scala via SDKMAN.
      export SDKMAN_DIR="$HOME/.sdkman"
      if [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
        source "$SDKMAN_DIR/bin/sdkman-init.sh"
      fi

      sched() {
        case "''${1:-}" in
          all)
            printf '%s\n' '=== System timers ==='
            systemctl list-timers --all

            printf '\n%s\n' '=== User timers ==='
            systemctl --user list-timers --all

            printf '\n%s\n' '=== User cron ==='
            crontab -l 2>/dev/null || echo "No user crontab"
            ;;

          *)
            printf '%s\n' '=== Dotfiles timers ==='
            systemctl --user list-timers screenshot-cleanup.timer --all

            printf '\n%s\n' '=== User cron ==='
            crontab -l 2>/dev/null || echo "No user crontab"

            printf '\n%s\n' 'Use "sched all" to show everything.'
            ;;
        esac
      }
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