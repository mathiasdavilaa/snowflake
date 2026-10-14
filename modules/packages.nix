{ inputs, ... }: {
  flake.nixosModules.packages =
    {
      pkgs,
      lib,
      profile,
      ...
    }:
    let
      common = [
        zenBrowser
        pkgs.zapzap
        pkgs.nautilus
      ];

      desktop = with pkgs; [
        discord
        prismLauncher
        codex
        bubblewrap
        quickshell
      ];

      laptop = with pkgs; [
        discord
      ];

      disabled = {
        desktop = [ ];
        laptop = [ ];
      };

      zenBrowser = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default;

      prismLauncher = pkgs.symlinkJoin {
        name = "prismlauncher-minecraft-wayland";
        paths = [ pkgs.prismlauncher ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram "$out/bin/prismlauncher" \
            --unset SDL_OPENGL_LIBRARY \
            --set SDL_VIDEO_DRIVER wayland \
            --set __GL_THREADED_OPTIMIZATIONS 0

          for desktop in ${pkgs.prismlauncher}/share/applications/*.desktop; do
            target="$out/share/applications/$(basename "$desktop")"
            cp --remove-destination "$desktop" "$target"
            chmod u+w "$target"
            sed -i -E \
              -e "s|^Exec=[^ ]+|Exec=$out/bin/prismlauncher|" \
              -e "s|^TryExec=.*|TryExec=$out/bin/prismlauncher|" \
              "$target"
          done
        '';
        meta = pkgs.prismlauncher.meta;
      };
    in
    {
      nixpkgs.config.allowUnfree = true;
      environment.systemPackages = lib.subtractLists disabled.${profile} (
        common ++ { inherit desktop laptop; }.${profile}
      );
    };
}
