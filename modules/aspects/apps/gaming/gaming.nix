# Opt-in, included by the user. Linux gets Steam, launchers and emulators with
# the system tweaks they rely on; macOS only the Steam and itch casks, Game
# Mode and controller support are built in there.
{
  den.aspects.gaming = {
    provides.to-hosts.nixos =
      { pkgs, ... }:
      {
        programs = {
          steam = {
            enable = true;
            extraCompatPackages = [ pkgs.proton-ge-bin ];
            package = pkgs.steam.override { extraEnv.MANGOHUD = true; };
          };

          gamemode = {
            enable = true;
            settings = {
              general.renice = 10;
              gpu = {
                apply_gpu_optimisations = "accept-responsibility";
                gpu_device = 0;
                amd_performance_level = "high";
              };
            };
          };
        };

        hardware = {
          xone.enable = true;
          xpadneo.enable = true;
        };

        # Wine/Proton's NT sync primitives; many games need the larger map count
        boot.kernelModules = [ "ntsync" ];
        boot.kernel.sysctl."vm.max_map_count" = 2147483642;
      };

    provides.to-hosts.darwin.homebrew.casks = [
      "steam"
      "itch"
    ];

    homeManager =
      { lib, pkgs, ... }:
      lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        home.packages = with pkgs; [
          heroic
          itch
          rpcs3
          pcsx2
          ppsspp
          retroarch
          xemu
        ];

        programs.lutris.enable = true;

        # off until toggled with Pause; Steam injects it via MANGOHUD. Defaults
        # only, stylix themes the font and colours.
        programs.mangohud = {
          enable = true;
          settings = lib.mapAttrs (_: lib.mkDefault) {
            fps_limit = 0;
            gpu_stats = true;
            gpu_temp = true;
            gpu_power = true;
            cpu_stats = true;
            cpu_temp = true;
            ram = true;
            vram = true;
            fps = true;
            frametime = true;
            frame_timing = true;
            font_size = 20;
            position = "top-left";
            toggle_hud = "Pause";
            no_display = true;
          };
        };

        systemd.user.services.steam = {
          Unit = {
            Description = "Steam, started silently";
            PartOf = [ "graphical-session.target" ];
            After = [ "graphical-session.target" ];
          };
          Service.ExecStart = "/run/current-system/sw/bin/steam -silent";
          Install.WantedBy = [ "graphical-session.target" ];
        };
      };
  };
}
