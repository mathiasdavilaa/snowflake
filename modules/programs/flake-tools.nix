{ ... }: {
  flake.nixosModules.flakeTools = { pkgs, profile, ... }: {
    # Comandos disponíveis em qualquer shell ou ambiente gráfico.
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "nrs" ''
        exec /run/wrappers/bin/sudo /run/current-system/sw/bin/nixos-rebuild \
          switch --flake "$HOME/snowflake#${profile}" "$@"
      '')
      (pkgs.writeShellScriptBin "nru" ''
        exec ${pkgs.nix}/bin/nix flake update --flake "$HOME/snowflake" "$@"
      '')
    ];
  };
}
