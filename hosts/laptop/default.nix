{ self, username, ... }:
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
  home-manager.users.${username} = {
    imports = [ self.homeModules.zed ];
    wayland.windowManager.mango.settings.monitorrule = [
      "name:^eDP-1$,width:1920,height:1080,x:0,y:0,scale:1,rr:0"
    ];
  };
}
