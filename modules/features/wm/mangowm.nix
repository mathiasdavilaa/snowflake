{ self, inputs, ... }: {
  # MangoWM (mangowc): compositor Wayland baseado no dwl, com IPC, animações
  # e layouts próprios. Tudo o que estava em binds.conf/config.conf/input.conf/
  # output.conf/system.conf/dms/*.conf (mango.zip) foi juntado aqui num único
  # arquivo, igual ao hyprland.nix — o módulo Nix gera o config.conf sozinho,
  # não precisamos mais dos `source=./dms/...` manuais.
  #
  # Tudo que é do DMS (binds de spotlight/powermenu/screenshot/volume, cores,
  # layout e a window rule do próprio DMS) fica em shells/dms.nix, não aqui.
  # Os binds da Marea (search, lock, gravação) ficam em shells/marea.nix — as
  # duas são shells que rodam por cima do compositor, não compositores em si.
  # Aqui só entram as configurações "nativas" do MangoWM (input, monitores,
  # tags e os binds de janela que não dependem de DMS nem Marea).
  flake.nixosModules.mangowm = { lib, username, ... }: {
    programs.mango.enable = true;

    home-manager.users.${username} = {
      imports = [ inputs.mango.hmModules.mango ];

      wayland.windowManager.mango = {
        enable = true;

        settings = {
          # ---------------
          # ---- INPUT ----
          # ---------------
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

          # ------------------
          # ---- MONITORS ----
          # ------------------
          monitorrule = [
            "name:^HDMI-A-1$,width:1920,height:1080,x:0,y:0,scale:1,rr:1"
            "name:^DP-3$,width:1920,height:1080,x:1080,y:0,scale:1,rr:0"
            "name:^eDP-1$,width:1920,height:1080,x:1200,y:0,scale:1,rr:0"
          ];

          tagrule =
            (map (i: "id:${toString i},monitor_name:HDMI-A-1,layout_name:vertical_scroller") (lib.range 1 9))
            ++ (map (i: "id:${toString i},monitor_name:DP-3,layout_name:scroller") (lib.range 1 9));

          # ---------------------
          # ---- KEYBINDINGS ----
          # ---------------------
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
        source = self + "/modules/features/scripts/move-window-monitor-silent.sh";
        executable = true;
      };
    };
  };
}
