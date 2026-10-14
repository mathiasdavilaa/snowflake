{ ... }: {
  flake.nixosModules.waylandBase = { config, lib, pkgs, username, ... }: {
    security.polkit.enable = true;
    security.pam.services.swaylock = { };
    services.upower.enable = true;
    services.power-profiles-daemon.enable = true;
    hardware.bluetooth.enable = true;
    services.blueman.enable = true;
    users.users.${username}.extraGroups = [
      "video"
      "i2c"
    ];

    environment.systemPackages = with pkgs; [
      fuzzel
      swaylock
      swaybg
      wl-clipboard
      grim
      slurp
      brightnessctl
      playerctl
      wireplumber
      polkit_gnome
    ];
    systemd.user.services.snowflake-polkit = lib.mkIf (!(config.programs.sanctuary.enable or false)) {
      description = "Polkit authentication agent";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
      };
    };
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };
  };
}
