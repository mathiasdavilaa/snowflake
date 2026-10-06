{ self, ... }: {
  flake.nixosModules.niri = { lib, pkgs, username, monitors, ... }: {
    imports = [ self.nixosModules.dms ];

    # 0.8.2 quebra popups do Steam. Backport da versão corrigida do nixpkgs,
    # sem atualizar o restante do sistema. Some quando nixpkgs tiver >= 0.8.3.
    # Overlay garante a mesma versão no PATH do Niri e na sessão Niri.
    nixpkgs.overlays = [ (final: prev: {
      xwayland-satellite =
        if lib.versionOlder prev.xwayland-satellite.version "0.8.3" then
          prev.xwayland-satellite.overrideAttrs (finalAttrs: old: {
            version = "0.8.3";
            src = final.fetchFromGitHub {
              owner = "Supreeeme";
              repo = "xwayland-satellite";
              tag = "v0.8.3";
              hash = "sha256-eFEjCCniMCKeWU0PcZNv+tDYe08SLFPjRplyPY8OFt4=";
            };
            cargoHash = "sha256-gMGFvnbxM3hD5fmkSimaFd87GEf6BXFe/MGjoS6VNVU=";
            # cargoHash sozinho não substitui o hash já capturado por cargoDeps.
            # Refazer o vendor com a fonte e o hash da versão atualizada.
            cargoDeps = final.rustPlatform.fetchCargoVendor {
              inherit (finalAttrs) pname version src;
              hash = finalAttrs.cargoHash;
            };
          })
        else prev.xwayland-satellite;
    }) ];

    programs.niri.enable = true;
    environment.systemPackages = with pkgs; [ xwayland-satellite ghostty yazi ];

    # Niri inicia o Satellite automaticamente. Não definir DISPLAY manualmente.
    # O pacote fornece niri-session e niri.service, usados pelo SDDM/DMS.
    home-manager.users.${username}.xdg.configFile."niri/config.kdl".text = ''
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
          dwt // Desativa o touchpad durante a digitação.
        }
      }

      ${lib.concatMapStringsSep "\n" (m: ''
        output ${builtins.toJSON m.name} {
          mode "${toString m.width}x${toString m.height}@${toString m.refresh}"
          scale ${toString m.scale}
          transform "${builtins.elemAt [ "normal" "90" "180" "270" "flipped" "flipped-90" "flipped-180" "flipped-270" ] m.transform}"
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
      // O wallpaper permanece atrás dos workspaces durante o overview.
      layer-rule {
        match namespace="^quickshell$"
        place-within-backdrop true
      }
      // Também aceita o wallpaper desfocado quando Blur Layer está ativo no DMS.
      layer-rule {
        match namespace="^dms:blurwallpaper$"
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
        // Personalizações escolhidas; os demais atalhos seguem o Niri 26.04.
        Super+Return { spawn "ghostty"; }
        Super+E { spawn "ghostty" "--title=Yazi" "-e" "yazi"; }
        Super+Alt+F4 { quit; }
        Super+grave repeat=false { toggle-overview; }
        Super+Comma { spawn "dms" "ipc" "call" "settings" "toggle"; }
        Super+F1 { show-hotkey-overlay; }
        Super+L repeat=false allow-when-locked=true { spawn "dms" "ipc" "call" "lock" "lock"; }
        Super+Shift+W repeat=false { spawn "dms" "ipc" "call" "dash" "toggle" "wallpaper"; }

        Super+Shift+Slash { show-hotkey-overlay; }
        Super+Ctrl+V repeat=false { spawn "dms" "ipc" "call" "clipboard" "toggle"; }
        Super+N repeat=false { spawn "dms" "ipc" "call" "notifications" "toggle"; }
        Super+Shift+Comma repeat=false { spawn "dms" "ipc" "call" "control-center" "toggle"; }
        Super+Shift+Escape repeat=false { spawn "dms" "ipc" "call" "powermenu" "toggle"; }
        Super+D repeat=false { spawn "dms" "ipc" "call" "spotlight" "toggle"; }
        XF86AudioRaiseVolume allow-when-locked=true { spawn "dms" "ipc" "call" "audio" "increment" "5"; }
        XF86AudioLowerVolume allow-when-locked=true { spawn "dms" "ipc" "call" "audio" "decrement" "5"; }
        XF86AudioMute        allow-when-locked=true { spawn "dms" "ipc" "call" "audio" "mute"; }
        XF86AudioMicMute     allow-when-locked=true { spawn "dms" "ipc" "call" "audio" "micmute"; }
        XF86AudioPlay        allow-when-locked=true { spawn "dms" "ipc" "call" "mpris" "playPause"; }
        XF86AudioStop        allow-when-locked=true { spawn "dms" "ipc" "call" "mpris" "stop"; }
        XF86AudioPrev        allow-when-locked=true { spawn "dms" "ipc" "call" "mpris" "previous"; }
        XF86AudioNext        allow-when-locked=true { spawn "dms" "ipc" "call" "mpris" "next"; }
        XF86MonBrightnessUp allow-when-locked=true { spawn "dms" "ipc" "call" "brightness" "increment" "10" ""; }
        XF86MonBrightnessDown allow-when-locked=true { spawn "dms" "ipc" "call" "brightness" "decrement" "10" ""; }
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
        Print { screenshot; }
        Ctrl+Print { screenshot-screen; }
        Alt+Print { screenshot-window; }
        Super+Escape allow-inhibiting=false { toggle-keyboard-shortcuts-inhibit; }
        Super+Shift+P { power-off-monitors; }
      }
    '';
  };
}
