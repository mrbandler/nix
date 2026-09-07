# The development directory. Identity contexts and the direnv whitelist hang
# off it; a host whose layout differs sets it through provides.to-users.
{ config, lib, ... }:
{
  options.development.devDir = lib.mkOption {
    type = lib.types.str;
    default = "${config.home.homeDirectory}/dev";
    description = "Base path of the development directories.";
  };
}
