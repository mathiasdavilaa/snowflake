{ self, inputs, ... }: {
  # Sessão Mango: compositor, Home Manager, DMS e atalhos da Marea.
  # As regras de monitor ficam em cada host.
  flake.nixosModules.mango = { lib, pkgs, username, monitors, ... }: {
    imports = [ inputs.mango.nixosModules.mango self.nixosModules.dms ];
    programs.mango.enable = true;
    environment.systemPackages = [ pkgs.yazi ];

    home-manager.users.${username} = {
      imports = [ inputs.mango.hmModules.mango ];

      wayland.windowManager.mango = {
        enable = true;

        settings = {
          monitorrule = map (m:
            "name:^${m.name}$,width:${toString m.width},height:${toString m.height},refresh:${toString m.refresh},x:${toString m.x},y:${toString m.y},scale:${toString m.scale},rr:${toString m.transform}"
          ) monitors;
          tagrule = lib.concatMap (m:
            map (i: "id:${toString i},monitor_name:${m.name},layout_name:${if m.transform == 1 then "vertical_scroller" else "scroller"}") (lib.range 1 9)
          ) monitors;

          # Teclado e mouse.
          mouse_accel_profile = 1;
          mouse_accel_speed = 0;
          xkb_rules_layout = "us,br";
          xkb_rules_options = "caps:escape";
          repeat_rate = 30;
          repeat_delay = 400;

          sloppyfocus = 0;
          scroller_structs = 1;

          env = [
            "XDG_CURRENT_DESKTOP,mango"
            "XDG_SESSION_TYPE,wayland"
          ];

          # Atalhos de teclado.
          bind =
            [
              "SUPER,w,spawn,ghostty"
              "SUPER,q,killclient"
              "SUPER,e,spawn,ghostty --title=Yazi -e yazi"
              "SUPER+Alt,F4,quit"

              "SUPER+SHIFT,f,togglefullscreen"
              "SUPER,f,set_proportion,1.0"
              "SUPER,v,togglefloating"

              "SUPER,equal,resizewin,+150,0"
              "SUPER,minus,resizewin,-150,0"
              "SUPER,Prior,set_proportion,0.5"
              "SUPER,Next,set_proportion,0.8"

              # Foco
              "SUPER,h,focusdir,left"
              "SUPER,k,focusdir,up"
              "SUPER,j,focusdir,down"
              "SUPER,l,focusdir,right"
              "SUPER,left,focusdir,left"
              "SUPER,up,focusdir,up"
              "SUPER,down,focusdir,down"
              "SUPER,right,focusdir,right"

              # Monitores
              "SUPER,home,focusmon,right"
              "SUPER+SHIFT,home,tagmon,right"
              "SUPER+CTRL,home,spawn,~/.config/mango/scripts/move-window-monitor-silent.sh"
              "SUPER,space,spawn,marea search"
              "SUPER,l,spawn,marea lock"
              "SUPER+SHIFT,c,spawn,marea record_toggle"
            ]
            # Tags 1 a 9: ver, mover (tag) e mover em silêncio (tagsilent)
            ++ (map (i: "SUPER,${toString i},view,${toString i},0") (lib.range 1 9))
            ++ (map (i: "SUPER+SHIFT,${toString i},tag,${toString i}") (lib.range 1 9))
            ++ (map (i: "SUPER+CTRL,${toString i},tagsilent,${toString i}") (lib.range 1 9))
            ++ [
              # Trocar janela de lugar
              "SUPER+SHIFT,h,exchange_client,left"
              "SUPER+SHIFT,l,exchange_client,right"
              "SUPER+SHIFT,left,exchange_client,left"
              "SUPER+SHIFT,right,exchange_client,right"
              "SUPER+SHIFT,k,exchange_client,up"
              "SUPER+SHIFT,j,exchange_client,down"
              "SUPER+SHIFT,up,exchange_client,up"
              "SUPER+SHIFT,down,exchange_client,down"
            ];

          mousebind = [
            "SUPER,btn_left,moveresize,curmove"
            "SUPER,btn_right,moveresize,curresize"
          ];
        };
      };

      xdg.configFile."mango/scripts/move-window-monitor-silent.sh" = {
        source = self + "/modules/desktop/scripts/move-window-monitor-silent.sh";
        executable = true;
      };
    };
  };
}
