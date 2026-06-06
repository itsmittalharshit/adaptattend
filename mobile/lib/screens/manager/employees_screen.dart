import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value;

import '../../data/database.dart';
import '../../services/auth_service.dart';
import '../../services/face_local_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

const _uuid = Uuid();
const _maxEmployees = 5;
final _picker = ImagePicker();

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});
  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  List<AppUser>    _employees    = [];
  Map<String, bool> _faceEnrolled = {};
  bool _loading = true;
  int _photoVersion = 0; // bump to force UserAvatar to re-check local file

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final org   = AuthService.currentOrg!;
    final emps  = await db.getEmployees(org.id);
    final prefs = await SharedPreferences.getInstance();
    final enrolled = {
      for (final e in emps) e.id: prefs.containsKey('face_embed_${e.id}')
    };
    if (mounted) setState(() {
      _employees    = emps;
      _faceEnrolled = enrolled;
      _loading      = false;
    });
  }

  Future<void> _add() async {
    if (_employees.length >= _maxEmployees) {
      _snack('Demo limit: max $_maxEmployees employees', error: true);
      return;
    }
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => const _AddEmployeeDialog(),
    );
    if (result == null) return;
    final (name, pin) = result;
    final org = AuthService.currentOrg!;
    await db.insertUser(AppUsersCompanion.insert(
      id: _uuid.v4(),
      orgId: org.id,
      username: name.toLowerCase().replaceAll(' ', '_'),
      pinHash: hashPin(pin),
      role: 'employee',
      fullName: name,
    ));
    _snack('$name added');
    _load();
  }

  Future<void> _toggle(AppUser u) async {
    await db.toggleUserActive(u.id, !u.isActive);
    _load();
  }

  Future<void> _edit(AppUser u) async {
    final result = await showDialog<(String, String, String?)>(
      context: context,
      builder: (_) => _EditEmployeeDialog(user: u),
    );
    if (result == null) return;
    final (fullName, username, newPin) = result;
    await db.updateUser(AppUsersCompanion(
      id: Value(u.id),
      fullName: Value(fullName),
      username: Value(username),
      pinHash: newPin != null && newPin.isNotEmpty
          ? Value(hashPin(newPin))
          : const Value.absent(),
    ));
    _snack('$fullName updated');
    _load();
  }

  Future<void> _pickPhoto(AppUser u) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Change Photo for ${u.fullName}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: _PhotoSourceBtn(
                icon: Icons.camera_alt_rounded,
                label: 'Camera',
                color: AppColors.cyan,
                onTap: () => Navigator.pop(context, ImageSource.camera),
              )),
              const SizedBox(width: 12),
              Expanded(child: _PhotoSourceBtn(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                color: AppColors.indigo,
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              )),
            ]),
          ]),
        ),
      ),
    );
    if (source == null) return;

    final img = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 400,
      maxHeight: 400,
    );
    if (img == null) return;

    // Save to {appDocDir}/avatars/{userId}.jpg
    final dir = await getApplicationDocumentsDirectory();
    final avatarDir = Directory('${dir.path}/avatars');
    if (!await avatarDir.exists()) await avatarDir.create(recursive: true);
    final savedPath = '${dir.path}/avatars/${u.id}.jpg';
    await File(img.path).copy(savedPath);

    // Auto-enroll face embedding so face-scan attendance works immediately
    final enrolled = await FaceLocalService.enroll(u.id, savedPath);

    setState(() => _photoVersion++);
    _snack(enrolled
        ? 'Photo updated & face enrolled for ${u.fullName}'
        : 'Photo updated (no face detected — try a clearer photo for face scan)');
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.rose : AppColors.emerald,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employees'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: const Text('Add'),
              style: TextButton.styleFrom(foregroundColor: AppColors.indigo),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.indigo))
          : _employees.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.group_off_rounded, size: 56, color: Colors.white12),
                  const SizedBox(height: 16),
                  const Text('No employees yet', style: TextStyle(color: Colors.white38, fontSize: 16)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _add,
                    icon: const Icon(Icons.person_add_rounded, size: 16),
                    label: const Text('Add First Employee'),
                  ),
                ]))
              : Column(children: [
                  // Count banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.indigo.withOpacity(0.08),
                      border: Border(bottom: BorderSide(color: AppColors.indigo.withOpacity(0.1))),
                    ),
                    child: Row(children: [
                      Icon(Icons.group_rounded, size: 16, color: AppColors.indigo),
                      const SizedBox(width: 8),
                      Text('${_employees.length} of $_maxEmployees employees',
                          style: const TextStyle(fontSize: 13, color: AppColors.indigo, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text('Tap avatar to change photo',
                          style: TextStyle(fontSize: 11, color: Colors.white38)),
                    ]),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _employees.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _EmployeeTile(
                        user: _employees[i],
                        faceEnrolled: _faceEnrolled[_employees[i].id] ?? false,
                        photoVersion: _photoVersion,
                        onToggle: () => _toggle(_employees[i]),
                        onEdit: () => _edit(_employees[i]),
                        onPickPhoto: () => _pickPhoto(_employees[i]),
                      ),
                    ),
                  ),
                ]),
    );
  }
}

// ── Employee tile ─────────────────────────────────────────────────────────────
class _EmployeeTile extends StatelessWidget {
  const _EmployeeTile({
    required this.user,
    required this.faceEnrolled,
    required this.photoVersion,
    required this.onToggle,
    required this.onEdit,
    required this.onPickPhoto,
  });
  final AppUser user;
  final bool faceEnrolled;
  final int photoVersion;
  final VoidCallback onToggle, onEdit, onPickPhoto;

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        // Tappable avatar with camera badge
        GestureDetector(
          onTap: onPickPhoto,
          child: UserAvatar(
            key: ValueKey('${user.id}-$photoVersion'),
            username: user.username,
            fullName: user.fullName,
            userId: user.id,
            size: 50,
            showEditBadge: true,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(user.fullName,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 4),
          Row(children: [
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                color: user.isActive ? AppColors.emerald : Colors.white24,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              user.isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                  fontSize: 11,
                  color: user.isActive ? AppColors.emerald : Colors.white38),
            ),
            if (faceEnrolled) ...[
              const SizedBox(width: 10),
              const Icon(Icons.face_rounded, size: 11, color: AppColors.emerald),
              const SizedBox(width: 4),
              const Text('Face enrolled',
                  style: TextStyle(fontSize: 11, color: AppColors.emerald)),
            ],
          ]),
          const SizedBox(height: 2),
          Text('@${user.username}',
              style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.25))),
        ])),
        IconButton(
          icon: const Icon(Icons.edit_rounded, size: 18, color: Colors.white38),
          onPressed: onEdit,
          tooltip: 'Edit',
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
        ),
        Switch(
          value: user.isActive,
          onChanged: (_) => onToggle(),
          activeColor: AppColors.indigo,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ]),
    );
  }
}

// ── Photo source button ───────────────────────────────────────────────────────
class _PhotoSourceBtn extends StatelessWidget {
  const _PhotoSourceBtn({
    required this.icon, required this.label,
    required this.color, required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

// ── Add employee dialog ───────────────────────────────────────────────────────
class _AddEmployeeDialog extends StatefulWidget {
  const _AddEmployeeDialog();
  @override
  State<_AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<_AddEmployeeDialog> {
  final _nameCtrl = TextEditingController();
  final _pinCtrl  = TextEditingController();
  final _form = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Add Employee'),
      content: Form(
        key: _form,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_rounded),
            ),
            validator: (v) => v!.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _pinCtrl,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'PIN (4–6 digits)',
              prefixIcon: Icon(Icons.lock_rounded),
              counterText: '',
            ),
            validator: (v) => (v?.length ?? 0) < 4 ? 'Min 4 digits' : null,
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_form.currentState!.validate()) {
              Navigator.pop(context, (_nameCtrl.text.trim(), _pinCtrl.text));
            }
          },
          style: ElevatedButton.styleFrom(minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
          child: const Text('Add'),
        ),
      ],
    );
  }
}

// ── Edit employee dialog ──────────────────────────────────────────────────────
class _EditEmployeeDialog extends StatefulWidget {
  const _EditEmployeeDialog({required this.user});
  final AppUser user;
  @override
  State<_EditEmployeeDialog> createState() => _EditEmployeeDialogState();
}

class _EditEmployeeDialogState extends State<_EditEmployeeDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _usernameCtrl;
  final TextEditingController _pinCtrl = TextEditingController();
  final _form = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameCtrl     = TextEditingController(text: widget.user.fullName);
    _usernameCtrl = TextEditingController(text: widget.user.username);
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _usernameCtrl.dispose(); _pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [
        UserAvatar(username: widget.user.username, fullName: widget.user.fullName,
            userId: widget.user.id, size: 36),
        const SizedBox(width: 12),
        const Text('Edit Employee'),
      ]),
      content: Form(
        key: _form,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_rounded),
            ),
            validator: (v) => v!.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _usernameCtrl,
            decoration: const InputDecoration(
              labelText: 'Username',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
            validator: (v) => v!.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _pinCtrl,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'New PIN (blank = keep current)',
              prefixIcon: Icon(Icons.lock_rounded),
              counterText: '',
            ),
            validator: (v) {
              if (v != null && v.isNotEmpty && v.length < 4) return 'Min 4 digits';
              return null;
            },
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_form.currentState!.validate()) {
              Navigator.pop(context, (
                _nameCtrl.text.trim(),
                _usernameCtrl.text.trim().toLowerCase(),
                _pinCtrl.text.isNotEmpty ? _pinCtrl.text : null,
              ));
            }
          },
          style: ElevatedButton.styleFrom(minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
