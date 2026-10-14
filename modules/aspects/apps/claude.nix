# Claude Desktop: the cask on macOS; on Linux the community repack, as there
# is no official build. Its input keeps its own nixpkgs (the repack is
# pinned against it upstream).
{ inputs, ... }:
{
  flake-file.inputs.claude-desktop.url = "github:k3d3/claude-desktop-linux-flake";

  den.aspects.apps = {
    provides.to-hosts.darwin.homebrew.casks = [ "claude" ];

    homeManager =
      { lib, pkgs, ... }:
      {
        home.packages = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          inputs.claude-desktop.packages.${pkgs.stdenv.hostPlatform.system}.claude-desktop
        ];
      };
  };
}
