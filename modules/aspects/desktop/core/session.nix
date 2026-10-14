# The Wayland session plumbing a Linux desktop host needs regardless of the
# compositor: graphics, portals, polkit, fonts, file-manager services.
{
  den.aspects.desktop.nixos =
    { pkgs, ... }:
    {
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };

      security.polkit.enable = true;
      programs.dconf.enable = true;

      xdg.portal = {
        enable = true;
        xdgOpenUsePortal = true;
      };

      services = {
        gvfs.enable = true;
        tumbler.enable = true;
      };

      environment = {
        systemPackages = with pkgs; [
          xdg-utils
          xdg-user-dirs
          wayland-utils
          wl-clipboard
          playerctl
        ];
        sessionVariables = {
          NIXOS_OZONE_WL = "1";
          MOZ_ENABLE_WAYLAND = "1";
          QT_QPA_PLATFORM = "wayland";
        };
      };

      fonts = {
        enableDefaultPackages = false;
        packages = with pkgs; [
          inter
          roboto
          jetbrains-mono
          fira-code
          nerd-fonts.jetbrains-mono
          nerd-fonts.fira-code
          nerd-fonts.meslo-lg
          nerd-fonts.symbols-only
          symbola
          noto-fonts-color-emoji
          noto-fonts-cjk-sans
          corefonts
          vista-fonts
        ];
        fontconfig = {
          antialias = true;
          hinting.style = "slight";
          subpixel.rgba = "rgb";
          defaultFonts = {
            serif = [
              "Liberation Serif"
              "DejaVu Serif"
            ];
            sansSerif = [
              "Inter"
              "Roboto"
              "Liberation Sans"
              "DejaVu Sans"
            ];
            monospace = [
              "JetBrainsMono Nerd Font"
              "JetBrains Mono"
              "Fira Code"
            ];
            emoji = [ "Noto Color Emoji" ];
          };
        };
      };
    };
}
