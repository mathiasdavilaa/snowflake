{
  flake.nixosModules.services = {
    services.xserver.enable = true;
    services.xserver.xkb.layout = "us";
    services.printing.enable = true;
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };
}
