{
  flake.nixosModules.optimization = { pkgs, username, ... }: {

    programs.steam = {
      enable = true;
      extraPackages = [ pkgs.mangohud ];
    };

    programs.gamemode = {
      enable = true;
      settings.general = {
        desiredgov = "performance";
        renice = 10;
      };
    };
    users.users.${username}.extraGroups = [ "gamemode" ];

    environment.systemPackages = [ pkgs.mangohud ];

    services.fstrim.enable = true;
  };
}
