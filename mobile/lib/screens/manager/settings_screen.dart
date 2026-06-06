import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;

import 'package:go_router/go_router.dart';
import '../../data/database.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Org? _org;
  late Set<String> _methods;
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _radiusCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _latCtrl.dispose(); _lngCtrl.dispose(); _radiusCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final org = await db.getFirstOrg();
    if (org == null) return;
    setState(() {
      _org = org;
      _methods = Set.from(org.allowedMethods.split(',').map((s) => s.trim()));
      _latCtrl.text = org.officeLat?.toStringAsFixed(6) ?? '';
      _lngCtrl.text = org.officeLng?.toStringAsFixed(6) ?? '';
      _radiusCtrl.text = org.geofenceRadius.toStringAsFixed(0);
    });
  }

  Future<void> _save() async {
    if (_org == null) return;
    setState(() => _saving = true);
    await db.updateOrg(OrgsCompanion(
      id: Value(_org!.id),
      allowedMethods: Value(_methods.join(',')),
      officeLat: Value(double.tryParse(_latCtrl.text)),
      officeLng: Value(double.tryParse(_lngCtrl.text)),
      geofenceRadius: Value(double.tryParse(_radiusCtrl.text) ?? 100),
    ));
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Settings saved'),
        backgroundColor: AppColors.emerald,
      ));
    }
  }

  void _toggleMethod(String method) {
    setState(() {
      if (_methods.contains(method)) {
        if (_methods.length > 1) _methods.remove(method);
      } else {
        _methods.add(method);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _org == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.indigo))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Org info
                GradientCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.indigo.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.business_rounded, color: AppColors.indigo, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_org!.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      Text('Organisation', style: TextStyle(fontSize: 11, color: Colors.white38)),
                    ])),
                  ]),
                ])),
                const SizedBox(height: 16),

                // Attendance methods
                GradientCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Attendance Methods', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('Enable methods employees can use', style: TextStyle(fontSize: 12, color: Colors.white38)),
                  const SizedBox(height: 16),
                  ...[
                    (Icons.qr_code_2_rounded,   'qr',   'QR Code',         'Rotating 15-second token',    AppColors.indigo),
                    (Icons.location_on_rounded,  'geo',  'GPS Geofencing',  'Location-based attendance',   AppColors.cyan),
                    (Icons.face_rounded,         'face', 'Face Recognition','Biometric with liveness',     AppColors.emerald),
                  ].map((entry) {
                    final (icon, key, title, sub, color) = entry;
                    final active = _methods.contains(key);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => _toggleMethod(key),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: active ? color.withOpacity(0.08) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: active ? color.withOpacity(0.3) : Colors.white.withOpacity(0.06),
                            ),
                          ),
                          child: Row(children: [
                            Icon(icon, color: active ? color : Colors.white38, size: 20),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(title, style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13,
                                  color: active ? Colors.white : Colors.white60)),
                              Text(sub, style: TextStyle(fontSize: 11, color: Colors.white38)),
                            ])),
                            Switch(
                              value: active,
                              onChanged: (_) => _toggleMethod(key),
                              activeColor: color,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ]),
                        ),
                      ),
                    );
                  }),
                ])),
                const SizedBox(height: 16),

                // Geofence
                if (_methods.contains('geo')) ...[
                  GradientCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(Icons.my_location_rounded, color: AppColors.cyan, size: 20),
                      const SizedBox(width: 8),
                      const Text('Office Location', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ]),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: TextField(
                        controller: _latCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: const InputDecoration(labelText: 'Latitude', prefixIcon: Icon(Icons.north)),
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: TextField(
                        controller: _lngCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: const InputDecoration(labelText: 'Longitude', prefixIcon: Icon(Icons.east)),
                      )),
                    ]),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _radiusCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Geofence radius (meters)',
                        prefixIcon: Icon(Icons.radar_rounded),
                        suffixText: 'm',
                      ),
                    ),
                  ])),
                  const SizedBox(height: 16),
                ],

                // Save
                ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text(_saving ? 'Saving…' : 'Save Settings'),
                ),
                const SizedBox(height: 24),

                // Danger zone
                GradientCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Account', style: TextStyle(fontSize: 13, color: Colors.white38)),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      await AuthService.logout();
                      if (mounted) context.go('/login');
                    },
                    child: Row(children: [
                      const Icon(Icons.logout_rounded, color: AppColors.rose, size: 20),
                      const SizedBox(width: 10),
                      const Text('Sign Out', style: TextStyle(color: AppColors.rose, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ])),
              ],
            ),
    );
  }
}
