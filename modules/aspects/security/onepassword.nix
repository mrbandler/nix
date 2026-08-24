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
        plugins = with pkgs; [
          gh
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
          if pkgs.stdenv.isDarwin then
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
            matchBlocks."*" = {
              identityAgent = agentSock;
              extraOptions.IPQoS = "none";
            };
          };

          onepassword-secrets.tokenFile = "${config.home.homeDirectory}/.config/opnix/token";
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
