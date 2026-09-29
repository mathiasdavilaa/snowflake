{ inputs, self, ... }: {
  flake.nixosModules.hyprland = { lib, pkgs, username, monitors, ... }:
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

        # Usa apenas Lua e impede a mistura com configurações Hyprlang.
        settings = lib.mkForce {};
        extraConfig = lib.mkForce ''
          -- Monitores definidos pelo host
          hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
          ${lib.concatMapStringsSep "\n" (m: ''
            hl.monitor({ output = ${builtins.toJSON m.name}, mode = "${toString m.width}x${toString m.height}@${toString m.refresh}", position = "${toString m.x}x${toString m.y}", scale = ${toString m.scale}, transform = ${toString m.transform} })
          '') monitors}

          -- Input, aparência do Mango/DMS e scrolling
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
              focus_fit_method = 1, -- Só ajusta a visão para mostrar a janela, sem centralizar.
              wrap_focus = false,
              wrap_swapcol = false,
              explicit_column_widths = "0.5,0.8,1.0",
            },
            binds = {
              window_direction_monitor_fallback = false,
              -- Permite buscar outras janelas mesmo com a atual em fullscreen.
              movefocus_cycles_fullscreen = true,
            },
            misc = { disable_hyprland_logo = true, force_default_wallpaper = -1 },
          })

          -- Deslizamento e curvas da configuração de exemplo do MangoWM.
          -- speed é duração em décimos de segundo: 4 = 400 ms; maior = mais lento.
          hl.curve("mango", { type = "bezier", points = { {0.46, 1}, {0.29, 1} } })
          hl.curve("mangoClose", { type = "bezier", points = { {0.08, 0.92}, {0, 1} } })
          hl.curve("mangoFade", { type = "bezier", points = { {0.5, 0.5}, {0.5, 0.5} } })

          -- Abertura: 400 ms; movimento: 500 ms; fechamento: 800 ms.
          hl.animation({ leaf = "global", enabled = true, speed = 4, bezier = "mango" })
          hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "mango" })
          hl.animation({ leaf = "windowsIn", enabled = true, speed = 4, bezier = "mango", style = "slide" })
          hl.animation({ leaf = "windowsOut", enabled = true, speed = 8, bezier = "mangoClose", style = "slide" })
          hl.animation({ leaf = "windowsMove", enabled = true, speed = 5, bezier = "mango" })

          -- Troca horizontal de workspaces em 350 ms, como as tags do Mango.
          for _, leaf in ipairs({ "workspaces", "workspacesIn", "workspacesOut" }) do
            hl.animation({ leaf = leaf, enabled = true, speed = 3.5, bezier = "mango", style = "slide" })
          end
          hl.animation({ leaf = "layers", enabled = true, speed = 4, bezier = "mango" })
          hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "mango", style = "slide" })
          hl.animation({ leaf = "layersOut", enabled = true, speed = 8, bezier = "mangoClose", style = "slide" })

          -- O fade acompanha o deslizamento, sem sumir antes de a janela sair.
          for _, leaf in ipairs({ "fade", "fadeIn", "fadeLayersIn" }) do
            hl.animation({ leaf = leaf, enabled = true, speed = 4, bezier = "mango" })
          end
          for _, leaf in ipairs({ "fadeOut", "fadeLayersOut" }) do
            hl.animation({ leaf = leaf, enabled = true, speed = 8, bezier = "mangoFade" })
          end
          hl.animation({ leaf = "border", enabled = true, speed = 3.5, bezier = "mango" })

          ${lib.concatMapStringsSep "\n" (m: ''
            hl.workspace_rule({ workspace = ${builtins.toJSON "m[${m.name}]"}, layout_opts = { direction = "${if m.transform == 1 then "down" else "right"}" } })
          '') monitors}

          -- Workspaces independentes: 1–9 em cada monitor
          package.path = package.path .. ";${inputs.split-monitor-workspaces}/lua/?.lua"
          local smw = require("split-monitor-workspaces")
          smw.setup({
            workspace_count = 9,
            monitor_priority = { ${lib.concatMapStringsSep ", " (m: builtins.toJSON m.name) monitors} },
            keep_focused = true,
            enable_persistent_workspaces = true,
            restore_workspaces_on_monitor_reconnect = true,
            link_monitors = false,
            enable_notifications = false,
          })

          -- Aplicativos e janelas: atalhos do Mango
          local terminal = "${lib.getExe pkgs.ghostty}"
          local shell = "${lib.getExe dms}"
          local function run(keys, command, flags)
            hl.bind(keys, hl.dsp.exec_cmd(command), flags or {})
          end

          run("SUPER + W", terminal)
          run("SUPER + Return", terminal)
          run("SUPER + E", terminal .. " --title=Yazi -e ${lib.getExe pkgs.yazi}")
          hl.bind("SUPER + Q", hl.dsp.window.close())
          hl.bind("SUPER + ALT + F4", hl.dsp.exit())
          hl.bind("SUPER + V", hl.dsp.window.float({ action = "toggle" }))

          -- Largura da janela: 100%, 50% ou 80% da coluna.
          hl.bind("SUPER + F", hl.dsp.layout("colresize 1.0"))
          hl.bind("SUPER + Prior", hl.dsp.layout("colresize 0.5"))
          hl.bind("SUPER + Next", hl.dsp.layout("colresize 0.8"))
          hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle", layout_aware = true }))
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

          -- DMS: shell, launcher, bloqueio, captura, áudio e brilho
          hl.on("hyprland.start", function() hl.exec_cmd(shell .. " run") end)
          ${ (self.lib.dmsBinds {
            inherit lib;
            session = "hyprland";
            executable = lib.getExe dms;
          }).hyprland }

          -- Jogos identificados pela Steam abrem em tela cheia.
          hl.window_rule({ name = "steam-games-fullscreen", match = { class = "^steam_app_[0-9]+$" }, fullscreen = true })

          hl.window_rule({ name = "dms-floating", match = { class = "^com.danklinux.dms$" }, float = true })
          hl.window_rule({ name = "ignore-maximize", match = { class = ".*" }, suppress_event = "maximize" })
        '';
      };
    };
}
