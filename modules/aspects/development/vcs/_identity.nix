# Who commits where, and how commits get signed. Shared by git.nix and jj.nix.
{ devDir, pkgs }:
{
  default = {
    name = "mrbandler";
    email = "me@mrbandler.dev";
  };

  contexts = {
    "${devDir}/mrbandler" = {
      name = "mrbandler";
      email = "me@mrbandler.dev";
    };
    "${devDir}/ss" = {
      name = "Michael Baudler";
      email = "michael.baudler@smokingsquid.games";
    };
    "${devDir}/la" = {
      name = "mrbandler";
      email = "mrbandler@leakyabstractions.dev";
    };
  };

  signing = {
    key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG2G7J57J+2prp4UH/oWhIk6q+/rrvIhlsCypkK6Ak+d";
    # 1Password's signer: the cask app on macOS, the nixpkgs build on Linux
    program =
      if pkgs.stdenv.hostPlatform.isDarwin then
        "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
      else
        "${pkgs._1password-gui}/bin/op-ssh-sign";
  };
}
