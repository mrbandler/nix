# Desktop PC: AMD CPU and GPU, LG 38GN950 (DP-1) above a 1080p screen (DP-2).
# Dual-boots Windows from the firmware boot menu until the next install with
# the install tool, which gives the whole disk to disko.
{ den, ... }:
{
  den.hosts.x86_64-linux.zeus.users.mrbandler = { };

  den.aspects.zeus = {
    includes = [ den.aspects.desktop ];

    nixos =
      { lib, pkgs, ... }:
      {
        # the hand-made install's hardware file, until the install tool writes
        # facter.json and disko takes over the disk
        imports = lib.optional (!builtins.pathExists ./facter.json) ./_hardware-configuration.nix;

        # installed at 25.11; stateful services follow it, never bump blindly
        system.stateVersion = "25.11";

        networking.hostName = "zeus";

        boot.kernelPackages = pkgs.linuxPackages_latest;

        hardware = {
          amdgpu = {
            initrd.enable = true;
            opencl.enable = true;
          };
          keyboard.uhk.enable = true;
        };
        environment.sessionVariables = {
          LIBVA_DRIVER_NAME = "radeonsi";
          VDPAU_DRIVER = "radeonsi";
        };

        services = {
          xserver = {
            videoDrivers = [ "amdgpu" ];
            wacom.enable = true;
          };
          hardware.openrgb = {
            enable = true;
            motherboard = "amd";
          };
        };

        virtualisation = {
          docker = {
            enable = true;
            rootless = {
              enable = true;
              setSocketVariable = true;
            };
          };
          libvirtd = {
            enable = true;
            qemu.swtpm.enable = true;
          };
        };
        programs.virt-manager.enable = true;
        users.users.mrbandler.extraGroups = [
          "docker"
          "libvirtd"
        ];

        # `nixos-rebuild build-vm` only; the real system is untouched. The
        # VM starts with a fresh disk, so it needs its own login.
        virtualisation.vmVariant = {
          users.users.mrbandler.initialPassword = "password";
          virtualisation = {
            memorySize = 8192;
            cores = 4;
            # niri needs OpenGL; the default VGA has none
            qemu.options = [
              "-vga none"
              "-device virtio-vga-gl"
              "-display gtk,gl=on"
            ];
          };
        };
      };

    provides.to-users.homeManager =
      { config, pkgs, ... }:
      {
        # installed at 25.11: keep the paths that release used, where the
        # existing profile data lives
        home.stateVersion = "25.11";

        programs = {
          zsh.dotDir = config.home.homeDirectory;
          firefox.configPath = ".mozilla/firefox";
          zen-browser.profiles.${config.home.username}.settings."identity.fxaccounts.account.device.name" =
            "zeus";
        };

        home.packages = with pkgs; [
          # the app copies its docs from the store read-only, then fails to
          # update them; make them writable before every start
          (uhk-agent.overrideAttrs (old: {
            postFixup = (old.postFixup or "") + ''
              wrapProgram $out/bin/uhk-agent \
                --run 'chmod -R u+w "$HOME/.config/uhk-agent/smart-macro-docs" 2>/dev/null || true'
            '';
          }))
          ddcutil
          ddcui
          system-config-printer
        ];

        # output- and place-specific parts of the Noctalia setup
        programs.noctalia.settings =
          let
            loginBox = output: cx: cy: width: height: {
              inherit output cx cy;
              type = "login_box";
              box_width = 810.0;
              box_height = 196.0;
              placement_width = width;
              placement_height = height;
              rotation = 0.0;
              settings = {
                background_color = "surface_variant";
                background_opacity = 0.88;
                background_radius = 12.0;
                center_password_text = false;
                input_opacity = 1.0;
                input_radius = 6.0;
                layout = "regular";
                show_caps_lock = true;
                show_keyboard_layout = true;
                show_login_button = true;
                show_media = true;
                show_session_buttons = true;
                show_unlock_hint = true;
                show_weather = true;
              };
            };
          in
          {
            brightness.enable_ddcutil = true;
            location = {
              latitude = 48.5264991;
              longitude = 12.2662454;
            };
            lockscreen_widgets = {
              widget_order = [
                "lockscreen-login-box@DP-1"
                "lockscreen-login-box@DP-2"
              ];
              widget = {
                "lockscreen-login-box@DP-1" = loginBox "DP-1" 1920.0 1418.0 3840.0 1600.0;
                "lockscreen-login-box@DP-2" = loginBox "DP-2" 960.0 898.0 1920.0 1080.0;
              };
            };
          };

        desktop.niri.extraConfig = ''
          output "DP-1" {
            mode "3840x1600@74.977"
            position x=0 y=0
            variable-refresh-rate
          }

          output "DP-2" {
            mode "1920x1080@60.000"
            position x=960 y=1600
            variable-refresh-rate
          }

          workspace "1" { open-on-output "DP-2"; }
          workspace "2" { open-on-output "DP-2"; }
          workspace "3" { open-on-output "DP-2"; }

          window-rule {
            match app-id="^zen"
            exclude title="Private Browsing"
            match title="^Claude$"
            open-on-workspace "1"
            default-column-width { proportion 1.0; }
          }

          window-rule {
            match app-id="^zapfast$"
            match app-id="^org\\.telegram\\.desktop$"
            open-on-workspace "2"
            default-column-width { proportion 0.5; }
          }

          window-rule {
            match app-id="^vesktop$"
            open-on-workspace "2"
            default-column-width { proportion 1.0; }
          }

          window-rule {
            match app-id="^spotifast$"
            open-on-workspace "3"
            default-column-width { proportion 1.0; }
          }

          spawn-at-startup "zen-beta"
          spawn-at-startup "claude-desktop"
          spawn-at-startup "zapfast"
          spawn-at-startup "Telegram"
          spawn-at-startup "vesktop"
          spawn-at-startup "spotifast"
        '';
      };
  };
}
