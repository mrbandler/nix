{ inputs, ... }:
{
  flake-file.inputs = {
    opnix = {
      url = "github:brizzbuzz/opnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    _1password-shell-plugins = {
      url = "github:1Password/shell-plugins";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  den.aspects.security = {
    provides.to-hosts.darwin.homebrew.casks = [
      {
        name = "1password";
        args.appdir = "/Applications";
      }
    ];

    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        # gh is not here: op authorizes per terminal session, so every
        # non-interactive call (agents, scripts) re-prompted. It reads an
        # opnix-provisioned token instead, see the vcs gh aspect.
        plugins = with pkgs; [
          hcloud
        ];
        getExeName = package: lib.strings.unsafeDiscardStringContext (baseNameOf (lib.getExe package));
        nushellPluginCommands = lib.concatMapStringsSep "\n" (
          package:
          let
            exe = getExeName package;
          in
          ''
            def --wrapped ${exe} [...args] {
              op plugin run -- ${exe} ...$args
            }
          ''
        ) plugins;

        agentSock =
          if pkgs.stdenv.hostPlatform.isDarwin then
            "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\""
          else
            "~/.1password/agent.sock";
      in
      {
        imports = [
          inputs.opnix.homeManagerModules.default
          inputs._1password-shell-plugins.hmModules.default
        ];

        lib.opnix.mkSecret = name: reference: {
          inherit reference;
          path = ".local/share/opnix/secrets/${name}";
        };

        programs = {
          _1password-shell-plugins = {
            enable = true;
            inherit plugins;
          };
          nushell.extraConfig = lib.mkIf config.programs.nushell.enable nushellPluginCommands;

          ssh = {
            enable = true;
            enableDefaultConfig = false;
            settings."*" = {
              IdentityAgent = agentSock;
              IPQoS = "none";
            };
          };

          onepassword-secrets = {
            enable = true;
            tokenFile = "${config.home.homeDirectory}/.config/opnix/token";
            secrets.githubToken = config.lib.opnix.mkSecret "github-token" "op://Nix/gh/token";
          };
        };

        home.file.".config/1Password/ssh/agent.toml".text = ''
          # Managed by Home Manager
          [[ssh-keys]]
          vault = "Development"
        '';

        home.file.".config/opnix/.keep".text = "";
      };
  };
}
