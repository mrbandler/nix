{
  den.aspects.development.provides.vcs.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      vcs = import ./_identity.nix {
        inherit pkgs;
        devDir = config.development.devDir;
      };
      # every identity may sign with the shared key; git needs this list to
      # verify ssh signatures (git log --show-signature)
      allowedSigners = lib.concatMapStringsSep "\n" (email: "${email} ${vcs.signing.key}") (
        lib.unique ([ vcs.default.email ] ++ lib.mapAttrsToList (_: user: user.email) vcs.contexts)
      );
    in
    {
      imports = [ ../core/_devdir.nix ];

      xdg.configFile."git/allowed_signers".text = allowedSigners + "\n";

      # git reads ~/.gitconfig before the XDG config; pointing it at ours keeps
      # a stray legacy file from shadowing the declarative one
      home.file.".gitconfig".source =
        config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/git/config";

      programs.git = {
        enable = true;

        ignores = [
          # OS
          ".DS_Store"
          ".AppleDouble"
          ".LSOverride"
          "._*"
          ".Spotlight-V100"
          ".Trashes"
          ".AppleDB"
          ".AppleDesktop"
          "Thumbs.db"
          "Thumbs.db:encryptable"
          "ehthumbs.db"
          "ehthumbs_vista.db"
          "[Dd]esktop.ini"
          "$RECYCLE.BIN/"
          "*.lnk"
          "*~"
          ".fuse_hidden*"
          ".directory"
          ".Trash-*"
          ".nfs*"

          # Editors
          "*.swp"
          "*.swo"
          "[._]*.s[a-v][a-z]"
          "!*.svg"
          "[._]*.sw[a-p]"
          "[._]s[a-rt-v][a-z]"
          "[._]ss[a-gi-z]"
          "[._]*.un~"
          "Session.vim"
          "Sessionx.vim"
          ".netrwhist"
          "tags"
          ".idea/"
          ".vscode/*"
          "!.vscode/settings.json"
          "!.vscode/tasks.json"
          "!.vscode/launch.json"
          "!.vscode/extensions.json"
          "!.vscode/*.code-snippets"
          "*.code-workspace"

          # Direnv
          ".direnv"
          ".envrc"

          # Environment
          ".env"
          ".env.local"
          ".env.development.local"
          ".env.test.local"
          ".env.production.local"

          # Claude Code
          "**/.claude/settings.local.json"
        ];

        signing = {
          inherit (vcs.signing) key;
          format = "ssh";
          signer = vcs.signing.program;
          signByDefault = true;
        };

        settings = {
          user = vcs.default;
          gpg.ssh.allowedSignersFile = "${config.xdg.configHome}/git/allowed_signers";
          init.defaultBranch = "main";
          pull.rebase = true;
          push.autoSetupRemote = true;
        };

        includes = lib.mapAttrsToList (path: user: {
          condition = "gitdir:${path}/";
          contents = { inherit user; };
        }) vcs.contexts;
      };
    };
}
