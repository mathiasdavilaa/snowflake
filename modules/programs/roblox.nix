{ self, ... }: {
  # Complemento opcional: remova roblox dos imports do host para desativar.
  flake.nixosModules.roblox = { config, lib, pkgs, username, ... }:
    let
      # Equilibra qualidade visual e desempenho sem forçar o perfil de gráficos reduzidos.
      soberSettings = pkgs.writeText "sober-performance.json" (builtins.toJSON {
        graphics_optimization_mode = "balanced";
        enable_gamemode = true;
      });
      ntsyncSupported = lib.versionAtLeast config.boot.kernelPackages.kernel.version "6.14";
      configureSober = pkgs.writeText "configure-sober.py" ''
        import json
        import os
        from pathlib import Path
        import subprocess
        import sys
        import tempfile
        
        path = Path(sys.argv[1])
        settings = json.loads(Path(sys.argv[2]).read_text())
        # Não disputa o arquivo de configuração com uma instância aberta do Sober.
        apps = subprocess.run([sys.argv[3], 'ps', '--columns=application'],
                              capture_output=True, text=True, check=False)
        if apps.returncode == 0 and 'org.vinegarhq.Sober' in apps.stdout.splitlines():
            print('Sober aberto: feche-o e repita o rebuild para aplicar o perfil de desempenho.')
            sys.exit(0)
        
        original = path.read_text() if path.exists() else None
        try:
            current = json.loads(original) if original is not None else {}
            if not isinstance(current, dict):
                raise ValueError('A configuração precisa ser um objeto JSON.')
        except (ValueError, json.JSONDecodeError):
            print('Configuração do Sober inválida; arquivo preservado. Corrija-o antes de repetir o rebuild.', file=sys.stderr)
            sys.exit(0)
        
        if all(current.get(key) == value for key, value in settings.items()):
            sys.exit(0)
        path.parent.mkdir(parents=True, exist_ok=True)
        # Guarda a configuração anterior uma única vez, sem substituir backups existentes.
        if original is not None:
            backup = path.with_name(path.name + '.before-performance')
            try:
                fd = os.open(backup, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
            except FileExistsError:
                pass
            else:
                with os.fdopen(fd, 'w') as stream:
                    stream.write(original)
        current.update(settings)
        with tempfile.NamedTemporaryFile(mode='w', dir=path.parent, delete=False) as stream:
            temporary = Path(stream.name)
            json.dump(current, stream, indent=2, ensure_ascii=False)
            stream.write('\n')
        try:
            os.replace(temporary, path)
        finally:
            temporary.unlink(missing_ok=True)
      '';
    in {
    imports = [ self.nixosModules.flatpak ];

    # Vinegar instala e executa o Roblox Studio usando Wine.
    services.flatpak.packages = [ "org.vinegarhq.Vinegar" ];

    # GameMode aplica o perfil da CPU somente enquanto um aplicativo o solicita.
    programs.gamemode = {
      enable = true;
      settings.general.desiredgov = lib.mkDefault "performance";
    };
    users.users.${username}.extraGroups = [ "gamemode" ];

    # NTSync acelera a sincronização do Wine quando kernel e Wine oferecem suporte.
    boot.kernelModules = lib.optionals ntsyncSupported [ "ntsync" ];
    services.udev.extraRules = lib.optionalString ntsyncSupported ''
      KERNEL=="ntsync", SUBSYSTEM=="misc", GROUP="gamemode", MODE="0660"
    '';

    home-manager.users.${username} = { config, lib, ... }: {
      # Mescla apenas os ajustes geridos aqui e mantém o JSON gravável pelo Sober.
      home.activation.robloxPerformance = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${pkgs.python3}/bin/python3 ${configureSober} \
          ${lib.escapeShellArg "${config.home.homeDirectory}/.var/app/org.vinegarhq.Sober/config/sober/config.json"} \
          ${soberSettings} ${pkgs.flatpak}/bin/flatpak
      '';
      # Rojo também fica disponível no terminal externo ao Zed.
      home.packages = [ pkgs.rojo ];
    };
  };
}
