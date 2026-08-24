{ inputs, ... }:
{
  flake-file.inputs = {
    vicinae = {
      url = "github:vicinaehq/vicinae";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vicinae-extensions = {
      url = "github:vicinaehq/extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  den.aspects.desktop.provides.vicinae.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      system = pkgs.stdenv.hostPlatform.system;

      vicinaeMods = {
        Mod = "fn";
        Mod2 = "fn+ctrl";
      };
      vicinaeChord =
        bindStr:
        lib.concatMapStringsSep "+" (p: vicinaeMods.${p} or (lib.toLower p)) (lib.splitString "+" bindStr);
      rev = "2ce22330aa8cfeb43c8fc99448173a7e8cb9e9c9";
      exts = inputs.vicinae-extensions.packages.${system} or { };
      mkExt = inputs.vicinae.lib.${system}.mkVicinaeExtension;

      # Upstream's installPhase hardcodes /build (Linux sandbox convention);
      # on darwin the build dir differs and the copy glob comes up empty.
      # ray writes to $HOME/.config/raycast/extensions — use that instead.
      mkRaycastExt =
        args:
        (inputs.vicinae.lib.${system}.mkRayCastExtension args).overrideAttrs (_o: {
          installPhase = ''
            runHook preInstall
            mkdir -p "$out"
            cp -r "$HOME/.config/raycast/extensions/"*/. "$out"/
            runHook postInstall
          '';
        });
    in
    {
      imports = [
        inputs.vicinae.homeManagerModules.default
        ../core/_keybindings.nix
      ];

      programs.vicinae = {
        enable = true;

        systemd = lib.mkIf pkgs.stdenv.isLinux {
          enable = true;
          target = "graphical-session.target";
        };
        launchd = lib.mkIf pkgs.stdenv.isDarwin {
          enable = true;
          autoStart = true;
        };

        settings = {
          # launcher toggle from the shared keybinding contract
          keybinding = vicinaeChord config.desktop.keybindings.launcher;

          close_on_focus_loss = true;
          launcher_window.layer_shell.enabled = false;
          favicon_service = "duckduckgo";

          providers = {
            "@samlinville/tailscale" = {
              preferences.tailscalePath = "${pkgs.tailscale}/bin/tailscale";
            };

            "@mattisssa/spotify-player" = {
              entrypoints = {
                like.enabled = true;
                dislike.enabled = true;
                addPlayingSongToPlaylist = {
                  enabled = true;
                  preferences.duplicateSongCheck = true;
                };
                volume.enabled = true;
                volumeUp.enabled = true;
                volumeDown.enabled = true;
              };
            };
          };
        };

        extensions =
          # Linux-only concepts stay with zeus
          lib.optionals pkgs.stdenv.isLinux (
            with exts;
            [
              power-profile
              process-manager
              pulseaudio
              wifi-commander
              niri
            ]
          )
          ++ lib.optionals (exts ? nix) [ exts.nix ]
          ++ [
            # Raycast extensions (cross-platform JS)
            (mkRaycastExt {
              name = "linear";
              inherit rev;
              sha256 = "sha256-0HE+125/kt6dKCJo4T9rHRTQzjmvTHm5iqxCv/txyaQ=";
            })
            (mkRaycastExt {
              name = "spotify-player";
              inherit rev;
              sha256 = "sha256-J4EaKxrqVJgIta0gYl5rvhNfILUdMoQhDpA9f9gRxJc=";
            })
            (mkRaycastExt {
              name = "tailscale";
              inherit rev;
              sha256 = "sha256-1MW+747L1xPRsrqcEydXFyCWf3mKH2lVHT9uSE8ss4k=";
            })
            (mkRaycastExt {
              name = "uuid-generator";
              inherit rev;
              sha256 = "sha256-27KqqcVWFbQegoWLfpRlsaUGoWrektcs8uirGaMIU4k=";
            })

            # Custom extensions
            (mkExt {
              pname = "praxis";
              version = "0.1.0";
              src = ./_praxis;
            })
          ];
      };
    };
}
