{
  self,
  ...
}:
{
  imports = with self.nixosModules; [
    base
    graphics
    optimization
    plasma
    niri
    flatpak
    macro
    nh
    roblox # Complemento opcional para Studio e Luau.
    ./hardware-configuration.nix
    ./ssd.nix
  ];

  networking.hostName = "tarnished";

  # Dados compartilhados; cada compositor gera suas próprias regras.
  # transform: 0 = horizontal; 1 = vertical (90 graus).
  _module.args.monitors = [
    {
      name = "HDMI-A-1";
      width = 1920;
      height = 1080;
      refresh = 60;
      x = 0;
      y = 0;
      scale = 1;
      transform = 1;
    }
    {
      name = "DP-3";
      width = 1920;
      height = 1080;
      refresh = 144;
      x = 1080;
      y = 0;
      scale = 1;
      transform = 0;
    }
  ];

}
