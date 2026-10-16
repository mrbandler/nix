# The one disk layout every NixOS host shares, applied by disko when the host
# sets disk.device: an EFI partition and a btrfs partition with subvolumes.
# `/` sits on its own subvolume and /persist exists from the start, so wiping
# `/` at boot (system-level impermanence) can be turned on later without a
# reinstall. Hosts without disk.device keep their hand-made partitioning.
{ inputs, lib, ... }:
{
  flake-file.inputs.disko = {
    url = "github:nix-community/disko";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # the hardware report the install writes to modules/hosts/<host>/facter.json
  # replaces a generated hardware-configuration.nix
  den.aspects.core.includes = [
    (
      { host, ... }:
      let
        report = ../../hosts + "/${host.name}/facter.json";
      in
      {
        nixos.hardware.facter.reportPath = lib.mkIf (builtins.pathExists report) report;
      }
    )
  ];

  den.aspects.core.nixos =
    { config, lib, ... }:
    let
      cfg = config.disk;
      mountOptions = [
        "compress=zstd"
        "noatime"
      ];
    in
    {
      imports = [ inputs.disko.nixosModules.disko ];

      options.disk.device = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_2TB_S6B0NL0W123456";
        description = "The disk the install wipes and lays out; a stable /dev/disk/by-id path.";
      };

      config = lib.mkIf (cfg.device != null) {
        disko.devices.disk.main = {
          type = "disk";
          inherit (cfg) device;
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                size = "1G";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [ "umask=0077" ];
                };
              };
              root = {
                size = "100%";
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes = {
                    "/root" = {
                      mountpoint = "/";
                      inherit mountOptions;
                    };
                    "/home" = {
                      mountpoint = "/home";
                      inherit mountOptions;
                    };
                    # snapper keeps the /home snapshots in here
                    "/home/.snapshots" = { };
                    "/nix" = {
                      mountpoint = "/nix";
                      inherit mountOptions;
                    };
                    "/persist" = {
                      mountpoint = "/persist";
                      inherit mountOptions;
                    };
                  };
                };
              };
            };
          };
        };

        fileSystems."/persist".neededForBoot = true;

        services.snapper.configs.home = {
          SUBVOLUME = "/home";
          ALLOW_GROUPS = [ "wheel" ];
          TIMELINE_CREATE = true;
          TIMELINE_CLEANUP = true;
          TIMELINE_LIMIT_HOURLY = 24;
          TIMELINE_LIMIT_DAILY = 7;
          TIMELINE_LIMIT_WEEKLY = 4;
          TIMELINE_LIMIT_MONTHLY = 3;
          TIMELINE_LIMIT_YEARLY = 0;
        };
      };
    };
}
