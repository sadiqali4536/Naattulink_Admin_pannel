import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swiftclean_admin/MVVM/model/models/admin_model.dart';
import 'package:swiftclean_admin/MVVM/model/services/firebaseauthservices.dart';
import 'package:swiftclean_admin/MVVM/utils/rbac_session.dart';

class GrantAccessPage extends StatefulWidget {
  final ValueChanged<String>? onTabChanged;

  const GrantAccessPage({super.key, this.onTabChanged});

  @override
  State<GrantAccessPage> createState() => _GrantAccessPageState();
}

class _GrantAccessPageState extends State<GrantAccessPage> {
  final _session = RbacSession();
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Step 1 — Selected user
  Map<String, dynamic>? _selectedUser;

  // Step 2 — Selected roles
  final Set<String> _selectedRoleIds = {};
  final List<RoleDefinition> _selectedRoles = [];
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

  // Web password generated in step 4 and used during submit
  String? _webPassword;

  @override
  void initState() {
    super.initState();
    _loadModules();
    _loadRoles();
  }

  // ---------------------------------------------------------------------------
  // Data loaders
  // ---------------------------------------------------------------------------
  Future<void> _loadModules() async {
    if (mounted) setState(() => _loadingModules = true);
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('modules').get();
      if (snapshot.docs.isNotEmpty && mounted) {
        setState(() {
          _modules = snapshot.docs.map(ModuleDefinition.fromFirestore).toList();
        });
      }
    } catch (_) {
      // Fallback to builtin
    }
    if (mounted) setState(() => _loadingModules = false);
  }

  Future<void> _loadRoles() async {
    if (mounted) setState(() => _loadingRoles = true);
    try {
      final roles = await FirebaseAuthService.instance.fetchAssignableRoles(
        _session.roleLevel,
      );
      if (mounted) {
        setState(() {
          _availableRoles = roles;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingRoles = false);
  }

  void _updateSelectedPermissionsFromRoles() {
    _selectedPermissions = {};
    for (final role in _selectedRoles) {
      for (final e in role.permissions.entries) {
        final currentSet = _selectedPermissions[e.key] ?? {};
        currentSet.addAll(e.value);
        _selectedPermissions[e.key] = currentSet;
      }
    }
  }

  Future<void> _checkExistingRecord(String uid) async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('admin_users')
              .doc(uid)
              .get();
      if (doc.exists) {
        final record = AdminUserModel.fromFirestore(doc);
        setState(() {
          _existingRecord = record;
          _selectedRoleIds.clear();
          _selectedRoles.clear();

          // Tick all currently assigned roles
          for (final rId in record.roleIds) {
            final roleDef = _availableRoles.firstWhere(
              (r) => r.id == rId,
              orElse:
                  () => RoleDefinition(
                    id: rId,
                    name: rId
                        .split('_')
                        .map((w) => w[0].toUpperCase() + w.substring(1))
                        .join(' '),
                    level: record.roleLevel,
                    description: '',
                    status: 'Active',
                    permissions: {},
                  ),
            );
            _selectedRoleIds.add(rId);
            _selectedRoles.add(roleDef);
          }

          // Pre-populate permissions with existing user's overrides
          _selectedPermissions = {};
          // Start with the union of selected roles base permissions
          for (final role in _selectedRoles) {
            for (final e in role.permissions.entries) {
              final currentSet = _selectedPermissions[e.key] ?? {};
              currentSet.addAll(e.value);
              _selectedPermissions[e.key] = currentSet;
            }
          }
          // Apply overrides added
          for (final e in record.permissionOverridesAdded.entries) {
            final currentSet = _selectedPermissions[e.key] ?? {};
            currentSet.addAll(e.value);
            _selectedPermissions[e.key] = currentSet;
          }
          // Apply overrides removed
          for (final e in record.permissionOverridesRemoved.entries) {
            final currentSet = _selectedPermissions[e.key] ?? {};
            currentSet.removeAll(e.value);
            if (currentSet.isEmpty) {
              _selectedPermissions.remove(e.key);
            } else {
              _selectedPermissions[e.key] = currentSet;
            }
          }
        });
      } else {
        setState(() {
          _existingRecord = null;
          _selectedRoleIds.clear();
          _selectedRoles.clear();

          _selectedPermissions = {};
        });
      }
    } catch (_) {
      setState(() {
        _existingRecord = null;
        _selectedRoleIds.clear();
        _selectedRoles.clear();

        _selectedPermissions = {};
      });
    }
  }

  void _showCreateRoleDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final levelController = TextEditingController();
    bool isSaving = false;

    InputDecoration inputDecoration({
      required String labelText,
      required String hintText,
      required Widget prefixIcon,
    }) {
      return InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          color: const Color(0xFF64748B),
          fontWeight: FontWeight.w500,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 13,
          color: const Color(0xFF94A3B8),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      );
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              child: Container(
                width: 480,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 18,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.shield_outlined,
                              color: Color(0xFF10B981),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Create New Role',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed:
                                isSaving ? null : () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                            color: const Color(0xFF64748B),
                            splashRadius: 20,
                          ),
                        ],
                      ),
                    ),

                    // Body
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: nameController,
                              enabled: !isSaving,
                              decoration: inputDecoration(
                                labelText: 'Role Name',
                                hintText: 'e.g., Sub-Admin, Manager',
                                prefixIcon: const Icon(
                                  Icons.badge_outlined,
                                  size: 18,
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Please enter a role name';
                                }
                                if (val.trim().toLowerCase() == 'developer' ||
                                    val.trim().toLowerCase() == 'super_admin' ||
                                    val.trim().toLowerCase() == 'super admin') {
                                  return 'This role name is reserved';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: descriptionController,
                              enabled: !isSaving,
                              maxLines: 2,
                              decoration: inputDecoration(
                                labelText: 'Description',
                                hintText: 'Role duties and responsibilities',
                                prefixIcon: const Icon(
                                  Icons.description_outlined,
                                  size: 18,
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Please enter a description';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: levelController,
                              enabled: !isSaving,
                              keyboardType: TextInputType.number,
                              decoration: inputDecoration(
                                labelText:
                                    'Role Level (1 - ${_session.roleLevel - 1})',
                                hintText: 'Higher number = more privilege',
                                prefixIcon: const Icon(
                                  Icons.trending_up_rounded,
                                  size: 18,
                                ),
                              ).copyWith(
                                helperText:
                                    'Must be lower than your level (${_session.roleLevel})',
                                helperStyle: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Please enter a level';
                                }
                                final lvl = int.tryParse(val.trim());
                                if (lvl == null) {
                                  return 'Please enter a valid integer';
                                }
                                if (lvl < 1 || lvl >= _session.roleLevel) {
                                  return 'Level must be between 1 and ${_session.roleLevel - 1}';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Footer Actions
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed:
                                isSaving ? null : () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed:
                                isSaving
                                    ? null
                                    : () async {
                                      if (formKey.currentState!.validate()) {
                                        setDialogState(() => isSaving = true);
                                        try {
                                          final name =
                                              nameController.text.trim();
                                          final description =
                                              descriptionController.text.trim();
                                          final level = int.parse(
                                            levelController.text.trim(),
                                          );
                                          final roleId = name
                                              .toLowerCase()
                                              .replaceAll(' ', '_');

                                          final docSnap =
                                              await FirebaseFirestore.instance
                                                  .collection('roles')
                                                  .doc(roleId)
                                                  .get();

                                          if (docSnap.exists) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'A role with this name already exists!',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                            setDialogState(
                                              () => isSaving = false,
                                            );
                                            return;
                                          }

                                          final initials =
                                              name.length >= 2
                                                  ? name
                                                      .substring(0, 2)
                                                      .toUpperCase()
                                                  : name[0].toUpperCase();

                                          final List<Color> colors = [
                                            const Color(0xFF8B5CF6),
                                            const Color(0xFF3B82F6),
                                            const Color(0xFF0D9488),
                                            const Color(0xFFF59E0B),
                                            const Color(0xFFEC4899),
                                            const Color(0xFF64748B),
                                          ];
                                          final Color color =
                                              colors[name.hashCode %
                                                  colors.length];

                                          await FirebaseFirestore.instance
                                              .collection('roles')
                                              .doc(roleId)
                                              .set({
                                                'name': name,
                                                'description': description,
                                                'level': level,
                                                'status': 'Active',
                                                'createdAt': Timestamp.now(),
                                                'initials': initials,
                                                'badgeColor': color.toARGB32(),
                                                'permissions': {},
                                                'usersCount': 0,
                                                'canAssignBelow': true,
                                              });

                                          Navigator.pop(context);
                                          _loadRoles();

                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Role "$name" created successfully!',
                                              ),
                                              backgroundColor: const Color(
                                                0xFF059669,
                                              ),
                                            ),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Error creating role: $e',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        } finally {
                                          setDialogState(
                                            () => isSaving = false,
                                          );
                                        }
                                      }
                                    },
                            icon:
                                isSaving
                                    ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Icon(Icons.save_outlined, size: 18),
                            label: Text(
                              isSaving ? 'Saving...' : 'Save Role',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
  bool get _canProceedStep1 => _selectedRoleIds.isNotEmpty;
  bool get _canProceedStep2 => _selectedPermissions.isNotEmpty;

  // ---------------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------------
  Future<void> _submit() async {
    if (_selectedUser == null || _selectedRoles.isEmpty) return;

    // Require a web password for new grants. Re-grants keep the existing one.
    final isNewGrant = _existingRecord?.webAuthUid == null;
    if (isNewGrant && (_webPassword == null || _webPassword!.isEmpty)) {
      _showError(
        'Please generate a web password before granting access.\n'
        'Use the "Generate Password" button in the confirmation step.',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Build permission overrides relative to roles base (combined)
      final rolePerms = <String, List<String>>{};
      for (final r in _selectedRoles) {
        for (final e in r.permissions.entries) {
          final currentList = rolePerms[e.key] ?? [];
          for (final val in e.value) {
            if (!currentList.contains(val)) currentList.add(val);
          }
          rolePerms[e.key] = currentList;
        }
      }

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

      final primaryRole = _selectedRoles.first;
      final maxLevel = _selectedRoles
          .map((r) => r.level)
          .reduce((a, b) => a > b ? a : b);
      final roleDisplay = _selectedRoles.map((r) => r.name).join(', ');

      // 2. Write RBAC record (admin_users/{uid})
      await FirebaseAuthService.instance.grantAdminAccess(
        targetUid: _selectedUser!['uid'],
        targetDisplayName: _selectedUser!['fullName'],
        roleId: primaryRole.id,
        roleDisplayName: roleDisplay,
        roleLevel: maxLevel,
        roleIds: _selectedRoleIds.toList(),
        permissionsAdded: addedOverrides,
        permissionsRemoved: removedOverrides,
      );

      // 3. Create (or verify) the web-panel Firebase Auth account
      //    If the user already had one, createWebAdminAccount() returns the
      //    existing webAuthUid without changing the password.
      bool createdNew = false;
      if (_webPassword != null && _webPassword!.isNotEmpty) {
        final prevWebUid = _existingRecord?.webAuthUid;
        await FirebaseAuthService.instance.createWebAdminAccount(
          targetUid: _selectedUser!['uid'],
          targetDisplayName: _selectedUser!['fullName'],
          webPassword: _webPassword!,
        );
        // Detect whether a brand-new account was created
        createdNew = prevWebUid == null;
      } else {
        // Re-grant with no new password — existing web account is kept
        createdNew = false;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_selectedUser!["fullName"]} now has ${roleDisplay} access.',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: const Color(0xFF059669),
        ),
      );

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else if (widget.onTabChanged != null) {
        widget.onTabChanged!("User Roles");
      } else {
        setState(() {
          _currentStep = 0;
          _selectedUser = null;
          _selectedRoleIds.clear();
          _selectedRoles.clear();
          _selectedPermissions = {};
          _existingRecord = null;
          _webPassword = null;
        });
      }
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
          const Icon(
            Icons.admin_panel_settings_rounded,
            color: Color(0xFF059669),
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'Grant Admin Access',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
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
                  const Icon(
                    Icons.edit_outlined,
                    size: 14,
                    color: Color(0xFFD97706),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Update Mode',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFD97706),
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
        children:
            steps.asMap().entries.map((entry) {
              final i = entry.key;
              final (label, icon) = entry.value;
              final isDone = i < _currentStep;
              final isActive = i == _currentStep;

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    // Connector line
                    Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color:
                                isDone
                                    ? const Color(0xFF059669)
                                    : isActive
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(16),
                            border:
                                isActive
                                    ? Border.all(
                                      color: const Color(0xFF10B981),
                                      width: 2,
                                    )
                                    : null,
                          ),
                          child: Icon(
                            isDone ? Icons.check_rounded : icon,
                            color:
                                isDone || isActive
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
                            color:
                                isDone
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
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w400,
                            color:
                                isActive
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
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF059669)),
                );
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
            label: 'Username',
            value: _selectedUser!['username'] ?? '-',
          ),
          _ReadOnlyField(label: 'Email', value: _selectedUser!['email'] ?? '-'),
          _ReadOnlyField(
            label: 'Phone',
            value: _selectedUser!['phone'] ?? '-',
            isLast: true,
          ),
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
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFD97706),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This user already has "${_existingRecord!.roleDisplayName}" access. '
              'Proceeding will update their role and permissions.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFFD97706),
              ),
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
    return _StepCard(
      title: 'Assign Role',
      subtitle:
          'Select a role for this user. You can only assign roles below your own level (${_session.roleDisplayName}).',
      child:
          _loadingRoles
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF059669)),
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionLabel('Available Roles'),
                      TextButton.icon(
                        onPressed: () => _showCreateRoleDialog(context),
                        icon: const Icon(
                          Icons.add_rounded,
                          size: 18,
                          color: Color(0xFF059669),
                        ),
                        label: Text(
                          'Create Role',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF059669),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._availableRoles.map(
                    (role) => _RoleTile(
                      role: role,
                      isSelected: _selectedRoleIds.contains(role.id),
                      onTap:
                          () => setState(() {
                            if (_selectedRoleIds.contains(role.id)) {
                              _selectedRoleIds.remove(role.id);
                              _selectedRoles.removeWhere(
                                (r) => r.id == role.id,
                              );
                            } else {
                              _selectedRoleIds.add(role.id);
                              _selectedRoles.add(role);
                            }

                            _updateSelectedPermissionsFromRoles();
                          }),
                    ),
                  ),
                  if (_availableRoles.isEmpty)
                    Center(
                      child: Text(
                        'No roles available to assign at your current permission level.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF94A3B8),
                        ),
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
          if (_selectedRoles.isNotEmpty)
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
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF059669),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Base roles: ${_selectedRoles.map((r) => r.name).join(", ")} — permissions pre-loaded. '
                      'You can add or remove specific actions below.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF047857),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ..._modules
              .where((mod) => _session.canGrantModule(mod.id))
              .map(
                (mod) => _ModulePermissionTile(
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
                  onAllChanged: (actions, granted) {
                    setState(() {
                      if (granted) {
                        _selectedPermissions[mod.id] = Set<String>.from(
                          actions,
                        );
                      } else {
                        _selectedPermissions.remove(mod.id);
                      }
                    });
                  },
                ),
              ),
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
              label: 'Username',
              value: _selectedUser!['username'] ?? '-',
            ),
          ),
          const SizedBox(height: 16),

          // Role summary
          _SummarySection(
            title: 'Role',
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Text(
                    _selectedRoles.map((r) => r.name).join(', '),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF059669),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Level ${_selectedRoles.isNotEmpty ? _selectedRoles.map((r) => r.level).reduce((a, b) => a > b ? a : b) : 0}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF94A3B8),
                  ),
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
              children:
                  _selectedPermissions.entries
                      .map(
                        (e) => Chip(
                          label: Text(
                            '${e.key.split("_").map((w) => "${w[0].toUpperCase()}${w.substring(1)}").join(" ")} '
                            '(${e.value.join(", ")})',
                            style: GoogleFonts.inter(fontSize: 11),
                          ),
                          backgroundColor: const Color(0xFFF0FDF4),
                          side: const BorderSide(color: Color(0xFFBBF7D0)),
                        ),
                      )
                      .toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Web Password — required for new grants, optional for re-grants
          if (_existingRecord?.webAuthUid == null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFFD97706),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'A web panel password is required. Generate one below '
                      'and share it securely with the user.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFFD97706),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Color(0xFF059669),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This user already has a web panel account. '
                      'The existing password will be preserved.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _PasswordDeliverySection(
            email: _selectedUser?['email'] ?? '',
            username: _selectedUser?['username'] ?? '-',
            showGenerateOnly: _existingRecord?.webAuthUid != null,
            onPasswordGenerated: (pwd) {
              setState(() => _webPassword = pwd);
            },
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        const SizedBox(width: 12),
        if (_currentStep < 3)
          ElevatedButton.icon(
            onPressed: _canProceed() ? _nextStep : null,
            icon: Text(
              'Next',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            label: const Icon(Icons.arrow_forward_rounded, size: 16),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon:
                _isSubmitting
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : const Icon(Icons.check_rounded, size: 16),
            label: Text(
              _existingRecord != null ? 'Update Access' : 'Grant Access',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
  void _showSuccessDialog({bool webAccountCreatedNew = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Color(0xFF059669),
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Access Granted!',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_selectedUser!["fullName"]} now has ${_selectedRoles.map((r) => r.name).join(", ")} access.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 12),
                // Web account status indicator
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        webAccountCreatedNew
                            ? const Color(0xFFEFF6FF)
                            : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          webAccountCreatedNew
                              ? const Color(0xFFBFDBFE)
                              : const Color(0xFFBBF7D0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        webAccountCreatedNew
                            ? Icons.vpn_key_rounded
                            : Icons.lock_outline_rounded,
                        size: 16,
                        color:
                            webAccountCreatedNew
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFF059669),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          webAccountCreatedNew
                              ? 'Web panel account created. Share the generated password securely.'
                              : 'Existing web panel account preserved. Password unchanged.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color:
                                webAccountCreatedNew
                                    ? const Color(0xFF1D4ED8)
                                    : const Color(0xFF059669),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _currentStep = 0;
                      _selectedUser = null;
                      _selectedRoleIds.clear();
                      _selectedRoles.clear();
                      _selectedPermissions = {};
                      _existingRecord = null;
                      _webPassword = null;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
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
                color: const Color(0xFF94A3B8),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1E293B),
              ),
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
    final filtered =
        widget.users
            .where(
              (u) =>
                  u['fullName'].toString().toLowerCase().contains(
                    _query.toLowerCase(),
                  ) ||
                  u['username'].toString().toLowerCase().contains(
                    _query.toLowerCase(),
                  ),
            )
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Search by name or username…',
            hintStyle: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFFCBD5E1),
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              size: 20,
              color: Color(0xFF94A3B8),
            ),
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
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
            separatorBuilder:
                (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
            itemBuilder: (context, i) {
              final user = filtered[i];
              final isSelected = user['uid'] == widget.selectedUid;
              // Wrap in Material so ListTile's ink splashes and selection
              // background render above the outer Container's DecoratedBox.
              return Material(
                color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
                child: ListTile(
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
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ),
                  title: Text(
                    user['fullName'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    '@${user["username"]}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  trailing:
                      isSelected
                          ? const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF059669),
                            size: 18,
                          )
                          : null,
                  onTap: () => widget.onSelected(user),
                ),
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
            color:
                isSelected ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isSelected
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
                  color:
                      isSelected
                          ? const Color(0xFF059669)
                          : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.shield_outlined,
                  color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    if (role.description.isNotEmpty)
                      Text(
                        role.description,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Level ${role.level}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF059669),
                  size: 20,
                ),
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
  final void Function(List<String> actions, bool granted) onAllChanged;

  const _ModulePermissionTile({
    required this.module,
    required this.selected,
    required this.onChanged,
    required this.onAllChanged,
  });

  @override
  State<_ModulePermissionTile> createState() => _ModulePermissionTileState();
}

class _ModulePermissionTileState extends State<_ModulePermissionTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final hasAny = widget.selected.isNotEmpty;
    final allActions = widget.module.actions;
    final isAllSelected = widget.selected.length == allActions.length;
    final hasSomeSelected = widget.selected.isNotEmpty && !isAllSelected;

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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (isAllSelected) {
                          widget.onAllChanged(allActions, false);
                        } else {
                          widget.onAllChanged(allActions, true);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          isAllSelected
                              ? Icons.check_box_rounded
                              : hasSomeSelected
                              ? Icons.indeterminate_check_box_rounded
                              : Icons.check_box_outline_blank_rounded,
                          color:
                              hasAny
                                  ? const Color(0xFF059669)
                                  : const Color(0xFF94A3B8),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.module.displayName,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    if (hasAny)
                      Text(
                        '${widget.selected.length}/${widget.module.actions.length} actions',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF059669),
                        ),
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
                  children:
                      widget.module.actions.map((action) {
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
                            color:
                                isOn
                                    ? const Color(0xFF059669)
                                    : const Color(0xFFE2E8F0),
                          ),
                          labelStyle: GoogleFonts.inter(
                            color:
                                isOn
                                    ? const Color(0xFF059669)
                                    : const Color(0xFF64748B),
                            fontWeight:
                                isOn ? FontWeight.w600 : FontWeight.normal,
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
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Password Delivery Section Widget
// ---------------------------------------------------------------------------
class _PasswordDeliverySection extends StatefulWidget {
  final String email;
  final String username;

  /// Called whenever a password is generated. Parent uses this to gate submit.
  final void Function(String password) onPasswordGenerated;

  /// When true, the email-reset option is hidden (user already has web account).
  final bool showGenerateOnly;

  const _PasswordDeliverySection({
    required this.email,
    required this.username,
    required this.onPasswordGenerated,
    this.showGenerateOnly = false,
  });

  @override
  State<_PasswordDeliverySection> createState() =>
      _PasswordDeliverySectionState();
}

class _PasswordDeliverySectionState extends State<_PasswordDeliverySection> {
  String? _generatedPassword;
  bool _passwordCopied = false;
  bool _emailSent = false;
  bool _isSendingEmail = false;

  String _generateSecurePassword() {
    const upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    const lower = 'abcdefghjkmnpqrstuvwxyz';
    const digits = '23456789';
    const special = '!@#\$%^&*';
    const all = upper + lower + digits + special;
    final rand = Random.secure();
    final buf = [
      upper[rand.nextInt(upper.length)],
      lower[rand.nextInt(lower.length)],
      digits[rand.nextInt(digits.length)],
      special[rand.nextInt(special.length)],
      ...List.generate(8, (_) => all[rand.nextInt(all.length)]),
    ]..shuffle(rand);
    return buf.join();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.key_outlined,
                color: Color(0xFF059669),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Login Credentials',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Username: ${widget.username}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'Choose how to deliver the password to this user:',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 12),

          // Option — Copy Password (only option; email delivery not applicable
          // because the web-panel account uses an internal @naattulink.internal email)
          if (!widget.showGenerateOnly) ...[
            _OptionCard(
              icon: Icons.info_outline_rounded,
              iconColor: const Color(0xFF3B82F6),
              iconBg: const Color(0xFFEFF6FF),
              title: 'How to deliver the web password',
              subtitle:
                  'Generate a password below, copy it, and share it securely\n'
                  'with the user (e.g. via a secure messaging app or in person).\n'
                  'The web password is separate from the mobile app password.',
              trailingWidget: const SizedBox.shrink(),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 10),
          ],

          // Option — Generate & Copy Web Password
          _OptionCard(
            icon: Icons.copy_rounded,
            iconColor: const Color(0xFF059669),
            iconBg: const Color(0xFFF0FDF4),
            title:
                widget.showGenerateOnly
                    ? 'Generate New Password (Optional)'
                    : 'Generate Web Panel Password',
            subtitle:
                widget.showGenerateOnly
                    ? 'User already has a web account. You can generate a new password here for reference, but update it via Firebase console.'
                    : 'Generate a secure web-panel password and copy it to share with the user securely.',
            trailingWidget:
                _generatedPassword == null
                    ? ElevatedButton.icon(
                      onPressed: () {
                        final pass = _generateSecurePassword();
                        setState(() {
                          _generatedPassword = pass;
                          _passwordCopied = false;
                        });
                        // Notify parent so it can pass password to _submit()
                        widget.onPasswordGenerated(pass);
                      },
                      icon: const Icon(Icons.auto_fix_high_rounded, size: 14),
                      label: Text(
                        'Generate',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                    )
                    : const SizedBox.shrink(),
          ),

          // Generated password display
          if (_generatedPassword != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF10B981)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      _generatedPassword!,
                      style: GoogleFonts.robotoMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child:
                        _passwordCopied
                            ? const Icon(
                              Icons.check_circle_rounded,
                              key: ValueKey('check'),
                              color: Color(0xFF059669),
                              size: 22,
                            )
                            : IconButton(
                              key: const ValueKey('copy'),
                              tooltip: 'Copy to clipboard',
                              icon: const Icon(
                                Icons.copy_rounded,
                                size: 20,
                                color: Color(0xFF059669),
                              ),
                              onPressed: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: _generatedPassword!),
                                );
                                setState(() => _passwordCopied = true);
                                Future.delayed(const Duration(seconds: 3), () {
                                  if (mounted) {
                                    setState(() => _passwordCopied = false);
                                  }
                                });
                              },
                            ),
                  ),
                  IconButton(
                    tooltip: 'Regenerate',
                    icon: const Icon(
                      Icons.refresh_rounded,
                      size: 20,
                      color: Color(0xFF94A3B8),
                    ),
                    onPressed: () {
                      setState(() {
                        _generatedPassword = _generateSecurePassword();
                        _passwordCopied = false;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '⚠ Share this password securely with the user. '
              'It is the web panel login password — not the mobile app password.',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFFD97706),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Option card tile helper
// ---------------------------------------------------------------------------
class _OptionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final Widget trailingWidget;

  const _OptionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        trailingWidget,
      ],
    );
  }
}
