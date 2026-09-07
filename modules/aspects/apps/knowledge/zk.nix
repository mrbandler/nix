{
  den.aspects.apps.homeManager =
    { config, lib, ... }:
    {
      programs.zk = {
        enable = true;
        settings = {
          note = {
            filename = "{{id}}-{{slug title}}";
            extension = "md";
            template = "";
            id-charset = "alphanum";
            id-length = 4;
            id-case = "lower";
          };
          editor.command = "hx";
          format.markdown = {
            link-format = "markdown";
            hashtags = true;
          };
          lsp.diagnostics = {
            wiki-title = "hint";
            dead-link = "error";
          };
          tool =
            lib.optionalAttrs config.programs.bat.enable {
              pager = "bat --style=plain";
            }
            // lib.optionalAttrs config.programs.fzf.enable {
              fzf-preview = "bat --color=always --style=plain {-1}";
            };
        };
      };
    };
}
