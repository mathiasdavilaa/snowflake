{ inputs, ... }: {
  # pleamar-wm: compositor próprio (sessão "pleamar-wm" no SDDM).
  # O módulo upstream já instala pleamar-wm + pleamar, habilita polkit,
  # XWayland, hardware.graphics e os portals (gtk + hyprland).
  flake.nixosModules.pleamar = { username, ... }: {
    imports = [ inputs.pleamar-wm.nixosModules.default ];

    programs.pleamar-wm = {
      enable = true;
      # A Marea é instalada/configurada em marea.nix.
      withMarea = false;
    };

    # ~/.config/pleamar/{session,keys}.conf são só do pleamar-wm.
    # Sem monitor/teclado aqui, ele herda de ~/.config/hypr (monitor, kb_layout…).
    home-manager.users.${username}.xdg.configFile = {
      "pleamar/session.conf".text = ''
        # pleamar-wm session — o que não estiver aqui vem da config do Hyprland.
        # monitor DP-3 1920x1080@165 at 0,0
        # monitor HDMI-A-1 preferred at 1920,0
      '';

      # `defaults` já traz os atalhos da Marea (Super+Space busca, Super+L lock, Print/Shift+Print/Ctrl+Print
      # screenshots). Só a gravação de tela não vem por padrão.
      "pleamar/keys.conf".text = ''
        defaults
        bind Super+Shift+c launch marea record_toggle
      '';
    };
  };
}
