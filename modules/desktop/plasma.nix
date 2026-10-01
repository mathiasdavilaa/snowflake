{ ... }: {
  flake.nixosModules.plasma = {
    services.desktopManager.plasma6.enable = true;
    # SDDM fica em base.nix, compartilhado com a sessão Niri.
  };
}
