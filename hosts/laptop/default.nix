{ self, ... }: {
  imports = with self.nixosModules; [
    base
    fish
    ghostty
    terminalTools
    git
    fastfetch
    zed
    macro
    howdy
    niri
    hyprland
    mango
    pleamar
    sanctuary
    flatpak
    vm-curator
    nh
    roblox
    ./hardware-configuration.nix
  ];

  networking.hostName = "nixos";

  _module.args.monitors = [
    {
      name = "eDP-1";
      width = 1920;
      height = 1200;
      refresh = 60;
      x = 0;
      y = 0;
      scale = 1;
      transform = 0;
    }
    {
      name = "HDMI-A-1";
      width = 1920;
      height = 1080;
      refresh = 60;
      x = 1920;
      y = 0;
      scale = 1;
      transform = 0;
    }
  ];
}
