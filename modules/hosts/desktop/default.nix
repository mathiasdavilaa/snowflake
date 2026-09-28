{ self, inputs, ... }: {
  flake.nixosConfigurations.desktop = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = {
      username = "mad";
      profile = "desktop";
    };
    modules = [
      self.nixosModules.desktopConfiguration
    ];
  };
}
