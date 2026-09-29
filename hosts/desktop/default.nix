{ self, username, lib, ... }:
{
  imports = with self.nixosModules; [
    base
    graphics
    optimization
    hyprland
    mango
    plasma
    pleamar
    flatpak
    macro
    nh
    zed
    ./hardware-configuration.nix
    ./ssd.nix
  ];

  networking.hostName = "tarnished";

  # Mesmo posicionamento físico do Mango, sem depender da config do Hyprland.
  programs.pleamar-wm.extraConfig."session.conf" = lib.mkAfter ''
    monitor HDMI-A-1 1920x1080 at 0,0 scale 1 transform 90
    monitor DP-3 1920x1080 at 1080,0 scale 1
  '';
  home-manager.users.${username} = {
    imports = [ self.homeModules.zed ];

    # Regras específicas do monitor físico; o módulo Mango é compartilhável.
    wayland.windowManager.mango.settings = {
      monitorrule = [
        "name:^HDMI-A-1$,width:1920,height:1080,x:0,y:0,scale:1,rr:1"
        "name:^DP-3$,width:1920,height:1080,x:1080,y:0,scale:1,rr:0"
      ];
      tagrule = map (i: "id:${toString i},monitor_name:HDMI-A-1,layout_name:vertical_scroller") (lib.range 1 9)
        ++ map (i: "id:${toString i},monitor_name:DP-3,layout_name:scroller") (lib.range 1 9);
    };
  };
}
