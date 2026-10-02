{ self, ... }: {
  flake.nixosModules.niri = { lib, pkgs, username, monitors, ... }: {
    imports = [ self.nixosModules.inir ];

    # 0.8.2 quebra popups do Steam. Backport da versão corrigida do nixpkgs,
    # sem atualizar o restante do sistema. Some quando nixpkgs tiver >= 0.8.3.
    # Overlay garante a mesma versão no PATH do Niri e no runtime do iNiR.
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
    # O pacote fornece niri-session e niri.service, usados pelo SDDM/iNiR.
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
        touchpad { tap; natural-scroll; }
      }

      ${lib.concatMapStringsSep "\n" (m: ''
        output ${builtins.toJSON m.name} {
          mode "${toString m.width}x${toString m.height}@${toString m.refresh}"
          scale ${toString m.scale}
          transform "${builtins.elemAt [ "normal" "90" "180" "270" "flipped" "flipped-90" "flipped-180" "flipped-270" ] m.transform}"
          position x=${toString m.x} y=${toString m.y}
        }
      '') monitors}

      prefer-no-csd
      layout {
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
      window-rule {
        geometry-corner-radius 12
        clip-to-geometry true
      }
      window-rule {
        match app-id=r#"^steam_app_[0-9]+$"#
        open-fullscreen true
      }

      include "colors.kdl"

      binds {
        Super+Return { spawn "ghostty"; }
        Super+E { spawn "ghostty" "--title=Yazi" "-e" "yazi"; }
        Super+Q { close-window; }
        Super+Alt+F4 { quit; }
        Super+V { toggle-window-floating; }
        Super+F { maximize-column; }
        Super+Shift+F { fullscreen-window; }
        Super+Prior { set-column-width "50%"; }
        Super+Next { set-column-width "80%"; }
        Super+equal { set-column-width "+150"; }
        Super+minus { set-column-width "-150"; }
        Super+Tab { toggle-overview; }
        Super+I { focus-workspace-up; }
        Super+U { focus-workspace-down; }

        ${lib.concatMapStringsSep "\n" (item: ''
          Super+${item.key} { ${item.focus}; }
          Super+Shift+${item.key} { ${item.move}; }
        '') [
          { key = "H"; focus = "focus-column-left"; move = "move-column-left"; }
          { key = "Left"; focus = "focus-column-left"; move = "move-column-left"; }
          { key = "L"; focus = "focus-column-right"; move = "move-column-right"; }
          { key = "Right"; focus = "focus-column-right"; move = "move-column-right"; }
          { key = "J"; focus = "focus-window-down"; move = "move-window-down"; }
          { key = "Down"; focus = "focus-window-down"; move = "move-window-down"; }
          { key = "K"; focus = "focus-window-up"; move = "move-window-up"; }
          { key = "Up"; focus = "focus-window-up"; move = "move-window-up"; }
        ]}
        Super+Ctrl+Left { focus-monitor-left; }
        Super+Ctrl+Right { focus-monitor-right; }
        Super+Ctrl+Shift+Left { move-window-to-monitor-left; }
        Super+Ctrl+Shift+Right { move-window-to-monitor-right; }

        ${lib.concatMapStringsSep "\n" (i: ''
          Super+${toString i} { focus-workspace ${toString i}; }
          Super+Shift+${toString i} { move-window-to-workspace ${toString i}; }
          Super+Ctrl+${toString i} { move-window-to-workspace ${toString i} focus=false; }
        '') (lib.range 1 9)}

        // Mantém os atalhos principais do Hyprland, com ações da shell iNiR.
        Super+D repeat=false { spawn "inir" "overview" "toggle"; }
        Super+Shift+V { spawn "inir" "clipboard" "toggle"; }
        Super+Comma { spawn "inir" "settings"; }
        Super+F1 { spawn "inir" "cheatsheet" "toggle"; }
        Super+Alt+L allow-when-locked=true { spawn "inir" "lock" "activate"; }
        Print { screenshot; }
        Super+Shift+S { spawn "inir" "region" "screenshot"; }
        Super+Escape allow-inhibiting=false { toggle-keyboard-shortcuts-inhibit; }
        Super+F6 repeat=false { spawn "sh" "-c" "$HOME/.local/bin/macro"; }

        XF86AudioRaiseVolume allow-when-locked=true { spawn "wpctl" "set-volume" "-l" "1.0" "@DEFAULT_AUDIO_SINK@" "3%+"; }
        XF86AudioLowerVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "3%-"; }
        XF86AudioMute allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
        XF86AudioPlay { spawn "playerctl" "play-pause"; }
        XF86AudioNext { spawn "playerctl" "next"; }
        XF86AudioPrev { spawn "playerctl" "previous"; }
        XF86MonBrightnessUp allow-when-locked=true { spawn "brightnessctl" "set" "5%+"; }
        XF86MonBrightnessDown allow-when-locked=true { spawn "brightnessctl" "set" "5%-"; }
      }
    '';
  };
}
