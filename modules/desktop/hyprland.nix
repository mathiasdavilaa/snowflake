{ self, ... }: {
  flake.nixosModules.hyprland =
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
      command = args: fallback: if shellEnabled then lib.escapeShellArgs ([ shellCommand ] ++ args) else fallback;
    in {
      imports = [ self.nixosModules.waylandBase ];

      programs.hyprland = {
        enable = true;
        withUWSM = false;
        xwayland.enable = true;
      };
      environment.systemPackages = [ pkgs.hyprshot ];
      xdg.portal.config.hyprland = {
        default = [
          "hyprland"
          "gtk"
        ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      };

      home-manager.users.${username} = {
        xdg.configFile."hypr/hyprland.lua".force = true;
        wayland.windowManager.hyprland = {
          enable = true;
          package = null;
          portalPackage = null;
          configType = "lua";
          systemd.enable = true;
          extraConfig = ''
            ${lib.concatMapStringsSep "\n" (m: ''
              hl.monitor({
                output = ${builtins.toJSON m.name},
                mode = "${toString m.width}x${toString m.height}@${toString m.refresh}",
                position = "${toString m.x}x${toString m.y}",
                scale = ${toString m.scale},
                transform = ${toString m.transform},
              })
            '') monitors}
            hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

            hl.env("XCURSOR_SIZE", "24")
            hl.env("HYPRCURSOR_SIZE", "24")
            hl.config({
              general = {
                gaps_in = 4, gaps_out = 8, border_size = 2,
                layout = "dwindle", resize_on_border = true,
                col = { active_border = "rgb(d0bcff)", inactive_border = "rgb(948f99)" },
              },
              input = {
                kb_layout = "us,br", kb_options = "caps:escape",
                repeat_delay = 400, repeat_rate = 30,
                follow_mouse = 0, accel_profile = "flat",
                touchpad = { natural_scroll = true, tap_to_click = true, disable_while_typing = true },
              },
              decoration = {
                rounding = 12,
                blur = { enabled = true, size = 5, passes = 2 },
                shadow = { enabled = true, range = 12, render_power = 3, color = "rgba(00000055)" },
              },
              dwindle = { preserve_split = true },
              animations = { enabled = true },
              misc = { disable_hyprland_logo = true, force_default_wallpaper = -1 },
            })
            hl.curve("md3_spatial_default", { type = "spring", mass = 1, stiffness = 300, dampening = 30 })

            hl.curve("md3_effects_default", { type = "spring", mass = 1, stiffness = 16600, dampening = 80 })

            hl.curve("md3_standard", { type = "bezier", points = { {0.2, 0.0}, {0.0, 1.0} } })
            hl.curve("md3_emphasized_accel", { type = "bezier", points = { {0.3, 0.0}, {0.8, 0.15} } })

            hl.animation({ leaf = "windows", enabled = true, speed = 5, spring = "md3_spatial_default" })
            hl.animation({ leaf = "windowsIn", enabled = true, speed = 5, spring = "md3_spatial_default", style = "popin 92%" })
            hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, spring = "md3_spatial_default", style = "popin 92%" })
            hl.animation({ leaf = "windowsMove", enabled = true, speed = 5, spring = "md3_spatial_default" })

            hl.animation({ leaf = "layers", enabled = true, speed = 3, bezier = "md3_standard", style = "fade" })
            hl.animation({ leaf = "layersIn", enabled = true, speed = 3, bezier = "md3_standard", style = "fade" })
            hl.animation({ leaf = "layersOut", enabled = true, speed = 2.5, bezier = "md3_emphasized_accel", style = "fade" })

            hl.animation({ leaf = "fade", enabled = true, speed = 2, spring = "md3_effects_default" })
            hl.animation({ leaf = "fadeOut", enabled = true, speed = 2, spring = "md3_spatial_default" })

            hl.animation({ leaf = "workspaces", enabled = true, speed = 5, spring = "md3_spatial_default", style = "slide" })
            hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3.5, spring = "md3_spatial_default", style = "slidevert" })

            hl.on("hyprland.start", function()
              hl.exec_cmd("swaybg -c '#1e1e2e'")
              ${lib.optionalString shellEnabled ''hl.exec_cmd("${shellCommand} --compositor hyprland")''}
            end)

            local function run(keys, command, flags)
              hl.bind(keys, hl.dsp.exec_cmd(command), flags or {})
            end
            run("SUPER + RETURN", "ghostty")
            run("SUPER + E", "ghostty --title=Yazi -e yazi")
            run("SUPER + D", ${builtins.toJSON (command [ "launcher" ] "fuzzel")})
            run("SUPER + L", ${builtins.toJSON (command [ "lock" ] "swaylock -f -c 1e1e2e")})
            run("XF86ScreenSaver", ${builtins.toJSON (command [ "lock" ] "swaylock -f -c 1e1e2e")})
            run("PRINT", ${builtins.toJSON (command [ "screenshot" ] "hyprshot -m region --clipboard-only")})
            run("SUPER + SHIFT + S", ${builtins.toJSON (command [ "screenshot" ] "hyprshot -m region --clipboard-only")})
            run("SHIFT + PRINT", "hyprshot -m output --clipboard-only")

            hl.bind("SUPER + Q", hl.dsp.window.close())
            hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
            hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
            hl.bind("SUPER + V", hl.dsp.window.float({ action = "toggle" }))
            hl.bind("SUPER + ALT + F4", hl.dsp.exit())
            for _, direction in ipairs({ "left", "right", "up", "down" }) do
              hl.bind("SUPER + " .. direction, hl.dsp.focus({ direction = direction }))
              hl.bind("SUPER + SHIFT + " .. direction, hl.dsp.window.move({ direction = direction }))
            end
            for i = 1, 10 do
              local key = i % 10
              hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = i }))
              hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
            end
            hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
            hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

            local hardware = { locked = true, repeating = true }
            run("XF86AudioRaiseVolume", ${builtins.toJSON (command [ "volume-up" ] "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+")}, hardware)
            run("XF86AudioLowerVolume", ${builtins.toJSON (command [ "volume-down" ] "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")}, hardware)
            run("XF86AudioMute", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle", { locked = true })
            run("XF86AudioMicMute", "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle", { locked = true })
            run("XF86MonBrightnessUp", ${builtins.toJSON (command [ "brightness-up" ] "brightnessctl set +10%")}, hardware)
            run("XF86MonBrightnessDown", ${builtins.toJSON (command [ "brightness-down" ] "brightnessctl set 10%-")}, hardware)
            run("XF86AudioPlay", "playerctl play-pause", { locked = true })
            run("XF86AudioPause", "playerctl play-pause", { locked = true })
            run("XF86AudioNext", "playerctl next", { locked = true })
            run("XF86AudioPrev", "playerctl previous", { locked = true })
          '';
        };
      };
    };
}
