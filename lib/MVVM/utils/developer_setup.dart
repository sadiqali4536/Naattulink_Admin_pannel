import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Helper utility to create/ensure the default Developer account exists.
///
/// This will:
/// 1. Create a Firebase Auth account for `developer@naattulink.com` if it doesn't exist.
/// 2. Write/ensure `users/{uid}` exists with username `developer`.
/// 3. Write/ensure `admin_users/{uid}` exists with role `developer` (level 100).
Future<void> ensureDeveloperAccountCreated() async {
  const email = 'superadmin@naattulink.com';
  const password = 'SuperAdmin#V9!xQ7@Lm2-Kr8^Np4&Hy5*Zw';
  const username = 'SuperAdmin';

  try {
    final auth = FirebaseAuth.instance;
    final db = FirebaseFirestore.instance;

    UserCredential? creds;
    try {
      creds = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('RBAC SETUP: SuperAdmin Auth account created successfully.');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        print('RBAC SETUP: SuperAdmin Auth account already exists.');
      } else {
        print('RBAC SETUP: FirebaseAuthException: ${e.message}');
        rethrow;
      }
    }

    if (creds != null && creds.user != null) {
      final uid = creds.user!.uid;

      // 1. Create/update the users/{uid} document
      await db.collection('users').doc(uid).set({
        'email': email,
        'username': username,
        'fullName': 'SuperAdmin',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Create/update the admin_users/{uid} document
      await db.collection('admin_users').doc(uid).set({
        'roleId': 'admin',
        'roleDisplayName': 'Admin',
        'roleLevel': 100,
        'status': 'Active',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('RBAC SETUP: admin Firestore documents created/verified.');

      // Sign out only since this was a new registration and we want to start clean
      await auth.signOut();
    }
  } catch (e) {
    print('RBAC SETUP: Error ensuring admin account: $e');
  }
}
