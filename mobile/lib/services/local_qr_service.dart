// Local TOTP + Haversine — no backend needed for QR or Geo.
// Algorithm matches the FastAPI backend exactly:
//   secret = base32(HMAC-SHA256(orgSecret, 'adaptattend_qr'))
//   token  = TOTP(secret, interval=15)

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class LocalQrService {
  static const int _interval = 15;

  // ── TOTP ─────────────────────────────────────────────────────────────────────

  /// Generate a 6-digit token for the current 15-second window.
  static String generateToken(String orgSecret) {
    final counter = DateTime.now().millisecondsSinceEpoch ~/ 1000 ~/ _interval;
    return _totp(orgSecret, counter);
  }

  /// Verify a token — accepts the current window plus ±1 (handles small clock skew).
  static bool verifyToken(String orgSecret, String token) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    for (final delta in [-1, 0, 1]) {
      final counter = (now + delta * _interval) ~/ _interval;
      if (_totp(orgSecret, counter) == token) return true;
    }
    return false;
  }

  /// How many seconds remain in the current window.
  static int secondsLeft() {
    final elapsed = DateTime.now().millisecondsSinceEpoch ~/ 1000 % _interval;
    return _interval - elapsed;
  }

  // ── Geo ──────────────────────────────────────────────────────────────────────

  /// Haversine distance in metres between two lat/lon points.
  static double distanceMeters(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final a1 = lat1 * pi / 180, a2 = lat2 * pi / 180;
    final b1 = (lat2 - lat1) * pi / 180;
    final c1 = (lon2 - lon1) * pi / 180;
    final a = sin(b1 / 2) * sin(b1 / 2) +
        cos(a1) * cos(a2) * sin(c1 / 2) * sin(c1 / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static bool insideGeofence(
      double lat, double lng, double oLat, double oLng, double radius) =>
      distanceMeters(lat, lng, oLat, oLng) <= radius;

  // ── Internals ─────────────────────────────────────────────────────────────────

  static String _totp(String orgSecret, int counter) {
    // Derive key: HMAC-SHA256(orgSecret, 'adaptattend_qr')
    final raw = Hmac(sha256, utf8.encode(orgSecret))
        .convert(utf8.encode('adaptattend_qr'))
        .bytes;
    final key = _b32Decode(_b32Encode(raw));

    // Build 8-byte big-endian counter message
    final msg = Uint8List(8);
    var c = counter;
    for (int i = 7; i >= 0; i--) {
      msg[i] = c & 0xFF;
      c >>= 8;
    }

    // HMAC-SHA1 → dynamic truncation → 6 digits
    final digest = Hmac(sha1, key).convert(msg).bytes;
    final off = digest.last & 0x0F;
    final code = ((digest[off] & 0x7F) << 24) |
        ((digest[off + 1] & 0xFF) << 16) |
        ((digest[off + 2] & 0xFF) << 8) |
        (digest[off + 3] & 0xFF);
    return (code % 1000000).toString().padLeft(6, '0');
  }

  static const _b32Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  static String _b32Encode(List<int> bytes) {
    var out = '', buf = 0, bits = 0;
    for (final b in bytes) {
      buf = (buf << 8) | b;
      bits += 8;
      while (bits >= 5) {
        bits -= 5;
        out += _b32Chars[(buf >> bits) & 0x1F];
      }
    }
    if (bits > 0) out += _b32Chars[(buf << (5 - bits)) & 0x1F];
    return out;
  }

  static List<int> _b32Decode(String s) {
    final clean = s.toUpperCase().replaceAll('=', '');
    final out = <int>[];
    var buf = 0, bits = 0;
    for (final ch in clean.split('')) {
      final v = _b32Chars.indexOf(ch);
      if (v < 0) continue;
      buf = (buf << 5) | v;
      bits += 5;
      if (bits >= 8) {
        bits -= 8;
        out.add((buf >> bits) & 0xFF);
      }
    }
    return out;
  }
}
