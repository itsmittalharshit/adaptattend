import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/database.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Org? _org;
  List<AppUser> _users = [];
  AppUser? _selected;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final org = await db.getFirstOrg();
    if (org == null) {
      setState(() => _loading = false);
      return;
    }
    final allUsers = await db.getEmployees(org.id);
    final manager = await db.getUserByUsername(org.id, 'manager');
    setState(() {
      _org = org;
      _users = [if (manager != null) manager, ...allUsers];
      _loading = false;
    });
  }

  Future<void> _onPin(String pin) async {
    if (_selected == null) return;
    setState(() => _error = null);
    final user = await AuthService.login(_org!.id, _selected!.username, pin);
    if (!mounted) return;
    if (user == null) {
      setState(() => _error = 'Wrong PIN — try again');
      return;
    }
    context.go(user.role == 'manager' ? '/manager' : '/employee');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.indigo)),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              // Logo
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.indigo.withOpacity(0.4),
                      blurRadius: 24, offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.fingerprint_rounded,
                    color: Colors.white, size: 36),
              ),
              const SizedBox(height: 20),
              Text(
                _org?.name ?? 'AdaptAttend',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Select your name to sign in',
                style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.45)),
              ),
              const SizedBox(height: 36),

              // User picker
              if (_selected == null) ...[
                GradientCard(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: _users.map((u) => _UserTile(
                      user: u,
                      onTap: () => setState(() => _selected = u),
                    )).toList(),
                  ),
                ),
              ] else ...[
                // Selected user header
                GestureDetector(
                  onTap: () => setState(() { _selected = null; _error = null; }),
                  child: GradientCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(children: [
                      _Avatar(_selected!),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_selected!.fullName,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          Text(_selected!.role.toUpperCase(),
                              style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4))),
                        ],
                      )),
                      Icon(Icons.keyboard_arrow_down_rounded,
                          color: Colors.white.withOpacity(0.4)),
                    ]),
                  ),
                ),
                const SizedBox(height: 32),
                Text('Enter your PIN',
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.45))),
                const SizedBox(height: 24),
                SizedBox(width: double.infinity, child: PinPad(onComplete: _onPin)),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!,
                      style: const TextStyle(color: AppColors.rose, fontSize: 13)),
                ],
                const SizedBox(height: 16),
                Text('Demo PIN: 1234',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.25))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, required this.onTap});
  final AppUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(children: [
            _Avatar(user),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(user.role == 'manager' ? 'Manager' : 'Employee',
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4))),
              ],
            )),
            Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.3), size: 18),
          ]),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar(this.user);
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final color = user.role == 'manager' ? AppColors.amber : AppColors.indigo;
    return UserAvatar(
      username: user.username,
      fullName: user.fullName,
      size: 40,
      color: color,
    );
  }
}
