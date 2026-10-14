{ ... }: {
  flake.nixosModules.vm-curator = { pkgs, username, ... }: {

    environment.systemPackages = with pkgs; [
      vm-curator
      qemu
      virt-viewer
      passt
      swtpm
    ];

    users.users.${username}.extraGroups = [
      "kvm"
      "render"
    ];
    hardware.graphics.enable = true;

    systemd.tmpfiles.rules = [
      "d /run/libvirt 0755 root root -"
      "d /run/libvirt/nix-ovmf 0755 root root -"
      "L+ /run/libvirt/nix-ovmf/OVMF_CODE.fd - - - - ${pkgs.OVMF.fd}/FV/OVMF_CODE.fd"
      "L+ /run/libvirt/nix-ovmf/OVMF_VARS.fd - - - - ${pkgs.OVMF.fd}/FV/OVMF_VARS.fd"
    ];

    home-manager.users.${username} = { config, lib, ... }: {

      home.activation.vmCuratorDirectory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${pkgs.coreutils}/bin/mkdir -p -- ${lib.escapeShellArg "${config.home.homeDirectory}/vm-space"}
      '';
    };
  };
}
