{ config, lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      hosts = (config.flake.darwinConfigurations or { }) // (config.flake.nixosConfigurations or { });
      installedPackages =
        host:
        host.config.environment.systemPackages
        ++ lib.concatMap (user: user.home.packages) (
          lib.attrValues (host.config.home-manager.users or { })
        );
      hostsJson = pkgs.writeText "hosts.json" (
        builtins.toJSON (
          lib.mapAttrs (_: host: {
            system = host.config.nixpkgs.hostPlatform.system;
            packages = lib.unique (
              map (p: {
                name = lib.getName p;
                version = lib.getVersion p;
              }) (installedPackages host)
            );
          }) hosts
        )
      );
    in
    {
      packages.update-report = pkgs.writers.writePython3Bin "update-report" {
        flakeIgnore = [ "E501" ];
        makeWrapperArgs = [
          "--set"
          "UPDATE_REPORT_HOSTS"
          "${hostsJson}"
          "--prefix"
          "PATH"
          ":"
          (lib.makeBinPath (
            with pkgs;
            [
              hydra-check
              nvd
              gh
            ]
          ))
        ];
      } (builtins.readFile ./_update-report/update_report.py);
    };
}
