import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:swiftclean_admin/MVVM/model/models/admin_model.dart';
import 'package:swiftclean_admin/MVVM/utils/rbac_session.dart';
import 'package:swiftclean_admin/firebase_options.dart';

/// Firebase Auth + Firestore service for the admin panel.
///
/// Dual-platform authentication architecture:
///   Mobile App  → user signs in with their OWN password (unchanged).
///   Web Panel   → separate Firebase Auth account per admin user:
///                   email:    {uid}_adm@naattulink.internal
///                   password: admin-generated (stored nowhere, given to user once)
///
/// When granting access:
///   1. Write RBAC record to admin_users/{uid}  (grantAdminAccess)
///   2. Create web Firebase Auth account        (createWebAdminAccount)
///   3. Store webAuthUid + webEmail in admin_users/{uid}
///   4. Write reverse-lookup: web_auth_index/{webAuthUid} → originalUid
///
/// When logging in (web panel):
///   1. Resolve username → email + uid (users collection)
///   2. Fetch webEmail from admin_users/{uid}
///   3. signInWithEmailAndPassword(webEmail, webPassword)
///   4. loadSession() resolves webAuthUid → originalUid via web_auth_index
class FirebaseAuthService {
  FirebaseAuthService._();
  static final FirebaseAuthService instance = FirebaseAuthService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // Super Admin accounts bypass web-auth and sign in with their real email.
  static const _superAdminEmails = [
    'developer@naattulink.com',
    'developer@nattulinkapp.com',
    'superadmin@naattulink.com',
  ];

  // ---------------------------------------------------------------------------
  // Secondary Firebase App
  // ---------------------------------------------------------------------------

  /// Lazily initialises the secondary [FirebaseApp] used exclusively for
  /// creating web-panel Firebase Auth accounts without signing out the current
  /// admin.
  Future<FirebaseApp> _getSecondaryApp() async {
    const appName = 'naattulink_web_creator';
    try {
      return Firebase.app(appName);
    } catch (_) {
      return Firebase.initializeApp(
        name: appName,
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Web Admin Login
  // ---------------------------------------------------------------------------

  /// Signs in a web admin panel user.
  ///
  /// Steps:
  ///   1. Resolve [username] → email + uid via `users` collection.
  ///   2. Super Admin accounts: sign in directly with their real Firebase email.
  ///   3. All others: fetch `admin_users/{uid}.webEmail` and authenticate with
  ///      the web-panel Firebase account using [password].
  ///   4. Load RBAC session (resolves webAuthUid → originalUid internally).
  Future<void> signInWithUsername(String username, String password) async {
    // 1. Resolve username → email + uid
    String? email;
    String? uid;
    try {
      final query =
          await _db
              .collection('users')
              .where('username', isEqualTo: username.trim())
              .limit(1)
              .get();
      if (query.docs.isNotEmpty) {
        email = query.docs.first.data()['email'] as String?;
        uid = query.docs.first.id;
      }
    } catch (_) {
      throw 'Unable to reach the server. Please check your connection.';
    }

    if (email == null || email.isEmpty) {
      if (username.contains('@')) {
        email = username.trim();
      } else {
        await _writeFailedLoginLog(username);
        throw 'No account found with username "$username".';
      }
    }

    // 2. Super Admin bypass
    if (_superAdminEmails.contains(email)) {
      try {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException {
        await _writeFailedLoginLog(username);
        rethrow;
      }
      await _completeLogin(username);
      return;
    }

    // 3. Fetch webEmail from admin_users
    if (uid == null) {
      await _writeFailedLoginLog(username);
      throw 'Invalid web admin credentials.';
    }

    DocumentSnapshot? adminDoc;
    try {
      adminDoc = await _db.collection('admin_users').doc(uid).get();
    } catch (_) {
      throw 'Unable to reach the server. Please check your connection.';
    }

    if (!adminDoc.exists) {
      await _writeFailedLoginLog(username);
      throw 'You do not have permission to access the Admin Panel.';
    }

    final adminData = adminDoc.data() as Map<String, dynamic>? ?? {};
    final webEmail = adminData['webEmail'] as String?;

    if (webEmail == null || webEmail.isEmpty) {
      await _writeFailedLoginLog(username);
      throw 'No web admin account has been set up for this user.\n'
          'Please contact your Super Admin to set up web panel access.';
    }

    // 4. Sign in with web-panel Firebase account
    try {
      await _auth.signInWithEmailAndPassword(
        email: webEmail,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      await _writeFailedLoginLog(username);
      if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.code == 'invalid-login-credentials') {
        throw FirebaseAuthException(
          code: e.code,
          message:
              'Invalid web admin credentials. '
              'Use the password provided by your administrator.',
        );
      }
      rethrow;
    }

    await _completeLogin(username);
  }

  /// Shared post-sign-in logic: loads RBAC session and writes audit log.
  Future<void> _completeLogin(String username) async {
    await RbacSession().loadSession();

    if (!RbacSession().isActive) {
      await signOut();
      throw 'Your account access has been ${RbacSession().status.toLowerCase()}. '
          'Please contact your administrator.';
    }

    await _writeAuditLog(
      action: AuditActions.login,
      performedByUid: RbacSession().uid ?? '',
      performedByName: RbacSession().fullName ?? username,
      performedToUid: RbacSession().uid ?? '',
      performedToName: RbacSession().fullName ?? username,
      details: AuditDetails(platform: kIsWeb ? 'web' : 'app'),
    );
  }

  // ---------------------------------------------------------------------------
  // Create Web Admin Account
  // ---------------------------------------------------------------------------

  /// Creates a dedicated Firebase Auth account for web-panel login.
  ///
  /// Uses a secondary [FirebaseApp] so the current admin is never signed out.
  ///
  /// If [targetUid] already has a `webAuthUid` in `admin_users`, the existing
  /// account is preserved (password is NOT changed). Returns the UID.
  ///
  /// On first creation:
  ///   • Creates Firebase Auth account with email  {targetUid}_adm@naattulink.internal
  ///     and the supplied [webPassword].
  ///   • Writes webAuthUid + webEmail to admin_users/{targetUid}.
  ///   • Writes reverse-lookup doc web_auth_index/{webAuthUid}.
  Future<String> createWebAdminAccount({
    required String targetUid,
    required String targetDisplayName,
    required String webPassword,
  }) async {
    final session = RbacSession();
    if (!session.isActive)
      throw 'You must be logged in to create web accounts.';

    // Check if web account already exists — preserve existing password
    final existingDoc =
        await _db.collection('admin_users').doc(targetUid).get();
    if (existingDoc.exists) {
      final data = existingDoc.data() ?? {};
      final existingWebAuthUid = data['webAuthUid'] as String?;
      if (existingWebAuthUid != null && existingWebAuthUid.isNotEmpty) {
        return existingWebAuthUid;
      }
    }

    final webEmail = '${targetUid}_adm@naattulink.internal';
    final secondaryApp = await _getSecondaryApp();
    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

    String webAuthUid;
    try {
      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: webEmail,
        password: webPassword,
      );
      webAuthUid = cred.user!.uid;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // Auth account exists but admin_users was missing the field — recover
        try {
          final cred = await secondaryAuth.signInWithEmailAndPassword(
            email: webEmail,
            password: webPassword,
          );
          webAuthUid = cred.user!.uid;
        } catch (_) {
          try {
            await secondaryAuth.signOut();
          } catch (_) {}
          throw 'A web account already exists for this user but the password '
              'does not match. Please contact a Super Admin to reset it.';
        }
      } else {
        rethrow;
      }
    } finally {
      try {
        await secondaryAuth.signOut();
      } catch (_) {}
    }

    // Persist webAuthUid + webEmail to admin_users/{targetUid}
    await _db.collection('admin_users').doc(targetUid).update({
      'webAuthUid': webAuthUid,
      'webEmail': webEmail,
      'webAccountCreatedAt': FieldValue.serverTimestamp(),
    });

    // Write reverse-lookup index: web_auth_index/{webAuthUid} → originalUid
    await _db.collection('web_auth_index').doc(webAuthUid).set({
      'originalUid': targetUid,
      'webEmail': webEmail,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': session.uid,
    });

    await _writeAuditLog(
      action: AuditActions.webPasswordSet,
      performedByUid: session.uid!,
      performedByName: session.fullName ?? '',
      performedToUid: targetUid,
      performedToName: targetDisplayName,
      details: AuditDetails(
        extra: 'Web admin account created: $webEmail',
        platform: kIsWeb ? 'web' : 'app',
      ),
    );

    return webAuthUid;
  }

  // ---------------------------------------------------------------------------
  // Grant Access
  // ---------------------------------------------------------------------------

  /// Grants admin panel access to an existing user identified by [targetUid].
  Future<void> grantAdminAccess({
    required String targetUid,
    required String targetDisplayName,
    required String roleId,
    required String roleDisplayName,
    required int roleLevel,
    List<String>? roleIds,
    Map<String, List<String>> permissionsAdded = const {},
    Map<String, List<String>> permissionsRemoved = const {},
  }) async {
    final session = RbacSession();
    if (!session.isActive) throw 'You must be logged in to grant access.';

    if (!session.canAssignRole(roleLevel)) {
      throw 'You cannot assign a role equal to or higher than your own.';
    }
    if (session.isSelf(targetUid)) {
      throw 'You cannot modify your own access.';
    }

    AdminUserModel? existingRecord;
    final existingDoc =
        await _db.collection('admin_users').doc(targetUid).get();
    if (existingDoc.exists) {
      existingRecord = AdminUserModel.fromFirestore(existingDoc);
    }

    final now = DateTime.now();
    final newRecord = AdminUserModel(
      uid: targetUid,
      roleId: roleId,
      roleDisplayName: roleDisplayName,
      roleLevel: roleLevel,
      roleIds: roleIds ?? (existingRecord?.roleIds ?? [roleId]),
      status: 'Active',
      permissionOverridesAdded: permissionsAdded,
      permissionOverridesRemoved: permissionsRemoved,
      createdBy: existingRecord?.createdBy ?? session.uid!,
      createdByName: existingRecord?.createdByName ?? (session.fullName ?? ''),
      createdAt: existingRecord?.createdAt ?? now,
      updatedAt: existingRecord != null ? now : null,
      updatedBy: existingRecord != null ? session.uid : null,
      // Preserve existing web auth fields
      webAuthUid: existingRecord?.webAuthUid,
      webEmail: existingRecord?.webEmail,
    );

    await _db
        .collection('admin_users')
        .doc(targetUid)
        .set(newRecord.toFirestore());

    await _writeAuditLog(
      action:
          existingRecord != null
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
  // Revoke / Status management
  // ---------------------------------------------------------------------------

  Future<void> updateAdminStatus({
    required String targetUid,
    required String targetDisplayName,
    required String newStatus,
  }) async {
    final session = RbacSession();
    if (!session.isActive) throw 'Not authorized.';
    if (session.isSelf(targetUid)) {
      throw 'You cannot change your own account status.';
    }

    final targetDoc = await _db.collection('admin_users').doc(targetUid).get();
    if (targetDoc.exists) {
      final targetData = targetDoc.data() ?? {};
      final targetRoleId = targetData['roleId'] as String? ?? '';
      if (targetRoleId == 'super_admin' && newStatus != 'Active') {
        final isLast = await session.isLastSuperAdmin(targetUid);
        if (isLast) {
          throw 'Cannot deactivate the last Super Admin. '
              'Assign another Super Admin first.';
        }
      }
    }

    final oldStatus = targetDoc.data()?['status'] as String? ?? '';

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
  // Password Reset
  // ---------------------------------------------------------------------------

  /// Sends a Firebase password reset email.
  /// NOTE: This resets the MOBILE APP (real Firebase) password only.
  /// It does NOT affect the web-panel password.
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

  Future<List<Map<String, dynamic>>> fetchGrantableUsers() async {
    try {
      final adminSnap = await _db.collection('admin_users').get();
      final superAdminUids = adminSnap.docs.where((doc) {
        final d = doc.data();
        final roleId = (d['roleId'] ?? '').toString().toLowerCase();
        final roleDisplayName = (d['roleDisplayName'] ?? '').toString().toLowerCase();
        final roleIds = (d['roleIds'] as List<dynamic>?)?.map((e) => e.toString().toLowerCase()).toList() ?? [];
        return roleId == 'super_admin' ||
            roleId == 'developer' ||
            roleDisplayName == 'super admin' ||
            roleDisplayName == 'developer' ||
            roleIds.contains('super_admin') ||
            roleIds.contains('developer');
      }).map((doc) => doc.id).toSet();

      final snap = await _db.collection('users').get();
      return snap.docs
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
            if (superAdminUids.contains(user['uid'])) {
              return false;
            }
            final email = (user['email'] ?? '').toString().toLowerCase();
            final username = (user['username'] ?? '').toString().toLowerCase();
            final fullName = (user['fullName'] ?? '').toString().toLowerCase();
            return !email.contains('developer') &&
                !username.contains('developer') &&
                !fullName.contains('developer') &&
                !email.contains('superadmin') &&
                !username.contains('superadmin') &&
                !fullName.contains('superadmin');
          })
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<RoleDefinition>> fetchAssignableRoles(int currentLevel) async {
    try {
      final snapshot =
          await _db
              .collection('roles')
              .where('status', isEqualTo: 'Active')
              .get();
      final roles =
          snapshot.docs
              .map(RoleDefinition.fromFirestore)
              .where((r) => r.level < currentLevel)
              .toList()
            ..sort((a, b) => b.level.compareTo(a.level));
      return roles;
    } catch (_) {
      return RoleLevels.assignableBelow(currentLevel)
          .map(
            (e) => RoleDefinition(
              id: e.id,
              name: e.name,
              level: e.level,
              description: '',
              status: 'Active',
              permissions: {},
            ),
          )
          .toList();
    }
  }

  Stream<QuerySnapshot> streamAdminUsers() {
    return _db
        .collection('admin_users')
        .where('status', whereNotIn: ['Deleted'])
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

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
      // Audit log failures must never block the main operation
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
