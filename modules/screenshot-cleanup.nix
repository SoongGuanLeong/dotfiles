{ pkgs, ... }:

{
  systemd.user.services.screenshot-cleanup = {
    Unit = {
      Description = "Clean up old GNOME screenshots";
    };

    Service = {
      Type = "oneshot";

      ExecStart =
        "${pkgs.findutils}/bin/find %h/Pictures/Screenshots " +
        "-maxdepth 1 " +
        "-type f " +
        "-name 'Screenshot From *.png' " +
        "-mtime +7 " +
        "-print " +
        "-delete";
    };
  };

  systemd.user.timers.screenshot-cleanup = {
    Unit = {
      Description = "Weekly GNOME screenshot cleanup";
    };

    Timer = {
      OnCalendar = "weekly";
      Persistent = true;
    };

    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
}