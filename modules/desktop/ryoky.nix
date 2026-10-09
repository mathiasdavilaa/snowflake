{ inputs, ... }: {
  flake.nixosModules.ryoky =
    {
      config,
      pkgs,
      lib,
      username,
      monitors,
      ...
    }:
    let
      runtime = inputs.ryoku.packages.${pkgs.stdenv.hostPlatform.system};
      prepare = pkgs.writeShellScript "snowflake-prepare-ryoku" ''
        set -euo pipefail

        # Preparação única da base Ryoku. Guarda os arquivos anteriores antes de
        # liberar os caminhos que passam a ser gerenciados pelo materializador.
        config_home="''${XDG_CONFIG_HOME:-$HOME/.config}"
        state_home="''${XDG_STATE_HOME:-$HOME/.local/state}"
        state="$state_home/snowflake/ryoku-base-v1"

        if [[ -f "$state/prepared" ]]; then
          exit 0
        fi

        umask 077
        mkdir -p "$state"
        if [[ -f "$state/backup-path" ]]; then
          backup=$(cat "$state/backup-path")
        else
          backup=$(mktemp -d "$state/backup.XXXXXXXX")
          printf '%s\n' "$backup" > "$state/backup-path"
        fi
        mkdir -p "$backup/config"

        for name in niri ryoku fish ghostty fastfetch; do
          source="$config_home/$name"
          destination="$backup/config/$name"
          if [[ -e "$source" || -L "$source" ]]; then
            if [[ -e "$destination" || -L "$destination" ]]; then
              printf 'Preparação interrompida: origem e backup existem para %s.\n' "$name" >&2
              exit 1
            fi
            mv -- "$source" "$destination"
          fi
        done

        # Torna os arquivos do antigo Home Manager independentes do Nix store, para
        # que uma limpeza de gerações não deixe o backup com links quebrados.
        python3 - "$backup/config" <<'PY_BACKUP'
        import os
        import shutil
        import sys
        import tempfile
        from pathlib import Path

        for root, dirs, files in os.walk(sys.argv[1]):
            for name in dirs + files:
                link = Path(root) / name
                if not link.is_symlink():
                    continue
                try:
                    target = link.resolve(strict=True)
                except (FileNotFoundError, RuntimeError):
                    continue
                if not str(target).startswith("/nix/store/"):
                    continue
                if target.is_file():
                    fd, temp = tempfile.mkstemp(dir=root)
                    os.close(fd)
                    shutil.copy2(target, temp)
                    os.replace(temp, link)
                elif target.is_dir():
                    temp = Path(tempfile.mkdtemp(dir=root))
                    shutil.copytree(target, temp, dirs_exist_ok=True, symlinks=False)
                    link.unlink()
                    os.replace(temp, link)
        PY_BACKUP

        printf '%s\n' "$backup" > "$state/prepared"
        printf 'Configurações anteriores guardadas em: %s\n' "$backup/config"
      '';
    in
    {
      imports = [ inputs.ryoku.nixosModules.default ];

      programs.ryoku = {
        enable = true;
        defaultCompositor = "niri";
        browser = null; # Os navegadores pessoais ficam em packages.nix.
        shell = "fish";
        optionalApps = [
          "prompt"
          "fastfetch"
          "yazi"
          "cli-tools"
          "git-tools"
        ];
        updateFlake = "/home/${username}/snowflake";
        updateInput = "ryoku";
      };

      services.displayManager.defaultSession = lib.mkDefault "ryoku-niri";
      environment.systemPackages = [ pkgs.ghostty ];

      assertions = [
        {
          assertion = !(config.programs.dms-shell.enable or false);
          message = "Escolha ryoky ou DMS como shell do host: retire dms dos imports ao usar ryoky.";
        }
      ];

      home-manager.users.${username} = { config, lib, ... }: {
        assertions = [
          {
            assertion = !(config.xdg.configFile."niri/config.kdl".enable or false);
            message = "ryoky gera a base do Niri: escolha ryoky ou niri nos imports do host.";
          }
        ];

        # Neste ambiente, o materializador fornece os configs principais.
        # Os módulos genéricos continuam disponíveis para outros ambientes.
        programs.fish.enable = lib.mkForce false;
        programs.ghostty.enable = lib.mkForce false;

        xdg.configFile = {
          "niri/monitors_user.kdl".text = lib.concatMapStringsSep "\n" (m: ''
            output ${builtins.toJSON m.name} {
              mode "${toString m.width}x${toString m.height}@${toString m.refresh}"
              scale ${toString m.scale}
              transform "${
                builtins.elemAt [
                  "normal"
                  "90"
                  "180"
                  "270"
                  "flipped"
                  "flipped-90"
                  "flipped-180"
                  "flipped-270"
                ] m.transform
              }"
              position x=${toString m.x} y=${toString m.y}
            }
          '') monitors;

          # Apenas preferências de entrada. Todos os binds vêm do Ryoku/Hub.
          "niri/user.kdl".text = ''
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
                dwt
              }
            }
          '';
          "ghostty/user.conf".text = ''
            confirm-close-surface = false
          '';
        };

        # Move a configuração anterior uma única vez, após permitir escritas
        # e antes de o Home Manager instalar os novos overrides.
        home.activation.ryokuPrepare = lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ] ''
          run ${pkgs.coreutils}/bin/env \
            PATH=${
              lib.makeBinPath [
                pkgs.coreutils
                pkgs.python3
              ]
            } \
            XDG_CONFIG_HOME=${lib.escapeShellArg config.xdg.configHome} \
            XDG_STATE_HOME=${lib.escapeShellArg config.xdg.stateHome} \
            ${prepare}
        '';

        # Usa o materializador da revisão fixada no flake.lock. Gera a base,
        # as cores e os includes antes do primeiro login, inclusive em TTY.
        home.activation.ryokuMaterialize = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          run ${pkgs.coreutils}/bin/env \
            XDG_CONFIG_HOME=${lib.escapeShellArg config.xdg.configHome} \
            XDG_STATE_HOME=${lib.escapeShellArg config.xdg.stateHome} \
            XDG_DATA_HOME=${lib.escapeShellArg config.xdg.dataHome} \
            ${runtime.ryoku-materialize}/bin/ryoku-materialize
        '';
      };
    };
}
