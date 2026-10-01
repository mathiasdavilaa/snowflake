{ inputs, ... }:
let
  community = inputs.inir-nixos;
  upstream = community.inputs.inir;
in {
  flake.nixosModules.inir = { config, pkgs, lib, username, ... }:
    let
      # Mesmos patches do projeto comunitário, sem trazer o compositor Hyprland.
      shellPackage = (pkgs.callPackage (upstream + "/nix/package.nix") {
        pkgs = builtins.removeAttrs pkgs [ "hyprland" ];
      }).overrideAttrs (old: {
        patches = (old.patches or []) ++ [
          (community + "/modules/patches/inir-icon-theme.patch")
          (community + "/modules/patches/inir-nixos-fixes.patch")
          ./patches/inir-launcher-env.patch
        ];
      });
      # O sincronizador da comunidade grava só um fragmento de cores, nunca
      # substitui o config.kdl gerenciado pelo Home Manager.
      colorSync = pkgs.writeShellScript "niri-sync-colors" (
        lib.replaceStrings
          [ "NIRI_CONFIG_FILE=\"$HOME/.config/niri/config.kdl\""
            "niri_config_py=\"$(find_niri_config_py)\"" ]
          [ "NIRI_CONFIG_FILE=\"$HOME/.config/niri/colors.kdl\""
            "niri_config_py=\"\"" ]
          (builtins.readFile (community + "/scripts/niri-sync-colors"))
      );
    in {
      imports = [
        ({ config, pkgs, lib, ... }: import (community + "/modules/inir.nix") {
          inherit config pkgs lib;
          inir = upstream;
        })
        ({ config, pkgs, lib, ... }: import (community + "/modules/mascot.nix") {
          inherit config pkgs lib;
          inir = upstream;
        })
        (community + "/modules/fonts.nix")
      ];

      # Não importar desktop.nix (GDM/greetd) nem runtime.nix, que define
      # LD_LIBRARY_PATH/QT_PLUGIN_PATH globais e um parâmetro de kernel Intel.
      # O wrapper do pacote fornece os módulos Qt sem afetar o Plasma.
      programs.inir = {
        package = shellPackage;
        service.compositor = "niri";
        extraPackages = [ config.programs.niri.package ];
      };
      security.pam.services.quickshell = {};
      systemd.user.services.niri-sync-colors = {
        description = "Cores iNiR/Niri (integração LATAR-web)";
        wantedBy = [ "niri.service" ];
        partOf = [ "niri.service" ];
        after = [ "inir.service" ];
        path = with pkgs; [ bash coreutils python3 inotify-tools util-linux glib gnugrep config.programs.niri.package ];
        serviceConfig = {
          ExecStart = "${colorSync} --watch";
          Restart = "on-failure";
          RestartSec = 5;
        };
      };
      home-manager.users.${username} = { config, lib, ... }:
        let
          colors = pkgs.writeText "niri-colors.kdl" ''
            layout {
              focus-ring {
                active-color "#d0bcff"
                inactive-color "#948f99"
              }
            }
          '';
        in {
          home.activation.inirColors = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            if [ ! -e ${lib.escapeShellArg "${config.home.homeDirectory}/.config/niri/colors.kdl"} ]; then
              run ${pkgs.coreutils}/bin/install -Dm644 ${colors} ${lib.escapeShellArg "${config.home.homeDirectory}/.config/niri/colors.kdl"}
            fi
          '';
        };
      users.users.${username}.extraGroups = [ "video" "i2c" ];

      # Agente comunitário só no Niri; o Plasma inicia seu próprio agente.
      systemd.user.services.polkit-kde-authentication-agent-1 = {
        wantedBy = lib.mkForce [ "niri.service" ];
        wants = lib.mkForce [];
        after = lib.mkForce [ "niri.service" ];
        partOf = [ "niri.service" ];
        unitConfig.Requisite = "niri.service";
      };

      # O serviço comunitário deve enxergar os plugins adicionais sem contaminar
      # processos Qt do restante da sessão (especialmente Plasma).
      systemd.user.services.inir.environment = {
        QT_PLUGIN_PATH = lib.makeSearchPath "lib/qt-6/plugins" [
          pkgs.kdePackages.qtmultimedia pkgs.kdePackages.qt5compat
          pkgs.kdePackages.plasma-integration pkgs.darkly
        ];
      };
    };
}
