{
  den.aspects.cli.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
      theme = config.lib.stylix.colors.scheme-name or "unknown";
    in
    {
      programs.fastfetch = {
        enable = true;
        settings = {
          logo = {
            source = if isDarwin then "macos" else "nixos";
            padding.top = 1;
          };
          display.separator = " -> ";
          modules = [
            "title"
            "separator"
            {
              type = "os";
              key = "  OS";
            }
            {
              type = "kernel";
              key = "  Kernel";
            }
            {
              type = "host";
              key = "  Host";
            }
            {
              type = "uptime";
              key = "  Uptime";
            }
            {
              type = "packages";
              key = "  Pkgs";
            }
            "break"
            {
              type = "cpu";
              key = "  CPU";
            }
            {
              type = "gpu";
              key = "  GPU";
            }
            {
              type = "memory";
              key = "  RAM";
              percent.type = 0;
            }
            {
              type = "disk";
              key = "  Disk";
              percent.type = 0;
            }
            "break"
            {
              type = "shell";
              key = "  Shell";
            }
            {
              type = "terminal";
              key = "  Term";
            }
          ]
          # macOS has no window manager worth naming
          ++ lib.optional (!isDarwin) {
            type = "wm";
            key = "  WM";
          }
          ++ [
            {
              type = "terminalfont";
              key = "  Font";
            }
            {
              type = "command";
              key = "  Theme";
              shell = "echo ${theme}";
            }
            {
              type = "display";
              key = "  Display";
              compactType = "original-with-refresh-rate";
            }
            "break"
            "colors"
          ];
        };
      };
    };
}
