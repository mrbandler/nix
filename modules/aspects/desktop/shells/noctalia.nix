# Noctalia v5 (nixpkgs) as the desktop shell and the greetd greeter. The
# shell is themed by stylix's noctalia target; vicinae stays the launcher, so
# noctalia's own launcher is left unbound.
{
  den.aspects.desktop.provides.noctalia = {
    provides.to-hosts =
      { user, ... }:
      {
        nixos =
          { pkgs, ... }:
          {
            programs.noctalia = {
              enable = true;
              # networkmanager, bluetooth, upower and power-profiles-daemon
              recommendedServices.enable = true;
            };

            services.displayManager.noctalia-greeter = {
              enable = true;
              # the shell's Settings > Security > Noctalia Greeter sync copies
              # wallpaper and palette over without a password prompt
              passwordlessSyncUsers = [ user.userName ];
              cursorTheme = {
                package = pkgs.bibata-cursors;
                name = "Bibata-Modern-Classic";
              };
              settings = {
                session.default = "niri";
                user.default = user.userName;
                appearance = {
                  scheme = "Catppuccin";
                  theme_mode = "dark";
                };
                keyboard = {
                  layout = "us,de";
                  options = "grp:win_space_toggle";
                };
                cursor.size = 24;
              };
            };
          };
      };

    homeManager =
      { lib, pkgs, ... }:
      lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        programs.noctalia = {
          enable = true;
          systemd.enable = true;
          settings = lib.recursiveUpdate (builtins.fromTOML (builtins.readFile ./_noctalia/settings.toml)) {
            shell.launch_apps_as_systemd_services = true;
          };
        };
      };
  };
}
