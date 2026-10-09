!my current setup

# Niri_Config

## Thinh Swiss Palette Sync

This config tree is aligned with the local `Thinh-Swiss-Dark` GTK theme.

Core roles:

- Black: `#000000`
- Near-black surface: `#050505`, `#0a0a0a`, `#111111`
- Text: `#ffffff`
- Primary accent / active / positive: `#a7cdd9`, `#434766`
- Secondary accent / hover / selected: `#ffd29d`, `#ffc078`
- Destructive / critical: `#ff6b6b`

Synced configs:

- GTK/XSettings: `gtk-3.0`, `gtk-4.0`, `xsettingsd`, `nwg-look`
- niri session colors and env: `niri/config.kdl`
- Shell/UI: `waybar`, `mako`, `wofi`, `quickshell`, `eww`
- Terminal/TUI: `kitty`, `starship.toml`, `neofetch`, `cava`
- Editors/apps: `Code`, `Antigravity`, `MuseScore`, `Godot`, `Zathura`, `Flameshot`, `Vesktop`
- KDE/Qt color config: `kdeglobals`, `kdenlive*`, `qt5ct`, `qt6ct`, `Kvantum`

Qt plugin packages still need system installation:

```sh
sudo dnf install -y qt5ct qt6ct kvantum kvantum-qt5
```

Or run the helper from this repo:

```sh
./thinh-swiss-enable-qt.sh
```

After those packages are installed, the helper enables these commented Qt lines in `niri/config.kdl`:

```kdl
QT_QPA_PLATFORMTHEME "qt5ct"
QT_STYLE_OVERRIDE "kvantum"
KVANTUM_THEME "ThinhSwissDark"
```

Then restart the niri session or log out and back in.
