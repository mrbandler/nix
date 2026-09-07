{
  den.aspects.development = {
    homeManager =
      { lib, pkgs, ... }:
      {
        programs.vscode = {
          enable = true;
          # vendor-signed app: the cask keeps Gatekeeper happy on macOS
          package = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin null;
        };
      };

    provides.to-hosts.darwin.homebrew.casks = [ "visual-studio-code" ];
  };
}
