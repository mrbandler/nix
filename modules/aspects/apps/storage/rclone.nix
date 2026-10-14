# Google Drive and Proton Drive as rclone FUSE mounts on Linux (macOS uses the
# vendor apps). rclone.conf is written from the opnix secrets right before
# each mount starts, so no credential lands in the store.
{
  den.aspects.storage.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (config.lib.opnix) mkSecret;
      secrets = config.programs.onepassword-secrets.secretPaths;
      rclone = lib.getExe pkgs.rclone;
      configFile = "${config.xdg.configHome}/rclone/rclone.conf";

      writeConfig = pkgs.writeShellScript "rclone-config" ''
        set -eu
        mkdir -p "$(dirname "${configFile}")"
        umask 077
        {
          printf '[gdrive]\ntype = drive\nscope = drive\n'
          printf 'client_id = %s\n' "$(cat ${secrets.googleDriveClientId})"
          printf 'client_secret = %s\n' "$(cat ${secrets.googleDriveClientSecret})"
          printf 'token = %s\n\n' "$(cat ${secrets.googleDriveToken})"

          # rclone only accepts an obscured password in its config
          printf '[pdrive]\ntype = protondrive\n'
          printf 'username = %s\n' "$(cat ${secrets.protonDriveUsername})"
          printf 'password = %s\n' "$(${rclone} obscure "$(cat ${secrets.protonDrivePassword})")"
          printf 'otp_secret_key = %s\n' "$(cat ${secrets.protonDriveTotpSecretKey})"
        } > "${configFile}"
      '';

      mount = description: remote: mountPoint: {
        Unit = {
          Description = "rclone mount: ${description}";
          After = [ "network-online.target" ];
          Wants = [ "network-online.target" ];
        };
        Service = {
          Type = "notify";
          ExecStartPre = [
            "${pkgs.coreutils}/bin/mkdir -p ${mountPoint}"
            "${writeConfig}"
          ];
          ExecStart = "${rclone} mount ${remote}: ${mountPoint} --vfs-cache-mode writes --vfs-cache-max-age 24h --dir-cache-time 5m --tpslimit 4 --checkers 1";
          ExecStop = "/run/wrappers/bin/fusermount -u ${mountPoint}";
          Restart = "on-failure";
          RestartSec = 30;
          Environment = "PATH=/run/wrappers/bin";
        };
        Install.WantedBy = [ "default.target" ];
      };

      drives = "${config.home.homeDirectory}/.drives";
    in
    lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      home.packages = [ pkgs.rclone ];

      programs.onepassword-secrets.secrets = {
        googleDriveClientId = mkSecret "rclone-gdrive-client-id" "op://Nix/rclone-gdrive/username";
        googleDriveClientSecret = mkSecret "rclone-gdrive-client-secret" "op://Nix/rclone-gdrive/credential";
        googleDriveToken = mkSecret "rclone-gdrive-token" "op://Nix/rclone-gdrive/token";
        protonDriveUsername = mkSecret "rclone-pdrive-username" "op://Nix/rclone-pdrive/username";
        protonDrivePassword = mkSecret "rclone-pdrive-password" "op://Nix/rclone-pdrive/password";
        protonDriveTotpSecretKey = mkSecret "rclone-pdrive-otp" "op://Nix/rclone-pdrive/otp secret";
      };

      systemd.user.services = {
        rclone-gdrive = mount "Google Drive" "gdrive" "${drives}/g";
        rclone-pdrive = mount "Proton Drive" "pdrive" "${drives}/p";
      };

      # Nautilus sidebar entries
      gtk.gtk3.bookmarks = [
        "file://${drives}/g Google Drive"
        "file://${drives}/p Proton Drive"
      ];
    };
}
