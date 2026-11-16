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
      # expired timestamp); reattach lets it work inside tuios too
      security.pam.services.sudo_local = {
        touchIdAuth = true;
        reattach = true;
      };

      # keep the MacBook awake on AC power so background agents keep running;
      # the display can still sleep, and battery settings stay as they are
      system.activationScripts.power.text = ''
        pmset -c sleep 0 displaysleep 30
      '';

      # pmset cannot keep the Mac awake with the lid closed; Amphetamine can,
      # with a trigger that is active only while the power adapter is connected
      homebrew.masApps.Amphetamine = 937984704;
    };

    provides.to-users =
      { user, ... }:
      {
        homeManager = {
          programs.zen-browser.profiles.${user.name}.settings."identity.fxaccounts.account.device.name" =
            "hermes";
        };
      };
  };
}
