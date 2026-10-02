{ self, ... }:  { imports = with self.nixosModules; [
    base
    plasma
    niri
    flatpak
    macro
    vm-curator
    nh
    roblox # Complemento opcional para Studio e Luau.
    ./hardware-configuration.nix
  ];

  networking.hostName = "nixos";

  # Dados compartilhados; cada compositor gera suas próprias regras.
  # transform: 0 = horizontal; 1 = vertical (90 graus).
  _module.args.monitors = [
    { name = "eDP-1"; width = 1920; height = 1200; refresh = 60; x = 0; y = 0; scale = 1; transform = 0; }
    { name = "HDMI-A-1"; width = 1920; height = 1080; refresh = 60; x = 1920; y = 0; scale = 1; transform = 0; }
  ];
}
