/// On-device face recognition — no server, no cloud.
///
/// Pipeline:
///   1. Google ML Kit FaceDetector  → face bounding box
///   2. `image` package             → crop + resize to 112×112 RGB
///   3. MobileFaceNet TFLite model  → 128-d float32 embedding
///   4. Cosine similarity           → compare enrollment vs selfie
///
/// Model: assets/models/mobilefacenet.tflite
///   Input  : [1, 112, 112, 3] float32, values in [-1, 1]
///   Output : [1, 128] float32 L2-normalised embedding
///
/// Embeddings are stored in SharedPreferences as JSON, keyed by userId.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

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
  // ── Config ────────────────────────────────────────────────────────────────
  static const _modelAsset     = 'assets/models/mobilefacenet.tflite';
  static const _inputSize      = 112;   // MobileFaceNet input: 112×112
  static const _embeddingDim   = 128;   // MobileFaceNet output: 128-d
  static const _matchThreshold = 0.70;  // cosine similarity — same person

  // ── Singletons (lazy-initialised) ─────────────────────────────────────────
  static Interpreter? _interpreter;
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
  static Future<bool> enroll(String userId, String imagePath) async {
    final embedding = await _embed(imagePath);
    if (embedding == null) return false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('face_embed_$userId', jsonEncode(embedding));
    return true;
  }

  /// Enroll from a Flutter asset bundle path (e.g. 'assets/images/emma.jpg').
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

  /// Compare [selfiePath] against the stored embedding for [userId].
  static Future<FaceLocalResult> verify(String userId, String selfiePath) async {
    final prefs  = await SharedPreferences.getInstance();
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

  /// 1-to-N search: find the best-matching enrolled employee for [selfiePath].
  static Future<FaceMatchResult?> findBestMatch(
      String selfiePath, List<AppUser> users) async {
    final selfieEmbed = await _embed(selfiePath);
    if (selfieEmbed == null) return null;

    final prefs = await SharedPreferences.getInstance();
    FaceMatchResult? best;

    for (final user in users) {
      final stored = prefs.getString('face_embed_${user.id}');
      if (stored == null) continue;
      final enrolled = (jsonDecode(stored) as List).cast<double>();
      final sim      = _cosine(enrolled, selfieEmbed);
      if (sim >= _matchThreshold && (best == null || sim > best.confidence)) {
        best = FaceMatchResult(user: user, confidence: sim);
      }
    }

    return best;
  }

  // ── TFLite inference ──────────────────────────────────────────────────────

  static Future<Interpreter> _getInterpreter() async {
    _interpreter ??= await Interpreter.fromAsset(_modelAsset);
    return _interpreter!;
  }

  /// Detect face, crop, run MobileFaceNet, return L2-normalised 128-d embedding.
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

    final face = faces.reduce((a, b) =>
        (a.boundingBox.width * a.boundingBox.height) >=
        (b.boundingBox.width * b.boundingBox.height) ? a : b);

    // ── 2. Load + crop + resize face ──────────────────────────────────────
    final bytes = await File(imagePath).readAsBytes();
    final full  = img.decodeImage(bytes);
    if (full == null) return null;

    final bb   = face.boundingBox;
    final padX = (bb.width  * 0.25).round();
    final padY = (bb.height * 0.25).round();
    final cropX = (bb.left.toInt()   - padX).clamp(0, full.width  - 1);
    final cropY = (bb.top.toInt()    - padY).clamp(0, full.height - 1);
    final cropW = (bb.width.toInt()  + padX * 2).clamp(1, full.width  - cropX);
    final cropH = (bb.height.toInt() + padY * 2).clamp(1, full.height - cropY);

    final cropped = img.copyCrop(full,
        x: cropX, y: cropY, width: cropW, height: cropH);
    final resized = img.copyResize(cropped,
        width: _inputSize, height: _inputSize,
        interpolation: img.Interpolation.linear);

    // ── 3. Build input tensor [1, 112, 112, 3] float32 in [-1, 1] ────────
    final input = _imageToInput(resized);

    // ── 4. Allocate output matching the model's actual shape and run ─────────
    final interp = await _getInterpreter();

    // Read shape from the model (e.g. [1, 128] or [1, 192])
    final outShape = interp.getOutputTensor(0).shape; // [batchSize, embDim]
    final embDim   = outShape.last;

    // Output must be nested to match [1, embDim]
    final outputBuffer = [List<double>.filled(embDim, 0.0)];
    final outputs = <int, Object>{0: outputBuffer};
    interp.runForMultipleInputs([input], outputs);

    return _l2Normalize(outputBuffer[0]);
  }

  /// Returns a [1][H][W][3] nested list of float32 values in [-1, 1].
  static List _imageToInput(img.Image image) {
    final h = image.height;
    final w = image.width;
    return List.generate(1, (_) =>
      List.generate(h, (y) =>
        List.generate(w, (x) {
          final p = image.getPixel(x, y);
          return [
            (p.r.toDouble() - 127.5) / 128.0,
            (p.g.toDouble() - 127.5) / 128.0,
            (p.b.toDouble() - 127.5) / 128.0,
          ];
        })
      )
    );
  }

  // ── Math helpers ─────────────────────────────────────────────────────────

  static List<double> _l2Normalize(List<double> v) {
    double norm = 0;
    for (final x in v) norm += x * x;
    norm = sqrt(norm);
    if (norm == 0) return v;
    return v.map((x) => x / norm).toList();
  }

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
