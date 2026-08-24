{
  den.aspects.apps = {
    homeManager =
      { lib, pkgs, ... }:
      {
        home.packages =
          with pkgs;
          [ telegram-desktop ] ++ lib.optionals stdenv.hostPlatform.isLinux [ whatsapp-electron ];
      };

    provides.to-hosts.darwin.homebrew.casks = [
      "whatsapp"
      "discord"
    ];
  };
}
