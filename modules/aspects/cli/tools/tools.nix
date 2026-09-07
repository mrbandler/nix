# The bag of small CLI tools that need no configuration.
{
  den.aspects.cli.homeManager =
    { lib, pkgs, ... }:
    {
      home.packages =
        with pkgs;
        [
          jq
          just
          jnv
          duf
          dust
          ncdu
          ouch
          process-compose
          sd
          tokei
          gitnr
          pdftk
          hyperfine
          watchexec
          vhs
          static-web-server
          hcloud
          viddy
          yq-go
          doggo
          serpl
          devenv
          ffmpeg-full
        ]
        ++ lib.optionals stdenv.hostPlatform.isLinux [
          trashy
          kmon
          proton-vpn-cli
        ];
    };
}
