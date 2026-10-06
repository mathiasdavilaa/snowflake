{ ... }: {
  flake.nixosModules.ghostty = { username, ... }: {
    home-manager.users.${username} = {
      programs.ghostty = {
        enable = true;
        settings = {
          confirm-close-surface = false;
          theme = "dankcolors";
          font-family = "GeistMono Nerd Font";
        };
      };
    };
  };
}
