{ ... }:
{
  flake.nixosModules.howdy = { config, lib, pkgs, username, ... }:
    let
      patchLock = pkgs.writeShellScript "snowflake-howdy-ryoku" ''
        exec ${pkgs.python3}/bin/python3 ${./howdy-ryoku.py}
      '';
    in
    {
      services.howdy = {
        enable = true;
        control = "sufficient";
        settings = {
          core = {
            no_confirmation = true;
            timeout_notice = false;
          };
          video = {
            device_path = "/dev/v4l/by-id/usb-Chicony_Electronics_Co._Ltd._Integrated_Camera_0001-video-index0";
            frame_width = 640;
            frame_height = 360;
            timeout = 8;
            force_mjpeg = false;
          };
        };
      };

      services.linux-enable-ir-emitter = {
        enable = true;
        device = "video2";
      };

      # Enable facial authentication for the Ryoku lockscreen and SDDM.
      security.pam.howdy.enable = false;
      security.pam.services.sddm.howdy = {
        enable = true;
        control = "sufficient";
      };
      security.pam.services.ryoku-howdy = {
        howdy = {
          enable = true;
          control = "sufficient";
        };
        unixAuth = false;
        fprintAuth = false;
      };

      # Quickshell runs as the user, so it needs access to the IR camera and
      # read-only access to this user's face model. Models stay root-owned.
      users.groups.howdy = { };
      users.users.${username}.extraGroups = [ "video" "howdy" ];
      systemd.tmpfiles.rules = [
        "d /var/lib/howdy 0750 root howdy - -"
        "d /var/lib/howdy/models 0750 root howdy - -"
        "z /var/lib/howdy/models/${username}.dat 0640 root howdy - -"
      ];

      # Upstream regenerates the lockscreen on login and generation changes.
      # Run after its materializer, then add the independent face conversation.
      systemd.user.services.ryoku-materialize.serviceConfig.ExecStartPost =
        lib.mkAfter [ "${patchLock}" ];
      systemd.user.services.ryoku-materialize.restartTriggers = [ patchLock ];

      home-manager.users.${username} = { lib, ... }: {
        home.activation.ryokuHowdy = lib.hm.dag.entryAfter [ "ryokuMaterialize" ] ''
          run ${patchLock}
        '';
      };

      assertions = [
        {
          assertion = config.programs.ryoku.enable;
          message = "O módulo howdy deste flake integra a lockscreen do Ryoku.";
        }
      ];
    };
}
