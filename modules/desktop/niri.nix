{ ... }: {
  # Sessão Niri independente, disponível como alternativa nos hosts.
  flake.nixosModules.niri =
    {
      pkgs,
      lib,
      username,
      monitors,
      ...
    }:
    {
      programs.niri.enable = true;
      services.displayManager.defaultSession = lib.mkDefault "niri";
      security.polkit.enable = true;
      security.pam.services.swaylock = { };

      environment.systemPackages = with pkgs; [
        fuzzel
        swaylock
        swaybg
        yazi
        wl-clipboard
        xwayland-satellite
      ];
      xdg.portal = {
        enable = true;
        extraPortals = [
          pkgs.xdg-desktop-portal-gnome
          pkgs.xdg-desktop-portal-gtk
        ];
        config.niri.default = [
          "gnome"
          "gtk"
        ];
      };

      home-manager.users.${username}.xdg.configFile."niri/config.kdl" = {
        # O arquivo pertence a esta sessão, inclusive após uma troca de ambiente.
        force = true;
        text = ''
          ${lib.concatMapStringsSep "\n" (m: ''
            output ${builtins.toJSON m.name} {
              mode "${toString m.width}x${toString m.height}@${toString m.refresh}"
              scale ${toString m.scale}
              transform "${
                builtins.elemAt [
                  "normal"
                  "90"
                  "180"
                  "270"
                  "flipped"
                  "flipped-90"
                  "flipped-180"
                  "flipped-270"
                ] m.transform
              }"
              position x=${toString m.x} y=${toString m.y}
            }
          '') monitors}

          input {
            keyboard {
              xkb {
                layout "us,br"
                options "caps:escape"
              }
              repeat-delay 400
              repeat-rate 30
            }
            mouse { accel-profile "flat"; }
            touchpad { tap; natural-scroll; dwt; }
          }

          spawn-at-startup "swaybg" "-c" "#1e1e2e"
          screenshot-path "~/Pictures/Screenshots/%Y-%m-%d_%H-%M-%S.png"

          binds {
            Super+Return { spawn "ghostty"; }
            Super+E { spawn "ghostty" "--title=Yazi" "-e" "yazi"; }
            Super+D { spawn "fuzzel"; }
            Super+L { spawn "swaylock" "-f" "-c" "1e1e2e"; }
            Super+Q { close-window; }
            Super+F1 { show-hotkey-overlay; }
            Super+grave repeat=false { toggle-overview; }
            Super+Left { focus-column-left; }
            Super+Right { focus-column-right; }
            Super+Up { focus-window-up; }
            Super+Down { focus-window-down; }
            Super+Shift+Left { move-column-left; }
            Super+Shift+Right { move-column-right; }
            Super+Shift+Up { move-window-up; }
            Super+Shift+Down { move-window-down; }
            Super+Page_Up { focus-workspace-up; }
            Super+Page_Down { focus-workspace-down; }
            Super+Shift+Page_Up { move-column-to-workspace-up; }
            Super+Shift+Page_Down { move-column-to-workspace-down; }
            Super+F { maximize-column; }
            Super+Shift+F { fullscreen-window; }
            Super+C { center-column; }
            Super+V { toggle-window-floating; }
            Super+R { switch-preset-column-width; }
            Super+Shift+E { quit; }
            Print { screenshot; }
            Ctrl+Print { screenshot-screen; }
            Alt+Print { screenshot-window; }
            XF86AudioRaiseVolume allow-when-locked=true { spawn "wpctl" "set-volume" "-l" "1" "@DEFAULT_AUDIO_SINK@" "5%+"; }
            XF86AudioLowerVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"; }
            XF86AudioMute allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
            XF86AudioMicMute allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"; }
            XF86AudioPlay { spawn "playerctl" "play-pause"; }
            XF86AudioNext { spawn "playerctl" "next"; }
            XF86AudioPrev { spawn "playerctl" "previous"; }
            XF86MonBrightnessUp allow-when-locked=true { spawn "brightnessctl" "set" "+10%"; }
            XF86MonBrightnessDown allow-when-locked=true { spawn "brightnessctl" "set" "10%-"; }
          }
        '';
      };
    };
}
