import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swiftclean_admin/MVVM/model/models/admin_model.dart';
import 'package:swiftclean_admin/MVVM/model/services/firebaseauthservices.dart';
import 'package:swiftclean_admin/MVVM/utils/rbac_session.dart';

class GrantAccessPage extends StatefulWidget {
  const GrantAccessPage({super.key});

  @override
  State<GrantAccessPage> createState() => _GrantAccessPageState();
}

class _GrantAccessPageState extends State<GrantAccessPage> {
  final _session = RbacSession();
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Step 1 — Selected user
  Map<String, dynamic>? _selectedUser;

  // Step 2 — Selected role
  RoleDefinition? _selectedRole;
  List<RoleDefinition> _availableRoles = [];
  bool _loadingRoles = false;

  // Step 3 — Permissions
  // Map<moduleId, Set<action>>
  Map<String, Set<String>> _selectedPermissions = {};

  // Dynamic modules (from Firestore or fallback)
  List<ModuleDefinition> _modules = List.from(AppModules.builtin);
  bool _loadingModules = false;

  // Step 4 — Confirmation / existing record info
  AdminUserModel? _existingRecord;

  @override
  void initState() {
    super.initState();
    _loadModules();
  }

  // ---------------------------------------------------------------------------
  // Data loaders
  // ---------------------------------------------------------------------------
  Future<void> _loadModules() async {
    setState(() => _loadingModules = true);
    try {
      final snapshot = await FirebaseFirestore.instance.collection('modules').get();
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _modules = snapshot.docs.map(ModuleDefinition.fromFirestore).toList();
        });
      }
    } catch (_) {
      // Fallback to builtin
    }
    setState(() => _loadingModules = false);
  }

  Future<void> _loadRoles() async {
    setState(() => _loadingRoles = true);
    _availableRoles = await FirebaseAuthService.instance
        .fetchAssignableRoles(_session.roleLevel);
    setState(() => _loadingRoles = false);
  }

  Future<void> _checkExistingRecord(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('admin_users')
          .doc(uid)
          .get();
      if (doc.exists) {
        setState(() => _existingRecord = AdminUserModel.fromFirestore(doc));
      } else {
        setState(() => _existingRecord = null);
      }
    } catch (_) {
      setState(() => _existingRecord = null);
    }
  }

  // ---------------------------------------------------------------------------
  // Step navigation
  // ---------------------------------------------------------------------------
  void _nextStep() {
    if (_currentStep < 3) setState(() => _currentStep++);
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  bool get _canProceedStep0 => _selectedUser != null;
  bool get _canProceedStep1 => _selectedRole != null;
  bool get _canProceedStep2 => _selectedPermissions.isNotEmpty;

  // ---------------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------------
  Future<void> _submit() async {
    if (_selectedUser == null || _selectedRole == null) return;
    setState(() => _isSubmitting = true);

    try {
      // Build permission overrides relative to role base
      final rolePerms = _selectedRole!.permissions;
      final addedOverrides = <String, List<String>>{};
      final removedOverrides = <String, List<String>>{};

      for (final mod in _modules) {
        final selected = _selectedPermissions[mod.id] ?? {};
        final base = Set<String>.from(rolePerms[mod.id] ?? []);

        final added = selected.difference(base);
        final removed = base.difference(selected);

        if (added.isNotEmpty) addedOverrides[mod.id] = added.toList();
        if (removed.isNotEmpty) removedOverrides[mod.id] = removed.toList();
      }

      await FirebaseAuthService.instance.grantAdminAccess(
        targetUid: _selectedUser!['uid'],
        targetDisplayName: _selectedUser!['fullName'],
        roleId: _selectedRole!.id,
        roleDisplayName: _selectedRole!.name,
        roleLevel: _selectedRole!.level,
        permissionsAdded: addedOverrides,
        permissionsRemoved: removedOverrides,
      );

      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Row(
              children: [
                // Step progress sidebar
                _buildStepSidebar(),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        _buildStepContent(),
                        const SizedBox(height: 32),
                        _buildNavigationButtons(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          const Icon(Icons.admin_panel_settings_rounded,
              color: Color(0xFF059669), size: 24),
          const SizedBox(width: 12),
          Text(
            'Grant Admin Access',
            style: GoogleFonts.inter(
                fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          const Spacer(),
          if (_existingRecord != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit_outlined,
                      size: 14, color: Color(0xFFD97706)),
                  const SizedBox(width: 6),
                  Text('Update Mode',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFD97706))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step sidebar
  // ---------------------------------------------------------------------------
  Widget _buildStepSidebar() {
    final steps = [
      ('Select User', Icons.person_search_rounded),
      ('Assign Role', Icons.shield_outlined),
      ('Set Permissions', Icons.tune_rounded),
      ('Confirm & Submit', Icons.check_circle_outline_rounded),
    ];

    return Container(
      width: 220,
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: steps.asMap().entries.map((entry) {
          final i = entry.key;
          final (label, icon) = entry.value;
          final isDone = i < _currentStep;
          final isActive = i == _currentStep;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                // Connector line
                Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDone
                            ? const Color(0xFF059669)
                            : isActive
                                ? const Color(0xFF10B981)
                                : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: isActive
                            ? Border.all(color: const Color(0xFF10B981), width: 2)
                            : null,
                      ),
                      child: Icon(
                        isDone ? Icons.check_rounded : icon,
                        color: isDone || isActive
                            ? Colors.white
                            : const Color(0xFF475569),
                        size: 16,
                      ),
                    ),
                    if (i < steps.length - 1)
                      Container(
                        width: 2,
                        height: 36,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        color: isDone
                            ? const Color(0xFF059669)
                            : const Color(0xFF1E293B),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 36),
                    child: Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive
                            ? Colors.white
                            : isDone
                                ? const Color(0xFF10B981)
                                : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step content switcher
  // ---------------------------------------------------------------------------
  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep0SelectUser();
      case 1:
        return _buildStep1AssignRole();
      case 2:
        return _buildStep2SetPermissions();
      case 3:
        return _buildStep3Confirm();
      default:
        return const SizedBox.shrink();
    }
  }

  // ---------------------------------------------------------------------------
  // Step 0 — Select User
  // ---------------------------------------------------------------------------
  Widget _buildStep0SelectUser() {
    return _StepCard(
      title: 'Select User',
      subtitle: 'Choose an existing registered user to grant admin access.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('Search & Select User'),
          const SizedBox(height: 12),
          // User picker
          FutureBuilder<List<Map<String, dynamic>>>(
            future: FirebaseAuthService.instance.fetchGrantableUsers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(
                    color: Color(0xFF059669)));
              }
              final users = snapshot.data ?? [];
              return _UserSearchDropdown(
                users: users,
                selectedUid: _selectedUser?['uid'],
                onSelected: (user) async {
                  setState(() => _selectedUser = user);
                  await _checkExistingRecord(user['uid']);
                },
              );
            },
          ),

          if (_selectedUser != null) ...[
            const SizedBox(height: 24),
            _SectionLabel('User Information (Read-Only)'),
            const SizedBox(height: 12),
            _buildReadOnlyCard(),
            if (_existingRecord != null) ...[
              const SizedBox(height: 16),
              _buildExistingAccessBanner(),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildReadOnlyCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _ReadOnlyField(
              label: 'Full Name', value: _selectedUser!['fullName'] ?? '-'),
          _ReadOnlyField(
              label: 'Username', value: _selectedUser!['username'] ?? '-'),
          _ReadOnlyField(label: 'Email', value: _selectedUser!['email'] ?? '-'),
          _ReadOnlyField(
              label: 'Phone',
              value: _selectedUser!['phone'] ?? '-',
              isLast: true),
        ],
      ),
    );
  }

  Widget _buildExistingAccessBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFFD97706), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This user already has "${_existingRecord!.roleDisplayName}" access. '
              'Proceeding will update their role and permissions.',
              style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFFD97706)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 1 — Assign Role
  // ---------------------------------------------------------------------------
  Widget _buildStep1AssignRole() {
    if (_availableRoles.isEmpty && !_loadingRoles) {
      _loadRoles();
    }

    return _StepCard(
      title: 'Assign Role',
      subtitle:
          'Select a role for this user. You can only assign roles below your own level (${_session.roleDisplayName}).',
      child: _loadingRoles
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF059669)))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLabel('Available Roles'),
                const SizedBox(height: 12),
                ..._availableRoles.map((role) => _RoleTile(
                      role: role,
                      isSelected: _selectedRole?.id == role.id,
                      onTap: () => setState(() {
                        _selectedRole = role;
                        // Pre-populate permissions with role base permissions
                        _selectedPermissions = {};
                        for (final e in role.permissions.entries) {
                          _selectedPermissions[e.key] = Set<String>.from(e.value);
                        }
                      }),
                    )),
                if (_availableRoles.isEmpty)
                  Center(
                    child: Text(
                      'No roles available to assign at your current permission level.',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: const Color(0xFF94A3B8)),
                    ),
                  ),
              ],
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 2 — Set Permissions
  // ---------------------------------------------------------------------------
  Widget _buildStep2SetPermissions() {
    return _StepCard(
      title: 'Set Permissions',
      subtitle:
          'Customize module access for this user. You can only assign modules you have access to.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedRole != null)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined,
                      color: Color(0xFF059669), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Base role: ${_selectedRole!.name} — permissions pre-loaded. '
                    'You can add or remove actions below.',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: const Color(0xFF059669)),
                  ),
                ],
              ),
            ),
          ..._modules
              .where((mod) => _session.canGrantModule(mod.id))
              .map((mod) => _ModulePermissionTile(
                    module: mod,
                    selected: _selectedPermissions[mod.id] ?? {},
                    onChanged: (action, granted) {
                      setState(() {
                        _selectedPermissions[mod.id] ??= {};
                        if (granted) {
                          _selectedPermissions[mod.id]!.add(action);
                        } else {
                          _selectedPermissions[mod.id]!.remove(action);
                        }
                        if (_selectedPermissions[mod.id]!.isEmpty) {
                          _selectedPermissions.remove(mod.id);
                        }
                      });
                    },
                  )),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 3 — Confirm
  // ---------------------------------------------------------------------------
  Widget _buildStep3Confirm() {
    return _StepCard(
      title: 'Confirm & Submit',
      subtitle: 'Review the access configuration before granting.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User summary
          _SummarySection(
            title: 'User',
            child: _ReadOnlyField(
                label: 'Full Name',
                value: _selectedUser!['fullName'] ?? '-'),
          ),
          const SizedBox(height: 16),

          // Role summary
          _SummarySection(
            title: 'Role',
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Text(
                    _selectedRole?.name ?? '-',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF059669)),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Level ${_selectedRole?.level ?? 0}',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: const Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Permissions summary
          _SummarySection(
            title: 'Permissions',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedPermissions.entries
                  .map((e) => Chip(
                        label: Text(
                          '${e.key.split("_").map((w) => "${w[0].toUpperCase()}${w.substring(1)}").join(" ")} '
                          '(${e.value.join(", ")})',
                          style: GoogleFonts.inter(fontSize: 11),
                        ),
                        backgroundColor: const Color(0xFFF0FDF4),
                        side: const BorderSide(color: Color(0xFFBBF7D0)),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Login credentials note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.key_outlined,
                        color: Color(0xFF059669), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Login Credentials',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '• Username: ${_selectedUser!["username"] ?? "-"} (unchanged)',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: const Color(0xFF475569)),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Password: The user\'s existing app password.',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: const Color(0xFF475569)),
                ),
                const SizedBox(height: 4),
                Text(
                  '• If they need a new password, use "Send Reset Email" below.',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: const Color(0xFF475569)),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final email = _selectedUser!['email'] ?? '';
                    if (email.isEmpty) return;
                    try {
                      await FirebaseAuthService.instance
                          .sendPasswordResetEmail(email);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Reset email sent to $email'),
                          backgroundColor: const Color(0xFF059669),
                        ));
                      }
                    } catch (_) {}
                  },
                  icon: const Icon(Icons.email_outlined, size: 16),
                  label: Text('Send Password Reset Email',
                      style: GoogleFonts.inter(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF059669),
                    side: const BorderSide(color: Color(0xFF059669)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Navigation buttons
  // ---------------------------------------------------------------------------
  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_currentStep > 0)
          OutlinedButton.icon(
            onPressed: _prevStep,
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: Text('Back', style: GoogleFonts.inter()),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF475569),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        const SizedBox(width: 12),
        if (_currentStep < 3)
          ElevatedButton.icon(
            onPressed: _canProceed() ? _nextStep : null,
            icon: Text('Next', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            label: const Icon(Icons.arrow_forward_rounded, size: 16),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.check_rounded, size: 16),
            label: Text(
              _existingRecord != null ? 'Update Access' : 'Grant Access',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
      ],
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _canProceedStep0;
      case 1:
        return _canProceedStep1;
      case 2:
        return _canProceedStep2;
      default:
        return true;
    }
  }

  // ---------------------------------------------------------------------------
  // Dialogs
  // ---------------------------------------------------------------------------
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFF0FDF4),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline_rounded,
                  color: Color(0xFF059669), size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              'Access Granted!',
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Text(
              '${_selectedUser!["fullName"]} now has ${_selectedRole!.name} access.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Reset form
                setState(() {
                  _currentStep = 0;
                  _selectedUser = null;
                  _selectedRole = null;
                  _selectedPermissions = {};
                  _existingRecord = null;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size(double.infinity, 44),
              ),
              child: Text('Grant Another', style: GoogleFonts.inter()),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: GoogleFonts.inter()),
      backgroundColor: const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }
}

// ===========================================================================
// Sub-widgets
// ===========================================================================

class _StepCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _StepCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Text(subtitle,
              style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFF64748B))),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFF1F5F9)),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF64748B),
        letterSpacing: 0.5,
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _ReadOnlyField({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserSearchDropdown extends StatefulWidget {
  final List<Map<String, dynamic>> users;
  final String? selectedUid;
  final void Function(Map<String, dynamic>) onSelected;

  const _UserSearchDropdown({
    required this.users,
    required this.selectedUid,
    required this.onSelected,
  });

  @override
  State<_UserSearchDropdown> createState() => _UserSearchDropdownState();
}

class _UserSearchDropdownState extends State<_UserSearchDropdown> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.users
        .where((u) =>
            u['fullName'].toString().toLowerCase().contains(_query.toLowerCase()) ||
            u['username'].toString().toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Search by name or username…',
            hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFCBD5E1)),
            prefixIcon: const Icon(Icons.search_rounded,
                size: 20, color: Color(0xFF94A3B8)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 240),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: filtered.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
            itemBuilder: (context, i) {
              final user = filtered[i];
              final isSelected = user['uid'] == widget.selectedUid;
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFFF0FDF4),
                  child: Text(
                    (user['fullName'] as String).isNotEmpty
                        ? (user['fullName'] as String)[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF059669)),
                  ),
                ),
                title: Text(user['fullName'] as String,
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                subtitle: Text('@${user["username"]}',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: const Color(0xFF94A3B8))),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF059669), size: 18)
                    : null,
                tileColor: isSelected ? const Color(0xFFF0FDF4) : null,
                onTap: () => widget.onSelected(user),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RoleTile extends StatelessWidget {
  final RoleDefinition role;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleTile({
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF059669)
                  : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF059669)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.shield_outlined,
                    color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                    size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(role.name,
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A))),
                    if (role.description.isNotEmpty)
                      Text(role.description,
                          style: GoogleFonts.inter(
                              fontSize: 12, color: const Color(0xFF94A3B8))),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Level ${role.level}',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500)),
              ),
              const SizedBox(width: 8),
              if (isSelected)
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF059669), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModulePermissionTile extends StatefulWidget {
  final ModuleDefinition module;
  final Set<String> selected;
  final void Function(String action, bool granted) onChanged;

  const _ModulePermissionTile({
    required this.module,
    required this.selected,
    required this.onChanged,
  });

  @override
  State<_ModulePermissionTile> createState() => _ModulePermissionTileState();
}

class _ModulePermissionTileState extends State<_ModulePermissionTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final hasAny = widget.selected.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: hasAny ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasAny ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      hasAny
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      color: hasAny
                          ? const Color(0xFF059669)
                          : const Color(0xFF94A3B8),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.module.displayName,
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF0F172A)),
                      ),
                    ),
                    if (hasAny)
                      Text(
                        '${widget.selected.length}/${widget.module.actions.length} actions',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: const Color(0xFF059669)),
                      ),
                    const SizedBox(width: 8),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFF94A3B8),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded) ...[
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.module.actions.map((action) {
                    final isOn = widget.selected.contains(action);
                    return FilterChip(
                      label: Text(
                        '${action[0].toUpperCase()}${action.substring(1)}',
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                      selected: isOn,
                      onSelected: (v) => widget.onChanged(action, v),
                      selectedColor: const Color(0xFFD1FAE5),
                      checkmarkColor: const Color(0xFF059669),
                      backgroundColor: const Color(0xFFF1F5F9),
                      side: BorderSide(
                        color: isOn
                            ? const Color(0xFF059669)
                            : const Color(0xFFE2E8F0),
                      ),
                      labelStyle: GoogleFonts.inter(
                        color: isOn
                            ? const Color(0xFF059669)
                            : const Color(0xFF64748B),
                        fontWeight: isOn ? FontWeight.w600 : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  final String title;
  final Widget child;

  const _SummarySection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF94A3B8),
                letterSpacing: 1),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
