{ ... }: {
  flake.nixosModules.macro = { pkgs, config, username, profile, ... }:
    let
      python = pkgs.python3.withPackages (p: [ p.pygobject3 p.pycairo ]);
      cursor = pkgs.stdenvNoCC.mkDerivation {
        pname = "snowflake-cursor-reader";
        version = "1.1";
        dontUnpack = true;
        nativeBuildInputs = [ pkgs.wrapGAppsHook3 pkgs.gobject-introspection ];
        buildInputs = [ python pkgs.gtk3 pkgs.gtk-layer-shell ];
        installPhase = ''
          install -Dm755 ${./macro/cursor-overlay.py} "$out/bin/snowflake-cursor-reader"
          substituteInPlace "$out/bin/snowflake-cursor-reader" \
            --replace-fail '#!/usr/bin/env python3' '#!${python}/bin/python3'
        '';
      };
      command = name: pkgs.writeShellApplication {
        inherit name;
        runtimeInputs = [ pkgs.python3 pkgs.niri pkgs.ydotool cursor ];
        text = ''
          export SNOWFLAKE_PROFILE=${pkgs.lib.escapeShellArg profile}
          export YDOTOOL_SOCKET=${pkgs.lib.escapeShellArg config.environment.variables.YDOTOOL_SOCKET}
          exec python3 ${./macro/macro.py} ${pkgs.lib.escapeShellArg name} "$@"
        '';
      };
    in {
      programs.ydotool.enable = true;
      users.users.${username}.extraGroups = [ config.programs.ydotool.group ];
      environment.systemPackages = [ (command "macro") (command "cursor-pos") ];
      home-manager.users.${username} = { lib, config, ... }: {
        # Editável no terminal; o rebuild não sobrescreve os pontos do usuário.
        home.activation.macroConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg "${config.xdg.configHome}/snowflake"}
          if [ ! -e ${lib.escapeShellArg "${config.xdg.configHome}/snowflake/macro.json"} ]; then
            run ${pkgs.coreutils}/bin/cp ${./macro/example.json} ${lib.escapeShellArg "${config.xdg.configHome}/snowflake/macro.json"}
            run ${pkgs.coreutils}/bin/chmod u+w ${lib.escapeShellArg "${config.xdg.configHome}/snowflake/macro.json"}
          fi
        '';
      };
    };
}
