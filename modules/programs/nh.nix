{ ... }: {
  # nh simplifica rebuilds e mostra as diferenças entre gerações.
  # A formatação com nix fmt é definida separadamente em parts/systems.nix.
  flake.nixosModules.nh = { username, ... }: {
    programs.nh = {
      enable = true;
      flake = "/home/${username}/snowflake";

      # Limpeza semanal: preserva 5 gerações e as dos últimos 7 dias.
      clean = {
        enable = true;
        dates = "weekly";
        extraArgs = "--keep 5 --keep-since 7d";
      };
    };
  };
}
