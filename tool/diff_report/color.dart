import 'dart:math' as math;

/// CIE L*a*b* (D65) of an sRGB colour.
typedef Lab = ({double l, double a, double b});

Lab labOf(int r, int g, int b) {
  double lin(int c) {
    final v = c / 255;
    return v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  }

  final rl = lin(r), gl = lin(g), bl = lin(b);
  final x = (rl * 0.4124564 + gl * 0.3575761 + bl * 0.1804375) / 0.95047;
  final y = rl * 0.2126729 + gl * 0.7151522 + bl * 0.0721750;
  final z = (rl * 0.0193339 + gl * 0.1191920 + bl * 0.9503041) / 1.08883;
  double f(double t) => t > 216 / 24389 ? math.pow(t, 1 / 3).toDouble() : (24389 / 27 * t + 16) / 116;
  final fx = f(x), fy = f(y), fz = f(z);
  return (l: 116 * fy - 16, a: 500 * (fx - fy), b: 200 * (fy - fz));
}

Lab labOfHex(String hex) {
  final v = int.parse(hex.replaceFirst('#', ''), radix: 16);
  return labOf((v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF);
}

/// CIEDE2000 colour difference (Sharma, Wu & Dalal 2005), kL = kC = kH = 1.
double deltaE2000(Lab p, Lab q) {
  const deg = math.pi / 180;
  final c1 = math.sqrt(p.a * p.a + p.b * p.b);
  final c2 = math.sqrt(q.a * q.a + q.b * q.b);
  final cBar = (c1 + c2) / 2;
  final cBar7 = math.pow(cBar, 7);
  final g = 0.5 * (1 - math.sqrt(cBar7 / (cBar7 + math.pow(25, 7))));
  final a1 = (1 + g) * p.a, a2 = (1 + g) * q.a;
  final c1p = math.sqrt(a1 * a1 + p.b * p.b);
  final c2p = math.sqrt(a2 * a2 + q.b * q.b);
  double hue(double b, double a) {
    if (a == 0 && b == 0) return 0;
    final h = math.atan2(b, a) / deg;
    return h < 0 ? h + 360 : h;
  }

  final h1 = hue(p.b, a1), h2 = hue(q.b, a2);
  final dL = q.l - p.l;
  final dC = c2p - c1p;
  var dh = 0.0;
  if (c1p * c2p != 0) {
    dh = h2 - h1;
    if (dh > 180) dh -= 360;
    if (dh < -180) dh += 360;
  }
  final dH = 2 * math.sqrt(c1p * c2p) * math.sin(dh / 2 * deg);
  final lBar = (p.l + q.l) / 2;
  final cBarP = (c1p + c2p) / 2;
  var hBar = h1 + h2;
  if (c1p * c2p != 0) {
    if ((h1 - h2).abs() > 180) hBar += h1 + h2 < 360 ? 360 : -360;
    hBar /= 2;
  }
  final t = 1 -
      0.17 * math.cos((hBar - 30) * deg) +
      0.24 * math.cos(2 * hBar * deg) +
      0.32 * math.cos((3 * hBar + 6) * deg) -
      0.20 * math.cos((4 * hBar - 63) * deg);
  final dTheta = 30 * math.exp(-math.pow((hBar - 275) / 25, 2));
  final cBarP7 = math.pow(cBarP, 7);
  final rc = 2 * math.sqrt(cBarP7 / (cBarP7 + math.pow(25, 7)));
  final sl = 1 + 0.015 * math.pow(lBar - 50, 2) / math.sqrt(20 + math.pow(lBar - 50, 2));
  final sc = 1 + 0.045 * cBarP;
  final sh = 1 + 0.015 * cBarP * t;
  final rt = -math.sin(2 * dTheta * deg) * rc;
  final lTerm = dL / sl, cTerm = dC / sc, hTerm = dH / sh;
  return math.sqrt(lTerm * lTerm + cTerm * cTerm + hTerm * hTerm + rt * cTerm * hTerm);
}
