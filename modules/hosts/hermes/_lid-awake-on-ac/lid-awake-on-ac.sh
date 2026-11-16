#!/bin/bash
# Keep the Mac awake with the lid closed only while it is on AC power.
# Run as root (LaunchDaemon) every few seconds.

src=$(/usr/bin/pmset -g ps | /usr/bin/head -1)
# The SleepDisabled line is absent from `pmset -g` when the value is 0.
cur=$(/usr/bin/pmset -g | /usr/bin/awk '/SleepDisabled/ {print $2}')

if [[ "$src" == *"AC Power"* ]]; then
  # On charger: block lid-close sleep.
  [[ "$cur" == "1" ]] || /usr/bin/pmset -a disablesleep 1
else
  # On battery: restore normal sleep.
  if [[ "$cur" == "1" ]]; then
    /usr/bin/pmset -a disablesleep 0
    # If the lid is already closed, sleep now. Otherwise the Mac stays awake in the bag.
    if /usr/sbin/ioreg -r -k AppleClamshellState -d 4 | /usr/bin/grep -q '"AppleClamshellState" = Yes'; then
      /usr/bin/pmset sleepnow
    fi
  fi
fi
