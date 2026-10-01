{ ... }: {
  flake.nixosModules.vm-curator = { pkgs, username, ... }: {
    # VM Curator usa QEMU diretamente; não precisa de libvirtd/virt-manager.
    environment.systemPackages = with pkgs; [
      vm-curator
      qemu          # Inclui qemu-img, GTK, SDL, SPICE e virgl.
      virt-viewer   # remote-viewer, usado pelo backend spice-app.
      passt         # Backend de rede sem bridge privilegiada.
      swtpm         # TPM virtual quando solicitado pela configuração da VM.
    ];

    # kvm-amd/kvm-intel já são declarados no hardware de cada host.
    users.users.${username}.extraGroups = [ "kvm" "render" ];
    hardware.graphics.enable = true;

    # Caminhos NixOS detectados pelo VM Curator 1.4.0. Só firmware:
    # nenhum daemon libvirt é ativado. CODE e VARS pertencem ao mesmo OVMF.
    # O aplicativo copia VARS para a pasta da VM antes de executá-la.
    systemd.tmpfiles.rules = [
      "d /run/libvirt 0755 root root -"
      "d /run/libvirt/nix-ovmf 0755 root root -"
      "L+ /run/libvirt/nix-ovmf/OVMF_CODE.fd - - - - ${pkgs.OVMF.fd}/FV/OVMF_CODE.fd"
      "L+ /run/libvirt/nix-ovmf/OVMF_VARS.fd - - - - ${pkgs.OVMF.fd}/FV/OVMF_VARS.fd"
    ];

    home-manager.users.${username} = { config, lib, ... }: {
      # Cria a biblioteca padrão sem substituir configurações ou discos existentes.
      home.activation.vmCuratorDirectory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${pkgs.coreutils}/bin/mkdir -p -- ${lib.escapeShellArg "${config.home.homeDirectory}/vm-space"}
      '';
    };
  };
}
