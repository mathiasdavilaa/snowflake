{ inputs, ... }: {
  flake.nixosModules.hyprland = { lib, pkgs, username, ... }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      hyprlandPackages = inputs.hyprland.packages.${system};
      hyprland = hyprlandPackages.hyprland.overrideAttrs (old: {
        cmakeFlags = builtins.filter
          (flag: !(lib.hasPrefix "-DNO_UWSM" flag))
          (old.cmakeFlags or []) ++ [ "-DNO_UWSM:BOOL=ON" ];
        passthru = (old.passthru or {}) // { providedSessions = [ "hyprland" ]; };
      });
      dms = inputs.dms.packages.${system}.default;
    in {
      programs.hyprland = {
        enable = true;
        package = hyprland;
        portalPackage = hyprlandPackages.xdg-desktop-portal-hyprland;
        withUWSM = false;
        xwayland.enable = true;
      };

      # Executáveis usados pelos binds e pela shell do Hyprland.
      environment.systemPackages = [ dms pkgs.ghostty pkgs.yazi ];
      security.pam.services.dms = {};

      home-manager.users.${username}.wayland.windowManager.hyprland = {
        enable = true;
        package = null;
        portalPackage = null;
        configType = "lua";
        systemd.enable = false; # A sessão atual do Hyprland gerencia seus targets.

        # Toda a configuração do Hyprland é Lua neste módulo.
        # Evita mesclar binds antigos em Hyprlang e duplicar SUPER+L.
        settings = lib.mkForce {};
        extraConfig = lib.mkForce ''
          ----------------------------------------------------------------------
          -- Monitores: mesma geometria do mangowm.nix
          ----------------------------------------------------------------------
          hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
          hl.monitor({ output = "HDMI-A-1", mode = "1920x1080", position = "0x0", scale = 1, transform = 1 })
          hl.monitor({ output = "DP-3", mode = "1920x1080@144", position = "1080x0", scale = 1, transform = 0 })
          hl.monitor({ output = "eDP-1", mode = "1920x1080", position = "0x0", scale = 1, transform = 0 })

          ----------------------------------------------------------------------
          -- Input, aparência do Mango/DMS e scrolling
          ----------------------------------------------------------------------
          hl.env("XCURSOR_SIZE", "24")
          hl.env("HYPRCURSOR_SIZE", "24")
          hl.config({
            input = {
              kb_layout = "us,br",
              kb_options = "caps:escape",
              repeat_rate = 30,
              repeat_delay = 400,
              follow_mouse = 0,
              sensitivity = 0,
              accel_profile = "flat",
            },
            general = {
              layout = "scrolling",
              gaps_in = 2, -- 2 de cada lado: vão interno de 4 px
              gaps_out = 4,
              border_size = 2,
              col = {
                active_border = "rgba(d0bcffff)",
                inactive_border = "rgba(948f99ff)",
              },
            },
            decoration = {
              rounding = 12,
              active_opacity = 1,
              inactive_opacity = 1,
            },
            scrolling = {
              direction = "right",
              column_width = 0.5,
              fullscreen_on_one_column = true,
              follow_focus = true,
              focus_fit_method = 1,
              wrap_focus = false,
              wrap_swapcol = false,
              explicit_column_widths = "0.5,0.8,1.0",
            },
            binds = { window_direction_monitor_fallback = false },
            misc = { disable_hyprland_logo = true, force_default_wallpaper = -1 },
          })

          -- O seletor acompanha o monitor, sem assumir IDs globais fixos.
          hl.workspace_rule({ workspace = "m[HDMI-A-1]", layout_opts = { direction = "down" } })
          hl.workspace_rule({ workspace = "m[DP-3]", layout_opts = { direction = "right" } })

          ----------------------------------------------------------------------
          -- Workspaces independentes: 1–9 em cada monitor
          ----------------------------------------------------------------------
          package.path = package.path .. ";${inputs.split-monitor-workspaces}/lua/?.lua"
          local smw = require("split-monitor-workspaces")
          smw.setup({
            workspace_count = 9,
            monitor_priority = { "HDMI-A-1", "DP-3", "eDP-1" },
            keep_focused = true,
            enable_persistent_workspaces = true,
            restore_workspaces_on_monitor_reconnect = true,
            link_monitors = false,
            enable_notifications = false,
          })

          ----------------------------------------------------------------------
          -- Aplicativos e janelas: atalhos do Mango
          ----------------------------------------------------------------------
          local terminal = "${lib.getExe pkgs.ghostty}"
          local shell = "${lib.getExe dms}"
          local function run(keys, command, flags)
            hl.bind(keys, hl.dsp.exec_cmd(command), flags or {})
          end

          run("SUPER + W", terminal)
          run("SUPER + Return", terminal) -- Mantém também o Enter que você pediu.
          run("SUPER + E", terminal .. " --title=Yazi -e ${lib.getExe pkgs.yazi}")
          hl.bind("SUPER + Q", hl.dsp.window.close())
          hl.bind("SUPER + ALT + F4", hl.dsp.exit())
          hl.bind("SUPER + V", hl.dsp.window.float({ action = "toggle" }))

          -- Igual ao set_proportion do Mango: 100%, 50% e 80% da coluna.
          hl.bind("SUPER + F", hl.dsp.layout("colresize 1.0"))
          hl.bind("SUPER + Prior", hl.dsp.layout("colresize 0.5"))
          hl.bind("SUPER + Next", hl.dsp.layout("colresize 0.8"))
          hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle", layout_aware = false }))
          hl.bind("SUPER + equal", hl.dsp.window.resize({ x = 150, y = 0, relative = true }), { repeating = true })
          hl.bind("SUPER + minus", hl.dsp.window.resize({ x = -150, y = 0, relative = true }), { repeating = true })

          -- HJKL e setas: foco; SHIFT: troca de posição, como exchange_client.
          for _, item in ipairs({
            { "H", "left" }, { "J", "down" }, { "K", "up" }, { "L", "right" },
            { "Left", "left" }, { "Down", "down" }, { "Up", "up" }, { "Right", "right" },
          }) do
            hl.bind("SUPER + " .. item[1], hl.dsp.focus({ direction = item[2] }))
            hl.bind("SUPER + SHIFT + " .. item[1], hl.dsp.window.swap({ direction = item[2] }))
          end

          -- Home: próximo monitor; SHIFT segue a janela; CTRL permanece aqui.
          hl.bind("SUPER + Home", hl.dsp.focus({ monitor = "+1" }))
          hl.bind("SUPER + SHIFT + Home", hl.dsp.window.move({ monitor = "+1", follow = true }))
          hl.bind("SUPER + CTRL + Home", hl.dsp.window.move({ monitor = "+1", follow = false }))

          for i = 1, 9 do
            local n = tostring(i)
            hl.bind("SUPER + " .. n, smw.workspace(n))
            hl.bind("SUPER + SHIFT + " .. n, smw.move_to_workspace(n))
            hl.bind("SUPER + CTRL + " .. n, smw.move_to_workspace_silent(n))
          end

          hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
          hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

          ----------------------------------------------------------------------
          -- DMS: shell, launcher, bloqueio, captura, áudio e brilho
          ----------------------------------------------------------------------
          hl.on("hyprland.start", function() hl.exec_cmd(shell .. " run") end)
          run("SUPER + D", shell .. " ipc call spotlight toggle")
          run("SUPER + Escape", shell .. " ipc call powermenu toggle")
          run("SUPER + F1", shell .. " ipc call keybinds toggle hyprland")
          run("SUPER + ALT + L", shell .. " ipc call lock lock")
          run("Print", shell .. " screenshot")
          run("XF86AudioRaiseVolume", shell .. " ipc call audio increment 3", { repeating = true, locked = true })
          run("XF86AudioLowerVolume", shell .. " ipc call audio decrement 3", { repeating = true, locked = true })
          run("XF86AudioMute", shell .. " ipc call audio mute", { locked = true })
          run("XF86MonBrightnessUp", shell .. " ipc call brightness increment 5", { repeating = true, locked = true })
          run("XF86MonBrightnessDown", shell .. " ipc call brightness decrement 5", { repeating = true, locked = true })

          hl.window_rule({ name = "dms-floating", match = { class = "^com.danklinux.dms$" }, float = true })
          hl.window_rule({ name = "ignore-maximize", match = { class = ".*" }, suppress_event = "maximize" })
        '';
      };
    };
}
