{
  den.aspects.core.nixos = {
    security = {
      sudo = {
        enable = true;
        wheelNeedsPassword = true;
        extraConfig = "Defaults timestamp_timeout=15";
      };
      pam.services.su.requireWheel = true;
      apparmor.enable = true;
    };

    boot = {
      kernelParams = [
        "init_on_alloc=1"
        "init_on_free=1"
        "page_alloc.shuffle=1"
      ];

      kernel.sysctl = {
        "kernel.kptr_restrict" = 2;
        "kernel.unprivileged_bpf_disabled" = 1;
        "net.core.bpf_jit_harden" = 2;
        "fs.protected_fifos" = 2;
        "fs.protected_regular" = 2;
        "fs.suid_dumpable" = 0;

        "net.ipv4.conf.all.accept_redirects" = 0;
        "net.ipv4.conf.default.accept_redirects" = 0;
        "net.ipv4.conf.all.secure_redirects" = 0;
        "net.ipv4.conf.default.secure_redirects" = 0;
        "net.ipv4.conf.all.send_redirects" = 0;
        "net.ipv4.conf.default.send_redirects" = 0;
        "net.ipv4.conf.all.accept_source_route" = 0;
        "net.ipv4.conf.default.accept_source_route" = 0;
        "net.ipv4.conf.all.rp_filter" = 1;
        "net.ipv4.conf.default.rp_filter" = 1;
        "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
        "net.ipv4.conf.all.log_martians" = 1;
        "net.ipv4.conf.default.log_martians" = 1;

        "net.ipv6.conf.all.accept_redirects" = 0;
        "net.ipv6.conf.default.accept_redirects" = 0;
        "net.ipv6.conf.all.accept_source_route" = 0;
        "net.ipv6.conf.default.accept_source_route" = 0;
        "net.ipv6.conf.all.accept_ra" = 0;
        "net.ipv6.conf.default.accept_ra" = 0;
      };
    };
  };
}
