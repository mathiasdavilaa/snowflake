{ ... }: {
  flake.nixosModules.hyprland = { lib, username, ... }: {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    home-manager.users.${username} = {
      wayland.windowManager.hyprland = {
        enable = true;

        # Hyprland/portal já vêm do módulo NixOS (programs.hyprland): o HM só gera a config.
        package = null;
        portalPackage = null;

        # Com home.stateVersion >= 26.05 o padrão passa a ser "lua"; este arquivo é hyprlang.
        configType = "hyprlang";

        settings = {
          # ------------------
          # ---- MONITORS ----
          # ------------------
          monitor = [
            ",preferred,auto,auto"
          ];

          # ---------------------
          # ---- MY PROGRAMS ----
          # ---------------------
          "$terminal" = "kitty";
          "$fileManager" = "dolphin";
          "$menu" = "hyprlauncher";
          "$mainMod" = "SUPER";

          # -------------------------------
          # ---- ENVIRONMENT VARIABLES ----
          # -------------------------------
          env = [
            "XCURSOR_SIZE,24"
            "HYPRCURSOR_SIZE,24"
          ];

          # -----------------------
          # ---- LOOK AND FEEL ----
          # -----------------------
          general = {
            gaps_in = 5;
            gaps_out = 20;
            border_size = 2;
            "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
            "col.inactive_border" = "rgba(595959aa)";
            resize_on_border = false;
            allow_tearing = false;
            layout = "dwindle";
          };

          decoration = {
            rounding = 10;
            rounding_power = 2.0;
            active_opacity = 1.0;
            inactive_opacity = 1.0;

            shadow = {
              enabled = true;
              range = 4;
              render_power = 3;
              color = "0xee1a1a1a";
            };

            blur = {
              enabled = true;
              size = 3;
              passes = 1;
              vibrancy = 0.1696;
            };
          };

          animations = {
            enabled = true;

            bezier = [
              "easeOutQuint, 0.23, 1, 0.32, 1"
              "easeInOutCubic, 0.65, 0.05, 0.36, 1"
              "linear, 0, 0, 1, 1"
              "almostLinear, 0.5, 0.5, 0.75, 1"
              "quick, 0.15, 0, 0.1, 1"
            ];

            # Definição de springs como extra / parâmetros
            animation = [
              "global, 1, 10, default"
              "border, 1, 5.39, easeOutQuint"
              "windows, 1, 4.79, default"
              "windowsIn, 1, 4.1, default, popin 87%"
              "windowsOut, 1, 1.49, linear, popin 87%"
              "fadeIn, 1, 1.73, almostLinear"
              "fadeOut, 1, 1.46, almostLinear"
              "fade, 1, 3.03, quick"
              "layers, 1, 3.81, easeOutQuint"
              "layersIn, 1, 4, easeOutQuint, fade"
              "layersOut, 1, 1.5, linear, fade"
              "fadeLayersIn, 1, 1.79, almostLinear"
              "fadeLayersOut, 1, 1.39, almostLinear"
              "workspaces, 1, 1.94, almostLinear, fade"
              "workspacesIn, 1, 1.21, almostLinear, fade"
              "workspacesOut, 1, 1.94, almostLinear, fade"
              "zoomFactor, 1, 7, quick"
            ];
          };

          dwindle = {
            preserve_split = true;
          };

          master = {
            new_status = "master";
          };

          scrolling = {
            fullscreen_on_one_column = true;
          };

          misc = {
            force_default_wallpaper = -1;
            disable_hyprland_logo = false;
          };

          input = {
            kb_layout = "us";
            follow_mouse = 1;
            sensitivity = 0;
            touchpad = {
              natural_scroll = false;
            };
          };

          # Antigo `gestures:workspace_swipe` foi removido; agora é `gesture = dedos, direção, ação`.
          gesture = [
            "3, horizontal, workspace"
          ];

          device = [
            {
              name = "epic-mouse-v1";
              sensitivity = -0.5;
            }
          ];

          # ---------------------
          # ---- KEYBINDINGS ----
          # ---------------------
          exec-once = [
            "pleamar --autostart"
          ];

          bind = [
            "$mainMod, Q, exec, $terminal"
            "$mainMod, C, killactive,"
            "$mainMod, M, exec, command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit"
            "$mainMod, E, exec, $fileManager"
            "$mainMod, V, togglefloating,"
            "$mainMod, R, exec, $menu"
            "$mainMod, P, pseudo,"
            "$mainMod, J, togglesplit,"
            "$mainMod, F6, exec, ~/.local/bin/macro"

            # Foco
            "$mainMod, left, movefocus, l"
            "$mainMod, right, movefocus, r"
            "$mainMod, up, movefocus, u"
            "$mainMod, down, movefocus, d"

            # Special workspace
            "$mainMod, S, togglespecialworkspace, magic"
            "$mainMod SHIFT, S, movetoworkspace, special:magic"

            # Rato workspaces
            "$mainMod, mouse_down, workspace, e+1"
            "$mainMod, mouse_up, workspace, e-1"
          ]
          # Workspaces 1 a 9 (dispatchers nativos; `split-*` exigiam um plugin que não está instalado)
          ++ (map (i: "$mainMod, ${toString i}, workspace, ${toString i}") (lib.range 1 9))
          ++ (map (i: "$mainMod SHIFT, ${toString i}, movetoworkspace, ${toString i}") (lib.range 1 9));

          binde = [
            # Teclas multimédia com repetição
            ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
            ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
            ", XF86MonBrightnessUp, exec, brightnessctl -e4 -n2 set 5%+"
            ", XF86MonBrightnessDown, exec, brightnessctl -e4 -n2 set 5%-"
          ];

          bindl = [
            # Teclas multimédia com ecrã bloqueado
            ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
            ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
            ", XF86AudioNext, exec, playerctl next"
            ", XF86AudioPause, exec, playerctl play-pause"
            ", XF86AudioPlay, exec, playerctl play-pause"
            ", XF86AudioPrev, exec, playerctl previous"
          ];

          bindm = [
            # Mouse drag/resize
            "$mainMod, mouse:272, movewindow"
            "$mainMod, mouse:273, resizewindow"
          ];

          # --------------------------------
          # ---- WINDOWS AND WORKSPACES ----
          # --------------------------------
          # `windowrulev2` agora gera erro no Hyprland 0.56; sintaxe nova: `windowrule = match:<prop> <regex>, <efeito> <valor>`.
          windowrule = [
            "match:class .*, suppress_event maximize"
            "match:class ^$, match:title ^$, match:xwayland 1, match:float 1, match:fullscreen 0, match:pin 0, no_focus on"
            "match:class ^(hyprland-run)$, float on, move 20 monitor_h-120"
          ];
        };
      };
    };
  };
}
