# The LG 38GN950 switches between sRGB (editing) and HDR Effect (gaming) over
# DDC/CI: `monitor profile switch ...` in nushell, plus a watcher that holds
# sRGB while a colour-critical app is open. Values found with `ddcutil detect`
# and an OSD-diff feature scan.
{
  den.aspects.zeus.provides.to-users.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # niri app-ids; unverified since the old config, check with
      # `niri msg windows` while the apps are open
      triggerApps = [
        "Blender"
        "rapidraw"
        "darktable"
      ];

      modules = pkgs.runCommand "monitor-profiles" { } ''
        mkdir -p $out
        cp ${./_monitor-profiles/monitor-profile-switch.nu} $out/monitor-profile-switch.nu
        cat > $out/monitor-profile-config.nu <<'EOF'
        export const DISPLAY_SERIAL    = "112NTPCHM864"
        export const VCP_FEATURE       = "15"
        export const SRGB_VALUE        = "0x0f"
        export const HDR_VALUE         = "0x27"
        export const USE_SIDECHANNEL   = false
        export const SECONDARY_ENABLE  = false
        export const SECONDARY_FEATURE = ""
        export const SECONDARY_SRGB    = ""
        export const SECONDARY_HDR     = ""
        EOF
        substitute ${./_monitor-profiles/monitor-profiles-watcher.nu} $out/monitor-profiles-watcher.nu \
          --replace-fail "@SWITCH_MODULE@" "$out/monitor-profile-switch.nu"
      '';
    in
    {
      programs.nushell.extraConfig = ''
        use ${modules}/monitor-profile-switch.nu *
      '';

      systemd.user.services.monitor-profiles-watcher = {
        Unit = {
          Description = "Monitor profile auto-switcher (niri event watcher)";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${lib.getExe config.programs.nushell.package} ${modules}/monitor-profiles-watcher.nu ${lib.escapeShellArgs triggerApps}";
          Environment = "PATH=${
            lib.makeBinPath [
              pkgs.ddcutil
              pkgs.niri
            ]
          }";
          Restart = "on-failure";
          RestartSec = "5s";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    };
}
