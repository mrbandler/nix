# `nix run github:mrbandler/nix#install -- <host> [address]` installs a host
# from scratch with nixos-anywhere: disko lays out the disk from the host's
# disk.device, nixos-facter writes modules/hosts/<host>/facter.json, and the
# new system boots with the opnix token and a checkout of this repo in place.
#
# Without an address it installs onto the machine it runs on, which must be
# booted from a NixOS installer ISO. With one, it installs over SSH onto a
# machine booted from the ISO, e.g. from hermes. On this repo's own ISO
# (iso.nix) it is just `install <host>`.
{ inputs, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    let
      # the 1Password CLI is unfree
      unfree = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      repo = "https://github.com/mrbandler/nix.git";
      rev = inputs.self.rev or "";
    in
    {
      packages.install = pkgs.writeShellApplication {
        name = "install";
        runtimeInputs = [
          pkgs.nixos-anywhere
          pkgs.openssh
          pkgs.git
          pkgs.jq
          unfree._1password-cli
        ];
        text = ''
          nix() { command nix --extra-experimental-features "nix-command flakes" "$@"; }

          if [ $# -lt 1 ] || [ $# -gt 2 ]; then
            echo "Usage: install <host> [address]" >&2
            echo "  without an address it installs onto this machine (NixOS installer ISO)" >&2
            exit 1
          fi
          host=$1
          address=''${2:-localhost}

          work=$(mktemp -d)
          trap 'rm -rf "$work"' EXIT

          # --- the flake, at the revision this script came from ---
          # The clone is also the new system's ~/.dotfiles: it travels as an
          # extra file, and nixos-facter writes the hardware report into it
          # before the extra files are copied. A path: flake sees that report
          # although git does not track it yet.

          echo "==> Fetching ${repo}"
          clone="$work/clone"
          git clone --quiet ${repo} "$clone"
          # empty when the script was built from uncommitted changes
          rev="${rev}"
          if [ -n "$rev" ]; then
            git -C "$clone" checkout --quiet "$rev"
          else
            echo "warning: not run from a clean revision, installing the default branch" >&2
          fi
          # what the install generates gets committed from the new system,
          # where commits can be signed and pushed over SSH
          git -C "$clone" switch --quiet -c "install-$host"
          git -C "$clone" remote set-url origin git@github.com:mrbandler/nix.git
          flake="path:$clone"

          if [ ! -d "$clone/modules/hosts/$host" ]; then
            echo "error: modules/hosts/$host/ does not exist; installable hosts keep their files in a directory" >&2
            exit 1
          fi

          user=$(nix eval --raw "$flake#nixosConfigurations.$host.config.home-manager.users" \
            --apply 'users: builtins.head (builtins.attrNames users)')
          device=$(nix eval --json "$flake#nixosConfigurations.$host.config.disk.device" | jq -r '. // empty')

          # --- SSH access to the target ---

          key="$work/id_ed25519"
          ssh-keygen -q -t ed25519 -N "" -f "$key"
          ssh_opts=(-i "$key" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR)

          if [ "$address" = localhost ]; then
            if ! grep -q 'VARIANT_ID=installer' /etc/os-release 2>/dev/null; then
              echo "error: installing onto this machine only works from the NixOS installer ISO" >&2
              exit 1
            fi
            sudo install -d -m 700 /root/.ssh
            sudo cp "$key.pub" /root/.ssh/authorized_keys
            sudo systemctl start sshd
          else
            echo "==> Authorizing a one-off key on root@$address (enter the root password set on the ISO)"
            ssh-copy-id -i "$key.pub" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "root@$address"
          fi
          # the commands are built here on purpose, with this side's values
          # shellcheck disable=SC2029
          target() { ssh "''${ssh_opts[@]}" "root@$address" "$@"; }

          # --- the disk ---

          if [ -z "$device" ]; then
            echo
            echo "==> Disks on $address:"
            # runs on the target, so it expands there
            # shellcheck disable=SC2016
            mapfile -t disks < <(target 'for d in /dev/disk/by-id/*; do
              case $d in *-part*|*/wwn-*|*/nvme-eui.*) continue ;; esac
              echo "$d"
            done')
            if [ ''${#disks[@]} -eq 0 ]; then
              echo "error: no disks found on $address" >&2
              exit 1
            fi
            for i in "''${!disks[@]}"; do
              printf '  %d) %s  %s\n' "$((i + 1))" "''${disks[$i]##*/}" "$(target "lsblk -dno SIZE ''${disks[$i]}")"
            done
            read -rp "Install onto which disk? " choice
            device=''${disks[$((choice - 1))]:-}
            if [ -z "$device" ] || [ "$choice" -lt 1 ]; then
              echo "Aborted." >&2
              exit 1
            fi
            # commit it with the hardware report after the first boot
            printf '{\n  den.aspects.%s.nixos.disk.device = "%s";\n}\n' "$host" "$device" \
              > "$clone/modules/hosts/$host/disk.nix"
          fi

          echo
          echo "==> $host will be installed onto $address:"
          target "lsblk -o NAME,SIZE,TYPE,FSTYPE,MODEL $device"
          echo
          echo "This ERASES $device: a 1G EFI partition and btrfs on the rest."
          read -rp "Type '$host' to continue: " confirm
          if [ "$confirm" != "$host" ]; then
            echo "Aborted."
            exit 1
          fi

          # --- the opnix token ---

          echo "==> Reading the opnix token from 1Password"
          if ! token=$(op read "op://Nix/Opnix Service Account/credential" 2>/dev/null); then
            # no desktop app to ask (the ISO): a one-time full sign-in
            eval "$(op account add --signin)"
            token=$(op read "op://Nix/Opnix Service Account/credential")
          fi

          extra="$work/extra"
          home="$extra/home/$user"
          install -d -m 700 "$home/.config/opnix"
          mv "$clone" "$home/.dotfiles"
          flake="path:$home/.dotfiles"
          printf '%s' "$token" > "$home/.config/opnix/token"
          chmod 600 "$home/.config/opnix/token"
          unset token

          # --- install ---

          report="modules/hosts/$host/facter.json"
          nixos-anywhere \
            --flake "$flake#$host" \
            --target-host "root@$address" \
            "''${ssh_opts[@]}" \
            --build-on remote \
            --generate-hardware-config nixos-facter "$home/.dotfiles/$report" \
            --extra-files "$extra" \
            --chown "/home/$user" 1000:100

          echo
          echo "Done: $host reboots into the new system. The install generated"
          echo "files the repo does not have yet; commit them from $host:"
          echo "  cd ~/.dotfiles && git add -A && git commit -m 'feat($host): install onto disko' && git push -u origin install-$host"
        '';
      };
    };
}
