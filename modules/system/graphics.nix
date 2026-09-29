{
  flake.nixosModules.graphics = {
    # RTX 2060 12 GB do desktop físico; este módulo não é importado pelo laptop.
    hardware.graphics = {
      enable = true;
      enable32Bit = true; # Steam/Proton e jogos de 32 bits.
    };

    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.nvidia = {
      modesetting.enable = true;
      open = true; # RTX 2060 (Turing) aceita o módulo aberto da NVIDIA.
    };
  };
}
