{
  den.aspects.core.nixos.nix = {
    settings = {
      auto-optimise-store = true;
      trusted-users = [
        "root"
        "@wheel"
      ];
      min-free = 100 * 1024 * 1024;
      max-free = 1024 * 1024 * 1024;
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };
}
