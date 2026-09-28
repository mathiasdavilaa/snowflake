{ ... }: {
  flake.nixosModules.ghostty = { username, ... }: {
    home-manager.users.${username} = {
      programs.ghostty = {
        enable = true;
        settings = {
          # Personalização será feita depois.
        };
      };
    };
  };
}
