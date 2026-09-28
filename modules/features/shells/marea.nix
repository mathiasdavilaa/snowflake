{ inputs, ... }: {
  # Marea: shell/companheira escrita em pleamar. Funciona no pleamar-wm
  # (autostart) e em qualquer compositor com layer-shell (aqui: Hyprland).
  flake.nixosModules.marea = { pkgs, username, ... }:
    let
      wallpaper = pkgs.nixos-artwork.wallpapers.nineish.gnomeFilePath;
    in {
      environment.systemPackages = [
        inputs.marea.packages.${pkgs.stdenv.hostPlatform.system}.marea
      ];

      home-manager.users.${username} = {
        # Lido pelo pleamar-wm e por `pleamar --autostart` (Hyprland).
        # Linhas com `wm:` só rodam na sessão do pleamar-wm.
        # O comando certo é `marea start` (`marea` sozinho só mostra a ajuda).
        xdg.configFile."pleamar/autostart".text = ''
          # Papel de parede: o que a Marea salvou, senão o padrão abaixo.
          wm: swaybg -i "''${PLEAMAR_WALLPAPER:-${wallpaper}}" -m fill
          # A Marea, como programa da sessão (layer-shell).
          marea start
        '';

        # Atalhos da Marea no Hyprland (no pleamar-wm ficam em pleamar.nix, no keys.conf).
        wayland.windowManager.hyprland.settings.bind = [
          "SUPER, Space, exec, marea search"
          "SUPER, L, exec, marea lock"
          ", Print, exec, marea shot_region"
          "SHIFT, Print, exec, marea shot_screen"
          "CTRL, Print, exec, marea shot_window"
          "SUPER SHIFT, C, exec, marea record_toggle"
        ];

        # Atalhos da Marea no MangoWM. Sem os de screenshot (Print/Shift+Print/
        # Ctrl+Print): no MangoWM essa tecla já é do `dms screenshot` (dms.nix);
        # dá pra trocar depois se preferir a captura da Marea em vez da do DMS.
        wayland.windowManager.mango.settings.bind = [
          "SUPER,space,spawn,marea search"
          "SUPER,l,spawn,marea lock"
          "SUPER+SHIFT,c,spawn,marea record_toggle"
        ];
      };
    };
}
