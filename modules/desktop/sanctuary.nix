{ inputs, ... }: {
  flake.nixosModules.sanctuary = { lib, username, ... }: {
    imports = [ inputs.sanctuary.nixosModules.sanctuary ];
    programs.sanctuary.enable = true;

    home-manager.users.${username} = {
      imports = [ inputs.sanctuary.homeManagerModules.sanctuary ];
      programs.sanctuary = {
        enable = true;
        # Each compositor starts its own instance in the active session.
        autostart = false;
        settings.hoverScale = 1.20;
      };
      home.sessionVariables.TERMINAL = lib.mkDefault "ghostty";
      xdg.configFile."xdg-terminals.list".text = lib.mkDefault ''
        com.mitchellh.ghostty.desktop
      '';
    };
  };
}
