{ inputs, ... }:
{
  flake.nixosModules.packages =
    {
      pkgs,
      lib,
      profile,
      ...
    }:
    let
      # Aplica ao Prism e ao Minecraft a correção de OpenGL/Iris testada na NVIDIA.
      prismLauncher = pkgs.symlinkJoin {
        name = "prismlauncher-minecraft-wayland";
        paths = [ pkgs.prismlauncher ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram "$out/bin/prismlauncher" \
            --unset SDL_OPENGL_LIBRARY \
            --set SDL_VIDEO_DRIVER wayland \
            --set __GL_THREADED_OPTIMIZATIONS 0

          # O atalho do menu também precisa executar o Prism com a correção.
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
      environment.systemPackages =
        (with pkgs; [
          # Desktop e laptop
          git
          neovim
          kitty
          brave-origin
          inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
          hyprlauncher
          brightnessctl
          playerctl
        ])
        ++ lib.optionals (profile == "desktop") (
          with pkgs;
          [
            # Só desktop
            discord
            zapzap
            wev
            nautilus
            prismLauncher
          ]
        )
        ++ lib.optionals (profile == "laptop") (
          with pkgs;
          [
            # Só laptop
          ]
        );
    };
}
