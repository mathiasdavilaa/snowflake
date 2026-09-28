{ inputs, ... }:
{
  flake.nixosModules.packages = { pkgs, lib, profile, ... }: {
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
      ++ lib.optionals (profile == "desktop") (with pkgs; [
        # Só desktop
        discord
      ])
      ++ lib.optionals (profile == "laptop") (with pkgs; [
        # Só laptop
      ]);
  };
}
