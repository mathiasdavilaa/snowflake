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

      # O upstream do Pleamar inclui o portal Hyprland de nixpkgs. Quando
      # Hyprland usa outro input, duas derivações fornecem a mesma unit.
      # Normaliza a lista final, sem remover GTK/KDE/wlr/Pleamar.
      options.xdg.portal.extraPortals = lib.mkOption {
        apply = portals: lib.unique (map (portal:
          if config.programs.hyprland.enable
            && lib.getName portal == "xdg-desktop-portal-hyprland"
          then config.programs.hyprland.portalPackage
          else portal
        ) portals);
      };

      config = {
        programs.pleamar-wm = {
          enable = true;
          withMarea = false;
          extraConfig = {
            "session.conf" = ''
              # Monitores são acrescentados em hosts/<host>/default.nix.
              keyboard layout us,br options caps:escape repeat 30 delay 400
              pointer accel flat speed 0
            '';
            "keys.conf" = ''
              defaults

              # Terminal e gerenciador de arquivos.
              bind Super+Return launch ${lib.getExe pkgs.ghostty}
              bind Super+t launch ${lib.getExe pkgs.ghostty}
              bind Super+e launch ${lib.getExe pkgs.ghostty} --title=Yazi -e ${lib.getExe pkgs.yazi}

              # Fullscreen no mesmo atalho do Mango.
              unbind Super+f
              bind Super+Shift+f fullscreen

              # A cena padrão navega por ordem, não por geometria da janela.
              bind Super+h focus_previous
              bind Super+k focus_previous
              bind Super+j focus_next
              bind Super+l focus_next
              bind Super+Alt+l launch marea lock

              # Mesmas ações das setas padrão; não equivalem integralmente
              # ao exchange_client do Mango (left/right também podem mudar monitor).
              bind Super+Shift+h move_left
              bind Super+Shift+l move_right
              bind Super+Shift+k move_up
              bind Super+Shift+j move_down

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
          pkgs.ghostty
          pkgs.yazi
        ];
        environment.etc = lib.mapAttrs' (name: text:
          lib.nameValuePair "pleamar/${name}" { inherit text; }
        ) cfg.extraConfig;
        environment.sessionVariables.PLEAMAR_CONFIG = "/etc/pleamar";
      };
    };
}
