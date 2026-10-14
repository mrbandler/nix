{
  den.aspects.desktop.nixos =
    { pkgs, ... }:
    {
      security.rtkit.enable = true;

      services.pipewire = {
        enable = true;
        alsa = {
          enable = true;
          support32Bit = true;
        };
        pulse.enable = true;
        jack.enable = true;

        # low latency for music and recording; the keys are PipeWire's own
        # dotted names, so they must stay quoted (nested attrs are ignored)
        extraConfig.pipewire."92-low-latency"."context.properties" = {
          "default.clock.rate" = 48000;
          "default.clock.quantum" = 256;
          "default.clock.min-quantum" = 256;
          "default.clock.max-quantum" = 256;
        };
      };

      environment.systemPackages = [ pkgs.pulseaudio ];
    };
}
