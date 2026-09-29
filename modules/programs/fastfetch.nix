{ ... }: {
  flake.nixosModules.fastfetch = { username, ... }: {
    home-manager.users.${username} = {
      programs.fastfetch = {
        enable = true;

        settings = {
            "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";

            "logo" = {
              "source" = "~/.config/fastfetch/ascii.txt";

              "color" = {
                "1" = "default";
                "2" = "default";
                "3" = "default";
                "4" = "default";
                "5" = "default";
                "6" = "default";
              };
              "padding" = {
                "top" = 2;
                "right" = 5;
                "left" = 1;
              };
            };
            "display" = {
              "disableLinewrap" = true;
              "separator" = " ";
              "color" = {
                "keys" = "default";
                "title" = "default";
                "output" = "default";
                "separator" = "default";
                };
              };
            "modules" = [
              "break"
              {
                "type" = "custom";
                "format" = "┌──────────────────────Hardware──────────────────────┐";
              }
              {
                "type" = "host";
                "key" = "│ ";
                "format" = "{name}";
              }
              {
                "type" = "cpu";
                "key" = "│ ├";
                "showPeCoreCount" = true;
              }
              {
                "type" = "gpu";
                "key" = "│ ├";
                "detectionMethod" = "pci";
                "format" = "{name}";
              }
              {
                "type" = "display";
                "key" = "│ ├󱄄";
              }
              {
                "type" = "disk";
                "key" = "│ ├󰋊";
                "folders" = [
                  "/"
                  "/mad"
                ];
              }
              {
                "type" = "memory";
                "key" = "│ ├";
              }
              {
                "type" = "battery";
                "key" = "│ ├";
              }
              {
                "type" = "swap";
                "key" = "└ └󰓡";
              }
              "break"
              {
                "type" = "custom";
                "format" = "┌──────────────────────Software──────────────────────┐";
              }
              {
                "type" = "os";
                "key" = "│  ";
                "format" = "{name}";
              }
              {
                "type" = "kernel";
                "key" = "│ ├";
              }
              {
                "type" = "wm";
                "key" = "│ ├";
              }
              {
                "type" = "de";
                "key" = "│ ├ DE";
              }
              {
                "type" = "terminal";
                "key" = "│ ├";
              }
              {
                "type" = "packages";
                "key" = "│ ├󰏖";
              }
              {
                "type" = "wmtheme";
                "key" = "│ ├󰉼";
              }
              {
                "type" = "terminalfont";
                "key" = "└ └";
              }
              "break"
              {
                "type" = "custom";
                "format" = "┌─────────────────System Informations────────────────┐";
              }
              {
                "type" = "command";
                "key" = "│ 󱦟 OS Age";
                "text" = "created=$(stat -c %W /); if [ \"$created\" -gt 0 ]; then echo $(( ($(date +%s) - created) / 86400 )) days; else echo 'unknown'; fi";
              }
              {
                "type" = "uptime";
                "key" = "│ 󱫐 Uptime";
              }
              {
                "type" = "command";
                "key" = "└  Generation";
                "text" = "readlink /nix/var/nix/profiles/system | sed 's/.*system-//;s/-link//'";
              }
              "break"
            ];
        };
      };
    };
  };
}
