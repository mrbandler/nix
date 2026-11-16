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

      # jj usage guide, tested on jj 0.46. Its colocated section sends the
      # agent to `git checkout`; changes should go through jj only.
      jujutsuSkill = pkgs.runCommandLocal "jujutsu-skill" { } ''
        cp -r ${
          pkgs.fetchFromGitHub {
            owner = "danverbraganza";
            repo = "jujutsu-skill";
            rev = "85a8376a3a0d5cf16ecb9b0fb0f3f48a48ce62c2";
            hash = "sha256-+6xM0G/o9qHLdDogFAWI96t3lYK5h26iXyN/IPU1xC0=";
          }
        }/jujutsu $out
        chmod -R u+w $out
        sed -i '/^### Switching Between jj and git/,/^### Pushing Changes/{/^### Pushing Changes/!d}' $out/SKILL.md
        ! grep -q 'git checkout' $out/SKILL.md
      '';
    in
    {
      # opt-in flag for the i-have-adhd plugin's SessionStart hook, which then
      # injects its rules into every session (hooks/always-on.mjs)
      home.file.".claude/.i-have-adhd-always".text = "";

      programs.claude-code = {
        enable = true;

        # the pinned nixpkgs build, instead of an unpinned `nix run github:`
        mcpServers.nixos.command = lib.getExe pkgs.mcp-nixos;

        context = ./_claude-code/CLAUDE.md;

        outputStyles.absolute = ./_claude-code/output-styles/absolute.md;

        skills.jujutsu = jujutsuSkill;

        settings = {
          # matches the style's `name`, case-sensitive
          outputStyle = "Absolute";

          model = "opus";
          # keeps a session working while the primary model is unavailable
          fallbackModel = [ "sonnet" ];
          # model default is medium for the 5.5 family
          effortLevel = "high";
          # reviews often pause a session longer than the 5m default
          promptCacheTtl = "1h";
          showThinkingSummaries = true;

          # Approvals reach the phone and wait for an answer
          inputNeededNotifEnabled = true;
          dialogExpiry = "never";

          theme = "dark-ansi"; # Stylix sets the terminal ANSI colors
          timeFormat = "24-hour";
          spinnerTipsEnabled = false;
          feedbackSurveyRate = 0;
          cleanupPeriodDays = 90;

          # claude.ai synced skills that coding sessions don't need;
          # skill-creator duplicates the plugin of the same name
          skillOverrides = lib.genAttrs [
            "docx"
            "pptx"
            "xlsx"
            "docs"
            "google-workspace"
            "morning"
            "import-memory"
            "computer-use"
            "skill-creator"
          ] (_: "off");

          # Bash runs in a Seatbelt sandbox, so commands can't read secrets the
          # Read deny rules below only keep from the file tools
          sandbox = {
            enabled = true;
            filesystem = {
              denyRead = [
                "~/.ssh"
                "~/.aws"
                "~/.config/gh"
                "~/.config/opnix"
                "~/.local/share/opnix"
                "**/.env"
                "**/.env.*"
              ];
              # nix and direnv caches outside the project
              allowWrite = [
                "~/.cache/nix"
                "~/.local/state/nix"
                "~/.local/share/direnv"
              ];
            };
            network.allowUnixSockets = [ "/nix/var/nix/daemon-socket/socket" ];
          };

          # written by the desktop app before this file was managed; kept so
          # the takeover below loses nothing
          agentPushNotifEnabled = true;

          attribution = {
            commit = "";
            pr = "";
            sessionUrl = false;
          };

          statusLine = {
            type = "command";
            command = "bash ${./_claude-code/statusline.sh}";
          };

          # Human in the loop at both ends: sessions start by planning, and
          # anything that leaves the machine or throws work away asks first.
          # Paths are ~/ or **/: a bare /path in user settings means ~/.claude.
          # Commits and pushes are gated by the mrbandler plugin's hook, so a
          # session grant can allow them; an ask rule here would override it.
          permissions = {
            defaultMode = "plan";
            disableBypassPermissionsMode = "disable";
            ask = [
              "Bash(git reset --hard *)"
              "Bash(git clean *)"
              "Bash(jj abandon *)"
              "Bash(jj op restore *)"
            ];
            deny = [
              "Bash(git push --force *)"
              "Bash(git push -f *)"
              "Edit(~/.local/state/claude-grants/**)"
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
            i-have-adhd.source = {
              source = "github";
              repo = "ayghri/i-have-adhd";
            };
            caveman.source = {
              source = "github";
              repo = "JuliusBrussee/caveman";
            };
          };

          enabledPlugins = {
            # Core
            "superpowers@claude-plugins-official" = true;
            "remember@claude-plugins-official" = true;
            "security-guidance@claude-plugins-official" = true;
            "ponytail@ponytail" = true;
            "i-have-adhd@i-have-adhd" = true;
            "caveman@caveman" = true;

            # Review: test-gap and silent-failure reviewers the built-in
            # /code-review lacks, and CLAUDE.md upkeep
            "pr-review-toolkit@claude-plugins-official" = true;
            "claude-md-management@claude-plugins-official" = true;

            # LSP: devenv-lsp.nix starts the servers from each project's devenv
            # and turns off the official plugins it replaces; no Lua projects
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
            "plugin-dev@claude-plugins-official" = true;
            "chrome-devtools-mcp@claude-plugins-official" = true;

            # synced from the claude.ai account: its skills compete with
            # superpowers and /code-review, its MCP servers are unauthenticated
            "engineering@synced" = false;

            # Output styles: both injected overlapping instructions into
            # every session
            "explanatory-output-style@claude-plugins-official" = false;
            "learning-output-style@claude-plugins-official" = false;
          };
        };
      };
    };
}
