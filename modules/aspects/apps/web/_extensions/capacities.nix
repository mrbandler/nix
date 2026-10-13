# The official Capacities web extension. Not in the NUR firefox-addons set, so
# it is pinned to the AMO release here; bump version, url and sha256 together
# from https://addons.mozilla.org/api/v5/addons/addon/capacities-web-extension/
{ lib, buildFirefoxXpiAddon }:
buildFirefoxXpiAddon {
  pname = "capacities-web-extension";
  version = "1.5.10";
  addonId = "team@capacities.io";
  url = "https://addons.mozilla.org/firefox/downloads/file/4451722/capacities_web_extension-1.5.10.xpi";
  sha256 = "22f62d65316afce41564d5da68d164931e8c044fc6564f2260dc69f4421b6688";
  meta = {
    homepage = "https://capacities.io";
    description = "Save websites to Capacities";
    license = lib.licenses.unfree;
    platforms = lib.platforms.all;
  };
}
