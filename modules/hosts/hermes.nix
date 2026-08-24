{
  den.hosts.aarch64-darwin.hermes.users.mrbandler = { };

  den.aspects.hermes = {
    darwin = {
      networking = {
        hostName = "hermes";
        computerName = "Hermes";
        localHostName = "hermes";
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
