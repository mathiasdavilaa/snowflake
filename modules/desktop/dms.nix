{ inputs, self, ... }: {
  # Fonte única das ações do DMS; cada compositor adapta apenas a sintaxe.
  flake.lib.dmsBinds =
    {
      lib,
      session,
      executable ? "dms",
    }:
    let
      common = [
        {
          mods = "SUPER";
          key = "d";
          command = "ipc call spotlight toggle";
        }
        {
          mods = "SUPER";
          key = "Escape";
          command = "ipc call powermenu toggle";
        }
        {
          mods = "SUPER";
          key = "F1";
          command = "ipc call keybinds toggle ${session}";
        }
        {
          key = "Print";
          command = "screenshot";
        }
        {
          key = "XF86AudioRaiseVolume";
          command = "ipc call audio increment 3";
          repeating = true;
          locked = true;
        }
        {
          key = "XF86AudioLowerVolume";
          command = "ipc call audio decrement 3";
          repeating = true;
          locked = true;
        }
        {
          key = "XF86AudioMute";
          command = "ipc call audio mute";
          locked = true;
        }
        {
          key = "XF86MonBrightnessUp";
          command = "ipc call brightness increment 5";
          repeating = true;
          locked = true;
        }
        {
          key = "XF86MonBrightnessDown";
          command = "ipc call brightness decrement 5";
          repeating = true;
          locked = true;
        }
      ];
      binds =
        common
        ++ lib.optionals (session == "hyprland") [
          {
            mods = "SUPER+ALT";
            key = "L";
            command = "ipc call lock lock";
          }
        ];
      luaString = builtins.toJSON;
    in
    {
      mango = map (b: "${b.mods or "NONE"},${b.key},spawn_shell,${executable} ${b.command}") binds;
      hyprland = lib.concatMapStringsSep "\n" (
        b:
        let
          keys = lib.optionalString (b ? mods) (lib.replaceStrings [ "+" ] [ " + " ] b.mods + " + ") + b.key;
          flag = value: if value then "true" else "false";
        in
        "hl.bind(${luaString keys}, hl.dsp.exec_cmd(${luaString "${executable} ${b.command}"}), { repeating = ${flag (b.repeating or false)}, locked = ${flag (b.locked or false)} })"
      ) binds;
    };

  flake.nixosModules.dms = { lib, username, ... }: {
    imports = [ inputs.dms.nixosModules.default ];

    programs.dank-material-shell.enable = true;

    # Aparência e inicialização do DMS na sessão Mango.
    home-manager.users.${username}.wayland.windowManager = {
      mango.settings = {
        # spawn_shell executa os comandos IPC com seus argumentos.
        bind =
          (self.lib.dmsBinds {
            inherit lib;
            session = "mangowm";
          }).mango;

        # Cores das bordas: normal, focada e urgente.
        bordercolor = "0x948f99ff";
        focuscolor = "0xd0bcffff";
        urgentcolor = "0xf2b8b5ff";

        # Arredondamento, espessura das bordas e espaçamento.
        border_radius = 12;
        borderpx = 2;
        gappih = 4;
        gappiv = 4;
        gappoh = 4;
        gappov = 4;

        # As janelas do DMS ficam flutuantes.
        windowrule = [
          "appid:^com.danklinux.dms$,isfloating:1"
        ];

        # Inicia o DMS junto com a sessão Mango.
        "exec-once" = [ "dms run" ];
      };
    };
  };
}
