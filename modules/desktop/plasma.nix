{ ... }: {
  flake.nixosModules.plasma = { ... }: {
    # KDE Plasma is kept as a fallback/recovery desktop.
    # It does not replace Hyprland or Pleamar.
    services.desktopManager.plasma6.enable = true;

    # SDDM provides the graphical session selector, allowing you to
    # choose Plasma, Hyprland, or another installed Wayland session.
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
  };
}
