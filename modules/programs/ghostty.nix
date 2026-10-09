{ ... }: {
  flake.nixosModules.ghostty = { username, ... }: {
    home-manager.users.${username} = { config, lib, ... }: {
      programs.ghostty = {
        enable = true;
        settings.confirm-close-surface = false;
      };

      xdg.configFile = lib.mkIf config.programs.ghostty.enable {
        "ghostty/config".force = true;
      };
    };
  };
}
