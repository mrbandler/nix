{
  den.aspects.creative = {
    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        catppuccin = pkgs.fetchFromGitHub {
          owner = "catppuccin";
          repo = "godot";
          rev = "d8b72b679078f0103a5e5c1ef793c1d698a563b1";
          hash = "sha256-Og69rMEsygVYpWVGvJGsCydQzRC9BXBQxyrJ4kfdUEo=";
        };
        # only the text editor theme is a file; the interface colours live in
        # Godot's own editor_settings-*.tres, set by hand (see upstream README)
        theme = "${catppuccin}/themes/Catppuccin Mocha.tet";

        settingsDir =
          if pkgs.stdenv.hostPlatform.isDarwin then
            "${config.home.homeDirectory}/Library/Application Support/Godot"
          else
            "${config.xdg.configHome}/godot";

        # values from the upstream README; a preset other than Custom makes
        # Godot ignore the colours below
        settings = {
          "text_editor/theme/color_theme" = ''"Catppuccin Mocha"'';
          "interface/theme/color_preset" = ''"Custom"'';
          "interface/theme/base_color" = "Color(0.118, 0.118, 0.18, 1)"; # 1e1e2e
          "interface/theme/accent_color" = "Color(0.796, 0.651, 0.969, 1)"; # cba6f7
          "interface/theme/contrast" = "0.2";
          "interface/theme/icon_saturation" = "0.6";
        };
      in
      {
        home.packages = lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.godot_4 ];

        xdg.configFile."godot/text_editor_themes/Catppuccin Mocha.tet" =
          lib.mkIf pkgs.stdenv.hostPlatform.isLinux { source = theme; };
        home.file."Library/Application Support/Godot/text_editor_themes/Catppuccin Mocha.tet" =
          lib.mkIf pkgs.stdenv.hostPlatform.isDarwin { source = theme; };

        # Godot owns its editor settings (one file per minor version) and
        # rewrites them on exit, so the theme keys are set in place in every
        # file Godot has created; a version not launched yet is picked up by
        # the next switch after its first launch
        home.activation.godotTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          for f in ${lib.escapeShellArg settingsDir}/editor_settings-4.*.tres; do
            [ -e "$f" ] || continue
            ${lib.concatLines (
              lib.mapAttrsToList (key: value: ''
                if grep -q ${lib.escapeShellArg "^${key} = "} "$f"; then
                  run sed -i ${lib.escapeShellArg "s|^${key} = .*|${key} = ${value}|"} "$f"
                else
                  run sed -i ${lib.escapeShellArg "$a ${key} = ${value}"} "$f"
                fi
              '') settings
            )}
          done
        '';
      };

    provides.to-hosts.darwin.homebrew.casks = [ "godot" ];
  };
}
