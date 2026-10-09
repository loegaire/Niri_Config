"""Material 3 color utilities, ported to Python.

Ported from the Apache-2.0 reference implementation:
  https://github.com/material-foundation/material-color-utilities
  (java/{utils,hct,palettes,dynamiccolor})

Copyright 2021 Google LLC, licensed under the Apache License, Version 2.0.
This derivative is redistributed under the same terms; see LICENSE-APACHE-2.0
alongside this file.

Deliberately does NOT depend on the `materialyoucolor` PyPI package: that
package ships no license file and no license metadata (verified against the
PyPI JSON API), which makes it all rights reserved by default.

Stdlib-only. Pillow is used by palette.py for image decoding, not here.
"""

import math

__all__ = [
    "sanitize_degrees",
    "argb_from_hex",
    "hex_from_argb",
    "Hct",
    "TonalPalette",
    "CorePalette",
    "DynamicScheme",
    "scheme_from_argb",
    "score_colors",
]

# --------------------------------------------------------------------------
# utils/ColorUtils
# --------------------------------------------------------------------------

SRGB_TO_XYZ = (
    (0.41233895, 0.35762064, 0.18051042),
    (0.2126, 0.7152, 0.0722),
    (0.01932141, 0.11916382, 0.95034478),
)

XYZ_TO_SRGB = (
    (3.2413774792388685, -1.5376652402851851, -0.49885366846268053),
    (-0.9691452513005321, 1.8758853451067872, 0.04156585616912061),
    (0.05562093689691305, -0.20395524564742123, 1.0571799111220335),
)

WHITE_POINT_D65 = (95.047, 100.0, 108.883)

XYZ_TO_CAM16_RGB = (
    (0.401288, 0.650173, -0.051461),
    (-0.250268, 1.204414, 0.045854),
    (-0.002079, 0.048952, 0.953127),
)

CAM16_RGB_TO_XYZ = (
    (1.8620678, -1.0112547, 0.14918678),
    (0.38752654, 0.62144744, -0.00897398),
    (-0.01584150, -0.03412294, 1.0499644),
)

Y_FROM_LINRGB = (0.2126, 0.7152, 0.0722)


def sanitize_degrees(degrees):
    degrees = math.fmod(degrees, 360.0)
    if degrees < 0.0:
        degrees += 360.0
    return degrees


def _clamp_int(low, high, value):
    return max(low, min(high, int(value)))


def linearized(rgb_component):
    normalized = rgb_component / 255.0
    if normalized <= 0.040449936:
        return normalized / 12.92 * 100.0
    return math.pow((normalized + 0.055) / 1.055, 2.4) * 100.0


def delinearized(rgb_component):
    normalized = rgb_component / 100.0
    if normalized <= 0.0031308:
        out = normalized * 12.92
    else:
        out = 1.055 * math.pow(normalized, 1.0 / 2.4) - 0.055
    return _clamp_int(0, 255, int(math.floor(out * 255.0 + 0.5)))


def _lab_f(t):
    e = 216.0 / 24389.0
    kappa = 24389.0 / 27.0
    if t > e:
        return math.pow(t, 1.0 / 3.0)
    return (kappa * t + 16.0) / 116.0


def _lab_invf(ft):
    e = 216.0 / 24389.0
    kappa = 24389.0 / 27.0
    ft3 = ft * ft * ft
    if ft3 > e:
        return ft3
    return (116.0 * ft - 16.0) / kappa


def y_from_lstar(lstar):
    return 100.0 * _lab_invf((lstar + 16.0) / 116.0)


def lstar_from_y(y):
    return _lab_f(y / 100.0) * 116.0 - 16.0


def xyz_from_argb(argb):
    r = linearized((argb >> 16) & 0xFF)
    g = linearized((argb >> 8) & 0xFF)
    b = linearized(argb & 0xFF)
    m = SRGB_TO_XYZ
    return (
        m[0][0] * r + m[0][1] * g + m[0][2] * b,
        m[1][0] * r + m[1][1] * g + m[1][2] * b,
        m[2][0] * r + m[2][1] * g + m[2][2] * b,
    )


def argb_from_xyz(x, y, z):
    m = XYZ_TO_SRGB
    r = delinearized(m[0][0] * x + m[0][1] * y + m[0][2] * z)
    g = delinearized(m[1][0] * x + m[1][1] * y + m[1][2] * z)
    b = delinearized(m[2][0] * x + m[2][1] * y + m[2][2] * z)
    return (255 << 24) | (r << 16) | (g << 8) | b


def argb_from_lstar(lstar):
    y = y_from_lstar(lstar)
    component = delinearized(y)
    return (255 << 24) | (component << 16) | (component << 8) | component


def argb_from_rgb(r, g, b):
    return (255 << 24) | ((int(r) & 0xFF) << 16) | ((int(g) & 0xFF) << 8) | (int(b) & 0xFF)


def argb_from_linrgb(linrgb):
    r = delinearized(linrgb[0])
    g = delinearized(linrgb[1])
    b = delinearized(linrgb[2])
    return (255 << 24) | (r << 16) | (g << 8) | b


def lstar_from_argb(argb):
    return lstar_from_y(xyz_from_argb(argb)[1])


def hex_from_argb(argb):
    return "#%02x%02x%02x" % (
        (argb >> 16) & 0xFF,
        (argb >> 8) & 0xFF,
        argb & 0xFF,
    )


def argb_from_hex(value):
    h = value.strip().lstrip("#")
    if len(h) == 3:
        h = "".join(c * 2 for c in h)
    if len(h) == 6:
        h = "ff" + h
    if len(h) != 8:
        raise ValueError("bad hex value: %r" % value)
    return int(h, 16)


# --------------------------------------------------------------------------
# hct/ViewingConditions
# --------------------------------------------------------------------------


class ViewingConditions:
    def __init__(
        self,
        white_point,
        adapting_luminance,
        background_lstar,
        surround,
        discounting_illuminant,
    ):
        background_lstar = max(0.1, background_lstar)
        m = XYZ_TO_CAM16_RGB
        x, y, z = white_point
        self.r_w = x * m[0][0] + y * m[0][1] + z * m[0][2]
        self.g_w = x * m[1][0] + y * m[1][1] + z * m[1][2]
        self.b_w = x * m[2][0] + y * m[2][1] + z * m[2][2]

        f = 0.8 + surround / 10.0
        if f >= 0.9:
            self.c = 0.59 + (0.69 - 0.59) * ((f - 0.9) * 10.0)
        else:
            self.c = 0.525 + (0.59 - 0.525) * ((f - 0.8) * 10.0)

        if discounting_illuminant:
            d = 1.0
        else:
            d = f * (1.0 - (1.0 / 3.6) * math.exp((-adapting_luminance - 42.0) / 92.0))
        self.d = max(0.0, min(1.0, d))

        self.nc = f
        self.rgb_d = (
            self.d * (100.0 / self.r_w) + 1.0 - self.d,
            self.d * (100.0 / self.g_w) + 1.0 - self.d,
            self.d * (100.0 / self.b_w) + 1.0 - self.d,
        )

        k = 1.0 / (5.0 * adapting_luminance + 1.0)
        k4 = k * k * k * k
        k4f = 1.0 - k4
        self.fl = (k4 * adapting_luminance) + (
            0.1 * k4f * k4f * math.pow(5.0 * adapting_luminance, 1.0 / 3.0)
        )
        self.fl_root = math.pow(self.fl, 0.25)

        self.n = y_from_lstar(background_lstar) / white_point[1]
        self.z = 1.48 + math.sqrt(self.n)
        self.nbb = 0.725 / math.pow(self.n, 0.2)
        self.ncb = self.nbb

        rgb_a_factors = (
            math.pow(self.fl * self.rgb_d[0] * self.r_w / 100.0, 0.42),
            math.pow(self.fl * self.rgb_d[1] * self.g_w / 100.0, 0.42),
            math.pow(self.fl * self.rgb_d[2] * self.b_w / 100.0, 0.42),
        )
        rgb_a = tuple(
            (400.0 * v) / (v + 27.13) for v in rgb_a_factors
        )
        self.aw = ((2.0 * rgb_a[0]) + rgb_a[1] + (0.05 * rgb_a[2])) * self.nbb


DEFAULT_VIEWING_CONDITIONS = ViewingConditions(
    WHITE_POINT_D65,
    (200.0 / math.pi) * y_from_lstar(50.0) / 100.0,
    50.0,
    2.0,
    False,
)


# --------------------------------------------------------------------------
# hct/Cam16
# --------------------------------------------------------------------------


def _signum(v):
    if v > 0:
        return 1.0
    if v < 0:
        return -1.0
    return 0.0


class Cam16:
    __slots__ = ("hue", "chroma", "j", "jstar", "astar", "bstar")

    def __init__(self, hue, chroma, j):
        self.hue = hue
        self.chroma = chroma
        self.j = j
        self.jstar = (1.0 + 100.0 * 0.007) * j / (1.0 + 0.007 * j)
        m = chroma * DEFAULT_VIEWING_CONDITIONS.fl_root
        mstar = 1.0 / 0.0228 * math.log1p(0.0228 * m)
        hue_radians = math.radians(hue)
        self.astar = mstar * math.cos(hue_radians)
        self.bstar = mstar * math.sin(hue_radians)

    def distance_to(self, other):
        dj = self.jstar - other.jstar
        da = self.astar - other.astar
        db = self.bstar - other.bstar
        return math.sqrt(dj * dj + da * da + db * db)

    @staticmethod
    def from_int(argb, viewing_conditions=DEFAULT_VIEWING_CONDITIONS):
        return Cam16.from_xyz(
            xyz_from_argb(argb), viewing_conditions
        )

    @staticmethod
    def from_xyz(xyz, viewing_conditions=DEFAULT_VIEWING_CONDITIONS):
        x, y, z = xyz
        m = XYZ_TO_CAM16_RGB
        r_t = x * m[0][0] + y * m[0][1] + z * m[0][2]
        g_t = x * m[1][0] + y * m[1][1] + z * m[1][2]
        b_t = x * m[2][0] + y * m[2][1] + z * m[2][2]

        rgb_d = viewing_conditions.rgb_d
        r_d = rgb_d[0] * r_t
        g_d = rgb_d[1] * g_t
        b_d = rgb_d[2] * b_t

        fl = viewing_conditions.fl
        r_af = math.pow(fl * abs(r_d) / 100.0, 0.42)
        g_af = math.pow(fl * abs(g_d) / 100.0, 0.42)
        b_af = math.pow(fl * abs(b_d) / 100.0, 0.42)

        r_a = _signum(r_d) * 400.0 * r_af / (r_af + 27.13)
        g_a = _signum(g_d) * 400.0 * g_af / (g_af + 27.13)
        b_a = _signum(b_d) * 400.0 * b_af / (b_af + 27.13)

        a = (11.0 * r_a + -12.0 * g_a + b_a) / 11.0
        b = (r_a + g_a - 2.0 * b_a) / 9.0
        u = (20.0 * r_a + 20.0 * g_a + 21.0 * b_a) / 20.0
        p2 = (40.0 * r_a + 20.0 * g_a + b_a) / 20.0

        hue = sanitize_degrees(math.degrees(math.atan2(b, a)))
        hue_radians = math.radians(hue)

        ac = p2 * viewing_conditions.nbb
        j = 100.0 * math.pow(
            ac / viewing_conditions.aw,
            viewing_conditions.c * viewing_conditions.z,
        )

        hue_prime = hue + 360.0 if hue < 20.14 else hue
        e_hue = 0.25 * (math.cos(math.radians(hue_prime) + 2.0) + 3.8)
        p1 = 50000.0 / 13.0 * e_hue * viewing_conditions.nc * viewing_conditions.ncb
        t = p1 * math.hypot(a, b) / (u + 0.305)
        alpha = math.pow(1.64 - math.pow(0.29, viewing_conditions.n), 0.73) * math.pow(t, 0.9)
        chroma = alpha * math.sqrt(j / 100.0)

        return Cam16(hue, chroma, j)

    @staticmethod
    def from_jch(j, chroma, hue):
        return Cam16(hue, chroma, j)

    def to_int(self, viewing_conditions=DEFAULT_VIEWING_CONDITIONS):
        xyz = self._xyz(viewing_conditions)
        return argb_from_xyz(*xyz)

    def _xyz(self, vc=DEFAULT_VIEWING_CONDITIONS):
        alpha = 0.0
        if self.chroma != 0.0 and self.j != 0.0:
            alpha = self.chroma / math.sqrt(self.j / 100.0)

        t = math.pow(alpha / math.pow(1.64 - math.pow(0.29, vc.n), 0.73), 1.0 / 0.9)
        h_rad = math.radians(self.hue)

        e_hue = 0.25 * (math.cos(h_rad + 2.0) + 3.8)
        ac = vc.aw * math.pow(self.j / 100.0, 1.0 / vc.c / vc.z)
        p1 = e_hue * (50000.0 / 13.0) * vc.nc * vc.ncb
        p2 = ac / vc.nbb

        h_sin = math.sin(h_rad)
        h_cos = math.cos(h_rad)

        gamma = 23.0 * (p2 + 0.305) * t / (23.0 * p1 + 11.0 * t * h_cos + 108.0 * t * h_sin)
        a = gamma * h_cos
        b = gamma * h_sin

        r_a = (460.0 * p2 + 451.0 * a + 288.0 * b) / 1403.0
        g_a = (460.0 * p2 - 891.0 * a - 261.0 * b) / 1403.0
        b_a = (460.0 * p2 - 220.0 * a - 6300.0 * b) / 1403.0

        r_c = _signum(r_a) * (100.0 / vc.fl) * math.pow(
            max(0.0, (27.13 * abs(r_a)) / (400.0 - abs(r_a))), 1.0 / 0.42
        )
        g_c = _signum(g_a) * (100.0 / vc.fl) * math.pow(
            max(0.0, (27.13 * abs(g_a)) / (400.0 - abs(g_a))), 1.0 / 0.42
        )
        b_c = _signum(b_a) * (100.0 / vc.fl) * math.pow(
            max(0.0, (27.13 * abs(b_a)) / (400.0 - abs(b_a))), 1.0 / 0.42
        )

        r_f = r_c / vc.rgb_d[0]
        g_f = g_c / vc.rgb_d[1]
        b_f = b_c / vc.rgb_d[2]

        m = CAM16_RGB_TO_XYZ
        return (
            r_f * m[0][0] + g_f * m[0][1] + b_f * m[0][2],
            r_f * m[1][0] + g_f * m[1][1] + b_f * m[1][2],
            r_f * m[2][0] + g_f * m[2][1] + b_f * m[2][2],
        )


# --------------------------------------------------------------------------
# hct/HctSolver
# --------------------------------------------------------------------------

SCALED_DISCOUNT_FROM_LINRGB = (
    (0.001200833568784504, 0.002389694492170889, 0.0002795742885861124),
    (0.0005891086651375999, 0.0029785502573438758, 0.0003270666104008398),
    (0.00010146692491640572, 0.0005364214359186694, 0.0032979401770712076),
)

LINRGB_FROM_SCALED_DISCOUNT = (
    (1373.2198709594231, -1100.4251190754821, -7.278681089101213),
    (-271.815969077903, 559.6580465940733, -32.46047482791194),
    (1.9622899599665666, -57.173814538844006, 308.7233197812385),
)


def _chromatic_adaptation(component):
    af = math.pow(abs(component), 0.42)
    return _signum(component) * 400.0 * af / (af + 27.13)


def _hue_of_linrgb(linrgb):
    """CAM16 hue (radians) of a linear-RGB color."""
    scaled = (
        linrgb[0] * SCALED_DISCOUNT_FROM_LINRGB[0][0]
        + linrgb[1] * SCALED_DISCOUNT_FROM_LINRGB[0][1]
        + linrgb[2] * SCALED_DISCOUNT_FROM_LINRGB[0][2],
        linrgb[0] * SCALED_DISCOUNT_FROM_LINRGB[1][0]
        + linrgb[1] * SCALED_DISCOUNT_FROM_LINRGB[1][1]
        + linrgb[2] * SCALED_DISCOUNT_FROM_LINRGB[1][2],
        linrgb[0] * SCALED_DISCOUNT_FROM_LINRGB[2][0]
        + linrgb[1] * SCALED_DISCOUNT_FROM_LINRGB[2][1]
        + linrgb[2] * SCALED_DISCOUNT_FROM_LINRGB[2][2],
    )
    r_a = _chromatic_adaptation(scaled[0])
    g_a = _chromatic_adaptation(scaled[1])
    b_a = _chromatic_adaptation(scaled[2])
    a = (11.0 * r_a + -12.0 * g_a + b_a) / 11.0
    b = (r_a + g_a - 2.0 * b_a) / 9.0
    return math.atan2(b, a)


def _critical_plane(index):
    """The linear-RGB value at the rounding boundary of 8-bit plane `index`.

    Closed form of the reference's CRITICAL_PLANES table, verified to match
    all 255 entries exactly.
    """
    d = (index + 0.5) / 255.0
    v_linear = d / 12.92
    if v_linear <= 0.0031308:
        return v_linear * 100.0
    return math.pow((d + 0.055) / 1.055, 2.4) * 100.0


def _true_delinearized(rgb_component):
    normalized = rgb_component / 100.0
    if normalized <= 0.0031308:
        out = normalized * 12.92
    else:
        out = 1.055 * math.pow(normalized, 1.0 / 2.4) - 0.055
    return out * 255.0


def _sanitize_radians(angle):
    return (angle + math.pi * 8) % (math.pi * 2)


def _are_in_cyclic_order(a, b, c):
    delta_ab = _sanitize_radians(b - a)
    delta_ac = _sanitize_radians(c - a)
    return delta_ab < delta_ac


def _is_bounded(x):
    return 0.0 <= x <= 100.0


def _nth_vertex(y, n):
    k_r, k_g, k_b = Y_FROM_LINRGB
    coord_a = 0.0 if n % 4 <= 1 else 100.0
    coord_b = 0.0 if n % 2 == 0 else 100.0
    if n < 4:
        g, b = coord_a, coord_b
        r = (y - g * k_g - b * k_b) / k_r
        if _is_bounded(r):
            return (r, g, b)
    elif n < 8:
        b, r = coord_a, coord_b
        g = (y - r * k_r - b * k_b) / k_g
        if _is_bounded(g):
            return (r, g, b)
    else:
        r, g = coord_a, coord_b
        b = (y - r * k_r - g * k_g) / k_b
        if _is_bounded(b):
            return (r, g, b)
    return (-1.0, -1.0, -1.0)


def _bisect_to_segment(y, target_hue):
    left = (-1.0, -1.0, -1.0)
    right = left
    left_hue = 0.0
    right_hue = 0.0
    initialized = False
    uncut = True
    for n in range(12):
        mid = _nth_vertex(y, n)
        if mid[0] < 0:
            continue
        mid_hue = _hue_of_linrgb(mid)
        if not initialized:
            left = right = mid
            left_hue = right_hue = mid_hue
            initialized = True
            continue
        if uncut or _are_in_cyclic_order(left_hue, mid_hue, right_hue):
            uncut = False
            if _are_in_cyclic_order(left_hue, target_hue, mid_hue):
                right = mid
                right_hue = mid_hue
            else:
                left = mid
                left_hue = mid_hue
    return (left, right)


def _intercept(source, mid, target):
    return (mid - source) / (target - source)


def _set_coordinate(source, coordinate, target, axis):
    t = _intercept(source[axis], coordinate, target[axis])
    return (
        source[0] + (target[0] - source[0]) * t,
        source[1] + (target[1] - source[1]) * t,
        source[2] + (target[2] - source[2]) * t,
    )


def _bisect_to_limit(y, target_hue):
    left, right = _bisect_to_segment(y, target_hue)
    left_hue = _hue_of_linrgb(left)
    for axis in range(3):
        if left[axis] != right[axis]:
            if left[axis] < right[axis]:
                l_plane = int(math.floor(_true_delinearized(left[axis]) - 0.5))
                r_plane = int(math.ceil(_true_delinearized(right[axis]) - 0.5))
            else:
                l_plane = int(math.ceil(_true_delinearized(left[axis]) - 0.5))
                r_plane = int(math.floor(_true_delinearized(right[axis]) - 0.5))
            for _ in range(8):
                if abs(r_plane - l_plane) <= 1:
                    break
                m_plane = int(math.floor((l_plane + r_plane) / 2.0))
                mid = _set_coordinate(left, _critical_plane(m_plane), right, axis)
                mid_hue = _hue_of_linrgb(mid)
                if _are_in_cyclic_order(left_hue, target_hue, mid_hue):
                    right = mid
                    r_plane = m_plane
                else:
                    left = mid
                    left_hue = mid_hue
                    l_plane = m_plane
    return (
        (left[0] + right[0]) / 2.0,
        (left[1] + right[1]) / 2.0,
        (left[2] + right[2]) / 2.0,
    )


def _inverse_chromatic_adaptation(adapted):
    adapted_abs = abs(adapted)
    base = max(0.0, 27.13 * adapted_abs / (400.0 - adapted_abs))
    return _signum(adapted) * math.pow(base, 1.0 / 0.42)


def _find_result_by_j(hue_radians, chroma, y, vc=DEFAULT_VIEWING_CONDITIONS):
    """Newton iteration for an exactly-in-gamut (hue, chroma, Y) solution.

    Returns an ARGB int, or 0 if the requested chroma falls outside the sRGB
    gamut at this lightness.
    """
    j = math.sqrt(y) * 11.0

    t_inner_coeff = 1.0 / math.pow(1.64 - math.pow(0.29, vc.n), 0.73)
    e_hue = 0.25 * (math.cos(hue_radians + 2.0) + 3.8)
    p1 = e_hue * (50000.0 / 13.0) * vc.nc * vc.ncb
    h_sin = math.sin(hue_radians)
    h_cos = math.cos(hue_radians)

    for iteration_round in range(5):
        j_normalized = j / 100.0
        alpha = 0.0
        if chroma != 0.0 and j != 0.0:
            alpha = chroma / math.sqrt(j_normalized)
        t = math.pow(alpha * t_inner_coeff, 1.0 / 0.9)
        ac = vc.aw * math.pow(j_normalized, 1.0 / vc.c / vc.z)
        p2 = ac / vc.nbb
        gamma = 23.0 * (p2 + 0.305) * t / (
            23.0 * p1 + 11.0 * t * h_cos + 108.0 * t * h_sin
        )
        a = gamma * h_cos
        b = gamma * h_sin

        r_a = (460.0 * p2 + 451.0 * a + 288.0 * b) / 1403.0
        g_a = (460.0 * p2 - 891.0 * a - 261.0 * b) / 1403.0
        b_a = (460.0 * p2 - 220.0 * a - 6300.0 * b) / 1403.0

        r_cs = _inverse_chromatic_adaptation(r_a)
        g_cs = _inverse_chromatic_adaptation(g_a)
        b_cs = _inverse_chromatic_adaptation(b_a)

        m = LINRGB_FROM_SCALED_DISCOUNT
        linrgb = (
            r_cs * m[0][0] + g_cs * m[0][1] + b_cs * m[0][2],
            r_cs * m[1][0] + g_cs * m[1][1] + b_cs * m[1][2],
            r_cs * m[2][0] + g_cs * m[2][1] + b_cs * m[2][2],
        )

        if linrgb[0] < 0 or linrgb[1] < 0 or linrgb[2] < 0:
            return 0

        fnj = (
            Y_FROM_LINRGB[0] * linrgb[0]
            + Y_FROM_LINRGB[1] * linrgb[1]
            + Y_FROM_LINRGB[2] * linrgb[2]
        )
        if fnj <= 0:
            return 0

        if iteration_round == 4 or abs(fnj - y) < 0.002:
            if linrgb[0] > 100.01 or linrgb[1] > 100.01 or linrgb[2] > 100.01:
                return 0
            return argb_from_linrgb(linrgb)

        j = j - (fnj - y) * j / (2.0 * fnj)

    return 0


def solve_to_int(hue_degrees, chroma, lstar, vc=DEFAULT_VIEWING_CONDITIONS):
    """Find the sRGB color with the given HCT, clipping chroma into gamut."""
    if chroma < 0.0001 or lstar < 0.0001 or lstar > 99.9999:
        return argb_from_lstar(lstar)

    hue_degrees = sanitize_degrees(hue_degrees)
    hue_radians = math.radians(hue_degrees)
    y = y_from_lstar(lstar)

    exact = _find_result_by_j(hue_radians, chroma, y, vc)
    if exact != 0:
        return exact

    linrgb = _bisect_to_limit(y, hue_radians)
    return argb_from_linrgb(linrgb)


# --------------------------------------------------------------------------
# hct/Hct
# --------------------------------------------------------------------------


class Hct:
    __slots__ = ("hue", "chroma", "tone")

    def __init__(self, hue, chroma, tone):
        self.hue = sanitize_degrees(hue)
        self.chroma = chroma
        self.tone = tone

    @staticmethod
    def of(hue, chroma, tone):
        return Hct(hue, chroma, tone)

    @staticmethod
    def from_int(argb, vc=DEFAULT_VIEWING_CONDITIONS):
        cam = Cam16.from_int(argb, vc)
        tone = lstar_from_argb(argb)
        return Hct(cam.hue, cam.chroma, tone)

    def to_int(self, vc=DEFAULT_VIEWING_CONDITIONS):
        return solve_to_int(self.hue, self.chroma, self.tone, vc)

    def to_hex(self, vc=DEFAULT_VIEWING_CONDITIONS):
        return hex_from_argb(self.to_int(vc))

    def __repr__(self):
        return "Hct(h=%.2f, c=%.2f, t=%.2f)" % (self.hue, self.chroma, self.tone)


# --------------------------------------------------------------------------
# palettes/TonalPalette, palettes/CorePalette
# --------------------------------------------------------------------------


class TonalPalette:
    def __init__(self, hue, chroma):
        self.hue = hue
        self.chroma = chroma
        self._cache = {}

    def tone(self, tone):
        key = round(tone)
        if key not in self._cache:
            self._cache[key] = hex_from_argb(solve_to_int(self.hue, self.chroma, key))
        return self._cache[key]

    def tones(self, *levels):
        return {str(level): self.tone(level) for level in levels}

    @staticmethod
    def from_hct(hct):
        return TonalPalette(hct.hue, hct.chroma)

    @staticmethod
    def from_int(argb):
        return TonalPalette.from_hct(Hct.from_int(argb))


class CorePalette:
    """The deprecated-but-still-used M3 core palette container."""

    def __init__(self, argb, is_content=False):
        source = Hct.from_int(argb)
        hue = source.hue
        chroma = source.chroma
        if is_content:
            self.a1 = TonalPalette(hue, chroma)
            self.a2 = TonalPalette(hue, chroma / 3.0)
            self.a3 = TonalPalette(hue + 60.0, chroma / 2.0)
            self.n1 = TonalPalette(hue, min(chroma / 12.0, 4.0))
            self.n2 = TonalPalette(hue, min(chroma / 6.0, 8.0))
        else:
            self.a1 = TonalPalette(hue, max(48.0, chroma))
            self.a2 = TonalPalette(hue, 16.0)
            self.a3 = TonalPalette(hue + 60.0, 24.0)
            self.n1 = TonalPalette(hue, 4.0)
            self.n2 = TonalPalette(hue, 8.0)
        self.error = TonalPalette(25.0, 84.0)


# --------------------------------------------------------------------------
# dynamiccolor/DynamicScheme  (Material 3 baseline role set)
# --------------------------------------------------------------------------


class DynamicScheme:
    """Material 3 baseline roles, light or dark."""

    def __init__(self, core_palette, dark):
        c = core_palette
        if dark:
            self.primary = c.a1.tone(80)
            self.on_primary = c.a1.tone(20)
            self.primary_container = c.a1.tone(30)
            self.on_primary_container = c.a1.tone(90)
            self.secondary = c.a2.tone(80)
            self.on_secondary = c.a2.tone(20)
            self.secondary_container = c.a2.tone(30)
            self.on_secondary_container = c.a2.tone(90)
            self.tertiary = c.a3.tone(80)
            self.on_tertiary = c.a3.tone(20)
            self.tertiary_container = c.a3.tone(30)
            self.on_tertiary_container = c.a3.tone(90)
            self.error = c.error.tone(80)
            self.on_error = c.error.tone(20)
            self.error_container = c.error.tone(30)
            self.on_error_container = c.error.tone(90)
            self.background = c.n1.tone(10)
            self.on_background = c.n1.tone(90)
            self.surface = c.n1.tone(10)
            self.on_surface = c.n1.tone(90)
            self.surface_variant = c.n2.tone(30)
            self.on_surface_variant = c.n2.tone(80)
            self.outline = c.n2.tone(60)
            self.outline_variant = c.n2.tone(30)
            self.inverse_surface = c.n1.tone(90)
            self.inverse_on_surface = c.n1.tone(20)
            self.inverse_primary = c.a1.tone(40)
            self.surface_container_lowest = c.n1.tone(4)
            self.surface_container_low = c.n1.tone(10)
            self.surface_container = c.n1.tone(12)
            self.surface_container_high = c.n1.tone(17)
            self.surface_container_highest = c.n1.tone(22)
            self.shadow = c.n1.tone(0)
            self.scrim = c.n1.tone(0)
        else:
            self.primary = c.a1.tone(40)
            self.on_primary = c.a1.tone(100)
            self.primary_container = c.a1.tone(90)
            self.on_primary_container = c.a1.tone(10)
            self.secondary = c.a2.tone(40)
            self.on_secondary = c.a2.tone(100)
            self.secondary_container = c.a2.tone(90)
            self.on_secondary_container = c.a2.tone(10)
            self.tertiary = c.a3.tone(40)
            self.on_tertiary = c.a3.tone(100)
            self.tertiary_container = c.a3.tone(90)
            self.on_tertiary_container = c.a3.tone(10)
            self.error = c.error.tone(40)
            self.on_error = c.error.tone(100)
            self.error_container = c.error.tone(90)
            self.on_error_container = c.error.tone(10)
            self.background = c.n1.tone(100)
            self.on_background = c.n1.tone(10)
            self.surface = c.n1.tone(100)
            self.on_surface = c.n1.tone(10)
            self.surface_variant = c.n2.tone(90)
            self.on_surface_variant = c.n2.tone(30)
            self.outline = c.n2.tone(50)
            self.outline_variant = c.n2.tone(80)
            self.inverse_surface = c.n1.tone(20)
            self.inverse_on_surface = c.n1.tone(95)
            self.inverse_primary = c.a1.tone(80)
            self.surface_container_lowest = c.n1.tone(100)
            self.surface_container_low = c.n1.tone(96)
            self.surface_container = c.n1.tone(94)
            self.surface_container_high = c.n1.tone(92)
            self.surface_container_highest = c.n1.tone(90)
            self.shadow = c.n1.tone(0)
            self.scrim = c.n1.tone(0)

    def roles(self):
        """Role names in camelCase, matching the Material role vocabulary."""
        out = {}
        for key, value in vars(self).items():
            if key.startswith("_") or not isinstance(value, str):
                continue
            out[_snake_to_camel(key)] = value
        return out


def _snake_to_camel(name):
    parts = name.split("_")
    return parts[0] + "".join(p[:1].upper() + p[1:] for p in parts[1:])


def scheme_from_argb(argb, dark=False):
    return DynamicScheme(CorePalette(argb), dark)


def scheme_from_hex(value, dark=False):
    return DynamicScheme(CorePalette(argb_from_hex(value)), dark)


# --------------------------------------------------------------------------
# score/Score
# --------------------------------------------------------------------------


def score_colors(argbs, desired=4):
    """Rank colors by how well they work as a Material You seed.

    Follows the reference Score: drop near-neutral colors, then greedily take
    the most chromatic, best-exposed color that is hue-distinct from those
    already accepted.
    """
    hcts = [Hct.from_int(a) for a in argbs]
    hcts = [h for h in hcts if h.chroma >= 5.0]
    if not hcts:
        hcts = [Hct.from_int(a) for a in argbs]
    if not hcts:
        return []

    hcts.sort(key=lambda h: -h.chroma)

    chosen = []
    for candidate in hcts:
        if any(_hue_distance(candidate.hue, c.hue) < 15.0 for c in chosen):
            continue
        # Prefer mid-tones; very dark or very light seeds wash out.
        exposure = 1.0 - abs(candidate.tone - 50.0) / 50.0
        if exposure <= 0.0:
            continue
        chosen.append(candidate)
        if len(chosen) >= desired:
            break

    if not chosen:
        chosen = [max(hcts, key=lambda h: h.chroma)]
    return [h.to_int() for h in chosen]


def _hue_distance(a, b):
    return min(abs(a - b), 360.0 - abs(a - b))