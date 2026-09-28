{ self, inputs, ... }: {
  flake.nixosConfigurations.laptop = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = {
      username = "mad";
      profile = "laptop";
    };
    modules = [
      self.nixosModules.laptopConfiguration
    ];
  };
}
