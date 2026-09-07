{
  den.aspects.development.homeManager.programs.helix = {
    enable = true;
    defaultEditor = false; # $EDITOR is set by the env file

    settings.editor = {
      line-number = "relative";
      auto-format = true;
      auto-pairs = true;
      rulers = [
        80
        100
        120
      ];
      soft-wrap.enable = true;
      indent-guides.render = true;
      gutters = [
        "diagnostics"
        "line-numbers"
        "spacer"
        "diff"
      ];
      cursor-shape = {
        normal = "block";
        insert = "bar";
        select = "underline";
      };
      statusline = {
        left = [
          "mode"
          "spinner"
          "file-name"
          "file-modification-indicator"
        ];
        right = [
          "diagnostics"
          "selections"
          "register"
          "position"
          "file-encoding"
          "file-line-ending"
          "file-type"
        ];
      };
      lsp = {
        display-messages = true;
        display-inlay-hints = true;
      };
      file-picker = {
        hidden = false;
        git-ignore = true;
      };
    };

    languages =
      let
        prettier = name: ext: {
          inherit name;
          formatter = {
            command = "prettierd";
            args = [ ext ];
          };
          auto-format = true;
        };
      in
      {
        language-server.nushell-lsp = {
          command = "nu";
          args = [ "--lsp" ];
        };

        language = [
          {
            name = "nix";
            formatter.command = "nixfmt";
            auto-format = true;
          }
          {
            name = "toml";
            formatter = {
              command = "taplo";
              args = [
                "fmt"
                "-"
              ];
            };
            auto-format = true;
          }
          (prettier "javascript" ".js")
          (prettier "typescript" ".ts")
          (prettier "jsx" ".jsx")
          (prettier "tsx" ".tsx")
          (prettier "html" ".html")
          (prettier "css" ".css")
          (prettier "json" ".json")
          (prettier "yaml" ".yaml")
          (prettier "markdown" ".md")
          {
            name = "nu";
            language-servers = [ "nushell-lsp" ];
          }
        ];
      };
  };
}
