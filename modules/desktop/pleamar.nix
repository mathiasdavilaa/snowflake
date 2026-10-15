{ self, inputs, ... }: {
  flake.nixosModules.pleamar =
    { lib, pkgs, username, monitors, ... }:
    let
      marea = inputs.marea.packages.${pkgs.stdenv.hostPlatform.system}.marea;
    in {
      imports = [
        self.nixosModules.waylandBase
        inputs.pleamar-wm.nixosModules.default
      ];

      programs.pleamar-wm = {
        enable = true;
        withMarea = true;
      };

      # Marea's lock screen uses this PAM service, including unix_chkpwd.
      security.pam.services.pleamar = { };

      home-manager.users.${username}.xdg.configFile = {
        "pleamar/session.conf".text = ''
          ${lib.concatMapStringsSep "\n" (m:
            "monitor ${m.name} ${toString m.width}x${toString m.height}@${toString m.refresh} at ${toString m.x},${toString m.y} scale ${toString m.scale} transform ${toString m.transform}"
          ) monitors}

          keyboard layout us,br options caps:escape repeat 30 delay 400
          pointer accel flat
          touchpad tap on natural on dwt on
        '';

        # Session-local processes: no global Marea/Sanctuary service to overlap.
        # Upstream's agent discovery uses /usr/lib paths, absent on NixOS.
        "pleamar/autostart".text = ''
          wm: ${pkgs.swaybg}/bin/swaybg -c '#1e1e2e'
          wm: ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1
          wm: ${marea}/bin/marea start
        '';

        "pleamar/keys.conf".text = ''
          defaults
          bind Super+Return launch ghostty
          bind Super+t launch ghostty
          bind Super+e launch ghostty --title=Yazi -e yazi
          bind Super+d launch marea search
          bind Super+grave overview
          bind Super+Shift+s launch marea shot_region
          bind XF86ScreenSaver launch marea lock
        '';
      };
    };
}
