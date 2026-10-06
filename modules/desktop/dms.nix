{ ... }: {
  flake.nixosModules.dms = { inputs, lib, pkgs, username, ... }: {
    # Módulo nativo com o pacote da branch stable oficial do DMS.
    programs.dms-shell = {
      enable = true;
      package = inputs.dms.packages.${pkgs.stdenv.hostPlatform.system}.default;
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
