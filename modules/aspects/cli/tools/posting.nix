{
  den.aspects.cli.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      catppuccin = pkgs.fetchFromGitHub {
        owner = "catppuccin";
        repo = "posting";
        rev = "87d6a397d38061445bd76c2013cba7e604185569";
        hash = "sha256-xfoyqZ2Jz5of5PxJe6A0icobZNEyMcxBOsES51vPnZs=";
      };
    in
    {
      programs.posting = {
        enable = true;
        settings = {
          theme = "catppuccin-mocha-blue";
          layout = "vertical";
          animation = "full";
          spacing = "standard";
          response = {
            prettify_json = true;
            show_size_and_time = true;
          };
          heading = {
            visible = true;
            show_host = true;
            show_version = true;
          };
          url_bar = {
            show_value_preview = true;
            hide_secrets_in_value_preview = true;
          };
          collection_browser = {
            position = "left";
            show_on_startup = true;
          };
          focus = {
            on_startup = "url";
            on_response = "body";
            on_request_open = "url";
          };
          text_input.blinking_cursor = true;
          command_palette.theme_preview = false;
        }
        // lib.optionalAttrs config.programs.bat.enable {
          pager_json = "bat --language=json --style=plain --paging=always";
        };
      };

      # upstream keeps the themes in per-flavour folders; posting wants a flat dir
      xdg.dataFile."posting/themes" = {
        source = pkgs.runCommand "catppuccin-posting-themes" { } ''
          mkdir -p $out
          cp ${catppuccin}/themes/*/*.yaml $out/
        '';
        recursive = true;
      };
    };
}
