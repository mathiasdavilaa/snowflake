{ self, ... }: {
  flake.nixosModules.desktopConfiguration = { ... }: {
    imports = [
      self.nixosModules.common
      self.nixosModules.desktopHardware
      self.nixosModules.graphics

      # Sessões gráficas e apps deste host
      self.nixosModules.hyprland
      self.nixosModules.mangowm
      self.nixosModules.plasma
      self.nixosModules.pleamar
      self.nixosModules.marea
      self.nixosModules.dms
      self.nixosModules.flatpak
      self.nixosModules.macro
      self.nixosModules.nh
      self.nixosModules.zed
    ];

    networking.hostName = "tarnished";
  };
}
