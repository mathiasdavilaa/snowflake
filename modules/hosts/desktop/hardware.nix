{ ... }: {
  flake.nixosModules.desktopHardware = { lib, modulesPath, ... }: {
    imports =
      [ (modulesPath + "/profiles/qemu-guest.nix")
    ];

    boot.initrd.availableKernelModules = [ "virtio_pci" "uhci_hcd" "ehci_pci" "ahci" "sr_mod" "virtio_blk" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-amd" ];
    boot.extraModulePackages = [ ];

    fileSystems."/" =
      { device = "/dev/disk/by-uuid/9ba8815b-fdf2-43a0-b170-286a102ff4ba";
        fsType = "ext4";
    };

    fileSystems."/boot" =
      { device = "/dev/disk/by-uuid/149A-F9B9";
        fsType = "vfat";
        options = [ "fmask=0077" "dmask=0077" ];
    };

    swapDevices =
      [ { device = "/dev/disk/by-uuid/b2d463c3-8f02-461b-9c65-cc10c2d85ce3"; }
    ];

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  };
}
