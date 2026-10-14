{
  den.aspects.core.nixos.networking =
    let
      nameservers = [
        "1.0.0.1"
        "1.1.1.1"
        "8.8.8.8"
        "8.8.4.4"
      ];
    in
    {
      inherit nameservers;

      # NetworkManager runs DHCP itself; this only turns off the scripted
      # dhcpcd that nixos-generate-config enables by default
      useDHCP = false;

      networkmanager = {
        enable = true;
        dns = "none";
        insertNameservers = nameservers;
        wifi.powersave = false;
        connectionConfig = {
          "ipv6.addr-gen-mode" = "stable-privacy";
          "ipv6.ip6-privacy" = 2;
        };
      };

      firewall.enable = true;
    };
}
