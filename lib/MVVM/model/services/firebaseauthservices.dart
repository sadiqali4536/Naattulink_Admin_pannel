import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:swiftclean_admin/MVVM/model/models/admin_model.dart';
import 'package:swiftclean_admin/MVVM/utils/rbac_session.dart';

/// Firebase Auth + Firestore service for the admin panel.
///
/// Key design principles:
/// • One Firebase Auth account per person — no duplicate identities.
/// • Username login: query Firestore users collection for email, then authenticate.
/// • Granting access = write admin_users/{uid}, NOT a new Auth account.
/// • Every significant action writes an audit log.
class FirebaseAuthService {
  FirebaseAuthService._();
  static final FirebaseAuthService instance = FirebaseAuthService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // Login — username → email → Firebase Auth (recommendation #3)
  // ---------------------------------------------------------------------------

  /// Signs in using a username. Resolves username → real email via Firestore,
  /// then authenticates with Firebase. On success, loads the RBAC session.
  ///
  /// Throws [FirebaseAuthException] or a [String] message on failure.
  Future<void> signInWithUsername(String username, String password) async {
    // 1. Resolve username → email from users collection
    String? email;
    try {
      final query = await _db
          .collection('users')
          .where('username', isEqualTo: username.trim())
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        email = query.docs.first.data()['email'] as String?;
      }
    } catch (e) {
      throw 'Unable to reach the server. Please check your connection.';
    }

    if (email == null || email.isEmpty) {
      // Try developer login by email directly
      if (username.contains('@')) {
        email = username.trim();
      } else {
        await _writeFailedLoginLog(username);
        throw 'No account found with username "$username".';
      }
    }

    // 2. Sign in with Firebase Auth using the resolved real email
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      await _writeFailedLoginLog(username);
      rethrow;
    }

    // 3. Load RBAC session — validates status, loads role & permissions
    await RbacSession().loadSession();

    // 4. If session is not active after loading, sign out and throw
    if (!RbacSession().isActive) {
      await signOut();
      throw 'Your account access has been ${RbacSession().status.toLowerCase()}. '
          'Please contact your administrator.';
    }

    // 5. Write login audit log
    await _writeAuditLog(
      action: AuditActions.login,
      performedByUid: RbacSession().uid ?? '',
      performedByName: RbacSession().fullName ?? username,
      performedToUid: RbacSession().uid ?? '',
      performedToName: RbacSession().fullName ?? username,
      details: const AuditDetails(platform: kIsWeb ? 'web' : 'app'),
    );
  }

  // ---------------------------------------------------------------------------
  // Grant Access (recommendation: write admin_users, no new Auth account)
  // ---------------------------------------------------------------------------

  /// Grants admin panel access to an existing user identified by [targetUid].
  ///
  /// [roleId]         — e.g. "admin", "staff"
  /// [roleDisplayName]— e.g. "Admin"
  /// [roleLevel]      — numeric level from RoleLevels
  /// [permissionsAdded]   — extra permissions beyond role base
  /// [permissionsRemoved] — permissions removed from role base
  Future<void> grantAdminAccess({
    required String targetUid,
    required String targetDisplayName,
    required String roleId,
    required String roleDisplayName,
    required int roleLevel,
    Map<String, List<String>> permissionsAdded = const {},
    Map<String, List<String>> permissionsRemoved = const {},
  }) async {
    final session = RbacSession();
    if (!session.isActive) throw 'You must be logged in to grant access.';

    // Guard: cannot assign a role at or above own level
    if (!session.canAssignRole(roleLevel)) {
      throw 'You cannot assign a role equal to or higher than your own.';
    }

    // Guard: cannot act on self (self-demotion)
    if (session.isSelf(targetUid)) {
      throw 'You cannot modify your own access.';
    }

    // Check if access record already exists (for update path)
    AdminUserModel? existingRecord;
    final existingDoc = await _db.collection('admin_users').doc(targetUid).get();
    if (existingDoc.exists) {
      existingRecord = AdminUserModel.fromFirestore(existingDoc);
    }

    final now = DateTime.now();
    final newRecord = AdminUserModel(
      uid: targetUid,
      roleId: roleId,
      roleDisplayName: roleDisplayName,
      roleLevel: roleLevel,
      status: 'Active',
      permissionOverridesAdded: permissionsAdded,
      permissionOverridesRemoved: permissionsRemoved,
      createdBy: existingRecord?.createdBy ?? session.uid!,
      createdByName: existingRecord?.createdByName ?? (session.fullName ?? ''),
      createdAt: existingRecord?.createdAt ?? now,
      updatedAt: existingRecord != null ? now : null,
      updatedBy: existingRecord != null ? session.uid : null,
    );

    await _db
        .collection('admin_users')
        .doc(targetUid)
        .set(newRecord.toFirestore());

    await _writeAuditLog(
      action: existingRecord != null
          ? AuditActions.updatedPermissions
          : AuditActions.grantedAccess,
      performedByUid: session.uid!,
      performedByName: session.fullName ?? '',
      performedToUid: targetUid,
      performedToName: targetDisplayName,
      details: AuditDetails(
        oldRole: existingRecord?.roleId,
        newRole: roleId,
        oldPermissions: existingRecord?.permissionOverridesAdded,
        newPermissions: permissionsAdded,
        platform: kIsWeb ? 'web' : 'app',
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Revoke / Status management (soft delete — recommendation #5)
  // ---------------------------------------------------------------------------

  /// Soft-revokes access by setting status to [newStatus].
  /// Valid values: Active | Inactive | Suspended | Revoked | Deleted
  Future<void> updateAdminStatus({
    required String targetUid,
    required String targetDisplayName,
    required String newStatus,
  }) async {
    final session = RbacSession();
    if (!session.isActive) throw 'Not authorized.';

    // Guard: self-modification
    if (session.isSelf(targetUid)) {
      throw 'You cannot change your own account status.';
    }

    // Guard: last Super Admin protection (recommendation #4)
    final targetDoc = await _db.collection('admin_users').doc(targetUid).get();
    if (targetDoc.exists) {
      final targetData = targetDoc.data() as Map<String, dynamic>? ?? {};
      final targetRoleId = targetData['roleId'] as String? ?? '';
      if (targetRoleId == 'super_admin' && newStatus != 'Active') {
        final isLast = await session.isLastSuperAdmin(targetUid);
        if (isLast) {
          throw 'Cannot deactivate the last Super Admin. '
              'Assign another Super Admin first.';
        }
      }
    }

    final oldStatus = (targetDoc.data() as Map<String, dynamic>?)?['status'] as String? ?? '';

    await _db.collection('admin_users').doc(targetUid).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': session.uid,
    });

    await _writeAuditLog(
      action: AuditActions.updatedStatus,
      performedByUid: session.uid!,
      performedByName: session.fullName ?? '',
      performedToUid: targetUid,
      performedToName: targetDisplayName,
      details: AuditDetails(
        oldStatus: oldStatus,
        newStatus: newStatus,
        platform: kIsWeb ? 'web' : 'app',
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Password Reset (sends Firebase reset email)
  // ---------------------------------------------------------------------------

  /// Sends a Firebase password reset email to the user's registered email.
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);

    final session = RbacSession();
    await _writeAuditLog(
      action: AuditActions.passwordReset,
      performedByUid: session.uid ?? '',
      performedByName: session.fullName ?? '',
      performedToUid: '',
      performedToName: email,
      details: AuditDetails(
        extra: 'Password reset email sent to $email',
        platform: kIsWeb ? 'web' : 'app',
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sign Out
  // ---------------------------------------------------------------------------

  Future<void> signOut() async {
    final session = RbacSession();
    final uid = session.uid ?? '';
    final name = session.fullName ?? '';

    await _writeAuditLog(
      action: AuditActions.logout,
      performedByUid: uid,
      performedByName: name,
      performedToUid: uid,
      performedToName: name,
      details: AuditDetails(platform: kIsWeb ? 'web' : 'app'),
    );

    session.clear();
    await _auth.signOut();
  }

  // ---------------------------------------------------------------------------
  // Fetch helpers
  // ---------------------------------------------------------------------------

  /// Fetches all non-admin users for the Grant Access selection list.
  Future<List<Map<String, dynamic>>> fetchGrantableUsers() async {
    try {
      final snapshot = await _db.collection('users').get();
      return snapshot.docs
          .map((doc) {
            final d = doc.data();
            return {
              'uid': doc.id,
              'fullName': d['fullName'] ?? d['name'] ?? '',
              'username': d['username'] ?? '',
              'email': d['email'] ?? '',
              'phone': d['phone'] ?? d['phoneNumber'] ?? '',
            };
          })
          .where((user) {
            final email = (user['email'] ?? '').toString().toLowerCase();
            final username = (user['username'] ?? '').toString().toLowerCase();
            return email != 'developer@naattulink.com' && username != 'developer';
          })
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetches all active role definitions from Firestore.
  Future<List<RoleDefinition>> fetchAssignableRoles(int currentLevel) async {
    try {
      final snapshot = await _db
          .collection('roles')
          .where('status', isEqualTo: 'Active')
          .get();
      final roles = snapshot.docs
          .map(RoleDefinition.fromFirestore)
          .where((r) => r.level < currentLevel) // level-based filter
          .toList()
        ..sort((a, b) => b.level.compareTo(a.level));
      return roles;
    } catch (_) {
      // Fallback: return built-in roles below current level
      return RoleLevels.assignableBelow(currentLevel)
          .map((e) => RoleDefinition(
                id: e.id,
                name: e.name,
                level: e.level,
                description: '',
                status: 'Active',
                permissions: {},
              ))
          .toList();
    }
  }

  /// Fetches all admin users for management.
  Stream<QuerySnapshot> streamAdminUsers() {
    return _db
        .collection('admin_users')
        .where('status', whereNotIn: ['Deleted'])
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Fetches audit logs with optional filters.
  Stream<QuerySnapshot> streamAuditLogs({int limit = 50}) {
    return _db
        .collection('audit_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  // ---------------------------------------------------------------------------
  // Audit log writer
  // ---------------------------------------------------------------------------
  Future<void> _writeAuditLog({
    required String action,
    required String performedByUid,
    required String performedByName,
    required String performedToUid,
    required String performedToName,
    required AuditDetails details,
  }) async {
    try {
      final log = AuditLogModel(
        action: action,
        performedBy: performedByUid,
        performedByName: performedByName,
        performedTo: performedToUid,
        performedToName: performedToName,
        details: details,
        timestamp: DateTime.now(),
      );
      await _db.collection('audit_logs').add(log.toFirestore());
    } catch (_) {
      // Audit log failures should never block the main operation
    }
  }

  Future<void> _writeFailedLoginLog(String username) async {
    try {
      final log = AuditLogModel(
        action: AuditActions.failedLogin,
        performedBy: '',
        performedByName: username,
        performedTo: '',
        performedToName: username,
        details: AuditDetails(
          extra: 'Failed login attempt for username: $username',
          platform: kIsWeb ? 'web' : 'app',
        ),
        timestamp: DateTime.now(),
      );
      await _db.collection('audit_logs').add(log.toFirestore());
    } catch (_) {}
  }
}