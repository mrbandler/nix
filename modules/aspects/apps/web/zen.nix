{ inputs, ... }:
{
  flake-file.inputs.zen-browser = {
    url = "github:0xc000022070/zen-browser-flake";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.apps.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      profile = config.home.username;
      sessionsDir =
        if pkgs.stdenv.isDarwin then
          "${config.home.homeDirectory}/Library/Application Support/Zen/Profiles/${profile}"
        else
          "${config.xdg.configHome}/zen/${profile}";
    in
    {
      imports = [ inputs.zen-browser.homeModules.beta ];

      stylix.targets.zen-browser.profileNames = [ profile ];

      home.activation = {
        zenDefaultBrowser = lib.mkIf pkgs.stdenv.isDarwin (
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            ${pkgs.defaultbrowser}/bin/defaultbrowser zen || true
          ''
        );

        zenBindInstall = lib.mkIf pkgs.stdenv.isDarwin (
          lib.hm.dag.entryAfter [ "zen-browser-${profile}" ] ''
            INSTALLS_INI="${config.home.homeDirectory}/Library/Application Support/Zen/installs.ini"
            if [ -f "$INSTALLS_INI" ]; then
              /usr/bin/sed -i "" 's|^Default=.*|Default=Profiles/${profile}|' "$INSTALLS_INI"
            fi
          ''
        );

        zenSessionsSeed = lib.hm.dag.entryBetween [ "zen-browser-${profile}" ] [ "writeBoundary" ] ''
          SESSIONS_FILE="${sessionsDir}/zen-sessions.jsonlz4"
          if [ ! -f "$SESSIONS_FILE" ]; then
            mkdir -p "${sessionsDir}"
            SEED_TMP="$(mktemp)"
            echo '{"spaces":[],"tabs":[],"folders":[],"groups":[],"lastSelected":0,"splitViewData":{"groups":[]}}' > "$SEED_TMP"
            ${lib.getExe pkgs.mozlz4a} "$SEED_TMP" "$SESSIONS_FILE"
            rm -f "$SEED_TMP"
            echo "zen-sessions: Seeded empty sessions file for fresh profile"
          fi
        '';

        zenSessionsSort = lib.hm.dag.entryAfter [ "zen-browser-${profile}" ] ''
          SESSIONS_FILE="${sessionsDir}/zen-sessions.jsonlz4"
          if [ -f "$SESSIONS_FILE" ]; then
            SORT_TMP="$(mktemp)"
            SORT_OUT="$(mktemp)"
            ${lib.getExe pkgs.mozlz4a} -d "$SESSIONS_FILE" "$SORT_TMP" 2>/dev/null
            ${lib.getExe pkgs.jq} '.spaces = (.spaces | sort_by(.position))' "$SORT_TMP" > "$SORT_OUT" 2>/dev/null
            if [ -s "$SORT_OUT" ]; then
              ${lib.getExe pkgs.mozlz4a} "$SORT_OUT" "$SESSIONS_FILE"
              echo "zen-sessions: Sorted workspaces by position"
            fi
            rm -f "$SORT_TMP" "$SORT_OUT"
          fi
        '';
      };

      programs.zen-browser = {
        enable = true;

        darwinDefaultsId = "app.zen-browser.zen";

        policies = {
          AutofillAddressEnabled = false;
          AutofillCreditCardEnabled = false;
          DisableAppUpdate = true;
          DisableFeedbackCommands = true;
          DisableFirefoxStudies = true;
          DisablePocket = true;
          DisableTelemetry = true;
          DontCheckDefaultBrowser = true;
          NoDefaultBookmarks = true;
          OfferToSaveLogins = false;
          EnableTrackingProtection = {
            Value = true;
            Locked = true;
            Cryptomining = true;
            Fingerprinting = true;
          };
        };

        profiles.${profile} = {
          id = 0;
          name = profile;
          isDefault = true;

          extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
            ublock-origin
            onepassword-password-manager
            darkreader
            # Wikiwand, vidIQ, and Grammarly are installed manually (not in NUR)
          ];

          search = {
            force = true;
            default = "ddg";
          };

          # Zen Mods (by UUID from theme store)
          mods = [
            "f7c71d9a-bce2-420f-ae44-a64bd92975ab" # Better Unloaded Tabs
            "906c6915-5677-48ff-9bfc-096a02a72379" # Floating Status Bar
            "79dde383-4fe7-404a-a8e6-9be440022542" # Tidy Popup
            "378ba8b9-cd36-45f5-88df-595df5288795" # Add new tab urlbar icon
            "ae7868dc-1fa1-469e-8b89-a5edf7ab1f24" # Load Bar
            "58649066-2b6f-4a5b-af6d-c3d21d16fc00" # Private Mode Highlighting
            "ad97bb70-0066-4e42-9b5f-173a5e42c6fc" # SuperPins
            "f4866f39-cfd6-4498-ab92-54213b8279dc" # Animations Plus
          ];

          # Workspaces
          spacesForce = true;
          spaces = {
            "Live" = {
              id = "0a2e02a7-e275-4b87-b2b0-a09f9eea25db";
              icon = "🔴";
              position = 1;
              container = 1;
            };
            "Home" = {
              id = "6999010f-0d9f-4762-b172-3c8085827d3d";
              icon = "🏡";
              position = 2;
              container = 1;
            };
            "Research" = {
              id = "25b1ffc3-3866-41f2-b95d-96ad37020dd0";
              icon = "📖";
              position = 3;
              container = 1;
            };
            "Watching" = {
              id = "f8724f7d-3fde-4f50-b8fe-a08347485c8d";
              icon = "👀";
              position = 4;
              container = 1;
            };
            "Leaky Abstractions" = {
              id = "46cae16d-0d8e-4a0b-80fe-29ddc0245ac7";
              icon = "🔧";
              position = 5;
              container = 7;
            };
            "Smoking Squid" = {
              id = "99e1f307-afd0-40c7-afcf-3762a4dfe82f";
              icon = "🐙";
              position = 6;
              container = 2;
            };
            "The Considered Shops" = {
              id = "522ae6de-e64e-460d-94e3-4d6990542d9e";
              icon = "🛋️";
              position = 7;
              container = 6;
            };
          };

          # Containers
          containers = {
            "Smoking Squid" = {
              id = 2;
              icon = "circle";
              color = "red";
            };
            "The Considered Shops" = {
              id = 6;
              icon = "cart";
              color = "turquoise";
            };
            "Leaky Abstractions" = {
              id = 7;
              icon = "circle";
              color = "red";
            };
          };
          containersForce = true;

          settings = {
            # Extensions
            "extensions.autoDisableScopes" = 0;
            "extensions.enabledScopes" = 15;
            "extensions.allowPrivateBrowsingByDefault" = true;

            # Skip first-run onboarding (prevents Zen from wiping session data)
            "zen.welcomeScreen.enabled" = false;
            "zen.welcomeScreen.seen" = true;
            "browser.startup.homepage_override.mstone" = "ignore";
            "browser.aboutwelcome.enabled" = false;
            "startup.homepage_welcome_url" = "";
            "startup.homepage_welcome_url.additional" = "";
            "trailhead.firstrun.didSeeAboutWelcome" = true;

            # Privacy
            "privacy.donottrackheader.enabled" = true;
            "privacy.globalprivacycontrol.was_ever_enabled" = true;
            "privacy.clearOnShutdown_v2.formdata" = true;
            "dom.security.https_only_mode_ever_enabled" = true;
            "network.dns.disablePrefetch" = true;
            "network.http.speculative-parallel-limit" = 0;
            "network.prefetch-next" = false;

            # General
            "general.autoScroll" = true;
            "browser.ml.linkPreview.enabled" = true;
            "browser.warnOnQuitShortcut" = false;
            "widget.gtk.overlay-scrollbars.enabled" = false;
            "dom.disable_open_during_load" = false;
            "browser.translations.neverTranslateLanguages" = "en,de";

            # Media
            "media.hardwaremediakeys.enabled" = false;
            "media.videocontrols.picture-in-picture.enable-when-switching-tabs.enabled" = false;

            # Sync
            "services.sync.declinedEngines" = "passwords,creditcards,addresses";
            "services.sync.engine.passwords" = false;
            "services.sync.engine.workspaces" = true;

            # Toolbar, pins uBlock, DarkReader and 1Password icons to the
            # nav-bar (upper right). NOTE: this declares the whole toolbar
            # layout, so manual drag-customizations revert on restart. To adopt
            # new manual changes: grep browser.uiCustomization.state prefs.js
            # and paste the updated blob here.
            "browser.uiCustomization.state" =
              ''{"placements":{"widget-overflow-fixed-list":[],"unified-extensions-area":[],"nav-bar":["back-button","forward-button","stop-reload-button","customizableui-special-spring1","vertical-spacer","urlbar-container","customizableui-special-spring2","ublock0_raymondhill_net-browser-action","addon_darkreader_org-browser-action","_d634138d-c276-4fc8-924b-40a0ea21d284_-browser-action","unified-extensions-button"],"TabsToolbar":["tabbrowser-tabs"],"vertical-tabs":[],"PersonalToolbar":["personal-bookmarks"],"zen-sidebar-top-buttons":["zen-toggle-compact-mode"],"zen-sidebar-foot-buttons":["downloads-button","zen-workspaces-button","zen-create-new-button"]},"seen":["_d634138d-c276-4fc8-924b-40a0ea21d284_-browser-action","addon_darkreader_org-browser-action","ublock0_raymondhill_net-browser-action","developer-button","screenshot-button"],"dirtyAreaCache":["unified-extensions-area","nav-bar","vertical-tabs","zen-sidebar-foot-buttons","TabsToolbar","PersonalToolbar","zen-sidebar-top-buttons"],"currentVersion":24,"newElementCount":2}'';

            # Zen UI
            "zen.theme.hide-unified-extensions-button" = true;
            "zen.urlbar.behavior" = "float";
            "zen.glance.activation-method" = "ctrl";
            "zen.view.compact.enable-at-startup" = false;
            "zen.view.show-newtab-button-top" = false;
            "zen.view.use-single-toolbar" = false;
            "zen.tabs.show-newtab-vertical" = false;
            "zen.tabs.ctrl-tab.ignore-essential-tabs" = true;
            "zen.tabs.ctrl-tab.ignore-pending-tabs" = true;
            "zen.pinned-tab-manager.restore-pinned-tabs-to-pinned-url" = true;
            "zen.workspaces.hide-default-container-indicator" = false;
            "zen.workspaces.indicator-name-center" = false;
            "zen.workspaces.show-workspace-indicator" = true;

            # Mod preferences
            "mod.cleanedurlbar.customcolor" = "hsl(0 0 10)";
            "mod.cleanedurlbar.customselectcolor" = "rgba(80, 80, 250, 0.75)";
            "mod.cleanedurlbar.customselectfontcolor" = "rgba(255,255,255,1)";
            "mod.cleanedurlbar.customtransparency" = "40%";
            "mod.superpins.essentials.grid-count" = "1";
            "mod.superpins.pins.grid-count" = "1";
            "mod.tidypopup.hovercolor" = "rgba(80, 80, 250, 1)";
            "mod.tidypopup.usecustomhovercolor" = false;
            "theme.better-active-tab.on-right" = false;
            "theme.better_uniextbtn.default" = "Default";

            # Essentials/Pins mod settings
            "uc.essentials.auto-grow" = false;
            "uc.essentials.gap" = "Normal";
            "uc.essentials.same-height" = false;
            "uc.essentials.transition-bg" = false;
            "uc.essentials.transition-speed" = "100ms";
            "uc.essentials.width" = "Normal";
            "uc.pins.legacy-layout" = false;
            "uc.pins.transition-speed" = "100ms";
            "uc.private-browsing-top-bar.border-style" = "default";
            "uc.private-browsing-top-bar.color" = "default";
            "uc.private-browsing-top-bar.highlighting-style" = "gradient";
            "uc.tabs.dim_unloaded" = false;
          };
        };
      };
    };
}
