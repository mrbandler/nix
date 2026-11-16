{
  den.aspects.development.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # LSP servers start by name from Claude Code's own PATH, so the language
      # servers from each project's devenv never start. This local plugin
      # starts them through `direnv exec` in the project dir instead.
      # Commands and extension maps follow the official claude-plugins-official
      # LSP plugins; add a language when a devenv has its server.
      # Godot serves GDScript LSP over TCP; this stdio bridge starts a
      # headless Godot per project, with `godot` from the project's devenv
      gdscriptBridge = pkgs.fetchFromGitHub {
        owner = "twaananen";
        repo = "claude-code-gdscript";
        rev = "58f421b8f4e1466a76bf21293900fe650888d31b";
        hash = "sha256-eCD0UkK+uqptKgygx4MkBL3inlp6V5NjHzNjZF7Oe6U=";
      };

      # name = { cmd = server command; languages.<LSP language id> = file
      # extensions; replaces = the official plugin to turn off; extra = more
      # lspServers fields }
      servers = {
        nixd = {
          cmd = [ "nixd" ];
          languages.nix = [ ".nix" ];
        };
        rust-analyzer = {
          cmd = [ "rust-analyzer" ];
          languages.rust = [ ".rs" ];
          replaces = "rust-analyzer-lsp";
        };
        gopls = {
          cmd = [ "gopls" ];
          languages.go = [ ".go" ];
          replaces = "gopls-lsp";
        };
        csharp-ls = {
          cmd = [ "csharp-ls" ];
          languages.csharp = [ ".cs" ];
          replaces = "csharp-lsp";
        };
        clangd = {
          cmd = [
            "clangd"
            "--background-index"
          ];
          languages = {
            c = [
              ".c"
              ".h"
            ];
            cpp = [
              ".cpp"
              ".cc"
              ".cxx"
              ".hpp"
              ".hxx"
              ".C"
              ".H"
            ];
          };
          replaces = "clangd-lsp";
        };
        typescript = {
          cmd = [
            "typescript-language-server"
            "--stdio"
          ];
          languages = {
            typescript = [
              ".ts"
              ".mts"
              ".cts"
            ];
            typescriptreact = [ ".tsx" ];
            javascript = [
              ".js"
              ".mjs"
              ".cjs"
            ];
            javascriptreact = [ ".jsx" ];
          };
          replaces = "typescript-lsp";
        };
        pyright = {
          cmd = [
            "pyright-langserver"
            "--stdio"
          ];
          languages.python = [
            ".py"
            ".pyi"
          ];
          replaces = "pyright-lsp";
        };
        taplo = {
          cmd = [
            "taplo"
            "lsp"
            "stdio"
          ];
          languages.toml = [ ".toml" ];
        };
        yaml-language-server = {
          cmd = [
            "yaml-language-server"
            "--stdio"
          ];
          languages.yaml = [
            ".yaml"
            ".yml"
          ];
        };
        marksman = {
          cmd = [
            "marksman"
            "server"
          ];
          languages.markdown = [ ".md" ];
        };
        # also serves Terraform: it maps the terraform language ids to these
        tofu-ls = {
          cmd = [
            "tofu-ls"
            "serve"
          ];
          languages = {
            opentofu = [
              ".tf"
              ".tofu"
            ];
            opentofu-vars = [ ".tfvars" ];
          };
        };
        gdscript = {
          cmd = [
            (lib.getExe pkgs.nodejs)
            "${gdscriptBridge}/bridge/gdscript-lsp-bridge.mjs"
          ];
          languages.gdscript = [ ".gd" ];
          extra.startupTimeout = 30000;
        };
      };

      viaDirenv =
        _: s:
        {
          command = lib.getExe config.programs.direnv.package;
          args = [
            "exec"
            "\${CLAUDE_PROJECT_DIR}"
          ]
          ++ s.cmd;
          extensionToLanguage = lib.concatMapAttrs (
            language: extensions: lib.genAttrs extensions (_: language)
          ) s.languages;
        }
        // s.extra or { };

      plugin = pkgs.writeTextDir ".claude-plugin/plugin.json" (
        builtins.toJSON {
          name = "devenv-lsp";
          version = "0.1.0";
          description = "Language servers from the project's devenv, through direnv";
          lspServers = lib.mapAttrs viaDirenv servers;
        }
      );
    in
    {
      programs.claude-code.plugins.devenv-lsp = plugin;

      # the official plugins look the servers up on PATH and would claim
      # the same extensions
      programs.claude-code.settings.enabledPlugins = lib.mapAttrs' (
        _: s: lib.nameValuePair "${s.replaces}@claude-plugins-official" false
      ) (lib.filterAttrs (_: s: s ? replaces) servers);
    };
}
