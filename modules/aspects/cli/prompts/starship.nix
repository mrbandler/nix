{
  den.aspects.cli.homeManager =
    { lib, pkgs, ... }:
    let
      jj-starship = lib.getExe pkgs.jj-starship;
    in
    {
      programs.starship = {
        enable = true;
        enableBashIntegration = true;
        enableZshIntegration = true;
        enableNushellIntegration = true;
        presets = [ "nerd-font-symbols" ];
        settings = {
          # vcs right after the directory, where the git modules sit by default
          format = "$shell$directory\${custom.vcs}$all$character";
          os.disabled = true;
          shell = {
            disabled = false;
            format = "$indicator in ";
            bash_indicator = "[bash](bold italic red)";
            zsh_indicator = "[zsh](bold italic blue)";
            nu_indicator = "[nu](bold italic green)";
          };

          # jj-starship shows jj state in jj repos and git state elsewhere, so it
          # replaces the git modules, which only see a detached HEAD under jj
          custom.vcs = {
            when = "${jj-starship} detect";
            command = jj-starship;
            shell = [ "sh" ];
            format = "$output ";
          };
          git_branch.disabled = true;
          git_commit.disabled = true;
          git_status.disabled = true;
        };
      };
    };
}
