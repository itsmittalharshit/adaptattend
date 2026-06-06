import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_theme.dart';
import '../utils/employee_avatar.dart';

// ── User avatar (local photo → bundle asset → gradient initial) ───────────────
class UserAvatar extends StatefulWidget {
  const UserAvatar({
    super.key,
    required this.username,
    required this.fullName,
    this.userId,
    this.size = 44,
    this.color,
    this.showEditBadge = false,
  });
  final String username;
  final String fullName;
  final String? userId;          // Pass for local-photo lookup
  final double size;
  final Color? color;
  final bool showEditBadge;

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  String? _localPath;

  @override
  void initState() {
    super.initState();
    if (widget.userId != null) _loadLocalPhoto();
  }

  Future<void> _loadLocalPhoto() async {
    final dir = await getApplicationDocumentsDirectory();
    final f = File('${dir.path}/avatars/${widget.userId}.jpg');
    if (await f.exists()) {
      if (mounted) setState(() => _localPath = f.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.color ?? AppColors.indigo;
    Widget inner;

    if (_localPath != null) {
      inner = ClipOval(
        child: Image.file(
          File(_localPath!),
          width: widget.size, height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(c),
        ),
      );
    } else {
      final asset = avatarForUsername(widget.username);
      if (asset != null) {
        inner = ClipOval(
          child: Image.asset(
            asset,
            width: widget.size, height: widget.size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallback(c),
          ),
        );
      } else {
        inner = _fallback(c);
      }
    }

    if (!widget.showEditBadge) return inner;

    return Stack(clipBehavior: Clip.none, children: [
      inner,
      Positioned(
        right: -2, bottom: -2,
        child: Container(
          width: widget.size * 0.38,
          height: widget.size * 0.38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.indigo, Color(0xFF7C3AED)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.surface0, width: 1.5),
            boxShadow: [BoxShadow(color: AppColors.indigo.withOpacity(0.4), blurRadius: 6)],
          ),
          child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: widget.size * 0.2),
        ),
      ),
    ]);
  }

  Widget _fallback(Color c) {
    // Gradient background based on name hash for consistent colors
    final hue = (widget.fullName.hashCode.abs() % 360).toDouble();
    return Container(
      width: widget.size, height: widget.size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HSVColor.fromAHSV(1, hue, 0.6, 0.5).toColor(),
            HSVColor.fromAHSV(1, (hue + 40) % 360, 0.7, 0.35).toColor(),
          ],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        widget.fullName.isNotEmpty ? widget.fullName[0].toUpperCase() : '?',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: widget.size * 0.4,
          shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
        ),
      ),
    );
  }
}

// ── Gradient card ─────────────────────────────────────────────────────────────
class GradientCard extends StatelessWidget {
  const GradientCard({
    super.key,
    required this.child,
    this.gradient,
    this.padding,
    this.borderRadius,
  });
  final Widget child;
  final Gradient? gradient;
  final EdgeInsets? padding;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient ?? const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF13131F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius ?? 20),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.12), color.withOpacity(0.04)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.18),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 14),
        Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.45))),
      ]),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'present'    => (AppColors.emerald, 'Present'),
      'absent'     => (AppColors.rose, 'Absent'),
      'incomplete' => (AppColors.amber, 'Incomplete'),
      _            => (Colors.grey, status),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Method badge ──────────────────────────────────────────────────────────────
class MethodBadge extends StatelessWidget {
  const MethodBadge(this.method, {super.key});
  final String? method;

  @override
  Widget build(BuildContext context) {
    if (method == null) return const SizedBox.shrink();
    final (icon, color) = switch (method) {
      'qr'   => (Icons.qr_code_2_rounded, AppColors.indigo),
      'geo'  => (Icons.location_on_rounded, AppColors.cyan),
      'face' => (Icons.face_rounded, AppColors.emerald),
      _      => (Icons.check_circle, Colors.grey),
    };
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 4),
      Text(method!.toUpperCase(),
          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    ]);
  }
}

// ── PIN pad ───────────────────────────────────────────────────────────────────
class PinPad extends StatefulWidget {
  const PinPad({super.key, required this.onComplete, this.length = 4});
  final void Function(String pin) onComplete;
  final int length;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _pin = '';

  void _press(String digit) {
    if (_pin.length >= widget.length) return;
    setState(() => _pin += digit);
    if (_pin.length == widget.length) {
      Future.delayed(const Duration(milliseconds: 100), () {
        widget.onComplete(_pin);
        setState(() => _pin = '');
      });
    }
  }

  void _delete() {
    if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Builder(builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (int i = 0; i < widget.length; i++) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 14, height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < _pin.length
                    ? AppColors.indigo
                    : (isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.15)),
              ),
            ),
            if (i < widget.length - 1) const SizedBox(width: 16),
          ],
        ]);
      }),
      const SizedBox(height: 32),
      for (final row in [['1','2','3'], ['4','5','6'], ['7','8','9'], ['','0','⌫']])
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: row.map((k) {
              return Expanded(
                child: k.isEmpty
                    ? const SizedBox(height: 60)
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: InkWell(
                          onTap: () => k == '⌫' ? _delete() : _press(k),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.surface2,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.07)),
                            ),
                            alignment: Alignment.center,
                            child: Text(k,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
                          ),
                        ),
                      ),
              );
            }).toList(),
          ),
        ),
    ]);
  }
}

// ── Loading overlay ────────────────────────────────────────────────────────────
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key, required this.child, required this.loading});
  final Widget child;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      child,
      if (loading)
        Container(
          color: Colors.black54,
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.indigo),
          ),
        ),
    ]);
  }
}
