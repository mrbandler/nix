{ den, lib, ... }:
{
  den.aspects.mrbandler = {
    includes = [
      den.batteries.define-user
      den.batteries.primary-user
      den.aspects.cli
      den.aspects.development
      den.aspects.development.vcs
      den.aspects.apps
      den.aspects.theme
      den.aspects.security
      den.aspects.storage
      den.aspects.creative
      den.aspects.gaming
      # each desktop piece applies on its own platform only
      den.aspects.desktop.aerospace
      den.aspects.desktop.karabiner
      den.aspects.desktop.niri
      den.aspects.desktop.noctalia
      den.aspects.desktop.keyd
      den.aspects.desktop.nautilus
      den.aspects.desktop.vicinae
    ];

    homeManager =
      { config, ... }:
      {
        development.devDir = "${config.home.homeDirectory}/Develop";
      };

    # account picture for the greeter (read through AccountsService)
    provides.to-hosts.nixos.system.activationScripts.userIcon = ''
      mkdir -p /var/lib/AccountsService/icons /var/lib/AccountsService/users
      cp ${./_profiles/mrbandler.png} /var/lib/AccountsService/icons/mrbandler
      printf '[User]\nIcon=/var/lib/AccountsService/icons/mrbandler\n' > /var/lib/AccountsService/users/mrbandler
    '';

    provides.to-hosts.darwin =
      { config, ... }:
      {
        nix.settings.trusted-users = [ "mrbandler" ];

        homebrew = {
          enable = true;
          onActivation.cleanup = "zap";
          caskArgs.appdir = "~/Applications";
        };

        # upgrades run from `nx upgrade`, not on activation, where they stall
        # every rebuild with hidden output; a stable path to the generated
        # Brewfile lets `brew bundle` honour the per-cask greedy flags
        environment.etc."homebrew/Brewfile".text = config.homebrew.brewfile;

        # macOS account picture (from the old repo's nix/profiles/). The login
        # window reads the Picture path attribute; System Settings reads the
        # binary JPEGPhoto attribute, which dscl cannot write — dsimport with an
        # externalbinary record can (scriptingosx.com/2018/10/changing-a-users-login-picture).
        system.activationScripts.postActivation.text = lib.mkAfter ''
          dscl . -delete /Users/mrbandler JPEGPhoto 2>/dev/null || true
          dscl . -delete /Users/mrbandler Picture 2>/dev/null || true
          dscl . -create /Users/mrbandler Picture "${./_profiles/mrbandler.png}"
          PICTURE_IMPORT="$(mktemp)"
          printf '%s %s\n%s:%s' \
            "0x0A 0x5C 0x3A 0x2C" \
            "dsRecTypeStandard:Users 2 dsAttrTypeStandard:RecordName externalbinary:dsAttrTypeStandard:JPEGPhoto" \
            "mrbandler" "${./_profiles/mrbandler.png}" > "$PICTURE_IMPORT"

          dsimport "$PICTURE_IMPORT" /Local/Default M
          rm -f "$PICTURE_IMPORT"
        '';
      };
  };
}
