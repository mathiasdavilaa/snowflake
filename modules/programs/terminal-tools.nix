{ ... }: {
  flake.nixosModules.terminalTools = { username, ... }: {
    home-manager.users.${username} =
      {
        config,
        lib,
        options,
        pkgs,
        ...
      }:
      let
        fileCommand = "fd --type f --hidden --exclude .git";
        directoryCommand = "fd --type d --hidden --exclude .git";
        previewOptions = [
          "--preview 'bat --style=numbers --color=always --line-range :200 -- {}'"
        ];
      in
      {
        home.packages = with pkgs; [
          fd
          bat
          (lib.lowPrio ncurses)
          xdg-utils
        ];

        programs.fzf = {
          enable = true;
          defaultCommand = fileCommand;
          defaultOptions = [
            "--height=50%"
            "--layout=reverse"
            "--border=rounded"
          ];
        }
        // lib.optionalAttrs (options.programs.fzf ? enableFishIntegration) {
          enableFishIntegration = true;
        }
        // (
          if options.programs.fzf ? fileWidget then
            {
              fileWidget = {
                command = fileCommand;
                options = previewOptions;
              };
              changeDirWidget.command = directoryCommand;
            }
          else
            {
              fileWidgetCommand = fileCommand;
              fileWidgetOptions = previewOptions;
              changeDirWidgetCommand = directoryCommand;
            }
        );

        programs.yazi = {
          enable = true;
          enableFishIntegration = true;
          shellWrapperName = "y";
        };

        xdg.mimeApps = lib.mkIf config.programs.zed-editor.enable {
          enable = true;
          defaultApplications."text/plain" = [ "dev.zed.Zed.desktop" ];
        };
      };
  };
}
