#!/usr/bin/env python3
"""Derive a Material 3 palette from the current wallpaper and emit Theme.qml.

Usage:
    palette.py [--set PATH] [--force] [--dry-run]

    --set PATH   Set the wallpaper with awww, regenerate, reload.
    --force      Regenerate even if the wallpaper hash is unchanged.
    --dry-run    Print the derived roles without writing anything.

The wallpaper daemon is `awww` (formerly swww). awww has no "which image is
current" query, so the active path is tracked here in a state file, written by
--set and by the pick-wallpaper helper.

Output is written to quickshell/Theme.qml, a QML singleton whose property
names match the ones the widget components already use. Components therefore
keep working untouched: the colours are simply generated instead of hardcoded.

The script is idempotent. It records a hash of the wallpaper it used and skips
regeneration when nothing changed, so it is cheap to call from a compositor
startup hook, a keybinding or a file watcher.
"""

import argparse
import hashlib
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
CONFIG_DIR = os.path.dirname(HERE)
sys.path.insert(0, HERE)

try:
    import m3color
except ImportError as exc:
    sys.exit("cannot import m3color: %s" % exc)

AWWW = os.path.expanduser("~/.local/bin/awww")
AWWW_DAEMON = os.path.expanduser("~/.local/bin/awww-daemon")
CACHE_DIR = os.path.expanduser("~/.cache/awww")
STATE_DIR = os.path.expanduser("~/.local/state/quickshell")
CURRENT_WALLPAPER = os.path.join(STATE_DIR, "wallpaper-current")
QML_OUT = os.path.join(CONFIG_DIR, "Theme.qml")
LAST_HASH_FILE = os.path.join(STATE_DIR, "palette.hash")

# Pillow lives in the system interpreter's site-packages, but the python3 first
# on PATH here is Hermes' own build, which has no Pillow. Re-exec through the
# distro interpreter once (guarded, so it can never loop) when that is the case.
if not os.environ.get("_PALETTE_REEXEC"):
    try:
        import PIL  # noqa: F401
    except ImportError:
        for candidate in ("/usr/bin/python3", "/usr/bin/python3.13"):
            if os.path.exists(candidate) and os.path.realpath(candidate) != os.path.realpath(sys.executable):
                os.environ["_PALETTE_REEXEC"] = "1"
                os.execv(candidate, [candidate, os.path.abspath(__file__)] + sys.argv[1:])

FALLBACK = "#6750A4"

# Historical property names consumed by components, in file order.
ROLE_ORDER = [
    "bg", "surface", "surface2", "surface3", "border",
    "text", "muted", "muted2",
    "accent", "accent2", "accentStrong",
    "secondary", "secondary2", "secondaryStrong",
    "critical", "onAccentText", "panelOverlay",
]

# Component property -> Material 3 role.
ROLE_MAP = {
    "bg": "background",
    "surface": "surface",
    "surface2": "surfaceContainer",
    "surface3": "surfaceContainerHigh",
    "border": "outlineVariant",
    "text": "onSurface",
    "muted": "onSurfaceVariant",
    "muted2": "outline",
    "accent": "primary",
    "accent2": "inversePrimary",
    "accentStrong": "primaryContainer",
    "secondary": "secondary",
    "secondary2": "tertiary",
    "secondaryStrong": "secondaryContainer",
    "critical": "error",
    "onAccentText": "onPrimary",
}


def log(*a):
    print("[palette]", *a, file=sys.stderr)


def file_hash(path):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 16), b""):
            h.update(chunk)
    return h.hexdigest()


def awww_query():
    """Ask the awww daemon which wallpaper it currently shows, if any.

    awww-daemon keeps no config file, so the active image is only knowable from
    the daemon itself. Returns a path or None.
    """
    import json
    try:
        out = subprocess.run(
            [AWWW_DAEMON, "query"],
            capture_output=True, text=True, timeout=5,
        ).stdout
    except (OSError, subprocess.TimeoutExpired):
        return None
    for line in out.splitlines():
        line = line.strip()
        if not line.startswith("{"):
            continue
        try:
            payload = json.loads(line)
        except ValueError:
            continue
        path = payload.get("image") or payload.get("path")
        if isinstance(path, str) and os.path.exists(path):
            return path
    return None


def read_wallpapers():
    """The wallpaper currently shown, tracked in the state file.

    awww exposes no query for the active image, so the path is recorded when
    --set runs (and by the pick-wallpaper helper). Falls back to the state file
    written by earlier runs.
    """
    path = awww_query()
    if not path and os.path.exists(CURRENT_WALLPAPER):
        try:
            candidate = open(CURRENT_WALLPAPER).read().strip()
            if candidate:
                path = candidate
        except OSError:
            pass
    if path and os.path.exists(path):
        return [path]
    return []


def extract_palette(path, max_side=192, colors=32):
    """Return `colors` representative ARGB values, cheaply.

    Resource notes, because this runs on every wallpaper change:

    * `draft()` makes libjpeg/libpng decode straight to a reduced size during
      the IDCT pass, so a 8.3 megapixel JPEG never becomes an 8.3 megapixel
      buffer. This is by far the biggest saving.
    * `thumbnail()` then only rescales what is already small, with BILINEAR
      rather than LANCZOS.
    * Quantisation runs in Pillow's C median-cut instead of pure Python, and
      `getcolors` / the palette table avoid materialising a Python tuple per
      pixel. Peak memory is a few hundred kilobytes, not tens of megabytes.
    * 192 px and 32 colours are ample for choosing a palette seed; Material You
      only needs the dominant hues, and a smaller box also makes the HCT scoring
      below cheaper.
    """
    from PIL import Image

    try:
        quantize_enum = Image.Quantize.MEDIANCUT
    except AttributeError:  # Pillow < 9.1
        quantize_enum = Image.MEDIANCUT

    with Image.open(path) as opened:
        opened.draft("RGB", (max_side, max_side))
        img = opened.convert("RGB")
        if max(img.size) > max_side:
            img.thumbnail((max_side, max_side), Image.Resampling.BILINEAR)
        reduced = img.quantize(colors=colors, method=quantize_enum)

        table = reduced.getpalette()[: colors * 3]
        histogram = reduced.getcolors() or []

    if not table:
        return []

    # Weight each palette entry by how many sampled pixels map to it, so the
    # dominant colour of the wallpaper wins.
    weights = {index: count for count, index in histogram}
    out = []
    for index in range(min(colors, len(table) // 3)):
        r = table[index * 3]
        g = table[index * 3 + 1]
        b = table[index * 3 + 2]
        out.append((m3color.argb_from_rgb(r, g, b), weights.get(index, 0)))

    out.sort(key=lambda item: -item[1])
    return [argb for argb, _ in out]


def choose_seed(argbs):
    if not argbs:
        return m3color.argb_from_hex(FALLBACK), "fallback"
    ranked = m3color.score_colors(argbs)
    if not ranked:
        return m3color.argb_from_hex(FALLBACK), "fallback"
    return ranked[0], "ranked"


def build_scheme(seed, dark):
    core = m3color.CorePalette(seed)
    scheme = m3color.DynamicScheme(core, dark)

    if dark:
        extra = {
            "surfaceContainer": core.n1.tone(12),
            "surfaceContainerHigh": core.n1.tone(17),
            "shadow": "#000000",
            "scrim": "#000000",
        }
    else:
        extra = {
            "surfaceContainer": core.n1.tone(94),
            "surfaceContainerHigh": core.n1.tone(92),
            "shadow": "#000000",
            "scrim": "#000000",
        }

    roles = scheme.roles()
    roles.update(extra)
    return roles


def overlay_from_scrim(scrim_hex, alpha=0.74):
    argb = m3color.argb_from_hex(scrim_hex)
    r, g, b = (argb >> 16) & 0xFF, (argb >> 8) & 0xFF, argb & 0xFF
    return "rgba(%d, %d, %d, %.2f)" % (r, g, b, alpha)


def render_qml(seed_hex, seed_source, roles, source_paths):
    lines = [
        "// GENERATED FILE - do not edit by hand.",
        "// Regenerated by quickshell/tools/palette.py from the wallpaper.",
        "//",
        "// Material 3 roles derived from: %s" % ", ".join(
            os.path.basename(p) for p in source_paths
        ) or "(none)",
        "// Seed colour: %s (%s)" % (seed_hex, seed_source),
        "pragma Singleton",
        "import QtQuick",
        "",
        "QtObject {",
        '    readonly property string mode: "dark"',
        "",
    ]
    for name in ROLE_ORDER:
        if name == "panelOverlay":
            lines.append(
                '    readonly property string panelOverlay: "%s"'
                % overlay_from_scrim(roles.get("scrim", "#000000"))
            )
            continue
        role = ROLE_MAP[name]
        lines.append('    readonly property color %s: "%s"' % (name, roles.get(role, FALLBACK)))
    lines.append("}")
    lines.append("")
    return "\n".join(lines)


def write_theme(seed_hex, seed_source, roles, source_paths):
    body = render_qml(seed_hex, seed_source, roles, source_paths)
    os.makedirs(os.path.dirname(QML_OUT), exist_ok=True)
    tmp = tempfile.NamedTemporaryFile(
        "w", dir=os.path.dirname(QML_OUT), delete=False, prefix=".theme-"
    )
    tmp.write(body)
    tmp.close()
    os.replace(tmp.name, QML_OUT)
    return body


def set_wallpaper(path):
    """Set the wallpaper through awww and record it as the active image."""
    path = os.path.abspath(path)
    if not os.path.exists(path):
        sys.exit("wallpaper not found: %s" % path)

    if shutil.which("awww") or os.path.exists(AWWW):
        # awww is the wallpaper daemon here; it replaces the image directly.
        # A missing daemon is not fatal: the state file below still makes the
        # next palette run pick this image up.
        result = subprocess.run(
            [AWWW, "img", path],
            capture_output=True, text=True, timeout=30,
        )
        if result.returncode != 0:
            log("awww img failed: %s" % (result.stderr or "").strip())
    else:
        log("awww not found, wallpaper recorded for next session")

    with open(CURRENT_WALLPAPER, "w") as fh:
        fh.write(path)


def signal_shell():
    """Ask the paint to be applied.

    Theme.qml is a QML singleton resolved when the shell is instantiated, so a
    regenerated file is not picked up by a running instance. A niri config
    reload re-runs the shell's spawn line, which already replaces the stale
    instance; that is the cheapest reliable way to repaint.
    """
    for tool in ("niri",):
        if shutil.which(tool):
            subprocess.call(
                [tool, "msg", "action", "reload-config"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            return
    log("niri not found, palette applies on next shell start")


def main(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument("--set", dest="set_wallpaper", metavar="PATH")
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args(argv)

    os.makedirs(CACHE_DIR, exist_ok=True)

    if args.set_wallpaper:
        set_wallpaper(args.set_wallpaper)

    walls = read_wallpapers()
    source_paths = []
    combined = []
    for path in walls:
        if not os.path.exists(path):
            continue
        source_paths.append(path)
        try:
            combined.extend(extract_palette(path))
        except Exception as exc:
            log("cannot read %s: %s" % (path, exc))

    digest = hashlib.sha256(
        b"".join(file_hash(p).encode() for p in source_paths)
    ).hexdigest() if source_paths else ""

    if not args.force and digest and os.path.exists(LAST_HASH_FILE) \
            and os.path.exists(QML_OUT) \
            and open(LAST_HASH_FILE).read().strip() == digest:
        log("palette up to date, skipping")
        signal_shell()
        return 0

    seed, seed_source = choose_seed(combined) if combined else (
        m3color.argb_from_hex(FALLBACK), "fallback"
    )
    seed_hex = m3color.hex_from_argb(seed)

    if digest:
        with open(LAST_HASH_FILE, "w") as fh:
            fh.write(digest)

    roles = build_scheme(seed, True)

    if args.dry_run:
        log("seed %s (%s)" % (seed_hex, seed_source))
        for name in ROLE_ORDER:
            print("%-16s %s" % (name, render_value(name, roles)))
        return 0

    write_theme(seed_hex, seed_source, roles, source_paths)
    log("seed %s (%s) -> %s" % (seed_hex, seed_source, QML_OUT))
    signal_shell()
    return 0


def render_value(name, roles):
    if name == "panelOverlay":
        return overlay_from_scrim(roles.get("scrim", "#000000"))
    return roles.get(ROLE_MAP[name], FALLBACK)


if __name__ == "__main__":
    sys.exit(main())