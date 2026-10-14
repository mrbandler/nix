# Linux counterpart of karabiner's fn tap: Super tapped alone (under 200ms,
# no other key in between) sends F13, which niri binds to the launcher.
# Held, or combined with another key, it stays Super.
{
  den.aspects.desktop.provides.keyd.provides.to-hosts.nixos.services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings.main.leftmeta = "overloadt2(meta, f13, 200)";
    };
  };
}
