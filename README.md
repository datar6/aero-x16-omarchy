# GIGABYTE AERO X16 на Omarchy

Шпаргалка и бэкап настроек ноутбука GIGABYTE AERO X16 4WH (BIOS FB04, Ryzen AI 9 465 + Radeon 890M, RTX 5070 Laptop) под Omarchy (Arch + Hyprland).

## Быстрые команды

### Питание и режимы прошивки

| Задача | Команда |
|---|---|
| Текущий профиль | `powerprofilesctl get` |
| Сменить профиль | `powerprofilesctl set performance` (`balanced`, `power-saver`) или панель батареи |
| Что применила служба | `journalctl -u gb-power-sync -n 5` |
| Перезапустить службу | `sudo systemctl restart gb-power-sync` |
| Мощность RTX сейчас | `nvidia-smi --query-gpu=power.draw,clocks.gr,power.limit --format=csv` |
| Почему RTX ограничена | `nvidia-smi -q -d PERFORMANCE` |
| RTX застряла на ~11 Вт | `sudo systemctl restart nvidia-powerd` или переключить профиль туда-обратно |

Профиль → прошивка (делает `gb-power-sync` автоматически):

| Профиль | Режим (WMI 237) | Тихий режим `CRAF` (WMI 87) | Игровые вентиляторы `FANB` (WMI 113) |
|---|---|---|---|
| power-saver | 0 (эко) | 1 (RTX до 30 Вт) | 0 |
| balanced | 1 | 0 | 0 |
| performance | 3 (игровой) | 0 | 1 |

### Порог зарядки батареи

| Задача | Команда |
|---|---|
| Показать порог и заряд | `gb-charge-limit` |
| Заряжать до 80 % (по умолчанию) | `sudo gb-charge-limit 80` |
| Любой порог 60–100 | `sudo gb-charge-limit 60` |
| Заряжать до 100 % (перед поездкой) | `sudo gb-charge-limit off` |

Порог хранится в `/etc/gb-charge-limit` и восстанавливается при загрузке.

### Игры

Параметры запуска в Steam (Свойства → Параметры запуска), Proton Experimental:

```
prime-run gamemoderun mangohud %command%
```

Для Deadlock в конце добавить ` -vulkan`.

| Задача | Как |
|---|---|
| Показать/скрыть MangoHud | `Ctrl_R + Shift_R + H` |
| Вкл/выкл лимит 165 FPS | `Ctrl_R + Shift_R + L` |
| Записать лог FPS | `Ctrl_R + Shift_R + R` → `~/Documents/mangohud-logs` |
| Игра на RTX? | `nvidia-smi` — процесс игры должен быть в списке |
| Температуры | `sensors`, `nvidia-smi` |

Перед игрой: родная зарядка (не USB-C 100 Вт) и профиль **performance**.

### Режим MUX (BIOS → Display Mode)

| Режим | Экран | Нужен `prime-run` |
|---|---|---|
| Dynamic | AMD, `eDP-2`, RTX спит | да |
| Discrete | NVIDIA, `eDP-1` | нет (не мешает) |

Драйверы видео (VA-API), монитор 165 Гц и рендер панели подстраиваются автоматически (`display-gpu-env`).

### Мышь Razer DeathAdder V3

| Задача | Команда |
|---|---|
| GUI | Polychromatic (лаунчер) |
| Частота опроса | `python3 -c "from openrazer.client import DeviceManager as D; d=D().devices[0]; d.poll_rate=2000"` |
| Проверить DPI/опрос | `python3 -c "from openrazer.client import DeviceManager as D; d=D().devices[0]; print(d.dpi, d.poll_rate)"` |

Ускорение курсора выключено в `~/.config/hypr/input.lua` (`accel_profile = "flat"`).

### Если что-то сломалось

| Симптом | Что делать |
|---|---|
| Панель Omarchy зависла | `pkill -9 quickshell; hyprctl dispatch 'hl.dsp.exec_cmd("omarchy-launch-shell")'` |
| Перезапуск панели (обычный) | `omarchy restart shell` |
| F-клавиши работают только с Fn | `Fn + Esc` (Fn Lock) |
| Микрофон не слышно | `wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 0` или клавиша mute микрофона |
| Чёрное видео в Chrome | проверить `~/.local/bin/display-gpu-env`, перезайти в сессию |
| Ошибки Hyprland | `hyprctl reload && hyprctl configerrors` |

## Что в репозитории

| Файл | Куда ставится | Что делает |
|---|---|---|
| `bin/gb-power-sync` | `/usr/local/bin/` | Связывает профили Omarchy с режимами прошивки, перезапускает `nvidia-powerd` |
| `systemd/gb-power-sync.service` | `/etc/systemd/system/` | Запуск службы при загрузке |
| `systemd/acpi_call.conf` | `/etc/modules-load.d/` | Загрузка модуля `acpi_call` (пакет `acpi_call-dkms`) |
| `bin/gb-charge-limit` | `/usr/local/bin/` | Порог зарядки (EC `BCPS`/`BCPC`) |
| `polkit/50-gb-charge-limit.rules` | `/etc/polkit-1/rules.d/` | Необязательно: менять порог через `pkexec` без пароля |
| `bin/display-gpu-env` | `~/.local/bin/` | Определяет GPU экрана и выдаёт переменные окружения |
| `uwsm/env` | `~/.config/uwsm/env` | Подключает `display-gpu-env`, Zed на AMD |
| `hypr/hyprland-gpu-env.lua` | конец `~/.config/hypr/hyprland.lua` | То же для Hyprland |
| `hypr/monitors.lua` | `~/.config/hypr/` | 165 Гц для `eDP-1` и `eDP-2` |
| `hypr/input-razer.lua` | конец `~/.config/hypr/input.lua` | Мышь без ускорения |
| `mangohud/MangoHud.conf` | `~/.config/MangoHud/` | Оверлей и горячие клавиши |
| `omarchy-plugin/datar6.power/` | `~/.config/omarchy/plugins/` | Необязательно: панель батареи с кнопками порога зарядки |
| `gigabyte-bios-bug-report.txt` | — | Отчёт Gigabyte об ошибке `\_SB.PC00` в ACPI |

### Установка с нуля

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
# hypr/*.lua и uwsm/env — вручную дописать в соответствующие файлы
```

Панель с кнопками порога (вместо стандартной):

```bash
cp -r omarchy-plugin/datar6.power ~/.config/omarchy/plugins/
sudo install -m644 polkit/50-gb-charge-limit.rules /etc/polkit-1/rules.d/
# в ~/.config/omarchy/shell.json заменить "omarchy.power" на "datar6.power"
omarchy restart shell
```

Вернуть стандартную: заменить обратно на `"omarchy.power"` и удалить папку плагина.

### Удаление

```bash
sudo systemctl disable --now gb-power-sync
sudo rm /usr/local/bin/gb-power-sync /usr/local/bin/gb-charge-limit \
  /etc/systemd/system/gb-power-sync.service /etc/modules-load.d/acpi_call.conf \
  /etc/gb-charge-limit /etc/polkit-1/rules.d/50-gb-charge-limit.rules
```

## Справка: методы прошивки

Вызов через `acpi_call` (нужен root):

```bash
# записать: метод <id>, значение <v> (байт в hex)
echo '\_SB.PCI0.AMW0.WMBD 0 0x<id> b<v>000000' | sudo tee /proc/acpi/call; sudo cat /proc/acpi/call
# прочитать регистр EC
echo '\_SB.PCI0.SBRG.EC0.CRAF' | sudo tee /proc/acpi/call; sudo cat /proc/acpi/call
```

| WMI id | Регистр EC | Назначение |
|---|---|---|
| 237 (`0xED`) | — | Режим питания 0–3 |
| 87 (`0x57`) | `CRAF` | Тихий режим: 1 = RTX до 30 Вт |
| 113 (`0x71`) | `FANB` | Игровые вентиляторы |
| 100 (`0x64`) | `BCPS` | Режим зарядки: 0 обычный, 1 с порогом |
| 101 (`0x65`) | `BCPC` | Порог зарядки, % |

Таблицу ACPI можно снять и прочитать так: `sudo cat /sys/firmware/acpi/tables/DSDT > DSDT && iasl -d DSDT` (пакет `acpica`), методы — в `Method (WMBD` и `Method (WMBC`.

Известный баг BIOS FB04: SSDT NVIDIA ссылается на `\_SB.PC00.AMW0.LTGP` вместо `\_SB.PCI0…`, поэтому в `dmesg` при каждом пробуждении RTX — `AE_NOT_FOUND`. Безвредно.
