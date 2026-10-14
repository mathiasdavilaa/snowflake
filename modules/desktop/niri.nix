{ self, ... }: {
  flake.nixosModules.niri =
    {
      config,
      lib,
      pkgs,
      username,
      monitors,
      ...
    }:
    let
      shellEnabled = config.programs.sanctuary.enable or false;
      shellCommand = if shellEnabled then lib.getExe config.programs.sanctuary.package else "";
      command = args: fallback: if shellEnabled then lib.concatStringsSep " " (map builtins.toJSON ([ shellCommand ] ++ args)) else fallback;
    in {
      imports = [ self.nixosModules.waylandBase ];
      services.displayManager.defaultSession = lib.mkDefault "niri";
      xdg.portal = {
        extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
        config.niri.default = [
          "gnome"
          "gtk"
        ];
      };

      nixpkgs.overlays = [
        (final: prev: {
          xwayland-satellite =
            if lib.versionOlder prev.xwayland-satellite.version "0.8.3" then
              prev.xwayland-satellite.overrideAttrs (
                finalAttrs: _: {
                  version = "0.8.3";
                  src = final.fetchFromGitHub {
                    owner = "Supreeeme";
                    repo = "xwayland-satellite";
                    tag = "v0.8.3";
                    hash = "sha256-eFEjCCniMCKeWU0PcZNv+tDYe08SLFPjRplyPY8OFt4=";
                  };
                  cargoHash = "sha256-gMGFvnbxM3hD5fmkSimaFd87GEf6BXFe/MGjoS6VNVU=";

                  cargoDeps = final.rustPlatform.fetchCargoVendor {
                    inherit (finalAttrs) pname version src;
                    hash = finalAttrs.cargoHash;
                  };
                }
              )
            else
              prev.xwayland-satellite;
        })
      ];

      programs.niri.enable = true;
      environment.systemPackages = [ pkgs.xwayland-satellite ];

      home-manager.users.${username}.xdg.configFile."niri/config.kdl" = {
        force = true;
        text = ''
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
            touchpad {
              tap
              natural-scroll
              dwt
            }
          }

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

          gestures {
            hot-corners { off; }
          }

          prefer-no-csd
          layout {
            background-color "transparent"
            gaps 4
            center-focused-column "never"
            default-column-width { proportion 0.5; }
            preset-column-widths {
              proportion 0.5
              proportion 0.8
              proportion 1.0
            }
            focus-ring {
              width 2
              active-color "#d0bcff"
              inactive-color "#948f99"
            }
            border { off; }
          }

          spawn-at-startup "swaybg" "-c" "#1e1e2e"
          ${lib.optionalString shellEnabled ''spawn-at-startup "${shellCommand}" "--compositor" "niri"''}
          layer-rule {
            match namespace="${if shellEnabled then "^(wallpaper|sanctuary-wallpaper)$" else "^wallpaper$"}"
            place-within-backdrop true
          }

          window-rule {
            geometry-corner-radius 12
            clip-to-geometry true
          }
          window-rule {
            match app-id=r#"^steam_app_[0-9]+$"#
            open-fullscreen true
          }

          binds {

            Super+Return { spawn "ghostty"; }
            Super+E { spawn "ghostty" "--title=Yazi" "-e" "yazi"; }
            Super+Alt+F4 { quit; }
            Super+grave repeat=false { toggle-overview; }
            Super+F1 { show-hotkey-overlay; }
            Super+L repeat=false { spawn ${command [ "lock" ] ''"swaylock" "-f" "-c" "1e1e2e"''}; }
            XF86ScreenSaver repeat=false { spawn ${command [ "lock" ] ''"swaylock" "-f" "-c" "1e1e2e"''}; }

            Super+Shift+Slash { show-hotkey-overlay; }
            Super+D repeat=false { spawn ${command [ "launcher" ] ''"fuzzel"''}; }
            XF86AudioRaiseVolume allow-when-locked=true { spawn ${command [ "volume-up" ] ''"wpctl" "set-volume" "-l" "1" "@DEFAULT_AUDIO_SINK@" "5%+"''}; }
            XF86AudioLowerVolume allow-when-locked=true { spawn ${command [ "volume-down" ] ''"wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"''}; }
            XF86AudioMute allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
            XF86AudioMicMute allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"; }
            XF86AudioPlay allow-when-locked=true { spawn "playerctl" "play-pause"; }
            XF86AudioStop allow-when-locked=true { spawn "playerctl" "stop"; }
            XF86AudioPrev allow-when-locked=true { spawn "playerctl" "previous"; }
            XF86AudioNext allow-when-locked=true { spawn "playerctl" "next"; }
            XF86MonBrightnessUp allow-when-locked=true { spawn ${command [ "brightness-up" ] ''"brightnessctl" "set" "+10%"''}; }
            XF86MonBrightnessDown allow-when-locked=true { spawn ${command [ "brightness-down" ] ''"brightnessctl" "set" "10%-"''}; }
            Super+Q repeat=false { close-window; }
            Super+Left  { focus-column-left; }
            Super+Down  { focus-window-down; }
            Super+Up    { focus-window-up; }
            Super+Right { focus-column-right; }
            Super+Ctrl+Left  { move-column-left; }
            Super+Ctrl+Down  { move-window-down; }
            Super+Ctrl+Up    { move-window-up; }
            Super+Ctrl+Right { move-column-right; }
            Super+Home { focus-column-first; }
            Super+End  { focus-column-last; }
            Super+Ctrl+Home { move-column-to-first; }
            Super+Ctrl+End  { move-column-to-last; }
            Super+Shift+Left  { focus-monitor-left; }
            Super+Shift+Down  { focus-monitor-down; }
            Super+Shift+Up    { focus-monitor-up; }
            Super+Shift+Right { focus-monitor-right; }
            Super+Shift+Ctrl+Left  { move-window-to-monitor-left; }
            Super+Shift+Ctrl+Down  { move-window-to-monitor-down; }
            Super+Shift+Ctrl+Up    { move-window-to-monitor-up; }
            Super+Shift+Ctrl+Right { move-window-to-monitor-right; }
            Super+Shift+Ctrl+H     { move-window-to-monitor-left; }
            Super+Shift+Ctrl+J     { move-window-to-monitor-down; }
            Super+Shift+Ctrl+K     { move-window-to-monitor-up; }
            Super+Shift+Ctrl+L     { move-window-to-monitor-right; }
            Super+Page_Down      { focus-workspace-down; }
            Super+Page_Up        { focus-workspace-up; }
            Super+U              { focus-workspace-down; }
            Super+I              { focus-workspace-up; }
            Super+Ctrl+Page_Down { move-column-to-workspace-down; }
            Super+Ctrl+Page_Up   { move-column-to-workspace-up; }
            Super+Ctrl+U         { move-column-to-workspace-down; }
            Super+Ctrl+I         { move-column-to-workspace-up; }
            Super+Shift+Page_Down { move-workspace-down; }
            Super+Shift+Page_Up   { move-workspace-up; }
            Super+Shift+U         { move-workspace-down; }
            Super+Shift+I         { move-workspace-up; }
            Super+WheelScrollDown      cooldown-ms=150 { focus-workspace-down; }
            Super+WheelScrollUp        cooldown-ms=150 { focus-workspace-up; }
            Super+Ctrl+WheelScrollDown cooldown-ms=150 { move-column-to-workspace-down; }
            Super+Ctrl+WheelScrollUp   cooldown-ms=150 { move-column-to-workspace-up; }
            Super+WheelScrollRight      { focus-column-right; }
            Super+WheelScrollLeft       { focus-column-left; }
            Super+Ctrl+WheelScrollRight { move-column-right; }
            Super+Ctrl+WheelScrollLeft  { move-column-left; }
            Super+Shift+WheelScrollDown      { focus-column-right; }
            Super+Shift+WheelScrollUp        { focus-column-left; }
            Super+Ctrl+Shift+WheelScrollDown { move-column-right; }
            Super+Ctrl+Shift+WheelScrollUp   { move-column-left; }
            Super+1 { focus-workspace 1; }
            Super+2 { focus-workspace 2; }
            Super+3 { focus-workspace 3; }
            Super+4 { focus-workspace 4; }
            Super+5 { focus-workspace 5; }
            Super+6 { focus-workspace 6; }
            Super+7 { focus-workspace 7; }
            Super+8 { focus-workspace 8; }
            Super+9 { focus-workspace 9; }
            Super+Ctrl+1 { move-column-to-workspace 1; }
            Super+Ctrl+2 { move-column-to-workspace 2; }
            Super+Ctrl+3 { move-column-to-workspace 3; }
            Super+Ctrl+4 { move-column-to-workspace 4; }
            Super+Ctrl+5 { move-column-to-workspace 5; }
            Super+Ctrl+6 { move-column-to-workspace 6; }
            Super+Ctrl+7 { move-column-to-workspace 7; }
            Super+Ctrl+8 { move-column-to-workspace 8; }
            Super+Ctrl+9 { move-column-to-workspace 9; }
            Super+BracketLeft  { consume-or-expel-window-left; }
            Super+BracketRight { consume-or-expel-window-right; }
            Super+Ctrl+Comma { consume-window-into-column; }
            Super+Period { expel-window-from-column; }
            Super+R { switch-preset-column-width; }
            Super+Shift+R { switch-preset-column-width-back; }
            Super+Ctrl+Shift+R { switch-preset-window-height; }
            Super+Ctrl+R { reset-window-height; }
            Super+F { maximize-column; }
            Super+Shift+F { fullscreen-window; }
            Super+M { maximize-window-to-edges; }
            Super+Ctrl+F { expand-column-to-available-width; }
            Super+C { center-column; }
            Super+Ctrl+C { center-visible-columns; }
            Super+Minus { set-column-width "-10%"; }
            Super+Equal { set-column-width "+10%"; }
            Super+Shift+Minus { set-window-height "-10%"; }
            Super+Shift+Equal { set-window-height "+10%"; }
            Super+V       { toggle-window-floating; }
            Super+Shift+V { switch-focus-between-floating-and-tiling; }
            Super+W { toggle-column-tabbed-display; }
            Print { ${if shellEnabled then ''spawn "${shellCommand}" "screenshot";'' else "screenshot;"} }
            Ctrl+Print { screenshot-screen; }
            Alt+Print { screenshot-window; }
            Super+Escape allow-inhibiting=false { toggle-keyboard-shortcuts-inhibit; }
            Super+Shift+P { power-off-monitors; }
          }
        '';
      };
    };
}
