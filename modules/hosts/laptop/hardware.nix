{ ... }: {
  # Cole aqui dentro o conteúdo do hardware-configuration.nix gerado pelo
  # `nixos-generate-config` no laptop de verdade (geralmente fica em
  # /etc/nixos/hardware-configuration.nix). A assinatura da função de dentro
  # (config, lib, pkgs, modulesPath, ...) pode vir exatamente como o
  # instalador gerou — só troque os dois `{ ... }: { ... };` de fora por
  # `flake.nixosModules.laptopHardware = <a função original>;`, como abaixo.
  flake.nixosModules.laptopHardware = { config, lib, pkgs, modulesPath, ... }: {
    imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

    boot.initrd.availableKernelModules = [ ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ ];
    boot.extraModulePackages = [ ];

    fileSystems."/" = {
      device = "/dev/disk/by-uuid/TROQUE-PELO-UUID-REAL";
      fsType = "ext4";
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/TROQUE-PELO-UUID-REAL";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

    swapDevices = [
      # { device = "/dev/disk/by-uuid/TROQUE-PELO-UUID-REAL"; }
    ];

    networking.useDHCP = lib.mkDefault true;

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  };
}
