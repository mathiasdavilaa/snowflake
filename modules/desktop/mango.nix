{ self, inputs, ... }: {
  flake.nixosModules.mango =
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
      mangoPackage = config.programs.mango.package;
      screenshot = pkgs.writeShellApplication {
        name = "mango-screenshot";
        runtimeInputs = [
          pkgs.grim
          pkgs.slurp
          pkgs.wl-clipboard
        ];
        text = ''
          region="$(slurp)" || exit 0
          [[ -n "$region" ]] || exit 0
          grim -g "$region" - | wl-copy
        '';
      };
    in
    {
      imports = [
        self.nixosModules.waylandBase
        inputs.mango.nixosModules.mango
      ];
      programs.mango = {
        enable = true;
        addLoginEntry = true;
      };
      environment.systemPackages = [
        screenshot
        pkgs.wlr-randr
      ];
      home-manager.users.${username} = {
        imports = [ inputs.mango.hmModules.mango ];
        xdg.configFile."mango/config.conf".force = true;
        wayland.windowManager.mango = {
          enable = true;
          package = mangoPackage;
          systemd.enable = true;
          autostart_sh = ''
            swaybg -c '#1e1e2e' &
            ${lib.optionalString shellEnabled ''${shellCommand} --compositor mango &''}
          '';
          extraConfig = ''
            xkb_rules_layout=us,br
            xkb_rules_options=caps:escape
            repeat_delay=400
            repeat_rate=30
            mouse_accel_profile=1
            device_rule=type:trackpad,tap_to_click:1,natural_scrolling:1,disable_while_typing:1

            ${lib.concatMapStringsSep "\n" (
              m:
              "monitor_rule=name:^${m.name}$,width:${toString m.width},height:${toString m.height},refresh:${toString m.refresh},x:${toString m.x},y:${toString m.y},scale:${toString m.scale},rr:${toString m.transform}"
            ) monitors}

            bind=SUPER,Return,spawn,ghostty
            bind=SUPER,E,spawn,ghostty --title=Yazi -e yazi
            bind=SUPER,D,spawn,${command [ "launcher" ] "fuzzel"}
            bind=SUPER,L,spawn,${command [ "lock" ] "swaylock -f -c 1e1e2e"}
            bind=NONE,XF86ScreenSaver,spawn,${command [ "lock" ] "swaylock -f -c 1e1e2e"}
            bind=SUPER,Q,killclient
            bind=SUPER,F,togglemaximizescreen
            bind=SUPER+SHIFT,F,togglefullscreen
            bind=SUPER,V,togglefloating
            bind=SUPER,grave,toggleoverview
            bind=SUPER,R,reload_config
            bind=SUPER,T,setlayout,scroller
            bind=SUPER+SHIFT,T,setlayout,tile
            bind=SUPER+ALT,F4,quit
            bind=NONE,Print,spawn,${command [ "screenshot" ] "mango-screenshot"}
            bind=SUPER+SHIFT,S,spawn,${command [ "screenshot" ] "mango-screenshot"}

            ${lib.concatMapStringsSep "\n"
              (direction: ''
                bind=SUPER,${direction},focusdir,${lib.toLower direction}
                bind=SUPER+CTRL,${direction},move_client,${lib.toLower direction}
                bind=SUPER+SHIFT,${direction},focusmon,${lib.toLower direction}
              '')
              [
                "Left"
                "Right"
                "Up"
                "Down"
              ]
            }
            ${lib.concatMapStringsSep "\n" (n: ''
              bind=SUPER,${toString n},view,${toString n},0
              bind=SUPER+CTRL,${toString n},tag,${toString n},0
            '') (lib.range 1 9)}

            mousebind=SUPER,btn_left,moveresize,curmove
            mousebind=SUPER,btn_right,moveresize,curresize
            bindl=NONE,XF86AudioRaiseVolume,spawn,${command [ "volume-up" ] "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"}
            bindl=NONE,XF86AudioLowerVolume,spawn,${command [ "volume-down" ] "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"}
            bindl=NONE,XF86AudioMute,spawn,wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
            bindl=NONE,XF86AudioMicMute,spawn,wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
            bindl=NONE,XF86MonBrightnessUp,spawn,${command [ "brightness-up" ] "brightnessctl set +10%"}
            bindl=NONE,XF86MonBrightnessDown,spawn,${command [ "brightness-down" ] "brightnessctl set 10%-"}
            bindl=NONE,XF86AudioPlay,spawn,playerctl play-pause
            bindl=NONE,XF86AudioNext,spawn,playerctl next
            bindl=NONE,XF86AudioPrev,spawn,playerctl previous
          '';
        };
      };
    };
}
