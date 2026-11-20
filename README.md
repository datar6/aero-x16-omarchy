# GIGABYTE AERO X16 on Omarchy

Cheat sheet and config backup for a GIGABYTE AERO X16 4WH (BIOS FB04, Ryzen AI 9 465 + Radeon 890M, RTX 5070 Laptop) running Omarchy (Arch + Hyprland).

## Quick commands

### Power and firmware modes

| Task | Command |
|---|---|
| Current profile | `powerprofilesctl get` |
| Change profile | `powerprofilesctl set performance` (`balanced`, `power-saver`) or the battery panel |
| What the service applied | `journalctl -u gb-power-sync -n 5` |
| Restart the service | `sudo systemctl restart gb-power-sync` |
| RTX power right now | `nvidia-smi --query-gpu=power.draw,clocks.gr,power.limit --format=csv` |
| Why the RTX is throttled | `nvidia-smi -q -d PERFORMANCE` |
| RTX stuck at ~11 W | `sudo systemctl restart nvidia-powerd`, or switch the profile away and back |

Profile → firmware mapping (applied automatically by `gb-power-sync`):

| Profile | Mode (WMI 237) | Quiet flag `CRAF` (WMI 87) | Gaming fans `FANB` (WMI 113) |
|---|---|---|---|
| power-saver | 0 (eco) | 1 (RTX capped at 30 W) | 0 |
| balanced | 1 | 0 | 0 |
| performance | 3 (gaming) | 0 | 1 |

### Battery charge limit

| Task | Command |
|---|---|
| Show limit and charge | `gb-charge-limit` |
| Charge to 80% (default) | `sudo gb-charge-limit 80` |
| Any limit from 60 to 100 | `sudo gb-charge-limit 60` |
| Charge to 100% (before a trip) | `sudo gb-charge-limit off` |

The limit is stored in `/etc/gb-charge-limit` and restored at boot.

### Gaming

Steam launch options (Properties → Launch Options), Proton Experimental:

```
prime-run gamemoderun mangohud %command%
```

For Deadlock, append ` -vulkan`.

| Task | How |
|---|---|
| Show/hide MangoHud | `Ctrl_R + Shift_R + H` |
| Toggle the 165 FPS cap | `Ctrl_R + Shift_R + L` |
| Record an FPS log | `Ctrl_R + Shift_R + R` → `~/Documents/mangohud-logs` |
| Is the game on the RTX? | `nvidia-smi`: the game process should be listed |
| Temperatures | `sensors`, `nvidia-smi` |

Before playing: use the stock charger (not the 100 W USB-C one) and the **performance** profile.

### MUX mode (BIOS → Display Mode)

| Mode | Panel | `prime-run` needed |
|---|---|---|
| Dynamic | AMD, `eDP-2`, RTX sleeps | yes |
| Discrete | NVIDIA, `eDP-1` | no (harmless) |

Video drivers (VA-API), the 165 Hz monitor setting and the shell render loop adapt automatically (`display-gpu-env`).

### Razer DeathAdder V3 mouse

| Task | Command |
|---|---|
| GUI | Polychromatic (app launcher) |
| Polling rate | `python3 -c "from openrazer.client import DeviceManager as D; d=D().devices[0]; d.poll_rate=2000"` |
| Check DPI and polling rate | `python3 -c "from openrazer.client import DeviceManager as D; d=D().devices[0]; print(d.dpi, d.poll_rate)"` |

Pointer acceleration is off in `~/.config/hypr/input.lua` (`accel_profile = "flat"`).

### Troubleshooting

| Symptom | Fix |
|---|---|
| Omarchy shell frozen | `pkill -9 quickshell; hyprctl dispatch 'hl.dsp.exec_cmd("omarchy-launch-shell")'` |
| Normal shell restart | `omarchy restart shell` |
| F-keys only work with Fn | `Fn + Esc` (Fn Lock) |
| Microphone silent | `wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 0` or the mic mute key |
| Black video in Chrome | check `~/.local/bin/display-gpu-env`, log out and back in |
| Hyprland config errors | `hyprctl reload && hyprctl configerrors` |

## Repository contents

| File | Installed to | Purpose |
|---|---|---|
| `bin/gb-power-sync` | `/usr/local/bin/` | Maps Omarchy power profiles to firmware modes, restarts `nvidia-powerd` |
| `systemd/gb-power-sync.service` | `/etc/systemd/system/` | Starts the service at boot |
| `systemd/acpi_call.conf` | `/etc/modules-load.d/` | Loads the `acpi_call` module (package `acpi_call-dkms`) |
| `bin/gb-charge-limit` | `/usr/local/bin/` | Battery charge limit (EC `BCPS`/`BCPC`) |
| `polkit/50-gb-charge-limit.rules` | `/etc/polkit-1/rules.d/` | Optional: change the limit via `pkexec` without a password |
| `bin/display-gpu-env` | `~/.local/bin/` | Detects which GPU drives the panel and prints env vars |
| `uwsm/env` | `~/.config/uwsm/env` | Loads `display-gpu-env`, pins Zed to the AMD GPU |
| `hypr/hyprland-gpu-env.lua` | end of `~/.config/hypr/hyprland.lua` | Same for Hyprland |
| `hypr/monitors.lua` | `~/.config/hypr/` | 165 Hz for both `eDP-1` and `eDP-2` |
| `hypr/input-razer.lua` | end of `~/.config/hypr/input.lua` | Flat mouse acceleration |
| `mangohud/MangoHud.conf` | `~/.config/MangoHud/` | Overlay layout and hotkeys |
| `omarchy-plugin/datar6.power/` | `~/.config/omarchy/plugins/` | Optional: battery panel with charge-limit buttons |
| `gigabyte-bios-bug-report.txt` | — | Report to Gigabyte about the `\_SB.PC00` ACPI bug |

### Fresh install

```bash
sudo pacman -S acpi_call-dkms gamemode mangohud openrazer-daemon
yay -S polychromatic
sudo gpasswd -a $USER gamemode
sudo gpasswd -a $USER openrazer

sudo install -m755 bin/gb-power-sync bin/gb-charge-limit /usr/local/bin/
sudo install -m644 systemd/gb-power-sync.service /etc/systemd/system/
sudo install -m644 systemd/acpi_call.conf /etc/modules-load.d/
sudo systemctl daemon-reload
sudo systemctl enable --now gb-power-sync nvidia-powerd
sudo gb-charge-limit 80

install -m755 bin/display-gpu-env ~/.local/bin/
cp mangohud/MangoHud.conf ~/.config/MangoHud/
# Append hypr/*.lua and uwsm/env to the matching files by hand
```

Battery panel with charge-limit buttons (instead of the stock one):

```bash
cp -r omarchy-plugin/datar6.power ~/.config/omarchy/plugins/
sudo install -m644 polkit/50-gb-charge-limit.rules /etc/polkit-1/rules.d/
# In ~/.config/omarchy/shell.json replace "omarchy.power" with "datar6.power"
omarchy restart shell
```

To go back to the stock panel, switch the id back to `"omarchy.power"` and delete the plugin folder.

### Uninstall

```bash
sudo systemctl disable --now gb-power-sync
sudo rm /usr/local/bin/gb-power-sync /usr/local/bin/gb-charge-limit \
  /etc/systemd/system/gb-power-sync.service /etc/modules-load.d/acpi_call.conf \
  /etc/gb-charge-limit /etc/polkit-1/rules.d/50-gb-charge-limit.rules
```

## Reference: firmware methods

Called through `acpi_call` (root required):

```bash
# write: method <id>, value <v> (one hex byte)
echo '\_SB.PCI0.AMW0.WMBD 0 0x<id> b<v>000000' | sudo tee /proc/acpi/call; sudo cat /proc/acpi/call
# read an EC register
echo '\_SB.PCI0.SBRG.EC0.CRAF' | sudo tee /proc/acpi/call; sudo cat /proc/acpi/call
```

| WMI id | EC register | Purpose |
|---|---|---|
| 237 (`0xED`) | — | Power mode 0–3 |
| 87 (`0x57`) | `CRAF` | Quiet flag: 1 = RTX capped at 30 W |
| 113 (`0x71`) | `FANB` | Gaming fans |
| 100 (`0x64`) | `BCPS` | Charge policy: 0 standard, 1 custom stop |
| 101 (`0x65`) | `BCPC` | Charge stop threshold, % |

To dump and read the ACPI table: `sudo cat /sys/firmware/acpi/tables/DSDT > DSDT && iasl -d DSDT` (package `acpica`); the methods are in `Method (WMBD` and `Method (WMBC`.

Known BIOS FB04 bug: the NVIDIA SSDT references `\_SB.PC00.AMW0.LTGP` instead of `\_SB.PCI0…`, so `dmesg` logs `AE_NOT_FOUND` every time the RTX wakes up. Harmless.
