# Licensing and attribution

## This repository

This configuration tree, including the Quickshell shell under `quickshell/` and
the Material 3 palette engine, is licensed under the **GNU General Public
License v3.0 or later**. See [`LICENSE`](LICENSE).

## Apache-2.0 component

`quickshell/tools/m3color.py` is a Python port of the Material Color Utilities
algorithms (CAM16, HCT, tonal palettes, dynamic schemes), originally from the
Material Foundation:

  https://github.com/material-foundation/material-color-utilities

That reference implementation is licensed under the **Apache License 2.0**, a
permissive license that is one-way compatible with GPL-3.0. Apache-2.0 requires
you to keep the Apache 2.0 notice, the copyright statement, and the NOTICE
contents with derivatives. The full Apache License 2.0 text is reproduced in
[`LICENSE-APACHE-2.0`](LICENSE-APACHE-2.0), and the ported module carries the
provenance notice at the top of the file.

The port was written from the published algorithm specification and by reading
the upstream Java sources. It deliberately does **not** vendor or link the
`materialyoucolor` PyPI package, which ships no license file and no license
metadata (checked against the PyPI JSON API), leaving it all rights reserved by
default.

## Vendored third-party code

The following is now present in this tree and is attributed here as its license requires.

### DankMaterialShell (MIT, Avenge Media LLC)

`quickshell/shaders/viz_bars.frag` is the six-bar audio visualizer fragment
shader from DankMaterialShell, driven by `quickshell/components/AudioVisualizer.qml`
and used by `MediaPlayerWidget.qml`.

  https://github.com/AvengeMedia/DankMaterialShell

```
MIT License

Copyright (c) 2025 Avenge Media LLC
```

The MIT notice and copyright must be retained in redistributions.

### Caelestia (GPL-3.0)

The full Caelestia shell is installed under `/opt/caelestia` (source:
caelestia-dots/shell). GPL-3.0 is the same license as this repository, so the
combined work is GPL-3.0 and the upstream `LICENSE` is installed alongside it at
`/opt/caelestia/etc/xdg/quickshell/caelestia/LICENSE`.

  https://github.com/caelestia-dots/shell

### m3shapes (MIT)

`M3Shapes`, a QML module providing Material 3 shapes, built from
`soramanew/m3shapes` at the pinned commit referenced by Caelestia's flake.
Installed under `/opt/caelestia/usr/lib/qt6/qml/M3Shapes`. Required by
Caelestia's UI components.

### cava (MIT, Karl Stavestrand)

Only `cavacore` (the FFT visualizer core) is built and installed, as
`libcavacore.a` plus headers under `/usr/local`, because Caelestia's services
module links against it. Built from cava v1.0.0 to match the `cava_init`
signature Caelestia expects.

  https://github.com/karlstav/cava

## Upstream projects that inspired, but are not incorporated

No source code from these projects is copied into this repository, so their
licenses do not currently constrain it:

| Project | License |
|---|---|
| https://github.com/end-4/dots-hyprland | GPL-3.0 |
| https://github.com/noctalia-dev/noctalia | MIT |
| https://github.com/AvengeMedia/DankMaterialShell | MIT (shader now vendored, see above) |
| https://github.com/caelestia-dots/shell | GPL-3.0 (now installed, see above) |
| https://github.com/ilyamiro/serpantinum | AGPL-3.0 |
| https://github.com/snowarch/iNiR | GPL-3.0 |

If you later vendor code from any of them, you must add its license and
copyright notice here. Note that AGPL-3.0 (Serpantinum, Ambxst) additionally
requires offering the corresponding source to users who interact with it over
a network.

## No-license caution

Several high-profile Quickshell configs linked from the official Quickshell
showcase have **no license file at all**, which means all rights reserved and
they are not legally reusable, despite being publicly visible. Do not paste from
these without obtaining permission:

- flickowoa/zephyr
- nydragon/nysh
- pfaj/nixos-config
- bdebiase/nixos-config
- ARCANGEL0/CyberArch-Shell
