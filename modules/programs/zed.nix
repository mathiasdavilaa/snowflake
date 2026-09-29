{
  flake.nixosModules.zed = { username, profile, ... }: {
    # A instalação com as ferramentas fica a cargo do Home Manager.
    # Evita um segundo Zed sem extraPackages no perfil do sistema.
    home-manager.users.${username}._module.args.snowflakeProfile = profile;
  };
}
