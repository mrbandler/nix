{
  den.aspects.apps = {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          telegram-desktop
          zapfast
        ];
      };

    provides.to-hosts.darwin.homebrew.casks = [ "discord" ];
  };
}
