{ self, ... }: {
  flake.nixosModules.macro = { config, username, ... }: {
    # ydotool precisa do daemon (ydotoold) para enviar eventos de entrada.
    programs.ydotool.enable = true;

    # O socket do ydotoold é 0660 do grupo ydotool: sem estar no grupo, o macro não funciona.
    users.users.${username}.extraGroups = [ config.programs.ydotool.group ];

    # ~/.local/bin no PATH (os scripts são chamados por nome/caminho).
    environment.localBinInPath = true;

    home-manager.users.${username}.home.file = {
      ".local/bin/mouse-position" = {
        source = self + "/modules/desktop/scripts/mouse-position.sh";
        executable = true;
      };

      ".local/bin/macro" = {
        source = self + "/modules/desktop/scripts/macro.sh";
        executable = true;
      };
    };
  };
}
