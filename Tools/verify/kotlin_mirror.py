"""Line-for-line Python mirror of the Android app's astro/*.kt, used only to produce golden
values for the Swift unit tests (no Swift or Kotlin toolchain is reachable from this workspace).
Python floats and the JVM's doubles are both IEEE-754 binary64, so results agree to ~1e-12."""
import math

def sin_deg(d): return math.sin(math.radians(d))
def cos_deg(d): return math.cos(math.radians(d))
def tan_deg(d): return math.tan(math.radians(d))
def asin_deg(x): return math.degrees(math.asin(max(-1.0, min(1.0, x))))
def acos_deg(x): return math.degrees(math.acos(max(-1.0, min(1.0, x))))
def atan2_deg(y, x): return math.degrees(math.atan2(y, x))

def normalize(d):
    d = math.fmod(d, 360.0)           # Kotlin % == fmod (sign of dividend)
    if d < 0: d += 360.0
    return d

def jd_from_epoch(sec): return 2440587.5 + sec / 86400.0
def centuries(jd): return (jd - 2451545.0) / 36525.0

def gmst(jd):
    t = centuries(jd)
    return normalize(280.46061837 + 360.98564736629 * (jd - 2451545.0) + 0.000387933 * t * t - (t * t * t) / 38710000.0)

def lmst(jd, lon): return normalize(gmst(jd) + lon)

def cardinal(az):
    n = math.fmod(math.fmod(az, 360) + 360, 360)
    return ["N", "NE", "E", "SE", "S", "SW", "W", "NW"][int(n / 45.0 + 0.5) % 8]

def to_horizontal(ra, dec, lat, lon, jd):
    lst = lmst(jd, lon)
    ha = normalize(lst - ra)
    sin_alt = sin_deg(dec) * sin_deg(lat) + cos_deg(dec) * cos_deg(lat) * cos_deg(ha)
    alt = asin_deg(sin_alt)
    c = cos_deg(alt)
    if abs(c) < 1e-9: c = 1e-9
    cos_az = (sin_deg(dec) - sin_deg(alt) * sin_deg(lat)) / (c * cos_deg(lat))
    az = acos_deg(cos_az)
    if sin_deg(ha) > 0: az = 360.0 - az
    return alt, az

def sun(jd):
    t = centuries(jd)
    l0 = normalize(280.46646 + 36000.76983 * t + 0.0003032 * t * t)
    m = normalize(357.52911 + 35999.05029 * t - 0.0001537 * t * t)
    c = (1.914602 - 0.004817 * t - 0.000014 * t * t) * sin_deg(m) + (0.019993 - 0.000101 * t) * sin_deg(2 * m) + 0.000289 * sin_deg(3 * m)
    true_lon = l0 + c
    omega = normalize(125.04 - 1934.136 * t)
    app_lon = true_lon - 0.00569 - 0.00478 * sin_deg(omega)
    mean_obl = 23.439291 - 0.0130042 * t - 0.00000016 * t * t + 0.000000504 * t * t * t
    obl = mean_obl + 0.00256 * cos_deg(omega)
    ra = normalize(atan2_deg(cos_deg(obl) * sin_deg(app_lon), cos_deg(app_lon)))
    dec = asin_deg(sin_deg(obl) * sin_deg(app_lon))
    return ra, dec

def moon(jd):
    t = centuries(jd)
    lm = normalize(218.3164591 + 481267.88134236 * t)
    d = normalize(297.8502042 + 445267.1115168 * t)
    ms = normalize(357.5291092 + 35999.0502909 * t)
    mm = normalize(134.9634114 + 477198.8676313 * t)
    f = normalize(93.2720993 + 483202.0175273 * t)
    lon = (lm + 6.289 * sin_deg(mm) - 1.274 * sin_deg(mm - 2 * d) + 0.658 * sin_deg(2 * d) - 0.186 * sin_deg(ms)
           - 0.059 * sin_deg(2 * mm - 2 * d) - 0.057 * sin_deg(mm - 2 * d + ms) + 0.053 * sin_deg(mm + 2 * d)
           + 0.046 * sin_deg(2 * d - ms) + 0.041 * sin_deg(mm - ms) - 0.035 * sin_deg(d) - 0.031 * sin_deg(mm + ms)
           - 0.015 * sin_deg(2 * f - 2 * d) + 0.011 * sin_deg(mm - 4 * d))
    lat = (5.128 * sin_deg(f) + 0.281 * sin_deg(mm + f) + 0.278 * sin_deg(mm - f) + 0.173 * sin_deg(2 * d - f)
           + 0.055 * sin_deg(2 * d - mm + f) + 0.046 * sin_deg(2 * d - mm - f) + 0.033 * sin_deg(2 * d + f)
           + 0.017 * sin_deg(2 * mm + f))
    par = 0.9508 + 0.0518 * cos_deg(mm) + 0.0095 * cos_deg(mm - 2 * d) + 0.0078 * cos_deg(2 * d) + 0.0028 * cos_deg(2 * mm)
    obl = 23.439291 - 0.0130042 * t
    ra = normalize(atan2_deg(sin_deg(lon) * cos_deg(obl) - tan_deg(lat) * sin_deg(obl), cos_deg(lon)))
    dec = asin_deg(sin_deg(lat) * cos_deg(obl) + cos_deg(lat) * sin_deg(obl) * sin_deg(lon))
    return ra, dec, par

def _cos_elong(jd):
    mra, mdec, _ = moon(jd); sra, sdec = sun(jd)
    return sin_deg(mdec) * sin_deg(sdec) + cos_deg(mdec) * cos_deg(sdec) * cos_deg(mra - sra)

def moon_illum(jd): return (1 - _cos_elong(jd)) / 2
def moon_mag(jd):
    p = 180.0 - acos_deg(_cos_elong(jd))
    return -12.73 + 0.026 * p + 4e-9 * p ** 4

EARTH = (1.00000261, 0.00000562, 0.01671123, -0.00004392, -0.00001531, -0.01294668,
         100.46457166, 35999.37244981, 102.93768193, 0.32327364, 0.0, 0.0)
PLANETS = {
    "mercury": (0.38709927, 0.00000037, 0.20563593, 0.00001906, 7.00497902, -0.00594749, 252.25032350, 149472.67411175, 77.45779628, 0.16047689, 48.33076593, -0.12534081),
    "venus": (0.72333566, 0.00000390, 0.00677672, -0.00004107, 3.39467605, -0.00078890, 181.97909950, 58517.81538729, 131.60246718, 0.00268329, 76.67984255, -0.27769418),
    "mars": (1.52371034, 0.00001847, 0.09339410, 0.00007882, 1.84969142, -0.00813131, -4.55343205, 19140.30268499, -23.94362959, 0.44441088, 49.55953891, -0.29257343),
    "jupiter": (5.20288700, -0.00011607, 0.04838624, -0.00013253, 1.30439695, -0.00183714, 34.39644051, 3034.74612775, 14.72847983, 0.21252668, 100.47390909, 0.20469106),
    "saturn": (9.53667594, -0.00125060, 0.05386179, -0.00050991, 2.48599187, 0.00193609, 49.95424423, 1222.49362201, 92.59887831, -0.41897216, 113.66242448, -0.28867794),
    "uranus": (19.18916464, -0.00196176, 0.04725744, -0.00004397, 0.77263783, -0.00242939, 313.23810451, 428.48202785, 170.95427630, 0.40805281, 74.01692503, 0.04240589),
    "neptune": (30.06992276, 0.00026291, 0.00859048, 0.00005105, 1.77004347, 0.00035372, -55.12002969, 218.45945325, 44.96476227, -0.32241464, 131.78422574, -0.00508664),
}

def _helio(el, t):
    a = el[0] + el[1] * t; e = el[2] + el[3] * t; i = el[4] + el[5] * t
    l = el[6] + el[7] * t; lp = el[8] + el[9] * t; ln = el[10] + el[11] * t
    ma = normalize(l - lp)
    if ma > 180.0: ma -= 360.0
    m = math.radians(ma); E = m + e * math.sin(m)
    for _ in range(8): E -= (E - e * math.sin(E) - m) / (1 - e * math.cos(E))
    E = math.degrees(E)
    xo = a * (cos_deg(E) - e); yo = a * math.sqrt(1 - e * e) * sin_deg(E)
    w = lp - ln
    cO, sO, cW, sW, cI, sI = cos_deg(ln), sin_deg(ln), cos_deg(w), sin_deg(w), cos_deg(i), sin_deg(i)
    x = (cW * cO - sW * sO * cI) * xo + (-sW * cO - cW * sO * cI) * yo
    y = (cW * sO + sW * cO * cI) * xo + (-sW * sO + cW * cO * cI) * yo
    z = (sW * sI) * xo + (cW * sI) * yo
    return x, y, z

def planet(name, jd):
    t = centuries(jd)
    xe, ye, ze = _helio(EARTH, t); xp, yp, zp = _helio(PLANETS[name], t)
    x, y, z = xp - xe, yp - ye, zp - ze
    obl = 23.439291 - 0.0130042 * t
    ye2 = y * cos_deg(obl) - z * sin_deg(obl); ze2 = y * sin_deg(obl) + z * cos_deg(obl)
    ra = normalize(atan2_deg(ye2, x)); r = math.sqrt(x * x + ye2 * ye2 + ze2 * ze2)
    return ra, asin_deg(ze2 / r)

def series(pos, lat, lon, start, end, step_min):
    """start/end are epoch seconds (ints). Mirrors AltitudeSampler.series."""
    out = []; t = start
    while t <= end:
        jd = jd_from_epoch(t); alt, az = to_horizontal(*pos(jd), lat, lon, jd)
        out.append((t, alt, az)); t += step_min * 60
    if out[-1][0] != end:
        jd = jd_from_epoch(end); alt, az = to_horizontal(*pos(jd), lat, lon, jd)
        out.append((end, alt, az))
    return out

def _cross(a, b, thr):
    span = b[1] - a[1]
    if span == 0.0: return a[0] * 1000
    frac = (thr - a[1]) / span
    dur_ms = (b[0] - a[0]) * 1000
    return a[0] * 1000 + int(dur_ms * frac)      # Kotlin .toLong() truncates toward zero

def sample(pos, lat, lon, start, end, thr, step_min=2):
    s = series(pos, lat, lon, start, end, step_min)
    mx = s[0]
    for x in s:
        if x[1] > mx[1]: mx = x
    rise = sett = None
    for i in range(1, len(s)):
        p, c = s[i - 1], s[i]
        if p[1] < thr <= c[1] and rise is None: rise = _cross(p, c, thr)
        if p[1] >= thr > c[1]: sett = _cross(p, c, thr)
    return dict(ever=any(x[1] >= thr for x in s), always=all(x[1] >= thr for x in s),
                rise_ms=rise, set_ms=sett, max_t=mx[0], max_alt=mx[1], max_az=mx[2])
