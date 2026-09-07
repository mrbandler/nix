{
  den.aspects.cli.homeManager =
    { config, pkgs, ... }:
    let
      tomlFormat = pkgs.formats.toml { };
      # harlequin resolves its config dir with platformdirs, which on macOS is
      # ~/Library/Application Support rather than ~/.config
      configDir =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "Library/Application Support/harlequin"
        else
          "${config.xdg.configHome}/harlequin";
    in
    {
      home.packages = with pkgs; [
        harlequin
        python3Packages.harlequin-postgres
      ];

      home.file."${configDir}/config.toml".source = tomlFormat.generate "harlequin-config.toml" {
        default_profile = "local";
        profiles.local = {
          adapter = "duckdb";
          theme = "catppuccin-mocha";
          limit = 100000;
          keymap_name = [ "vscode" ];
        };
      };
    };
}
