{ ... }: {
  flake.nixosModules.plasma = { ... }: {
    # Plasma oferece uma sessão alternativa aos compositores.
    services.desktopManager.plasma6.enable = true;

    # SDDM permite escolher a sessão gráfica na tela de login.
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
  };
}
