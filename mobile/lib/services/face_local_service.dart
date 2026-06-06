/// On-device face recognition — no server, no model download.
///
/// Pipeline:
///   1. Google ML Kit FaceDetector  → face bounding box from the photo file
///   2. `image` package             → crop + resize to 64×64 greyscale
///   3. LBP histogram (256 bins)    → compact face descriptor
///   4. Cosine similarity           → compare enrollment vs selfie
///
/// Enrollment is stored in SharedPreferences as a JSON list, keyed by userId.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database.dart' show AppUser;

class FaceLocalResult {
  final bool match;
  final double confidence; // 0.0 – 1.0
  final String? error;

  const FaceLocalResult({
    required this.match,
    required this.confidence,
    this.error,
  });

  String get pctLabel => '${(confidence * 100).round()}%';
}

/// Returned by [FaceLocalService.findBestMatch] for manager-side 1-to-N scan.
class FaceMatchResult {
  final AppUser user;
  final double confidence;

  const FaceMatchResult({required this.user, required this.confidence});

  String get pctLabel => '${(confidence * 100).round()}%';
}

class FaceLocalService {
  static const _cropSize       = 64;   // pixels
  static const _matchThreshold = 0.82; // cosine similarity for same-person

  static final _detector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableLandmarks: false,
      enableContours: false,
      enableClassification: false,
    ),
  );

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Compute face embedding from [imagePath] and store it for [userId].
  /// Called when manager saves an employee's profile photo.
  /// Returns true on success, false if no face was found.
  static Future<bool> enroll(String userId, String imagePath) async {
    final embedding = await _embed(imagePath);
    if (embedding == null) return false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('face_embed_$userId', jsonEncode(embedding));
    return true;
  }

  /// Compare [selfiePath] against the stored embedding for [userId].
  static Future<FaceLocalResult> verify(String userId, String selfiePath) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('face_embed_$userId');

    if (stored == null) {
      return const FaceLocalResult(
        match: false, confidence: 0,
        error: 'Not enrolled — ask the manager to update your profile photo',
      );
    }

    final enrolledEmbed = (jsonDecode(stored) as List).cast<double>();
    final selfieEmbed   = await _embed(selfiePath);

    if (selfieEmbed == null) {
      return const FaceLocalResult(
        match: false, confidence: 0,
        error: 'No face detected — good lighting, look straight at the camera',
      );
    }

    final similarity = _cosine(enrolledEmbed, selfieEmbed);
    return FaceLocalResult(
      match:      similarity >= _matchThreshold,
      confidence: similarity.clamp(0.0, 1.0),
    );
  }

  /// Returns true if [userId] has an enrolled face embedding.
  static Future<bool> isEnrolled(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('face_embed_$userId');
  }

  /// Enroll from a Flutter asset bundle path (e.g. 'assets/images/emma.jpg').
  /// Copies the asset to a temp file, runs [enroll], then cleans up.
  /// Used to pre-seed demo employees at app launch.
  static Future<bool> enrollFromAsset(String userId, String assetPath) async {
    try {
      final data  = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      final dir   = await getTemporaryDirectory();
      final tmp   = File('${dir.path}/face_enroll_$userId.jpg');
      await tmp.writeAsBytes(bytes);
      final success = await enroll(userId, tmp.path);
      await tmp.delete().catchError((_) {});
      return success;
    } catch (_) {
      return false;
    }
  }

  /// 1-to-N search: find the best-matching enrolled employee for [selfiePath].
  /// Returns null if no face is detected in the selfie or no match is found.
  static Future<FaceMatchResult?> findBestMatch(
      String selfiePath, List<AppUser> users) async {
    final selfieEmbed = await _embed(selfiePath);
    if (selfieEmbed == null) return null;

    final prefs = await SharedPreferences.getInstance();
    FaceMatchResult? best;

    for (final user in users) {
      final stored = prefs.getString('face_embed_${user.id}');
      if (stored == null) continue;
      final enrolled  = (jsonDecode(stored) as List).cast<double>();
      final sim       = _cosine(enrolled, selfieEmbed);
      if (sim >= _matchThreshold && (best == null || sim > best.confidence)) {
        best = FaceMatchResult(user: user, confidence: sim);
      }
    }

    return best;
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  /// Detect the largest face in [imagePath], crop it and return a 256-d LBP
  /// histogram. Returns null if no face is detected or image can't be read.
  static Future<List<double>?> _embed(String imagePath) async {
    // ── 1. ML Kit face detection ──────────────────────────────────────────
    final inputImage = InputImage.fromFilePath(imagePath);
    List<Face> faces;
    try {
      faces = await _detector.processImage(inputImage);
    } catch (_) {
      return null;
    }
    if (faces.isEmpty) return null;

    // Pick the largest detected face
    final face = faces.reduce((a, b) =>
        (a.boundingBox.width * a.boundingBox.height) >=
        (b.boundingBox.width * b.boundingBox.height) ? a : b);

    // ── 2. Load image with the Dart `image` package ───────────────────────
    final bytes = await File(imagePath).readAsBytes();
    final full  = img.decodeImage(bytes);
    if (full == null) return null;

    // ── 3. Crop face region (25% padding on each side) ────────────────────
    final bb    = face.boundingBox;
    final padX  = (bb.width  * 0.25).round();
    final padY  = (bb.height * 0.25).round();
    final cropX = (bb.left.toInt()   - padX).clamp(0, full.width  - 1);
    final cropY = (bb.top.toInt()    - padY).clamp(0, full.height - 1);
    final cropW = (bb.width.toInt()  + padX * 2).clamp(1, full.width  - cropX);
    final cropH = (bb.height.toInt() + padY * 2).clamp(1, full.height - cropY);

    final cropped = img.copyCrop(full,
        x: cropX, y: cropY, width: cropW, height: cropH);

    // ── 4. Resize → greyscale ─────────────────────────────────────────────
    final resized = img.copyResize(cropped,
        width: _cropSize, height: _cropSize,
        interpolation: img.Interpolation.linear);
    final grey = img.grayscale(resized);

    // ── 5. LBP histogram ─────────────────────────────────────────────────
    return _lbp(grey);
  }

  /// Compute a 256-bin Local Binary Pattern histogram from a greyscale image.
  /// LBP captures micro-texture patterns unique to each face.
  static List<double> _lbp(img.Image grey) {
    final w    = grey.width;
    final h    = grey.height;
    final hist = List<double>.filled(256, 0.0);

    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        final c = img.getLuminance(grey.getPixel(x, y));
        int code = 0;

        // 8 clockwise neighbours starting from top-left
        final neighbors = [
          img.getLuminance(grey.getPixel(x - 1, y - 1)),
          img.getLuminance(grey.getPixel(x,     y - 1)),
          img.getLuminance(grey.getPixel(x + 1, y - 1)),
          img.getLuminance(grey.getPixel(x + 1, y    )),
          img.getLuminance(grey.getPixel(x + 1, y + 1)),
          img.getLuminance(grey.getPixel(x,     y + 1)),
          img.getLuminance(grey.getPixel(x - 1, y + 1)),
          img.getLuminance(grey.getPixel(x - 1, y    )),
        ];

        for (int i = 0; i < 8; i++) {
          if (neighbors[i] >= c) code |= (1 << i);
        }
        hist[code]++;
      }
    }

    // Normalise so embeddings are comparable regardless of image size
    final total = ((w - 2) * (h - 2)).toDouble();
    return hist.map((v) => v / total).toList();
  }

  /// Cosine similarity between two equal-length vectors. Range [–1, 1].
  static double _cosine(List<double> a, List<double> b) {
    double dot = 0, na = 0, nb = 0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      na  += a[i] * a[i];
      nb  += b[i] * b[i];
    }
    if (na == 0 || nb == 0) return 0;
    return dot / (sqrt(na) * sqrt(nb));
  }
}
