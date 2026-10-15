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
    graphics
    optimization
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
    ./ssd.nix
  ];

  networking.hostName = "tarnished";

  boot.loader.limine = {
    secureBoot = {
      enable = true;
      autoGenerateKeys = true;

      autoEnrollKeys.enable = false;
    };

    extraEntries = ''
      /Windows
        protocol: efi_boot_entry
        entry: Windows Boot Manager
    '';
  };

  _module.args.monitors = [
    {
      name = "HDMI-A-1";
      width = 1920;
      height = 1080;
      refresh = 60;
      x = 0;
      y = 0;
      scale = 1;
      transform = 0;
    }
    {
      name = "DP-3";
      width = 1920;
      height = 1080;
      refresh = 144;
      x = 1920;
      y = 0;
      scale = 1;
      transform = 0;
    }
  ];
}
