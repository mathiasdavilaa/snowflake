{ self, ... }: {
  # Base compartilhada por todos os hosts: sistema, locale, áudio, usuário, fontes
  # e as features de shell/dev. O que é de uma máquina só (hostname, hardware,
  # sessões gráficas) fica em hosts/<host>/.
  flake.nixosModules.common = { pkgs, username, ... }: {
    imports = [
      self.nixosModules.packages
      self.nixosModules.homeManager
      self.nixosModules.fish
      self.nixosModules.ghostty
      self.nixosModules.git
      self.nixosModules.fastfetch
    ];

    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    nix.optimise.automatic = true;

    boot.loader.systemd-boot.enable = false;
    boot.loader.limine = {
      enable = true;
      efiSupport = true;
    };
    boot.loader.efi.canTouchEfiVariables = true;

    networking.networkmanager.enable = true;

    time.timeZone = "America/Sao_Paulo";
    i18n.defaultLocale = "en_US.UTF-8";
    i18n.extraLocaleSettings = {
      LC_ADDRESS = "pt_BR.UTF-8";
      LC_IDENTIFICATION = "pt_BR.UTF-8";
      LC_MEASUREMENT = "pt_BR.UTF-8";
      LC_MONETARY = "pt_BR.UTF-8";
      LC_NAME = "pt_BR.UTF-8";
      LC_NUMERIC = "pt_BR.UTF-8";
      LC_PAPER = "pt_BR.UTF-8";
      LC_TELEPHONE = "pt_BR.UTF-8";
      LC_TIME = "pt_BR.UTF-8";
    };

    services.xserver.enable = true;
    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

    services.printing.enable = true;

    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    users.users.${username} = {
      isNormalUser = true;
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
    };

    # Sem fontes o Marea/pleamar (fontconfig) e o fastfetch (glifos nerd font) ficam sem texto/ícones.
    fonts = {
      enableDefaultPackages = true;
      packages = with pkgs; [
        nerd-fonts.jetbrains-mono
        nerd-fonts.symbols-only
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
        font-awesome
      ];
    };

    system.stateVersion = "26.05";
  };
}
