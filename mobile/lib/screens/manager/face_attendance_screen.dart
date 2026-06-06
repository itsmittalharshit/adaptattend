/// Manager-side face attendance — one device scans all employees.
///
/// Flow:
///   1. Manager taps "Scan" and points the camera at the employee.
///   2. A photo is taken and compared against ALL enrolled face embeddings
///      (1-to-N search via [FaceLocalService.findBestMatch]).
///   3. If a match is found, the employee's info appears with a
///      "Check In / Check Out" confirmation button.
///   4. Manager confirms → attendance record is written.
///
/// Security: because the scan happens on the manager's device in the
/// manager's presence, employees cannot mark attendance from home.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import '../../data/database.dart';
import '../../services/auth_service.dart';
import '../../services/face_local_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

const _uuid = Uuid();

// ── Screen ────────────────────────────────────────────────────────────────────

class FaceAttendanceScreen extends StatefulWidget {
  const FaceAttendanceScreen({super.key});
  @override
  State<FaceAttendanceScreen> createState() => _FaceAttendanceScreenState();
}

enum _ScanState { idle, scanning, matched, noMatch, done }

class _FaceAttendanceScreenState extends State<FaceAttendanceScreen> {
  List<AppUser>   _employees   = [];
  bool            _loading     = true;
  _ScanState      _state       = _ScanState.idle;
  FaceMatchResult? _match;
  AttendanceRecord? _existingRecord;
  AppUser?        _justMarked;
  bool            _isCheckOut  = false;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    final org = AuthService.currentOrg!;
    final emps = await db.getEmployees(org.id);
    if (mounted) setState(() { _employees = emps; _loading = false; });
  }

  Future<void> _scan() async {
    setState(() { _state = _ScanState.scanning; _match = null; });

    try {
      final photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 90,
      );
      if (photo == null || !mounted) {
        setState(() => _state = _ScanState.idle);
        return;
      }

      final match = await FaceLocalService.findBestMatch(photo.path, _employees);

      // Clean up temp file (best-effort)
      try { File(photo.path).deleteSync(); } catch (_) {}

      if (!mounted) return;

      if (match == null) {
        setState(() => _state = _ScanState.noMatch);
        return;
      }

      // Check if already checked in/out today
      final existing = await db.getTodayRecord(match.user.id);

      setState(() {
        _match          = match;
        _existingRecord = existing;
        _isCheckOut     = existing?.checkIn != null && existing?.checkOut == null;
        _state          = _ScanState.matched;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _state = _ScanState.idle);
        _snack('Scan error: $e', error: true);
      }
    }
  }

  Future<void> _confirm() async {
    final match = _match;
    if (match == null) return;

    final user = match.user;
    final org  = AuthService.currentOrg!;
    final now  = DateTime.now();

    if (_isCheckOut && _existingRecord != null) {
      // Check out
      final mins = now.difference(_existingRecord!.checkIn!).inMinutes;
      await db.checkOut(_existingRecord!.id, now, mins);
      _snack('${user.fullName} checked out  ${mins ~/ 60}h ${mins % 60}m ✓');
    } else if (!_isCheckOut && _existingRecord == null) {
      // Check in
      await db.upsertRecord(AttendanceRecordsCompanion.insert(
        id: _uuid.v4(),
        userId: user.id,
        orgId: org.id,
        date: now,
        checkIn: Value(now),
        method: const Value('face'),
        status: const Value('incomplete'),
      ));
      _snack('${user.fullName} checked in via Face ✓');
    } else if (_existingRecord?.checkOut != null) {
      _snack('${user.fullName} already checked out today', error: true);
    }

    if (mounted) {
      setState(() {
        _justMarked = user;
        _state      = _ScanState.done;
        _match      = null;
      });
    }
  }

  void _reset() => setState(() {
        _state       = _ScanState.idle;
        _match       = null;
        _justMarked  = null;
        _isCheckOut  = false;
        _existingRecord = null;
      });

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.rose : AppColors.emerald,
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Attendance'),
        leading: const BackButton(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                DateFormat('EEE, d MMM').format(DateTime.now()),
                style: const TextStyle(fontSize: 13, color: Colors.white54),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.indigo))
          : SafeArea(
              child: LoadingOverlay(
                loading: _state == _ScanState.scanning,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TopBanner(employeeCount: _employees.length),
                      const SizedBox(height: 28),
                      Expanded(child: _buildBody()),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildBody() {
    return switch (_state) {
      _ScanState.idle     => _IdleView(onScan: _scan),
      _ScanState.scanning => _ScanningView(),
      _ScanState.noMatch  => _NoMatchView(onRetry: _scan, onCancel: _reset),
      _ScanState.matched  => _MatchedView(
          match:      _match!,
          isCheckOut: _isCheckOut,
          alreadyDone: _existingRecord?.checkOut != null,
          onConfirm:  _confirm,
          onCancel:   _reset,
        ),
      _ScanState.done     => _DoneView(
          user:       _justMarked!,
          wasCheckOut: _isCheckOut,
          onScanNext: _reset,
        ),
    };
  }
}

// ── Top banner ────────────────────────────────────────────────────────────────

class _TopBanner extends StatelessWidget {
  const _TopBanner({required this.employeeCount});
  final int employeeCount;

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.indigo.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.face_retouching_natural_rounded,
              color: AppColors.indigo, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Manager Face Scan',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 3),
          Text(
            'Employee stands in front of the camera  •  $employeeCount enrolled',
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ),
        ])),
      ]),
    );
  }
}

// ── Idle view ─────────────────────────────────────────────────────────────────

class _IdleView extends StatelessWidget {
  const _IdleView({required this.onScan});
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FaceIcon(),
        const SizedBox(height: 32),
        const Text(
          'Have the employee face the camera',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, height: 1.3),
        ),
        const SizedBox(height: 10),
        const Text(
          'Tap Scan, then the front camera opens.\nHold the phone so the employee\'s face fills the frame.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.white54, height: 1.6),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: onScan,
            icon: const Icon(Icons.camera_alt_rounded),
            label: const Text('Scan Employee Face',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.indigo,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Scanning animation ────────────────────────────────────────────────────────

class _ScanningView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: AppColors.indigo, strokeWidth: 3),
        SizedBox(height: 28),
        Text('Analysing face…',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white70)),
        SizedBox(height: 8),
        Text('Comparing against enrolled employees',
            style: TextStyle(fontSize: 12, color: Colors.white38)),
      ],
    );
  }
}

// ── No-match view ─────────────────────────────────────────────────────────────

class _NoMatchView extends StatelessWidget {
  const _NoMatchView({required this.onRetry, required this.onCancel});
  final VoidCallback onRetry, onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FaceIcon(color: AppColors.rose, icon: Icons.no_photography_rounded),
        const SizedBox(height: 28),
        const Text('No match found',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.rose)),
        const SizedBox(height: 10),
        const Text(
          'Face not recognised.\nMake sure the employee is enrolled and the lighting is good.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.white54, height: 1.6),
        ),
        const SizedBox(height: 36),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.indigo,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
        ),
      ],
    );
  }
}

// ── Matched view ──────────────────────────────────────────────────────────────

class _MatchedView extends StatelessWidget {
  const _MatchedView({
    required this.match,
    required this.isCheckOut,
    required this.alreadyDone,
    required this.onConfirm,
    required this.onCancel,
  });
  final FaceMatchResult match;
  final bool isCheckOut, alreadyDone;
  final VoidCallback onConfirm, onCancel;

  @override
  Widget build(BuildContext context) {
    final user  = match.user;
    final label = alreadyDone
        ? 'Already done for today'
        : isCheckOut ? 'Check Out' : 'Check In';
    final color = alreadyDone
        ? Colors.white38
        : isCheckOut ? AppColors.amber : AppColors.emerald;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Confidence chip
        Align(
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.emerald.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.emerald.withOpacity(0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.verified_rounded,
                  color: AppColors.emerald, size: 14),
              const SizedBox(width: 6),
              Text('Match · ${match.pctLabel} confidence',
                  style: const TextStyle(
                      color: AppColors.emerald,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ]),
          ),
        ),
        const SizedBox(height: 20),

        // Employee card
        GradientCard(
          child: Row(children: [
            UserAvatar(
              username: user.username,
              fullName: user.fullName,
              userId: user.id,
              size: 60,
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user.fullName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 4),
              Text('@${user.username}',
                  style: const TextStyle(fontSize: 13, color: Colors.white38)),
              const SizedBox(height: 8),
              Row(children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: color)),
              ]),
            ])),
          ]),
        ),
        const SizedBox(height: 28),

        if (!alreadyDone) ...[
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onConfirm,
              icon: Icon(isCheckOut
                  ? Icons.logout_rounded
                  : Icons.login_rounded),
              label: Text(
                'Confirm $label',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
        ),
      ],
    );
  }
}

// ── Done view ─────────────────────────────────────────────────────────────────

class _DoneView extends StatelessWidget {
  const _DoneView({
    required this.user,
    required this.wasCheckOut,
    required this.onScanNext,
  });
  final AppUser user;
  final bool wasCheckOut;
  final VoidCallback onScanNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FaceIcon(color: AppColors.emerald, icon: Icons.check_circle_rounded),
        const SizedBox(height: 24),
        Text(
          '${wasCheckOut ? 'Check-out' : 'Check-in'} recorded',
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.emerald),
        ),
        const SizedBox(height: 10),
        Text(
          user.fullName,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white70),
        ),
        const SizedBox(height: 6),
        Text(
          DateFormat('hh:mm a').format(DateTime.now()),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: Colors.white38),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: onScanNext,
            icon: const Icon(Icons.face_retouching_natural_rounded),
            label: const Text('Scan Next Employee',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.indigo,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shared face icon widget ───────────────────────────────────────────────────

class _FaceIcon extends StatelessWidget {
  const _FaceIcon({
    this.color = AppColors.indigo,
    this.icon  = Icons.face_retouching_natural_rounded,
  });
  final Color   color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.25), width: 2),
        ),
        child: Icon(icon, color: color, size: 44),
      ),
    );
  }
}
