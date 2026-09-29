{
  flake.nixosModules.optimization = { pkgs, username, ... }: {
    # Steam instala o ambiente de execução, bibliotecas de 32 bits e suporte
    # a controles. A escolha de Proton por jogo continua na própria Steam.
    programs.steam = {
      enable = true;
      extraPackages = [ pkgs.mangohud ];
    };

    # Só muda o governador e a prioridade enquanto um jogo solicita GameMode.
    programs.gamemode = {
      enable = true;
      settings.general = {
        desiredgov = "performance";
        renice = 10;
      };
    };
    users.users.${username}.extraGroups = [ "gamemode" ];

    # Ferramenta de medição opt-in: mangohud gamemoderun %command%
    environment.systemPackages = [ pkgs.mangohud ];

    # Manutenção periódica dos SSDs; não altera as opções de montagem.
    services.fstrim.enable = true;
  };
}
