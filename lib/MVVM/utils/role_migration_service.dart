import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:swiftclean_admin/MVVM/model/models/admin_model.dart';

class RoleMigrationService {
  static Future<Map<String, int>> run() async {
    print('[MIGRATION] Starting legacy role migration...');
    int totalFound = 0;
    int migrated = 0;
    int skipped = 0;
    int failed = 0;

    try {
      final db = FirebaseFirestore.instance;
      final snap = await db.collection('roles').get();

      for (final doc in snap.docs) {
        final data = doc.data();
        final String name = data['name'] as String? ?? '';
        if (name.isEmpty) {
          print('[MIGRATION] Warning: Role document ${doc.id} has no name field. Skipping.');
          skipped++;
          continue;
        }

        final expectedId = name.toLowerCase().replaceAll(' ', '_');

        if (doc.id == expectedId) {
          print('[MIGRATION] Role "${name}" is already migrated at document ID: ${doc.id}');
          skipped++;
          continue;
        }

        totalFound++;
        print('[MIGRATION] Found legacy role: "${name}" at document ID: ${doc.id}. Expected: $expectedId');

        try {
          // Prepare updated role data
          final Map<String, dynamic> updatedData = Map<String, dynamic>.from(data);
          updatedData['roleId'] = expectedId;
          updatedData['displayName'] = name;
          if (!updatedData.containsKey('level')) {
            updatedData['level'] = RoleLevels.levelFor(expectedId);
          }
          if (!updatedData.containsKey('canAssignBelow')) {
            updatedData['canAssignBelow'] = true;
          }
          if (!updatedData.containsKey('updatedAt')) {
            updatedData['updatedAt'] = FieldValue.serverTimestamp();
          }

          // 1. Create/overwrite the deterministic document ID roles/{expectedId}
          await db.collection('roles').doc(expectedId).set(updatedData, SetOptions(merge: true));
          print('[MIGRATION] Copied role data to roles/$expectedId');

          // Verify the copied doc exists
          final checkDoc = await db.collection('roles').doc(expectedId).get();
          if (checkDoc.exists) {
            // 2. Delete the legacy document
            await db.collection('roles').doc(doc.id).delete();
            print('[MIGRATION] Successfully deleted legacy document: ${doc.id}');
            migrated++;
          } else {
            throw Exception('Verification failed: roles/$expectedId not found after set.');
          }
        } catch (e) {
          print('[MIGRATION] Error migrating role ${doc.id} to $expectedId: $e');
          failed++;
        }
      }
    } catch (e) {
      print('[MIGRATION] Critical error during migration: $e');
    }

    final summary = {
      'totalFound': totalFound,
      'migrated': migrated,
      'skipped': skipped,
      'failed': failed,
    };
    print('[MIGRATION] Summary: $summary');
    return summary;
  }
}
