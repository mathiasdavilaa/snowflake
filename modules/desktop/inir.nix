{ inputs, ... }: {
  flake.nixosModules.inir = { config, pkgs, ... }: {
    imports = [ inputs.inir.nixosModules.inir ];

    programs.inir = {
      enable = true;
      # O pacote upstream inclui Hyprland opcionalmente; esta instalação usa Niri.
      package = pkgs.callPackage (inputs.inir + "/nix/package.nix") {
        pkgs = builtins.removeAttrs pkgs [ "hyprland" ];
      };
      # O serviço pertence exclusivamente à sessão Niri.
      service.compositor = "niri";
      extraPackages = [ config.programs.niri.package ];
    };

    security.pam.services.quickshell = {};
    services.upower.enable = true;
  };
}
