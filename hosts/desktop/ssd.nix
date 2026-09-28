{
    fileSystems."/mnt/ssd" = {
      device = "/dev/disk/by-label/ssd";
      fsType = "ext4";
      options = [
        "noatime"
        "nofail"
        "x-systemd.device-timeout=5s"
      ];
    };
}