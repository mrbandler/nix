{ den, lib, ... }:
{
  den.aspects.mrbandler = {
    includes = [
      den.batteries.define-user
      den.batteries.primary-user
      den.aspects.apps
      den.aspects.theme
      den.aspects.security
      den.aspects.storage
      den.aspects.desktop.paneru
      den.aspects.desktop.vicinae
      den.aspects.desktop.karabiner
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.htop
          pkgs.zed-editor
        ];
        programs.git = {
          enable = true;
          settings.user = {
            name = "mrbandler";
            email = "me@mrbandler.dev";
          };
        };
      };

    provides.to-hosts.darwin = {
      nix.settings.trusted-users = [ "mrbandler" ];

      homebrew = {
        enable = true;
        onActivation.cleanup = "zap";
        caskArgs.appdir = "~/Applications";
        casks = [ "claude" ];
      };

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

    provides.to-hosts.nixos = {
    };
  };
}
