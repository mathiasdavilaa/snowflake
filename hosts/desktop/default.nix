{ self, ... }:  {
  imports = with self.nixosModules; [
    base
    graphics
    optimization
    plasma
    niri
    flatpak
    macro
    vm-curator
    nh
    roblox # Complemento opcional para Studio e Luau.
    ./hardware-configuration.nix
    ./ssd.nix
  ];

  networking.hostName = "tarnished";

  boot.loader.limine = {
    secureBoot = {
      enable = true;
      autoGenerateKeys = true;
      # Cadastrar manualmente na UEFI após conferir o estado com sbctl.
      autoEnrollKeys.enable = false;
    };
    # Usa a entrada UEFI existente e deixa o firmware iniciar o Windows.
    # Não depende de um hash do bootmgfw.efi após atualizações do Windows.
    extraEntries = ''
      /Windows
        protocol: efi_boot_entry
        entry: Windows Boot Manager
    '';
  };

  # Dados compartilhados; cada compositor gera suas próprias regras.
  # transform: 0 = horizontal; 1 = vertical (90 graus).
  _module.args.monitors = [
    { name = "HDMI-A-1"; width = 1920; height = 1080; refresh = 60; x = 0; y = 0; scale = 1; transform = 0; }
    { name = "DP-3"; width = 1920; height = 1080; refresh = 144; x = 1920; y = 0; scale = 1; transform = 0; }
  ];
}
