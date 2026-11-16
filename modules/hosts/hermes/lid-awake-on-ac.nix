# Keep hermes awake with the lid closed, but only on AC power, so Claude Code
# Remote Control sessions stay reachable. Power assertions (caffeinate,
# Amphetamine) cannot block lid-close sleep; the kernel SleepDisabled flag
# can. The flag is global, not per power source, so a root daemon sets it on
# AC and clears it on battery. Cost: up to 10 s delay after a plug or unplug.
{
  den.aspects.hermes.darwin =
    { pkgs, ... }:
    {
      launchd.daemons.lid-awake-on-ac.serviceConfig = {
        ProgramArguments = [
          "${pkgs.writeShellScript "lid-awake-on-ac" (builtins.readFile ./_lid-awake-on-ac/lid-awake-on-ac.sh)}"
        ];
        StartInterval = 10;
        RunAtLoad = true;
        StandardErrorPath = "/var/log/lid-awake-on-ac.log";
      };
    };
}
