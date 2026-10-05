{ self, ... }:
{
  flake.nixosModules.base = { pkgs, username, ... }: {
    imports = with self.nixosModules; [
      homeManager boot packages
      fish ghostty git fastfetch
    ];

    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    nix.optimise.automatic = true;
    networking.networkmanager.enable = true;

    fonts.enableDefaultPackages = true;
    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only
      nerd-fonts.geist-mono
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      font-awesome
    ];

    # Tela de login independente de qualquer ambiente desktop.
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
    services.displayManager.defaultSession = "plasma";

    services.xserver.enable = true;
    services.xserver.xkb.layout = "us";
    services.printing.enable = true;
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    time.timeZone = "America/Sao_Paulo";
    i18n.defaultLocale = "en_US.UTF-8";
    i18n.extraLocaleSettings = builtins.listToAttrs (map
      (name: { inherit name; value = "pt_BR.UTF-8"; })
      [ "LC_ADDRESS" "LC_IDENTIFICATION" "LC_MEASUREMENT" "LC_MONETARY"
        "LC_NAME" "LC_NUMERIC" "LC_PAPER" "LC_TELEPHONE" "LC_TIME" ]);

    users.users.${username} = {
      isNormalUser = true;
      extraGroups = [ "networkmanager" "wheel" ];
    };
    system.stateVersion = "26.05";
  };
}
