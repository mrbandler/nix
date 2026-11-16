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
        runtimeInputs = [
          pkgs.jq
          pkgs.gnugrep
          pkgs.gnused
        ];
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

      # Commits and pushes ask every time, unless I typed `grant: commit` or
      # `grant: push` in this session. Settings `ask` rules can't do this:
      # they win over every allow, including "don't ask again". Grants live
      # outside the repo, keyed by session id, and end with the session.
      grants = ''grants="''${XDG_STATE_HOME:-$HOME/.local/state}/claude-grants"'';

      gate = pkgs.writeShellApplication {
        name = "mrbandler-vcs-gate";
        runtimeInputs = [
          pkgs.jq
          pkgs.gnugrep
          pkgs.gnused
        ];
        text = ''
          ${grants}
          input=$(cat)
          cmd=$(jq -r '.tool_input.command // ""' <<<"$input")
          session=$(jq -r '.session_id' <<<"$input")

          decide() {
            jq -n --arg d "$1" --arg r "$2" '{hookSpecificOutput: {
              hookEventName: "PreToolUse", permissionDecision: $d, permissionDecisionReason: $r}}'
            exit 0
          }

          # ponytail: plain string matching; an agent that obfuscates the
          # command gets past it. Upgrade path is a root-owned grants dir.
          grep -qF claude-grants <<<"$cmd" && decide deny "grants are set by Michael's prompt only"
          grep -Eq '\bgit( -C \S+)? push\b.*( -f\b| --force)' <<<"$cmd" && decide deny "force push is never allowed"

          if grep -Eq '\bgit( -C \S+)? push\b|\bjj( -R \S+)? git push\b|\bgh pr (create|merge)\b' <<<"$cmd"; then
            kind=push
          elif grep -Eq '\bgit( -C \S+)? commit\b|\bjj( -R \S+)? commit\b' <<<"$cmd"; then
            kind=commit
          else
            exit 0
          fi

          if grep -qx "$kind" "$grants/$session" 2>/dev/null; then
            decide allow "$kind granted for this session"
          fi
          decide ask "$kind needs approval (type 'grant: $kind' to allow it for this session)"
        '';
      };

      grant = pkgs.writeShellApplication {
        name = "mrbandler-grant";
        runtimeInputs = [
          pkgs.jq
          pkgs.gnugrep
          pkgs.gnused
        ];
        text = ''
          ${grants}
          input=$(cat)
          session=$(jq -r '.session_id' <<<"$input")
          kinds=$(jq -r '.prompt' <<<"$input" | sed -nE 's/^grant: (commit|push)[[:space:]]*$/\1/p')
          [ -z "$kinds" ] && exit 0
          mkdir -p "$grants"
          echo "$kinds" >>"$grants/$session"
          echo "Michael granted for this session: $(echo "$kinds" | tr '\n' ' ')"
        '';
      };

      revoke = pkgs.writeShellApplication {
        name = "mrbandler-revoke";
        runtimeInputs = [
          pkgs.jq
          pkgs.gnugrep
          pkgs.gnused
        ];
        text = ''
          ${grants}
          rm -f "$grants/$(jq -r '.session_id')"
        '';
      };

      manifest = pkgs.writeTextDir ".claude-plugin/plugin.json" (
        builtins.toJSON {
          name = "mrbandler";
          version = "0.1.0";
          description = "Michael's own hooks, skills and commands";
          hooks = {
            PreToolUse = [
              {
                matcher = "Bash|Write|Edit|MultiEdit";
                hooks = [
                  {
                    type = "command";
                    command = lib.getExe guard;
                  }
                ];
              }
              {
                matcher = "Bash";
                hooks = [
                  {
                    type = "command";
                    command = lib.getExe gate;
                  }
                ];
              }
            ];
            UserPromptSubmit = [
              {
                hooks = [
                  {
                    type = "command";
                    command = lib.getExe grant;
                  }
                ];
              }
            ];
            SessionEnd = [
              {
                hooks = [
                  {
                    type = "command";
                    command = lib.getExe revoke;
                  }
                ];
              }
            ];
          };
        }
      );
      plugin = pkgs.symlinkJoin {
        name = "mrbandler-plugin";
        paths = [
          manifest
          ./_mrbandler # skills/
        ];
      };
    in
    {
      # docs-lookup skill; anonymous lookups, replaces the context7 MCP plugin
      home.packages = [ pkgs.ctx7 ];

      programs.claude-code.plugins.mrbandler = plugin;
    };
}
