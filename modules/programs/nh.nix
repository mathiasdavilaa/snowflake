{ ... }: {

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
