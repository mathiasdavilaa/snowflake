{ inputs, ... }:
{
  # O módulo upstream instala a sessão; esta extensão local oferece extraConfig.
  flake.nixosModules.pleamar = { config, lib, pkgs, ... }:
    let
      cfg = config.programs.pleamar-wm;
      wallpaper = pkgs.nixos-artwork.wallpapers.nineish.gnomeFilePath;
    in
    {
      imports = [ inputs.pleamar-wm.nixosModules.default ];

      options.programs.pleamar-wm.extraConfig = lib.mkOption {
        type = lib.types.attrsOf lib.types.lines;
        default = { };
        description = "Arquivos declarativos em /etc/pleamar, usados pela sessão via PLEAMAR_CONFIG.";
      };

      config = {
        programs.pleamar-wm = {
          enable = true;
          withMarea = false;
          extraConfig = {
            "session.conf" = ''
              # Configuração de monitores e dispositivos pode ser adicionada por host.
            '';
            "keys.conf" = ''
              defaults
              bind Super+Shift+c launch marea record_toggle
            '';
            autostart = ''
              wm: swaybg -i "''${PLEAMAR_WALLPAPER:-${wallpaper}}" -m fill
              marea start
            '';
          };
        };

        environment.systemPackages = [
          inputs.marea.packages.${pkgs.stdenv.hostPlatform.system}.marea
          pkgs.swaybg
        ];
        environment.etc = lib.mapAttrs' (name: text:
          lib.nameValuePair "pleamar/${name}" { inherit text; }
        ) cfg.extraConfig;
        environment.sessionVariables.PLEAMAR_CONFIG = "/etc/pleamar";
      };
    };
}
