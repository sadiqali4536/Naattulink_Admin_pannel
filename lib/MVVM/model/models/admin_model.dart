import 'package:cloud_firestore/cloud_firestore.dart';

// ===========================================================================
// SECTION 1: Permission Constants
// Use these instead of raw strings to prevent typos and ease refactoring.
// ===========================================================================

class Modules {
  static const String userManagement = 'user_management';
  static const String workerManagement = 'worker_management';
  static const String advertisement = 'advertisement';
  static const String bus = 'bus';
  static const String taxi = 'taxi';
  static const String bookings = 'bookings';
  static const String payments = 'payments';
  static const String reports = 'reports';
  static const String notifications = 'notifications';
  static const String settings = 'settings';
  static const String grantAccess = 'grant_access';
  static const String roles = 'roles';
  static const String auditLogs = 'audit_logs';
}

/// Permission action constants.
/// Named [Perms] (not Actions) to avoid collision with Flutter's Actions widget.
class Perms {
  static const String view = 'view';
  static const String create = 'create';
  static const String edit = 'edit';
  static const String delete = 'delete';
  static const String approve = 'approve';
  static const String reject = 'reject';
  static const String cancel = 'cancel';
  static const String export = 'export';
  static const String manage = 'manage';
}

class AuditActions {
  static const String login = 'Login';
  static const String logout = 'Logout';
  static const String failedLogin = 'Failed Login';
  static const String passwordReset = 'Password Reset';
  static const String grantedAccess = 'Granted Access';
  static const String revokedAccess = 'Revoked Access';
  static const String updatedPermissions = 'Updated Permissions';
  static const String changedRole = 'Changed Role';
  static const String updatedStatus = 'Updated Status';
  static const String createdRole = 'Created Role';
  static const String updatedRole = 'Updated Role';
  static const String disabledRole = 'Disabled Role';

  /// Fired whenever an admin generates / resets a web-panel password.
  static const String webPasswordSet = 'Web Password Set';
}

// ===========================================================================
// SECTION 2: Role Hierarchy
// ===========================================================================

class RoleLevels {
  static const int superAdmin = 100;
  static const int admin = 80;
  static const int manager = 70;
  static const int staff = 60;
  static const int operator_ = 50;
  static const int support = 45;
  static const int customDefault = 40;

  /// Map of canonical roleId → level.
  static const Map<String, int> _levels = {
    'super_admin': superAdmin,
    'admin': admin,
    'manager': manager,
    'staff': staff,
    'operator': operator_,
    'support': support,
  };

  static int levelFor(String roleId) {
    final clean = roleId.toLowerCase().replaceAll(' ', '_');
    if (clean == 'developer') return superAdmin;
    return _levels[clean] ?? customDefault;
  }

  /// All standard assignable roleIds with levels strictly below [currentLevel].
  /// Super Admin (100) is NEVER in this list — it cannot be assigned by lower roles.
  static List<_RoleEntry> assignableBelow(int currentLevel) {
    const all = [
      _RoleEntry('admin', 'Admin', admin),
      _RoleEntry('manager', 'Manager', manager),
      _RoleEntry('staff', 'Staff', staff),
      _RoleEntry('operator', 'Operator', operator_),
      _RoleEntry('support', 'Support', support),
    ];
    return all.where((r) => r.level < currentLevel).toList();
  }
}

class _RoleEntry {
  final String id; // Firestore document id, e.g. "admin"
  final String name; // Display name, e.g. "Admin"
  final int level;
  const _RoleEntry(this.id, this.name, this.level);
}

// ===========================================================================
// SECTION 3: Module Registry
// Central source of truth for all modules and their Perms.
// Can be extended dynamically via Firestore `modules/` collection.
// ===========================================================================

class ModuleDefinition {
  final String id; // e.g. 'user_management'
  final String displayName; // e.g. 'User Management'
  final List<String> actions;
  final bool isSystem; // system modules cannot be disabled

  const ModuleDefinition({
    required this.id,
    required this.displayName,
    required this.actions,
    this.isSystem = false,
  });

  factory ModuleDefinition.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ModuleDefinition(
      id: doc.id,
      displayName: data['displayName'] ?? _toDisplayName(doc.id),
      actions: List<String>.from(data['actions'] ?? []),
      isSystem: data['isSystem'] ?? false,
    );
  }

  static String _toDisplayName(String id) =>
      id.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
}

/// Built-in fallback module registry (used when Firestore `modules/` is unavailable).
class AppModules {
  static const List<ModuleDefinition> builtin = [
    ModuleDefinition(
      id: Modules.userManagement,
      displayName: 'User Management',
      actions: [Perms.view, Perms.create, Perms.edit, Perms.delete],
      isSystem: true,
    ),
    ModuleDefinition(
      id: Modules.workerManagement,
      displayName: 'Worker Management',
      actions: [Perms.view, Perms.approve, Perms.reject, Perms.edit],
    ),
    ModuleDefinition(
      id: Modules.advertisement,
      displayName: 'Advertisement',
      actions: [Perms.view, Perms.create, Perms.edit, Perms.delete],
    ),
    ModuleDefinition(
      id: Modules.bus,
      displayName: 'Bus',
      actions: [Perms.view, Perms.create, Perms.edit],
    ),
    ModuleDefinition(
      id: Modules.taxi,
      displayName: 'Taxi',
      actions: [Perms.view, Perms.create, Perms.edit],
    ),
    ModuleDefinition(
      id: Modules.bookings,
      displayName: 'Bookings',
      actions: [Perms.view, Perms.approve, Perms.cancel],
    ),
    ModuleDefinition(
      id: Modules.payments,
      displayName: 'Payments',
      actions: [Perms.view, Perms.export],
    ),
    ModuleDefinition(
      id: Modules.reports,
      displayName: 'Reports',
      actions: [Perms.view, Perms.export],
    ),
    ModuleDefinition(
      id: Modules.notifications,
      displayName: 'Notifications',
      actions: [Perms.view, Perms.create],
    ),
    ModuleDefinition(
      id: Modules.settings,
      displayName: 'Settings',
      actions: [Perms.view, Perms.manage],
      isSystem: true,
    ),
    ModuleDefinition(
      id: Modules.grantAccess,
      displayName: 'Grant Access',
      actions: [Perms.view, Perms.create],
      isSystem: true,
    ),
    ModuleDefinition(
      id: Modules.roles,
      displayName: 'Role Management',
      actions: [Perms.view, Perms.create, Perms.edit, Perms.delete],
      isSystem: true,
    ),
    ModuleDefinition(
      id: Modules.auditLogs,
      displayName: 'Audit Logs',
      actions: [Perms.view, Perms.export],
      isSystem: true,
    ),
  ];
}

// ===========================================================================
// SECTION 4: AdminUserModel
// Stored in admin_users/{uid}
// Does NOT duplicate profile data — fullName/email/phone stay in users/{uid}
// ===========================================================================

class AdminUserModel {
  final String uid;
  final String roleId; // references roles/{roleId}, e.g. "admin"
  final String roleDisplayName; // cached for display only
  final int roleLevel;
  final List<String> roleIds; // all assigned roles

  /// Active | Inactive | Suspended | Revoked | Deleted
  final String status;

  /// Only the additions/removals on top of the role's base permissions
  final Map<String, List<String>> permissionOverridesAdded;
  final Map<String, List<String>> permissionOverridesRemoved;
  final String createdBy; // uid of granting user
  final String createdByName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? updatedBy;

  // ── Web-panel authentication ─────────────────────────────────────────────
  /// The Firebase Auth UID of the dedicated web-panel account
  /// (email: {uid}_adm@naattulink.internal).
  /// Null until an admin grants access and creates the web account.
  final String? webAuthUid;

  /// The synthetic Firebase Auth email used exclusively for web panel login.
  /// Format: {uid}_adm@naattulink.internal
  final String? webEmail;

  const AdminUserModel({
    required this.uid,
    required this.roleId,
    required this.roleDisplayName,
    required this.roleLevel,
    required this.roleIds,
    required this.status,
    required this.permissionOverridesAdded,
    required this.permissionOverridesRemoved,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    this.updatedAt,
    this.updatedBy,
    this.webAuthUid,
    this.webEmail,
  });

  factory AdminUserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    final overrides = d['permissionOverrides'] as Map<String, dynamic>? ?? {};
    final added = overrides['added'] as Map<String, dynamic>? ?? {};
    final removed = overrides['removed'] as Map<String, dynamic>? ?? {};
    final roleId = d['roleId'] as String? ?? d['role'] as String? ?? 'staff';
    final roleIds = (d['roleIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [roleId];

    return AdminUserModel(
      uid: doc.id,
      roleId: roleId,
      roleDisplayName: d['roleDisplayName'] as String? ?? _toDisplay(roleId),
      roleLevel: d['roleLevel'] as int? ?? RoleLevels.levelFor(roleId),
      roleIds: roleIds,
      status: d['status'] as String? ?? 'Active',
      permissionOverridesAdded: _castPermMap(added),
      permissionOverridesRemoved: _castPermMap(removed),
      createdBy: d['createdBy'] as String? ?? '',
      createdByName: d['createdByName'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
      updatedBy: d['updatedBy'] as String?,
      webAuthUid: d['webAuthUid'] as String?,
      webEmail: d['webEmail'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'roleId': roleId,
    'roleDisplayName': roleDisplayName,
    'roleLevel': roleLevel,
    'roleIds': roleIds,
    'status': status,
    'permissionOverrides': {
      'added': permissionOverridesAdded,
      'removed': permissionOverridesRemoved,
    },
    'createdBy': createdBy,
    'createdByName': createdByName,
    'createdAt': Timestamp.fromDate(createdAt),
    if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    if (updatedBy != null) 'updatedBy': updatedBy,
    if (webAuthUid != null) 'webAuthUid': webAuthUid,
    if (webEmail != null) 'webEmail': webEmail,
  };

  static String _toDisplay(String roleId) => roleId
      .split('_')
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');

  static Map<String, List<String>> _castPermMap(Map<String, dynamic> raw) =>
      raw.map(
        (k, v) => MapEntry(
          k,
          (v as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        ),
      );
}

// ===========================================================================
// SECTION 5: RoleDefinition
// Stored in roles/{roleId} e.g. roles/admin
// ===========================================================================

class RoleDefinition {
  final String id; // Firestore doc id, e.g. "admin"
  final String name; // Display, e.g. "Admin"
  final int level;
  final String description;

  /// Active | Disabled
  final String status;

  /// Base permissions for this role
  final Map<String, List<String>> permissions;

  /// If true, users with this role can assign roles below their level.
  /// Provides flexibility beyond simple level comparison.
  final bool canAssignBelow;
  final DateTime? createdAt;

  const RoleDefinition({
    required this.id,
    required this.name,
    required this.level,
    required this.description,
    required this.status,
    required this.permissions,
    this.canAssignBelow = true,
    this.createdAt,
  });

  factory RoleDefinition.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    final rawPerms = d['permissions'] as Map<String, dynamic>? ?? {};
    return RoleDefinition(
      id: doc.id,
      name: d['name'] as String? ?? '',
      level: d['level'] as int? ?? RoleLevels.levelFor(doc.id),
      description: d['description'] as String? ?? '',
      status: d['status'] as String? ?? 'Active',
      permissions: rawPerms.map(
        (k, v) => MapEntry(
          k,
          (v as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        ),
      ),
      canAssignBelow: d['canAssignBelow'] as bool? ?? true,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'level': level,
    'description': description,
    'status': status,
    'permissions': permissions,
    'canAssignBelow': canAssignBelow,
    'createdAt':
        createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
  };

  bool get isActive => status == 'Active';
}

// ===========================================================================
// SECTION 6: AuditLogModel
// Stored in audit_logs/{id} — append-only, never deleted.
// ===========================================================================

class AuditLogModel {
  final String action; // Use AuditActions constants
  final String performedBy; // uid
  final String performedByName;
  final String performedTo; // uid (same as performedBy for auth events)
  final String performedToName;
  final AuditDetails details;
  final DateTime timestamp;

  const AuditLogModel({
    required this.action,
    required this.performedBy,
    required this.performedByName,
    required this.performedTo,
    required this.performedToName,
    required this.details,
    required this.timestamp,
  });

  Map<String, dynamic> toFirestore() => {
    'action': action,
    'performedBy': performedBy,
    'performedByName': performedByName,
    'performedTo': performedTo,
    'performedToName': performedToName,
    'details': details.toMap(),
    'timestamp': Timestamp.fromDate(timestamp),
  };

  factory AuditLogModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return AuditLogModel(
      action: d['action'] as String? ?? '',
      performedBy: d['performedBy'] as String? ?? '',
      performedByName: d['performedByName'] as String? ?? '',
      performedTo: d['performedTo'] as String? ?? '',
      performedToName: d['performedToName'] as String? ?? '',
      details: AuditDetails.fromMap(
        d['details'] as Map<String, dynamic>? ?? {},
      ),
      timestamp: (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Rich details captured with every audit event.
class AuditDetails {
  final String? oldRole;
  final String? newRole;
  final Map<String, List<String>>? oldPermissions;
  final Map<String, List<String>>? newPermissions;
  final String? oldStatus;
  final String? newStatus;
  final String? platform; // 'web' | 'android' | 'ios' | 'desktop'
  final String? appVersion;
  final String? extra; // any freeform note

  const AuditDetails({
    this.oldRole,
    this.newRole,
    this.oldPermissions,
    this.newPermissions,
    this.oldStatus,
    this.newStatus,
    this.platform,
    this.appVersion,
    this.extra,
  });

  Map<String, dynamic> toMap() => {
    if (oldRole != null) 'oldRole': oldRole,
    if (newRole != null) 'newRole': newRole,
    if (oldPermissions != null) 'oldPermissions': oldPermissions,
    if (newPermissions != null) 'newPermissions': newPermissions,
    if (oldStatus != null) 'oldStatus': oldStatus,
    if (newStatus != null) 'newStatus': newStatus,
    if (platform != null) 'platform': platform,
    if (appVersion != null) 'appVersion': appVersion,
    if (extra != null) 'extra': extra,
  };

  factory AuditDetails.fromMap(Map<String, dynamic> m) => AuditDetails(
    oldRole: m['oldRole'] as String?,
    newRole: m['newRole'] as String?,
    oldPermissions: _castMap(m['oldPermissions']),
    newPermissions: _castMap(m['newPermissions']),
    oldStatus: m['oldStatus'] as String?,
    newStatus: m['newStatus'] as String?,
    platform: m['platform'] as String?,
    appVersion: m['appVersion'] as String?,
    extra: m['extra'] as String?,
  );

  static Map<String, List<String>>? _castMap(dynamic raw) {
    if (raw == null) return null;
    final m = raw as Map<String, dynamic>;
    return m.map(
      (k, v) =>
          MapEntry(k, (v as List<dynamic>).map((e) => e.toString()).toList()),
    );
  }
}
