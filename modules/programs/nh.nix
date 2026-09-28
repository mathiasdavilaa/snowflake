{ ... }: {
  # nh (nix-community/nh): CLI que substitui `nixos-rebuild`/`home-manager` por
  # comandos mais amigáveis (nh os switch, nh clean...), com diff de mudanças
  # e árvore de build. Ele NÃO formata arquivos .nix — quem cuida da formatação
  # do flake é o `formatter` do flake-parts, em modules/formatter.nix
  # (`nix fmt` roda o nixfmt-rfc-style sobre o repo inteiro).
  flake.nixosModules.nh = { username, ... }: {
    programs.nh = {
      enable = true;
      flake = "/home/${username}/snowflake";

      clean = {
        enable = true;
        dates = "weekly";
        extraArgs = "--keep 5 --keep-since 7d";
      };
    };
  };
}
