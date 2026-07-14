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

  bool get isSuperAdmin => roleLevel >= RoleLevels.superAdmin;
  bool get isDeveloper => isSuperAdmin;

  /// Alias for [isDeveloper] — kept for backward compatibility with existing pages.
  bool get isDev => isSuperAdmin;
  bool get isPrivileged => isSuperAdmin;

  /// Whether session is fully loaded and status is Active.
  bool get isActive => status == 'Active' && uid != null;

  // ---------------------------------------------------------------------------
  // Firestore real-time listener for session invalidation (recommendation #12)
  // ---------------------------------------------------------------------------
  StreamSubscription<DocumentSnapshot>? _sessionListener;

  void _startSessionListener(String uid) {
    // Hardcoded dev/superadmin accounts bypass the Firestore document listener
    // because their role, status, and permissions are hardcoded and cannot be
    // modified in Firestore. Skipping this prevents auto-signout if their
    // admin_users/{uid} document is missing.
    final currentUser = FirebaseAuth.instance.currentUser;
    const devEmails = [
      'superadmin@naattulink.com',
    ];
    if (currentUser != null && devEmails.contains(currentUser.email)) {
      return;
    }

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
          final data = snapshot.data() ?? {};
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

    final currentAuthUid = user.uid;
    email = user.email;

    // ── Resolve web-panel account → original UID ──────────────────────────────
    // When a web-panel account ({uid}_adm@naattulink.internal) is signed in,
    // its Firebase UID differs from the user's real UID stored in admin_users.
    // web_auth_index/{webAuthUid} maps back to the original uid.
    String? originalUid;
    try {
      final indexDoc =
          await FirebaseFirestore.instance
              .collection('web_auth_index')
              .doc(currentAuthUid)
              .get();
      if (indexDoc.exists) {
        originalUid = indexDoc.data()!['originalUid'] as String?;
      }
    } catch (_) {}

    // Use originalUid for all RBAC operations (falls back to currentAuthUid
    // for Super Admin accounts that sign in with their real Firebase account).
    uid = originalUid ?? currentAuthUid;

    // ── Super Admin check (hardcoded superadmin/dev emails) ───────────────────
    const devEmails = [
      'superadmin@naattulink.com',
    ];
    if (devEmails.contains(user.email)) {
      roleId = 'super_admin';
      roleDisplayName = 'Super Admin';
      roleLevel = RoleLevels.superAdmin;
      status = 'Active';
      fullName = 'Super Admin';
      username = 'superadmin';
      effectivePermissions = _allPermissions();

      // Ensure the Firestore documents exist for this Super Admin/Developer
      // so they are listed in the admin users list.
      _ensureFirestoreAdminDocExists(uid!, user.email!);

      return;
    }

    // ── Load admin_users/{uid} ────────────────────────────────────────────────
    // uid is the original user UID, not the web auth account UID.
    DocumentSnapshot? adminDoc;
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('admin_users')
              .doc(uid)
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

    // ── Status check ──────────────────────────────────────────────────────────
    if (adminUser.status != 'Active') {
      clear();
      await FirebaseAuth.instance.signOut();
      return;
    }

    roleId = adminUser.roleId;
    roleDisplayName = adminUser.roleDisplayName;
    roleLevel = adminUser.roleLevel;
    status = adminUser.status;

    // ── Super Admin — full access ─────────────────────────────────────────────
    if (adminUser.roleId == 'super_admin') {
      fullName = await _loadDisplayName(uid!);
      username = await _loadUsername(uid!);
      effectivePermissions = _allPermissions();
      if (!fromListener) _startSessionListener(uid!);
      return;
    }

    // ── Load role base permissions from roles/{roleIds} ───────────────────────
    Map<String, List<String>> basePermissions = {};
    try {
      for (final rId in adminUser.roleIds) {
        final roleDoc =
            await FirebaseFirestore.instance.collection('roles').doc(rId).get();
        if (roleDoc.exists) {
          final role = RoleDefinition.fromFirestore(roleDoc);
          if (role.isActive) {
            // Merge this role's base permissions (union)
            for (final entry in role.permissions.entries) {
              final currentList = basePermissions[entry.key] ?? [];
              for (final val in entry.value) {
                if (!currentList.contains(val)) {
                  currentList.add(val);
                }
              }
              basePermissions[entry.key] = currentList;
            }
          }
        }
      }
    } catch (_) {}

    // ── Merge overrides: base + added − removed ───────────────────────────────
    effectivePermissions = _mergePermissions(
      base: basePermissions,
      added: adminUser.permissionOverridesAdded,
      removed: adminUser.permissionOverridesRemoved,
    );

    // ── Load profile display info from users/{uid} ────────────────────────────
    fullName = await _loadDisplayName(uid!);
    username = await _loadUsername(uid!);

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
      final q =
          await FirebaseFirestore.instance
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
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final d = doc.data() as Map<String, dynamic>;
        return d['fullName'] as String? ?? d['name'] as String? ?? 'Admin';
      }
    } catch (_) {}
    return 'Admin';
  }

  Future<String?> _loadUsername(String uid) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final d = doc.data() as Map<String, dynamic>;
        return d['username'] as String?;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _ensureFirestoreAdminDocExists(String uid, String email) async {
    try {
      final db = FirebaseFirestore.instance;
      final doc = await db.collection('admin_users').doc(uid).get();
      if (!doc.exists) {
        final username = email.split('@').first;
        // 1. Create/update the users/{uid} document
        await db.collection('users').doc(uid).set({
          'email': email,
          'username': username,
          'fullName': 'Super Admin',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // 2. Create/update the admin_users/{uid} document
        await db.collection('admin_users').doc(uid).set({
          'roleId': 'super_admin',
          'roleDisplayName': 'Super Admin',
          'roleLevel': 100,
          'roleIds': ['super_admin'],
          'status': 'Active',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print(
          'RBAC SESSION: Automatically recreated missing Super Admin Firestore documents.',
        );
      }
    } catch (e) {
      print('RBAC SESSION: Error ensuring Super Admin document exists: $e');
    }
  }
}
