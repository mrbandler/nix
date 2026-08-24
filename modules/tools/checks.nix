{ config, lib, ... }:
{
  flake.checks =
    let
      hosts = (config.flake.darwinConfigurations or { }) // (config.flake.nixosConfigurations or { });
      entries = lib.mapAttrsToList (name: host: {
        system = host.config.nixpkgs.hostPlatform.system;
        value = lib.nameValuePair name host.config.system.build.toplevel;
      }) hosts;
    in
    lib.mapAttrs (_: group: lib.listToAttrs (map (e: e.value) group)) (
      lib.groupBy (e: e.system) entries
    );
}
