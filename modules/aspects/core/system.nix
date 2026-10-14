{
  den.aspects.core = {
    nixos =
      { pkgs, ... }:
      {
        hardware.enableAllFirmware = true;
        services.fwupd.enable = true;

        services.journald.settings.Journal = {
          Storage = "persistent";
          MaxRetentionSec = "1month";
          MaxFileSizeMiB = 128;
          SystemMaxUse = "512M";
          RateLimitBurst = 10000;
          RateLimitIntervalSec = "30s";
          ForwardToSyslog = false;
        };

        environment = {
          variables = {
            EDITOR = "nano";
            PAGER = "less";
          };

          systemPackages = with pkgs; [
            util-linux
            file
            rsync
            tree
            curl
            wget
            unzip
            p7zip
            nmap
            nano
            git
            lshw
            pciutils
            usbutils
            killall
            htop
            nix-index
            nixd
            nil
            libnotify
            parted
            gptfdisk
            dosfstools
            ntfs3g
            exfatprogs
            btrfs-progs
            xfsprogs
            e2fsprogs
            smartmontools
            hdparm
            nvme-cli
          ];
        };
      };
  };
}
