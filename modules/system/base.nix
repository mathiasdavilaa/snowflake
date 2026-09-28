{ self, ... }:
{
  flake.nixosModules.base = { username, ... }: {
    imports = with self.nixosModules; [
      homeManager boot networking services hardware packages
      fish ghostty git fastfetch
    ];

    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    nix.optimise.automatic = true;
    time.timeZone = "America/Sao_Paulo";
    i18n.defaultLocale = "en_US.UTF-8";
    i18n.extraLocaleSettings = builtins.listToAttrs (map
      (name: { inherit name; value = "pt_BR.UTF-8"; })
      [ "LC_ADDRESS" "LC_IDENTIFICATION" "LC_MEASUREMENT" "LC_MONETARY"
        "LC_NAME" "LC_NUMERIC" "LC_PAPER" "LC_TELEPHONE" "LC_TIME" ]);

    users.users.${username} = {
      isNormalUser = true;
      extraGroups = [ "networkmanager" "wheel" ];
    };
    system.stateVersion = "26.05";
  };
}
