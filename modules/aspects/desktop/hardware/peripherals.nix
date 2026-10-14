{
  den.aspects.desktop.provides.to-users.user.extraGroups = [
    "scanner"
    "lp"
  ];

  den.aspects.desktop.nixos =
    { pkgs, ... }:
    {
      hardware = {
        bluetooth = {
          enable = true;
          powerOnBoot = true;
          settings.General = {
            Enable = "Source,Sink,Media,Socket";
            Experimental = true;
          };
        };

        # DDC/CI for monitor brightness and profiles
        i2c.enable = true;

        logitech.wireless.enable = true;

        sane = {
          enable = true;
          extraBackends = [ pkgs.sane-airscan ];
        };
      };

      programs.solaar.enable = true;

      services = {
        blueman.enable = true;

        printing.enable = true;
        avahi = {
          enable = true;
          nssmdns4 = true;
          openFirewall = true;
        };

        libinput = {
          enable = true;
          touchpad = {
            naturalScrolling = false;
            tapping = true;
            scrollMethod = "twofinger";
            disableWhileTyping = true;
          };
        };
      };
    };
}
