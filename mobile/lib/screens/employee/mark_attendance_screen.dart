import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value;
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../data/database.dart';
import '../../services/auth_service.dart';
import '../../services/face_local_service.dart';
import '../../services/local_qr_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/employee_avatar.dart';
import '../../widgets/common_widgets.dart';

const _uuid = Uuid();

class MarkAttendanceScreen extends StatefulWidget {
  const MarkAttendanceScreen({super.key});
  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  AttendanceRecord? _todayRecord;
  bool _loading = true;
  bool _working = false;
  final _qrCtrl = TextEditingController();
  Duration _elapsed = Duration.zero;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _qrCtrl.dispose();
    _clock?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final user = AuthService.currentUser!;
    final rec = await db.getTodayRecord(user.id);
    if (mounted) setState(() { _todayRecord = rec; _loading = false; });
    if (rec?.checkIn != null && rec?.checkOut == null) {
      _startClock(rec!.checkIn!);
    }
  }

  void _startClock(DateTime checkIn) {
    _clock?.cancel();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed = DateTime.now().difference(checkIn));
    });
  }

  // ── QR verification (fully offline — TOTP) ─────────────────────────────────
  Future<void> _markQr() async {
    final token = _qrCtrl.text.trim();
    if (token.isEmpty) {
      _snack('Enter the 6-digit code from the manager screen', error: true);
      return;
    }
    setState(() => _working = true);
    try {
      final org = AuthService.currentOrg!;
      final valid = LocalQrService.verifyToken(org.orgSecret, token);
      if (!valid) {
        _snack('Invalid or expired code — check the timer on manager screen', error: true);
        return;
      }
      await _doCheckIn('qr');
      _qrCtrl.clear();
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  // ── Geo check (fully offline — Haversine) ──────────────────────────────────
  Future<void> _markGeo() async {
    setState(() => _working = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        _snack('Location blocked — enable it in Settings → Apps → AdaptAttend', error: true);
        return;
      }
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _snack('GPS is off — enable it in device Settings', error: true);
        return;
      }
      late Position pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
      } on TimeoutException {
        // fallback to medium accuracy if high-accuracy GPS times out
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 12),
        );
      }
      final org = AuthService.currentOrg!;
      if (org.officeLat == null || org.officeLng == null) {
        _snack('Manager has not set office location yet', error: true);
        return;
      }
      final dist = LocalQrService.distanceMeters(
        pos.latitude, pos.longitude, org.officeLat!, org.officeLng!,
      );
      final inside = dist <= org.geofenceRadius;
      if (!inside) {
        _snack('You are ${dist.round()}m from office — need to be within ${org.geofenceRadius.round()}m', error: true);
        return;
      }
      await _doCheckIn('geo');
    } catch (e) {
      _snack('Location error: $e', error: true);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  // ── Face scan — on-device LBP recognition, with geo-fence guard ──────────
  Future<void> _markFace() async {
    final user = AuthService.currentUser!;

    // 1. Check enrollment before opening camera
    final enrolled = await FaceLocalService.isEnrolled(user.id);
    if (!enrolled) {
      _snack('Face not enrolled — ask manager to update your profile photo', error: true);
      return;
    }

    // 2. Geo-fence guard: face scan is only valid from within the office.
    //    This prevents attendance fraud from a different location.
    final org = AuthService.currentOrg!;
    if (org.officeLat != null && org.officeLng != null) {
      setState(() => _working = true);
      try {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.deniedForever) {
          _snack('Location blocked — enable in Settings to use face scan', error: true);
          return;
        }
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          _snack('Turn on GPS to use face scan at the office', error: true);
          return;
        }
        try {
          late Position pos;
          try {
            pos = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
              timeLimit: const Duration(seconds: 10),
            );
          } on TimeoutException {
            pos = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.medium,
              timeLimit: const Duration(seconds: 12),
            );
          }
          final dist = LocalQrService.distanceMeters(
            pos.latitude, pos.longitude, org.officeLat!, org.officeLng!,
          );
          if (dist > org.geofenceRadius) {
            _snack(
              'Face scan requires being at the office '
              '(you are ${dist.round()}m away)',
              error: true,
            );
            return;
          }
        } catch (e) {
          // If location check fails, allow face scan but log the issue.
          // Don't block attendance over a GPS glitch.
          debugPrint('Face geo-check skipped: $e');
        }
      } finally {
        if (mounted) setState(() => _working = false);
      }
    }

    // 3. Open front camera
    final picker = ImagePicker();
    final photo  = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 85,
    );
    if (photo == null || !mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FaceScanDialog(
        userId: user.id,
        selfie: File(photo.path),
        enrolledAsset: avatarForUsername(user.username),
      ),
    ) ?? false;
    if (ok) await _doCheckIn('face');
  }

  Future<void> _doCheckIn(String method) async {
    if (_todayRecord != null) {
      _snack('Already checked in today!', error: true);
      return;
    }
    final user = AuthService.currentUser!;
    final org  = AuthService.currentOrg!;
    final now  = DateTime.now();
    await db.upsertRecord(AttendanceRecordsCompanion.insert(
      id: _uuid.v4(),
      userId: user.id,
      orgId: org.id,
      date: now,
      checkIn: Value(now),
      method: Value(method),
      status: const Value('incomplete'),
    ));
    _snack('Checked in via ${method.toUpperCase()} ✓');
    await _load();
    _startClock(now);
  }

  Future<void> _checkOut() async {
    final rec = _todayRecord;
    if (rec == null || rec.checkIn == null) return;
    setState(() => _working = true);
    final now  = DateTime.now();
    final mins = now.difference(rec.checkIn!).inMinutes;
    await db.checkOut(rec.id, now, mins);
    _clock?.cancel();
    _snack('Checked out ✓  ${mins ~/ 60}h ${mins % 60}m worked');
    if (mounted) setState(() => _working = false);
    await _load();
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.rose : AppColors.emerald,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser!;
    final org  = AuthService.currentOrg!;
    final methods = org.allowedMethods.split(',');
    final checkedIn  = _todayRecord?.checkIn != null;
    final checkedOut = _todayRecord?.checkOut != null;

    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.indigo));

    return Scaffold(
      body: SafeArea(
        child: LoadingOverlay(
          loading: _working,
          child: RefreshIndicator(
            color: AppColors.indigo,
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Header ─────────────────────────────────────────────────
                Row(children: [
                  UserAvatar(
                    username: user.username,
                    fullName: user.fullName,
                    userId: user.id,
                    size: 44,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Hello, ${user.fullName.split(' ').first} 👋',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    Text(DateFormat('EEEE, d MMMM').format(DateTime.now()),
                        style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4))),
                  ])),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded),
                    onPressed: () async {
                      await AuthService.logout();
                      if (mounted) context.go('/login');
                    },
                  ),
                ]),
                const SizedBox(height: 24),

                // ── Status card ─────────────────────────────────────────────
                _StatusCard(
                  checkedIn: checkedIn,
                  checkedOut: checkedOut,
                  elapsed: _elapsed,
                  durationMinutes: _todayRecord?.durationMinutes,
                  method: _todayRecord?.method,
                ),
                const SizedBox(height: 24),

                // ── Attendance methods ──────────────────────────────────────
                if (!checkedIn) ...[
                  Text('Mark Attendance',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),

                  if (methods.contains('qr')) ...[
                    GradientCard(
                      gradient: LinearGradient(
                        colors: [AppColors.indigo.withOpacity(0.12), AppColors.surface1],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.indigo.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.qr_code_2_rounded, color: AppColors.indigo, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('QR Code', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            Text('6-digit code from manager screen',
                                style: TextStyle(fontSize: 11, color: Colors.white38)),
                          ]),
                        ]),
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(
                            child: TextField(
                              controller: _qrCtrl,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.w800,
                                letterSpacing: 8, fontFamily: 'monospace',
                              ),
                              decoration: InputDecoration(
                                hintText: '000000',
                                hintStyle: TextStyle(color: Colors.white12, letterSpacing: 8),
                                counterText: '',
                              ),
                              onSubmitted: (_) => _markQr(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 56,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _markQr,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.indigo,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(56, 48),
                              ),
                              child: const Icon(Icons.check_rounded, color: Colors.white),
                            ),
                          ),
                        ]),
                      ]),
                    ),
                    const SizedBox(height: 10),
                  ],

                  if (methods.contains('geo')) ...[
                    _MethodButton(
                      icon: Icons.location_on_rounded,
                      label: 'Mark via GPS',
                      sublabel: 'Must be within office geofence',
                      color: AppColors.cyan,
                      onTap: _markGeo,
                    ),
                    const SizedBox(height: 10),
                  ],

                  if (methods.contains('face'))
                    _MethodButton(
                      icon: Icons.face_rounded,
                      label: 'Mark via Face Scan',
                      sublabel: 'Uses your enrolled profile photo',
                      color: AppColors.emerald,
                      onTap: _markFace,
                    ),
                ],

                // ── Check-out ───────────────────────────────────────────────
                if (checkedIn && !checkedOut) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _checkOut,
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Check Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.rose,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Status card ────────────────────────────────────────────────────────────────
class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.checkedIn,
    required this.checkedOut,
    required this.elapsed,
    required this.durationMinutes,
    required this.method,
  });
  final bool checkedIn, checkedOut;
  final Duration elapsed;
  final int? durationMinutes;
  final String? method;

  @override
  Widget build(BuildContext context) {
    final color = checkedOut ? AppColors.emerald : checkedIn ? AppColors.amber : Colors.white24;
    final bgGrad = LinearGradient(
      colors: checkedOut
          ? [const Color(0xFF0F2920), const Color(0xFF061510)]
          : checkedIn
              ? [const Color(0xFF1E1800), const Color(0xFF130F00)]
              : [const Color(0xFF13131F), const Color(0xFF0F0F18)],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: bgGrad,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: Icon(
            checkedOut ? Icons.check_circle_rounded
                : checkedIn ? Icons.timer_rounded
                : Icons.radio_button_unchecked_rounded,
            color: color, size: 32,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          checkedOut ? 'Day Complete' : checkedIn ? 'In Progress' : 'Not Checked In',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: color),
        ),
        if (checkedIn && !checkedOut) ...[
          const SizedBox(height: 10),
          Text(
            _fmt(elapsed),
            style: const TextStyle(
                fontSize: 36, fontWeight: FontWeight.w900,
                fontFamily: 'monospace', color: Colors.white, letterSpacing: 2),
          ),
          const SizedBox(height: 4),
          Text('elapsed', style: TextStyle(fontSize: 12, color: Colors.white38)),
          if (method != null) ...[
            const SizedBox(height: 10),
            MethodBadge(method),
          ],
        ],
        if (checkedOut && durationMinutes != null) ...[
          const SizedBox(height: 10),
          Text(
            '${durationMinutes! ~/ 60}h ${durationMinutes! % 60}m',
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.emerald),
          ),
          Text('total worked today', style: TextStyle(fontSize: 12, color: Colors.white38)),
        ],
        if (!checkedIn) ...[
          const SizedBox(height: 8),
          Text('Pick a method below to record attendance',
              style: TextStyle(fontSize: 12, color: Colors.white38)),
        ],
      ]),
    );
  }

  String _fmt(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

// ── Face scan dialog — on-device LBP recognition ──────────────────────────────
class _FaceScanDialog extends StatefulWidget {
  const _FaceScanDialog({
    required this.userId,
    required this.selfie,
    this.enrolledAsset,
  });
  final String userId;
  final File selfie;
  final String? enrolledAsset; // asset path for display only, may be null

  @override
  State<_FaceScanDialog> createState() => _FaceScanDialogState();
}

class _FaceScanDialogState extends State<_FaceScanDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _spin;
  FaceLocalResult? _result;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _runVerification();
  }

  Future<void> _runVerification() async {
    final result = await FaceLocalService.verify(
      widget.userId,
      widget.selfie.path,
    );
    if (!mounted) return;
    _spin.stop();
    setState(() => _result = result);

    if (result.match) {
      // auto-dismiss after 1.2 s on success
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) Navigator.pop(context, true);
      });
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;
    final isLoading = r == null;
    final isMatch   = r?.match ?? false;
    final isError   = r != null && r.error != null && !isMatch;
    final isNoMatch = r != null && !isMatch && r.error == null;

    final titleColor = isMatch ? AppColors.emerald
        : isNoMatch ? AppColors.rose
        : isError   ? AppColors.amber
        : Colors.white;

    final title = isLoading ? 'Comparing Faces...'
        : isMatch   ? 'Face Matched!'
        : isNoMatch ? 'Face Not Recognised'
        : 'Error';

    return Dialog(
      backgroundColor: AppColors.surface1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [

          // ── Title ─────────────────────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: Text(title,
              key: ValueKey(title),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: titleColor),
            ),
          ),
          const SizedBox(height: 20),

          // ── Photo comparison row ───────────────────────────────────────────
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _PhotoFrame(label: 'Enrolled',
              child: widget.enrolledAsset != null
                  ? Image.asset(widget.enrolledAsset!, fit: BoxFit.cover)
                  : const Icon(Icons.person_rounded, size: 40, color: Colors.white38),
              state: isLoading ? _FrameState.scanning
                  : isMatch   ? _FrameState.match
                  : _FrameState.noMatch,
            ),
            // Centre indicator
            SizedBox(width: 44, height: 84,
              child: Center(child: isLoading
                ? AnimatedBuilder(
                    animation: _spin,
                    builder: (_, __) => Transform.rotate(
                      angle: _spin.value * 2 * pi,
                      child: CustomPaint(size: const Size(36, 36),
                          painter: _ArcPainter(AppColors.indigo)),
                    ))
                : Icon(
                    isMatch ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    size: 32,
                    color: isMatch ? AppColors.emerald : AppColors.rose,
                  ),
              ),
            ),
            _PhotoFrame(label: 'You',
              child: Image.file(widget.selfie, fit: BoxFit.cover),
              state: isLoading ? _FrameState.scanning
                  : isMatch   ? _FrameState.match
                  : _FrameState.noMatch,
            ),
          ]),

          const SizedBox(height: 18),

          // ── Confidence / status chip ───────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: _StatusChip(result: r, key: ValueKey(r?.match)),
          ),

          // ── Error text ────────────────────────────────────────────────────
          if (r?.error != null) ...[
            const SizedBox(height: 12),
            Text(r!.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
          ],

          // ── Action buttons (only on failure) ──────────────────────────────
          if (!isLoading && !isMatch) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.rose,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Try Again'),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

enum _FrameState { scanning, match, noMatch }

class _StatusChip extends StatelessWidget {
  const _StatusChip({super.key, required this.result});
  final FaceLocalResult? result;

  @override
  Widget build(BuildContext context) {
    if (result == null) {
      return _chip(AppColors.indigo, Icons.manage_search_rounded, 'Analysing biometrics...');
    }
    if (result!.match) {
      return _chip(AppColors.emerald, Icons.verified_rounded,
          'Identity verified · ${result!.pctLabel} confidence');
    }
    if (result!.error != null) {
      return _chip(AppColors.amber, Icons.warning_amber_rounded, 'Check error below');
    }
    return _chip(AppColors.rose, Icons.close_rounded,
        'No match · ${result!.pctLabel} similarity');
  }

  Widget _chip(Color c, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 6),
        Flexible(child: Text(label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c))),
      ]),
    );
  }
}

class _PhotoFrame extends StatelessWidget {
  const _PhotoFrame({required this.label, required this.child, required this.state});
  final String label;
  final Widget child;
  final _FrameState state;

  @override
  Widget build(BuildContext context) {
    final color = state == _FrameState.match    ? AppColors.emerald
                : state == _FrameState.noMatch  ? AppColors.rose
                : AppColors.indigo;
    return Column(children: [
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54)),
      const SizedBox(height: 6),
      AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        width: 84, height: 84,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color,
              width: state == _FrameState.scanning ? 1.5 : 2.5),
          boxShadow: [BoxShadow(color: color.withOpacity(0.25), blurRadius: 12)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: child,
        ),
      ),
    ]);
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      -pi / 2, pi * 1.5, false,
      Paint()
        ..color = color.withOpacity(0.8)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }
  @override
  bool shouldRepaint(_) => false;
}

// ── Method button ──────────────────────────────────────────────────────────────
class _MethodButton extends StatelessWidget {
  const _MethodButton({
    required this.icon, required this.label,
    required this.sublabel, required this.color, required this.onTap,
  });
  final IconData icon;
  final String label, sublabel;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.08), AppColors.surface1],
            begin: Alignment.centerLeft, end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 2),
            Text(sublabel, style: TextStyle(fontSize: 11, color: Colors.white38)),
          ])),
          Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.5), size: 22),
        ]),
      ),
    );
  }
}
