{ ... }: {
  flake.nixosModules.fish = { pkgs, username, ... }: {
    programs.fish.enable = true;
    users.users.${username}.shell = pkgs.fish;

    home-manager.users.${username} = { config, lib, ... }: {
      programs.fish = {
        enable = true;
        interactiveShellInit = ''
          fastfetch
        '';
        functions.fish_greeting = "";
      };

      # Permite assumir a configuração ao trocar de ambiente.
      xdg.configFile = lib.mkIf config.programs.fish.enable {
        "fish/config.fish".force = true;
      };
      home.packages = lib.mkIf config.programs.fish.enable [ pkgs.fastfetch ];
    };
  };
}
