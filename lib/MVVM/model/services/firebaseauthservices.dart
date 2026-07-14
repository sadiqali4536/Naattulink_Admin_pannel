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
  static const _superAdminEmails = ['superadmin@naattulink.com'];

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
    print('[RBAC LOGIN] Starting authentication for: $username');
    final trimmedUser = username.trim();
    String? uid;
    String? email;

    // 1. Parse virtual email first to get the UID directly if possible
    if (trimmedUser.endsWith('_adm@naattulink.internal')) {
      final parts = trimmedUser.split('_adm@naattulink.internal');
      if (parts.isNotEmpty) {
        uid = parts[0];
        print('[RBAC LOGIN] Parsed virtual email prefix to resolve UID: $uid');
      }
    }

    // 2. Resolve username → email + uid (if not resolved via virtual email)
    if (uid == null) {
      try {
        final query =
            await _db
                .collection('users')
                .where('username', isEqualTo: trimmedUser)
                .limit(1)
                .get();
        if (query.docs.isNotEmpty) {
          email = query.docs.first.data()['email'] as String?;
          uid = query.docs.first.id;
          print(
            '[RBAC LOGIN] Resolved username "$trimmedUser" to UID: $uid, Email: $email',
          );
        }
      } catch (_) {
        throw 'Unable to reach the server. Please check your connection.';
      }
    }

    if (uid != null && (email == null || email.isEmpty)) {
      try {
        final userDoc = await _db.collection('users').doc(uid).get();
        if (userDoc.exists) {
          email = userDoc.data()?['email'] as String?;
          print('[RBAC LOGIN] Resolved customer email from UID: $email');
        }
      } catch (_) {}
    }

    if (email == null || email.isEmpty) {
      if (trimmedUser.contains('@')) {
        email = trimmedUser;
      } else {
        await _writeFailedLoginLog(username);
        print(
          '[RBAC LOGIN] Failed: No account found with username "$username"',
        );
        throw 'No account found with username "$username".';
      }
    }

    // 2. Super Admin bypass
    if (_superAdminEmails.contains(email)) {
      print('[RBAC LOGIN] Super Admin bypass triggered for email: $email');
      try {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException {
        await _writeFailedLoginLog(username);
        print('[RBAC LOGIN] Super Admin login failed.');
        rethrow;
      }
      print('[RBAC LOGIN] Super Admin successfully authenticated.');
      await _completeLogin(username);
      return;
    }

    // 3. Fetch webEmail from admin_users
    DocumentSnapshot? adminDoc;
    if (uid != null) {
      try {
        adminDoc = await _db.collection('admin_users').doc(uid).get();
      } catch (_) {
        throw 'Unable to reach the server. Please check your connection.';
      }
    }

    if (uid == null || adminDoc == null || !adminDoc.exists) {
      print(
        '[RBAC LOGIN] No active role document found in admin_users for UID: $uid',
      );
      await _writeFailedLoginLog(username);
      await _auth.signOut();

      // Check if they previously had their role removed
      if (uid != null) {
        print('[RBAC LOGIN] Checking role_users_history for UID: $uid');
        try {
          final historyQuery =
              await _db
                  .collection('role_users_history')
                  .where('uid', isEqualTo: uid)
                  .limit(1)
                  .get();
          if (historyQuery.docs.isNotEmpty) {
            print(
              '[RBAC LOGIN] Found revoked role history for UID: $uid. Denying access.',
            );
            throw 'No access found. Your admin role has been removed. Please contact the Super Admin if you believe this is an error.';
          }
        } catch (e) {
          if (e.toString().contains('No access found')) rethrow;
        }
      }
      throw 'You do not have permission to access the Admin Panel.';
    }

    final adminData = adminDoc.data() as Map<String, dynamic>? ?? {};
    final webEmail = adminData['webEmail'] as String?;

    if (webEmail == null || webEmail.isEmpty) {
      await _writeFailedLoginLog(username);
      print('[RBAC LOGIN] Failed: No web admin account set up for UID: $uid');
      throw 'No web admin account has been set up for this user.\n'
          'Please contact your Super Admin to set up web panel access.';
    }

    // 4. Sign in with web-panel Firebase account
    print('[RBAC LOGIN] Authenticating webEmail: $webEmail with Firebase...');
    try {
      await _auth.signInWithEmailAndPassword(
        email: webEmail,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      await _writeFailedLoginLog(username);
      print('[RBAC LOGIN] Firebase Auth failed: ${e.code}');
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
    print(
      '[RBAC CREATE] Starting createWebAdminAccount for targetUid: $targetUid, displayName: $targetDisplayName',
    );
    final session = RbacSession();
    if (!session.isActive)
      throw 'You must be logged in to create web accounts.';

    final isCallerSuperAdmin = session.email == 'superadmin@naattulink.com';

    // Check if web account already exists
    final existingDoc =
        await _db.collection('admin_users').doc(targetUid).get();

    bool shouldRecreate = false;
    String? oldWebEmail;
    String? oldWebPassword;
    String? oldWebAuthUid;

    if (existingDoc.exists) {
      final data = existingDoc.data() ?? {};
      final existingWebAuthUid = data['webAuthUid'] as String?;
      if (existingWebAuthUid != null && existingWebAuthUid.isNotEmpty) {
        if (isCallerSuperAdmin) {
          shouldRecreate = true;
          oldWebAuthUid = existingWebAuthUid;
          oldWebEmail = data['webEmail'] as String?;
          oldWebPassword = data['webPassword'] as String?;
          print(
            '[RBAC CREATE] Existing web credentials found for Super Admin recreate flow: $oldWebEmail',
          );
        } else {
          print(
            '[RBAC CREATE] Existing web credentials found, returning existing UID: $existingWebAuthUid',
          );
          return existingWebAuthUid;
        }
      }
    }

    final webEmail = '${targetUid}_adm@naattulink.internal';

    // If caller is Super Admin and old credentials exist, try to delete the old Auth user first
    if (shouldRecreate &&
        oldWebEmail != null &&
        oldWebPassword != null &&
        oldWebEmail.isNotEmpty &&
        oldWebPassword.isNotEmpty) {
      try {
        print(
          '[RBAC CREATE] Attempting to delete existing secondary Auth user "$oldWebEmail"...',
        );
        final secondaryApp = await _getSecondaryApp();
        final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
        final cred = await secondaryAuth.signInWithEmailAndPassword(
          email: oldWebEmail,
          password: oldWebPassword,
        );
        if (cred.user != null) {
          await cred.user!.delete();
          print(
            '[RBAC CREATE] Existing secondary Auth user deleted successfully.',
          );
        }
      } catch (e) {
        print(
          '[RBAC CREATE] Deletion of existing secondary Auth user failed: $e',
        );
      } finally {
        try {
          final secondaryApp = await _getSecondaryApp();
          final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
          await secondaryAuth.signOut();
        } catch (_) {}
      }
    }

    print('[RBAC CREATE] Creating new Firebase Auth account: $webEmail...');
    final secondaryApp = await _getSecondaryApp();
    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

    String webAuthUid;
    try {
      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: webEmail,
        password: webPassword,
      );
      webAuthUid = cred.user!.uid;
      print(
        '[RBAC CREATE] Firebase Auth account created successfully. webAuthUid: $webAuthUid',
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        if (isCallerSuperAdmin) {
          print(
            '[RBAC CREATE] Legacy web account already exists but could not be resolved automatically: $webEmail',
          );
          throw 'A legacy web account already exists for this user and cannot '
              'be recreated automatically. Delete the internal account ($webEmail) '
              'once from Firebase Authentication, then try again.';
        }
        // Auth account exists but admin_users was missing the field — recover (for regular admins)
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

    // Persist webAuthUid + webEmail + webPassword to admin_users/{targetUid}
    print(
      '[RBAC CREATE] Committing database updates to admin_users and web_auth_index...',
    );
    await _db.collection('admin_users').doc(targetUid).update({
      'webAuthUid': webAuthUid,
      'webEmail': webEmail,
      'webPassword': webPassword,
      'webAccountCreatedAt': FieldValue.serverTimestamp(),
    });

    // Write reverse-lookup index: web_auth_index/{webAuthUid} → originalUid
    await _db.collection('web_auth_index').doc(webAuthUid).set({
      'originalUid': targetUid,
      'webEmail': webEmail,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': session.uid,
    });

    // If the old webAuthUid is different from the new one, delete the old index doc
    if (oldWebAuthUid != null && oldWebAuthUid != webAuthUid) {
      try {
        await _db.collection('web_auth_index').doc(oldWebAuthUid).delete();
        print(
          '[RBAC CREATE] Old web_auth_index document deleted successfully.',
        );
      } catch (e) {
        print('[RBAC CREATE] Failed to delete old web_auth_index doc: $e');
      }
    }

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

    print('[RBAC CREATE] createWebAdminAccount finished successfully.');
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

    final userDoc = await _db.collection('users').doc(targetUid).get();
    final userData = userDoc.data() ?? {};
    final fName =
        userData['fullName'] as String? ??
        userData['name'] as String? ??
        targetDisplayName;
    final uName = userData['username'] as String? ?? '';
    final emailVal = userData['email'] as String? ?? '';

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
      webPassword: existingRecord?.webPassword,
      webAccountCreatedAt: existingRecord?.webAccountCreatedAt,
      fullName: fName,
      username: uName,
      email: emailVal,
      assignedRole: roleDisplayName,
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

  Future<void> deleteAdminAccess({
    required String targetUid,
    required String targetDisplayName,
    required String assignedRole,
    required String phone,
    required String email,
  }) async {
    print(
      '[RBAC DELETE] Starting deleteAdminAccess for targetUid: $targetUid, displayName: $targetDisplayName, role: $assignedRole',
    );
    final session = RbacSession();
    if (!session.isActive) throw 'Not authorized.';
    if (session.isSelf(targetUid)) {
      throw 'You cannot delete your own admin access.';
    }

    final targetDoc = await _db.collection('admin_users').doc(targetUid).get();
    if (targetDoc.exists) {
      final targetData = targetDoc.data() ?? {};
      final targetRoleId = targetData['roleId'] as String? ?? '';
      if (targetRoleId == 'super_admin') {
        final isLast = await session.isLastSuperAdmin(targetUid);
        if (isLast) {
          throw 'Cannot delete the last Super Admin. '
              'Assign another Super Admin first.';
        }
      }
    }

    // Try to delete Firebase Auth user from secondary app
    if (targetDoc.exists) {
      final webEmail = targetDoc.data()?['webEmail'] as String?;
      final webPassword = targetDoc.data()?['webPassword'] as String?;
      if (webEmail != null &&
          webPassword != null &&
          webEmail.isNotEmpty &&
          webPassword.isNotEmpty) {
        try {
          print(
            '[RBAC DELETE] Attempting to sign in and delete web email "$webEmail" via secondary Auth...',
          );
          final secondaryApp = await _getSecondaryApp();
          final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
          final cred = await secondaryAuth.signInWithEmailAndPassword(
            email: webEmail,
            password: webPassword,
          );
          if (cred.user != null) {
            await cred.user!.delete();
            print('[RBAC DELETE] Web Auth account deleted successfully.');
          }
        } catch (e) {
          print('[RBAC DELETE] Secondary Auth user deletion failed: $e');
        } finally {
          try {
            final secondaryApp = await _getSecondaryApp();
            final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
            await secondaryAuth.signOut();
          } catch (_) {}
        }
      }
    }

    print(
      '[RBAC DELETE] Committing batch delete from admin_users, web_auth_index, and archiving in role_users_history...',
    );
    final batch = _db.batch();

    final historyRef = _db.collection('role_users_history').doc();
    batch.set(historyRef, {
      'uid': targetUid,
      'fullName': targetDisplayName,
      'assignedRole': assignedRole,
      'phone': phone,
      'email': email,
      'deletedBy': session.fullName ?? session.email ?? 'Admin',
      'deletedAt': FieldValue.serverTimestamp(),
    });

    // 2. Delete role assignment from admin_users collection
    final adminRef = _db.collection('admin_users').doc(targetUid);
    batch.delete(adminRef);

    // 3. Delete from web_auth_index (if webAuthUid is present)
    if (targetDoc.exists) {
      final webAuthUid = targetDoc.data()?['webAuthUid'] as String?;
      if (webAuthUid != null && webAuthUid.isNotEmpty) {
        final indexRef = _db.collection('web_auth_index').doc(webAuthUid);
        batch.delete(indexRef);
      }
    }

    await batch.commit();
    print('[RBAC DELETE] Admin access successfully deleted and archived.');

    // 4. Audit Log
    await _writeAuditLog(
      action: 'Deleted Admin Access',
      performedByUid: session.uid!,
      performedByName: session.fullName ?? '',
      performedToUid: targetUid,
      performedToName: targetDisplayName,
      details: AuditDetails(
        platform: kIsWeb ? 'web' : 'app',
        extra: 'Deleted role assignment: $assignedRole',
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
      final assignedRoleUids = adminSnap.docs.map((doc) => doc.id).toSet();

      final snap =
          await _db
              .collection('users')
              .where('status', whereIn: ['Active', 'active'])
              .get();

      return snap.docs
          .map((doc) {
            final d = doc.data();
            return {
              'uid': doc.id,
              'fullName': d['fullName'] ?? d['name'] ?? '',
              'username': d['username'] ?? '',
              'email': d['email'] ?? '',
              'phone': d['phone'] ?? d['phoneNumber'] ?? '',
              'userType': d['userType'] ?? 'Customer',
            };
          })
          .where((user) {
            if (assignedRoleUids.contains(user['uid'])) {
              return false;
            }

            final userType = (user['userType'] ?? '').toString().toLowerCase();
            if (userType != 'customer' &&
                userType != 'admin' &&
                userType.isNotEmpty) {
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
