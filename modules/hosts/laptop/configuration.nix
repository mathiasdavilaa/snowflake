{ self, ... }: {
  flake.nixosModules.laptopConfiguration = { ... }: {
    imports = [
      self.nixosModules.common

      # Ainda não existe: crie modules/hosts/laptop/hardware.nix definindo
      # `flake.nixosModules.laptopHardware` (o `nixos-generate-config` do
      # laptop entra aí — mesmo formato de modules/hosts/desktop/hardware.nix).
      self.nixosModules.laptopHardware

      # Sessões gráficas e apps deste host (mesmas do desktop por enquanto;
      # tire o que não fizer sentido no laptop, ex.: pleamar/marea se não usar).
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

    # Troque pelo hostname real do laptop (usado pela função `nrs` em
    # features/cli/fish.nix para saber qual host reconstruir).
    networking.hostName = "laptop";
  };
}
