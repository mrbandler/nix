{
  den.aspects.apps = {
    homeManager =
      { lib, pkgs, ... }:
      {
        home.packages = with pkgs; [
          telegram-desktop
          zapfast
        ];

        # nixpkgs' discord is unreliable on Linux; vesktop is themed by stylix
        programs.vesktop = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
          enable = true;
          settings = {
            discordBranch = "stable";
            minimizeToTray = true;
            arRPC = true;
            checkUpdates = false;
            customTitleBar = false;
            splashTheming = true;
            hardwareAcceleration = true;
          };
        };
      };

    provides.to-hosts.darwin.homebrew.casks = [ "discord" ];
  };
}
