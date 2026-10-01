{
  flake.nixosModules.boot = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.sbctl pkgs.efibootmgr ];

    boot.loader.systemd-boot.enable = false;
    boot.loader.limine = {
      enable = true;
      efiSupport = true;
      maxGenerations = 5;
    };
    boot.loader.efi.canTouchEfiVariables = true;
  };
}
