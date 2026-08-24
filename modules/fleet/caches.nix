let
  caches = {
    extra-substituters = [
      "https://mrbandler.cachix.org"
      "https://vicinae.cachix.org"
    ];
    extra-trusted-public-keys = [
      "mrbandler.cachix.org-1:c8vkDjwmPK1VSMaLG9Qbu3J1tPX3mlmQagt5cOvrDCo="
      "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
    ];
  };
in
{
  flake-file.nixConfig = caches;

  den.default = {
    darwin.nix.settings = caches;
    nixos.nix.settings = caches;
  };
}
