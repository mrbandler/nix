{
  den.aspects.core.nixos = {
    boot = {
      loader = {
        efi.canTouchEfiVariables = true;
        systemd-boot = {
          enable = true;
          editor = false;
          # room for a known-good generation while a new config is tried
          configurationLimit = 20;
        };
        timeout = 3;
      };
      consoleLogLevel = 4;
      tmp = {
        useTmpfs = true;
        cleanOnBoot = true;
      };
    };

    # large builds would fill the tmpfs /tmp
    systemd.services.nix-daemon.environment.TMPDIR = "/var/tmp";

    zramSwap = {
      enable = true;
      memoryPercent = 50;
      priority = 5;
      algorithm = "zstd";
    };
  };
}
