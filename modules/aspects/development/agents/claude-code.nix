{
  den.aspects.development.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # Project toolchains come from devenv through direnv. The desktop app
      # never enters a direnv'd shell, so the agent's Bash commands get the
      # project environment from this hook instead (it reaches Bash only, not
      # LSP or MCP servers).
      direnvEnv = {
        type = "command";
        command = ''[ -n "$CLAUDE_ENV_FILE" ] && ${lib.getExe config.programs.direnv.package} export bash > "$CLAUDE_ENV_FILE" || true'';
      };
    in
    {
      programs.claude-code = {
        enable = true;

        # the pinned nixpkgs build, instead of an unpinned `nix run github:`
        mcpServers.nixos.command = lib.getExe pkgs.mcp-nixos;

        context = ./_claude-code/CLAUDE.md;

        settings = {
          # written by the desktop app before this file was managed; kept so
          # the takeover below loses nothing
          agentPushNotifEnabled = true;

          attribution = {
            commit = "";
            pr = "";
          };

          statusLine = {
            type = "command";
            command = "bash ${./_claude-code/statusline.sh}";
          };

          # Human in the loop at both ends: sessions start by planning, and
          # anything that leaves the machine or throws work away asks first.
          # Paths are ~/ or **/: a bare /path in user settings means ~/.claude.
          permissions = {
            defaultMode = "plan";
            ask = [
              "Bash(git push *)"
              "Bash(gh pr create *)"
              "Bash(gh pr merge *)"
              "Bash(git reset --hard *)"
              "Bash(git clean *)"
            ];
            deny = [
              "Bash(git push --force *)"
              "Bash(git push -f *)"
              "Read(~/.ssh/**)"
              "Read(~/.aws/**)"
              "Read(~/.config/gh/**)"
              "Read(~/.config/opnix/**)"
              "Read(~/.local/share/opnix/**)"
              "Read(**/.env)"
              "Read(**/.env.*)"
            ];
          };

          hooks = {
            SessionStart = [ { hooks = [ direnvEnv ]; } ];
            CwdChanged = [ { hooks = [ direnvEnv ]; } ];
          };

          extraKnownMarketplaces = {
            superpowers-marketplace.source = {
              source = "github";
              repo = "obra/superpowers-marketplace";
            };
            neoeinstein-plugins.source = {
              source = "github";
              repo = "neoeinstein/claude-plugins";
            };
            ponytail.source = {
              source = "github";
              repo = "DietrichGebert/ponytail";
            };
            trailofbits.source = {
              source = "github";
              repo = "trailofbits/skills";
            };
          };

          enabledPlugins = {
            # Core
            "superpowers@superpowers-marketplace" = true;
            "context7@claude-plugins-official" = true;
            "github@claude-plugins-official" = true;
            "remember@claude-plugins-official" = true;
            "security-guidance@claude-plugins-official" = true;
            "commit-commands@claude-plugins-official" = true;
            "linear@claude-plugins-official" = true;
            "feature-dev@claude-plugins-official" = true;
            "ponytail@ponytail" = true;

            # Review: test-gap and silent-failure reviewers the built-in
            # /code-review lacks, and CLAUDE.md upkeep
            "pr-review-toolkit@claude-plugins-official" = true;
            "claude-md-management@claude-plugins-official" = true;

            # LSP: the binaries come from each project's devenv
            "typescript-lsp@claude-plugins-official" = true;
            "rust-analyzer-lsp@claude-plugins-official" = true;
            # no Go, C#, Lua or C++ projects, and no binaries for them
            "gopls-lsp@claude-plugins-official" = false;
            "csharp-lsp@claude-plugins-official" = false;
            "clangd-lsp@claude-plugins-official" = false;
            "lua-lsp@claude-plugins-official" = false;

            # Rust
            "rust-best-practices@neoeinstein-plugins" = true;
            "rust-review@trailofbits" = true;
            "mutation-testing@trailofbits" = true;
            "property-based-testing@trailofbits" = true;

            # Tools
            # duplicates the built-in /simplify
            "code-simplifier@claude-plugins-official" = false;
            "skill-creator@claude-plugins-official" = true;
            "hookify@claude-plugins-official" = true;
            "plugin-dev@claude-plugins-official" = true;
            # opens its hosted-login page on every start; we have no semgrep
            # account, and security-guidance + /security-review cover this
            "semgrep@claude-plugins-official" = false;
            "chrome-devtools-mcp@claude-plugins-official" = true;

            # Output styles: both injected overlapping instructions into
            # every session
            "explanatory-output-style@claude-plugins-official" = false;
            "learning-output-style@claude-plugins-official" = false;
          };
        };
      };
    };
}
