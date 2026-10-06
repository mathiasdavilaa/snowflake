{ ... }: {
  flake.nixosModules.dms = { lib, pkgs, username, ... }: {
    # Módulo nativo do nixpkgs já fixado em flake.lock (DMS 1.6.2).
    programs.dms-shell = {
      enable = true;
      systemd = {
        enable = true;
        target = "niri.service";
        restartIfChanged = true;
      };
    };

    # A sessão Niri é a única responsável por iniciar e parar a shell.
    systemd.user.services.dms = {
      wantedBy = lib.mkForce [ "niri.service" ];
      partOf = [ "niri.service" ];
      after = [ "niri.service" ];
      unitConfig.Requisite = "niri.service";
    };

    # Autenticação do bloqueio e serviços utilizados pelos widgets do DMS.
    security.pam.services.dankshell = {};
    security.polkit.enable = true;
    services.upower.enable = true;
    services.power-profiles-daemon.enable = true;
    hardware.bluetooth.enable = true;
    services.blueman.enable = true;
    users.users.${username}.extraGroups = [ "video" "i2c" ];

    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gnome pkgs.xdg-desktop-portal-gtk ];
      config.niri.default = [ "gnome" "gtk" ];
    };
  };
}
