{
  den.aspects.apps.homeManager.programs.mpv = {
    enable = true;
    config = {
      # Video
      vo = "gpu-next";
      hwdec = "auto-safe";

      # Audio
      volume = 80;
      volume-max = 150;

      # Subtitles
      sub-auto = "fuzzy";
      sub-font-size = 40;

      # OSD
      osd-bar = false;
      osd-font-size = 30;

      # Misc
      save-position-on-quit = true;
      keep-open = true;
    };
  };
}
