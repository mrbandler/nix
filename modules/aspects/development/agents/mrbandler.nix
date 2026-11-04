{
  den.aspects.development.homeManager =
    { lib, pkgs, ... }:
    let
      # CLAUDE.md bans em dashes and self credit in anything written for me.
      # A prompt rule can slip; this hook blocks the tool call instead, for
      # files and for commands that publish text. Chat replies stay a prompt
      # rule, since no hook sees them.
      guard = pkgs.writeShellApplication {
        name = "mrbandler-text-guard";
        runtimeInputs = [ pkgs.jq ];
        text = ''
          # the character itself would trip this guard on its own source
          emdash=$'\xe2\x80\x94'

          input=$(cat)
          tool=$(jq -r '.tool_name' <<<"$input")
          text=$(jq -r '
            .tool_input as $i
            | if .tool_name == "Bash" then $i.command
              elif .tool_name == "Write" then $i.content
              elif .tool_name == "Edit" then $i.new_string
              elif .tool_name == "MultiEdit" then [$i.edits[].new_string] | join("\n")
              else "" end
            // ""' <<<"$input")

          # other commands may well mention an em dash, e.g. a grep for one
          if [ "$tool" = Bash ] && ! grep -Eq \
            '(git (commit|tag)|jj (describe|commit|new)|gh (pr|issue|release) (create|edit|comment))' \
            <<<"$text"; then
            exit 0
          fi

          block() {
            echo "Blocked by mrbandler-text-guard: $1. Rewrite the text and retry." >&2
            exit 2
          }
          grep -qF "$emdash" <<<"$text" && block "it contains an em dash"
          grep -qiF "co-authored-by" <<<"$text" && block "it contains a Co-Authored-By trailer"
          grep -qF "Generated with Claude Code" <<<"$text" && block "it contains a Claude Code credit line"
          exit 0
        '';
      };

      plugin = pkgs.writeTextDir ".claude-plugin/plugin.json" (
        builtins.toJSON {
          name = "mrbandler";
          version = "0.1.0";
          description = "Michael's own hooks, skills and commands";
          hooks.PreToolUse = [
            {
              matcher = "Bash|Write|Edit|MultiEdit";
              hooks = [
                {
                  type = "command";
                  command = lib.getExe guard;
                }
              ];
            }
          ];
        }
      );
      marketplace = pkgs.symlinkJoin {
        name = "mrbandler-marketplace";
        paths = [
          plugin
          (pkgs.writeTextDir ".claude-plugin/marketplace.json" (
            builtins.toJSON {
              name = "mrbandler";
              owner.name = "mrbandler";
              plugins = [
                {
                  name = "mrbandler";
                  source = "./";
                }
              ];
            }
          ))
        ];
      };
    in
    {
      programs.claude-code.settings = {
        extraKnownMarketplaces.mrbandler.source = {
          source = "directory";
          path = "${marketplace}";
        };

        enabledPlugins."mrbandler@mrbandler" = true;
      };
    };
}
