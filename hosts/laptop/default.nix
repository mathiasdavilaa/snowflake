{ self, username, lib, ... }:
{
  imports = with self.nixosModules; [
    base
    hyprland
    mango
    plasma
    pleamar
    flatpak
    macro
    nh
    zed
    ./hardware-configuration.nix
  ];

  networking.hostName = "laptop";

  programs.pleamar-wm.extraConfig."session.conf" = lib.mkAfter ''
    monitor eDP-1 1920x1080 at 0,0 scale 1
  '';
  home-manager.users.${username} = {
    imports = [ self.homeModules.zed ];
    wayland.windowManager.mango.settings.monitorrule = [
      "name:^eDP-1$,width:1920,height:1080,x:0,y:0,scale:1,rr:0"
    ];
  };
}
