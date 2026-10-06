{ ... }: {
  flake.nixosModules.fish = { pkgs, username, ... }: {
    programs.fish.enable = true;

    # Sem isso o terminal abre bash e aliases/fastfetch do fish nunca aparecem.
    users.users.${username}.shell = pkgs.fish;

    home-manager.users.${username} = {
      programs.fish = {
        enable = true;
        interactiveShellInit = ''
          fastfetch
        '';
        shellAliases = {
          nru = "nix flake update --flake ~/snowflake";
        };
        functions = {
          fish_greeting = ""; # Oculta a mensagem de boas-vindas.
          nrs = {
            description = "Rebuild the current NixOS host";
            body = ''
              set host (hostnamectl --static 2>/dev/null)
              switch $host
                case tarnished desktop
                  cd ~/snowflake && sudo nixos-rebuild switch --flake ~/snowflake#desktop
                case laptop nixos
                  cd ~/snowflake && sudo nixos-rebuild switch --flake ~/snowflake#laptop
                case '*'
                  echo "nixos profile not found: $host"
                  return 1
              end
            '';
          };
        };
      };
    };
  };
}
