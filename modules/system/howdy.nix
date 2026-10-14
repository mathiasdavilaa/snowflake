{ ... }: {

  flake.nixosModules.howdy = { ... }: {
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
    security.pam.howdy.enable = false;
    security.pam.services.sddm.howdy = {
      enable = true;
      control = "sufficient";
    };
  };
}
