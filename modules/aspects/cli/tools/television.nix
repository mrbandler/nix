{
  den.aspects.cli.homeManager.programs.television = {
    enable = true;

    settings.ui.preview_panel.border_type = "rounded";

    channels = {
      files = {
        metadata = {
          name = "files";
          description = "Find files";
          requirements = [ "fd" ];
        };
        source.command = "fd --type f --hidden --follow";
        preview.command = "bat --color=always --style=plain {}";
        keybindings = {
          ctrl-e = "actions:edit";
          ctrl-o = "actions:visual";
        };
        actions = {
          edit = {
            description = "Open in $EDITOR";
            command = "$EDITOR '{}'";
            mode = "execute";
          };
          visual = {
            description = "Open in $VISUAL";
            command = "$VISUAL '{}'";
            mode = "execute";
          };
        };
      };

      ripgrep = {
        metadata = {
          name = "ripgrep";
          description = "Search file contents with ripgrep";
          requirements = [
            "rg"
            "bat"
          ];
        };
        source.command = "rg --line-number --color=never --field-match-separator='\t' .";
        preview = {
          command = "bat --color=always --style=numbers --highlight-line {split:\t:1} {split:\t:0}";
          offset = "{split:\t:1}";
        };
        keybindings = {
          ctrl-e = "actions:edit";
          ctrl-o = "actions:visual";
          shortcut = "ctrl-s";
        };
        actions = {
          edit = {
            description = "Open at line in $EDITOR";
            command = "$EDITOR +{split:\t:1} '{split:\t:0}'";
            mode = "execute";
          };
          visual = {
            description = "Open at line in $VISUAL";
            command = "$VISUAL '{split:\t:0}:{split:\t:1}'";
            mode = "execute";
          };
        };
      };
    };
  };
}
