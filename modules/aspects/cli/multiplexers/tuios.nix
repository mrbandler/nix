# No home-manager module yet, so the config is written directly; tuios fills
# everything left out with defaults. It goes to config.d, which tuios layers
# under config.toml: config.toml stays writable for the settings UI, and
# `tuios config origin` shows which UI changes override this file.
{
  den.aspects.cli.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      toml = pkgs.formats.toml { };
      tuios = lib.getExe pkgs.tuios;

      configStub = pkgs.writeText "tuios-config-stub.toml" ''
        # Settings changed in the tuios UI land here and override config.d/nix.toml
        # until they are carried into the Nix config.

        [startup]
        daemon = true
      '';

      # The hook entries `tuios integration install claude-code` writes, by
      # store path. --integration is tuios's version marker: when
      # `tuios integration status` reports them outdated, copy the new set.
      claudeHook = timeout: {
        hooks = [
          {
            type = "command";
            command = "${tuios} agent-hook claude-code --integration 3";
            inherit timeout;
          }
        ];
      };
      claudeEvents = [
        "SessionStart"
        "UserPromptSubmit"
        "PreToolUse"
        "PostToolUse"
        "PostToolUseFailure"
        "PermissionDenied"
        "ElicitationResult"
        "Notification"
        "Stop"
        "StopFailure"
        "SessionEnd"
        "SubagentStart"
        "SubagentStop"
      ];

      # Pi's integration is a whole extension file, so tuios writes it at
      # build time and it follows the pinned tuios version on its own
      piExtension = pkgs.runCommand "tuios-pi-extension" { } ''
        export HOME=$TMPDIR
        mkdir -p $HOME/.pi/agent
        ${tuios} integration install pi --command ${tuios}
        cp $HOME/.pi/agent/extensions/tuios-agent-state.ts $out
      '';
    in
    {
      home.packages = [ pkgs.tuios ];

      xdg.configFile."tuios/config.d/nix.toml".source = toml.generate "tuios-config.toml" {
        appearance = {
          theme = "catppuccin_mocha";
          # the same shell wezterm launches, by store path
          preferred_shell = lib.getExe config.programs.nushell.package;
          hide_window_buttons = true;
          shared_borders = false;
          dock_workspace_tabs = true;
          whichkey_position = "bottom-right";
          focus_follows_mouse = false;
          new_window_follow_ssh = true;
          sidebar = {
            sections = "sessions,terminals,agents,git,files";
            show_numbers = true;
          };
        };

        dock = {
          left = [
            "mode"
            "workspaces"
            "trail"
          ];
          center = [ "windows" ];
          right = [
            "notifications"
            "copy-help"
          ];
        };

        spotlight.enabled = false;

        notifications.agent = {
          notify = false;
          sound_mode = "audio";
        };

        startup = {
          open_default_window = true;
          tiled = true;
          start_in_terminal_mode = true;
          layout = "master-stack";
        };

        screensaver = {
          enabled = true;
          effect = "matrix";
        };
      };

      # Without a config.toml tuios ignores config.d, and without a [startup]
      # table in it a session starts floating and daemonless. A fresh install
      # gets the stub tuios itself would write; an existing one is left alone,
      # since it holds UI changes not yet carried over.
      home.activation.tuiosConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ ! -e ${lib.escapeShellArg "${config.xdg.configHome}/tuios/config.toml"} ]; then
          run install -Dm600 ${configStub} ${lib.escapeShellArg "${config.xdg.configHome}/tuios/config.toml"}
        fi
      '';

      # agent state for the pane rail and the Inbox, from each harness's hooks
      programs.claude-code.settings.hooks = lib.genAttrs claudeEvents (_: [ (claudeHook 5) ]) // {
        # stays open while the permission prompt waits for an answer
        PermissionRequest = [ (claudeHook 310) ];
      };

      home.file.".pi/agent/extensions/tuios-agent-state.ts" = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        source = piExtension;
      };
    };
}
