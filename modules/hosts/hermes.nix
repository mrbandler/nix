{
  den.hosts.aarch64-darwin.hermes.users.mrbandler = { };

  den.aspects.hermes = {
    darwin = {
      networking = {
        hostName = "hermes";
        computerName = "Hermes";
        localHostName = "hermes";
      };

      # the MacBook's Touch ID answers sudo (brew cask upgrades ask once per
      # expired timestamp); reattach lets it work inside zellij/tuios too
      security.pam.services.sudo_local = {
        touchIdAuth = true;
        reattach = true;
      };
    };

    provides.to-users =
      { user, ... }:
      {
        homeManager = {
          stylix.image = ../aspects/theme/_wallpapers/16-9/mocha-2560x1440.png;
          programs.zen-browser.profiles.${user.name}.settings."identity.fxaccounts.account.device.name" =
            "hermes";
        };
      };
  };
}
