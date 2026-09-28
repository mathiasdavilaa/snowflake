{ inputs, ... }: {
  flake.nixosModules.packages = { pkgs, lib, profile, ... }: {
    nixpkgs.config.allowUnfree = true;

    environment.systemPackages = with pkgs; [
      # =====================
      # Shared by all hosts
      # =====================
      git
      neovim
      kitty # $terminal do Hyprland (ghostty vem do programs.ghostty em ghostty.nix)
      brave-origin
      # zed-editor vem do features/dev/zed.nix (programs.zed-editor via home-manager,
      # já com LSPs/formatters/debugger configurados — não precisa duplicar aqui)
      inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default

      # usados pelas binds do Hyprland
      hyprlauncher
      brightnessctl
      playerctl
    ]
    ++ lib.optionals (profile == "desktop") [
      # =====================
      # Desktop only
      # =====================
    ]
    ++ lib.optionals (profile == "laptop") [
      # =====================
      # Laptop only
      # =====================
    ];
  };
}
