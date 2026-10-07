{
  den.aspects.cli.homeManager.programs.starship = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
    presets = [ "nerd-font-symbols" ];
    settings = {
      format = "$shell$all$character";
      os.disabled = true;
      shell = {
        disabled = false;
        format = "$indicator in ";
        bash_indicator = "[bash](bold italic red)";
        zsh_indicator = "[zsh](bold italic blue)";
        nu_indicator = "[nu](bold italic green)";
      };
    };
  };
}
