import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:swiftclean_admin/MVVM/model/models/admin_model.dart';

/// Singleton that holds the currently logged-in admin's session.
///
/// Permission resolution order (recommendation #7):
///   Role base permissions
///   + permissionOverridesAdded
///   - permissionOverridesRemoved
///   = effectivePermissions
///
/// Session is cached after login and refreshed only on:
///   • Login / Logout
///   • Firestore listener detects a change in admin_users/{uid}
class RbacSession {
  // ---------------------------------------------------------------------------
  // Singleton
  // ---------------------------------------------------------------------------
  static final RbacSession _instance = RbacSession._internal();
  factory RbacSession() => _instance;
  RbacSession._internal();

  // ---------------------------------------------------------------------------
  // Session fields
  // ---------------------------------------------------------------------------
  String? uid;
  String? username;
  String? fullName;
  String? email;
  String? roleId;
  String? roleDisplayName;
  int roleLevel = 0;
  String status = 'Inactive';
  Map<String, List<String>> effectivePermissions = {};

  bool get isSuperAdmin => roleLevel >= RoleLevels.superAdmin && roleLevel < RoleLevels.developer;
  bool get isDeveloper => roleLevel >= RoleLevels.developer;
  /// Alias for [isDeveloper] — kept for backward compatibility with existing pages.
  bool get isDev => isDeveloper;
  bool get isPrivileged => isSuperAdmin || isDeveloper;

  /// Whether session is fully loaded and status is Active.
  bool get isActive => status == 'Active' && uid != null;

  // ---------------------------------------------------------------------------
  // Firestore real-time listener for session invalidation (recommendation #12)
  // ---------------------------------------------------------------------------
  StreamSubscription<DocumentSnapshot>? _sessionListener;

  void _startSessionListener(String uid) {
    _sessionListener?.cancel();
    _sessionListener = FirebaseFirestore.instance
        .collection('admin_users')
        .doc(uid)
        .snapshots()
        .listen((snapshot) async {
      if (!snapshot.exists) {
        // Access revoked — force sign out
        await _forceSignOut();
        return;
      }
      final data = snapshot.data() as Map<String, dynamic>? ?? {};
      final newStatus = data['status'] as String? ?? 'Active';
      if (newStatus != 'Active') {
        await _forceSignOut();
        return;
      }
      // Re-load session silently to pick up permission changes
      await loadSession(fromListener: true);
    });
  }

  Future<void> _forceSignOut() async {
    clear();
    await FirebaseAuth.instance.signOut();
  }

  // ---------------------------------------------------------------------------
  // Load Session
  // ---------------------------------------------------------------------------
  Future<void> loadSession({bool fromListener = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      clear();
      return;
    }

    uid = user.uid;
    email = user.email;

    // ── Developer check (hardcoded dev emails) ────────────────────────────────
    const devEmails = [
      'developer@naattulink.com',
      'developer@nattulinkapp.com',
    ];
    if (devEmails.contains(user.email)) {
      roleId = 'developer';
      roleDisplayName = 'Developer';
      roleLevel = RoleLevels.developer;
      status = 'Active';
      fullName = 'Developer';
      username = 'developer';
      effectivePermissions = _allPermissions();
      if (!fromListener) _startSessionListener(uid!);
      return;
    }

    // ── Load admin_users/{uid} ────────────────────────────────────────────────
    DocumentSnapshot? adminDoc;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('admin_users')
          .doc(user.uid)
          .get();
      if (doc.exists) adminDoc = doc;
    } catch (_) {}

    if (adminDoc == null) {
      // Not an admin panel user — deny access
      clear();
      await FirebaseAuth.instance.signOut();
      return;
    }

    final adminUser = AdminUserModel.fromFirestore(adminDoc);

    // ── Status check (recommendation #8) ─────────────────────────────────────
    if (adminUser.status != 'Active') {
      clear();
      await FirebaseAuth.instance.signOut();
      return;
    }

    roleId = adminUser.roleId;
    roleDisplayName = adminUser.roleDisplayName;
    roleLevel = adminUser.roleLevel;
    status = adminUser.status;

    // ── Super Admin — full access, no role doc needed ─────────────────────────
    if (adminUser.roleId == 'super_admin') {
      fullName = await _loadDisplayName(user.uid);
      username = await _loadUsername(user.uid);
      effectivePermissions = _allPermissions();
      if (!fromListener) _startSessionListener(uid!);
      return;
    }

    // ── Load role base permissions from roles/{roleId} ────────────────────────
    Map<String, List<String>> basePermissions = {};
    try {
      final roleDoc = await FirebaseFirestore.instance
          .collection('roles')
          .doc(adminUser.roleId)
          .get();
      if (roleDoc.exists) {
        final role = RoleDefinition.fromFirestore(roleDoc);
        // If role is disabled, deny access
        if (!role.isActive) {
          clear();
          await FirebaseAuth.instance.signOut();
          return;
        }
        basePermissions = role.permissions;
      }
    } catch (_) {}

    // ── Merge overrides: base + added - removed (recommendation #7) ───────────
    effectivePermissions = _mergePermissions(
      base: basePermissions,
      added: adminUser.permissionOverridesAdded,
      removed: adminUser.permissionOverridesRemoved,
    );

    // ── Load profile display info from users/{uid} ────────────────────────────
    fullName = await _loadDisplayName(user.uid);
    username = await _loadUsername(user.uid);

    // ── Start listener for real-time session refresh ──────────────────────────
    if (!fromListener) _startSessionListener(uid!);
  }

  // ---------------------------------------------------------------------------
  // Permission checks
  // ---------------------------------------------------------------------------

  /// Check if the current user has [action] permission for [module].
  /// Use Modules.xxx and Perms.xxx constants.
  bool hasPermission(String module, String action) {
    if (isDeveloper || isSuperAdmin) return true;
    final actions = effectivePermissions[module];
    if (actions == null) return false;
    return actions.contains(action);
  }

  /// Whether this user can assign a role with [targetLevel].
  /// User can only assign roles strictly below their own level.
  bool canAssignRole(int targetLevel) {
    return targetLevel < roleLevel;
  }

  /// Whether this user can grant access to [module].
  /// Admins can only grant modules they themselves have view access to.
  bool canGrantModule(String module) {
    if (isDeveloper || isSuperAdmin) return true;
    return hasPermission(module, Perms.view);
  }

  // ---------------------------------------------------------------------------
  // Guards (recommendation #3 — self-demotion and last Super Admin protection)
  // ---------------------------------------------------------------------------

  /// Returns true if performing the action on [targetUid] would affect self.
  bool isSelf(String targetUid) => uid == targetUid;

  /// Check whether the last super admin safeguard applies.
  /// Must be checked before revoking/demoting/deactivating any super admin.
  Future<bool> isLastSuperAdmin(String targetUid) async {
    try {
      final q = await FirebaseFirestore.instance
          .collection('admin_users')
          .where('roleId', isEqualTo: 'super_admin')
          .where('status', isEqualTo: 'Active')
          .get();
      // If only one super admin exists and it's the target → block
      return q.docs.length == 1 && q.docs.first.id == targetUid;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Clear / Logout
  // ---------------------------------------------------------------------------
  void clear() {
    _sessionListener?.cancel();
    _sessionListener = null;
    uid = null;
    username = null;
    fullName = null;
    email = null;
    roleId = null;
    roleDisplayName = null;
    roleLevel = 0;
    status = 'Inactive';
    effectivePermissions = {};
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Returns full permission map granting all actions on all modules.
  Map<String, List<String>> _allPermissions() {
    final result = <String, List<String>>{};
    for (final module in AppModules.builtin) {
      result[module.id] = List<String>.from(module.actions);
    }
    return result;
  }

  /// Merges base + added − removed to produce effective permissions.
  Map<String, List<String>> _mergePermissions({
    required Map<String, List<String>> base,
    required Map<String, List<String>> added,
    required Map<String, List<String>> removed,
  }) {
    final result = <String, List<String>>{};

    // Start with base
    for (final e in base.entries) {
      result[e.key] = List<String>.from(e.value);
    }

    // Apply additions
    for (final e in added.entries) {
      if (result.containsKey(e.key)) {
        for (final a in e.value) {
          if (!result[e.key]!.contains(a)) result[e.key]!.add(a);
        }
      } else {
        result[e.key] = List<String>.from(e.value);
      }
    }

    // Apply removals
    for (final e in removed.entries) {
      if (result.containsKey(e.key)) {
        result[e.key]!.removeWhere((a) => e.value.contains(a));
        if (result[e.key]!.isEmpty) result.remove(e.key);
      }
    }

    return result;
  }

  Future<String> _loadDisplayName(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final d = doc.data() as Map<String, dynamic>;
        return d['fullName'] as String? ?? d['name'] as String? ?? 'Admin';
      }
    } catch (_) {}
    return 'Admin';
  }

  Future<String?> _loadUsername(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final d = doc.data() as Map<String, dynamic>;
        return d['username'] as String?;
      }
    } catch (_) {}
    return null;
  }
}
