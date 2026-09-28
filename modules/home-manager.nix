{ inputs, ... }: {
  # Configuração global do Home Manager (integrado como módulo do NixOS).
  # Os demais módulos só fazem `home-manager.users.${username} = { ... }`.
  flake.nixosModules.homeManager = { username, ... }: {
    imports = [ inputs.home-manager.nixosModules.home-manager ];

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "backup";

      users.${username}.home = {
        inherit username;
        homeDirectory = "/home/${username}";
        stateVersion = "26.05";
      };
    };
  };
}
