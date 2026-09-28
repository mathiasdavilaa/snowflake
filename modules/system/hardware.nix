{
  flake.nixosModules.hardware = { pkgs, ... }: {
    fonts.enableDefaultPackages = true;
    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono nerd-fonts.symbols-only
      noto-fonts-cjk-sans noto-fonts-color-emoji font-awesome
    ];
  };
}
