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
  static const String dashboard = 'dashboard';
  static const String services = 'services';
  static const String serviceReviews = 'service_reviews';
  static const String truck = 'truck';
  static const String healthcare = 'healthcare';
  static const String business = 'business';
  static const String storeProducts = 'store_products';
  static const String storeOrders = 'store_orders';
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
    // ── Dashboard ─────────────────────────────────────────────────────────
    ModuleDefinition(
      id: Modules.dashboard,
      displayName: 'Dashboard',
      actions: [
        'view',
        'view_analytics_cards',
        'view_recent_activity',
        'view_statistics',
      ],
      isSystem: true,
    ),
    // ── User Management ───────────────────────────────────────────────────
    ModuleDefinition(
      id: Modules.userManagement,
      displayName: 'User Management',
      actions: [
        'view',
        'create',
        'edit',
        'delete',
        'suspend_user',
        'ban_user',
        'assign_role',
        'export',
      ],
      isSystem: true,
    ),

    // ── Worker Management ─────────────────────────────────────────────────
    ModuleDefinition(
      id: Modules.workerManagement,
      displayName: 'Worker Management',
      actions: [
        'view',
        'create',
        'edit',
        'delete',
        'approve_worker',
        'reject_worker',
        'suspend_worker',
        'export',
      ],
    ),
    // ── Services ──────────────────────────────────────────────────────────
    ModuleDefinition(
      id: Modules.services,
      displayName: 'Services',
      actions: [
        'view',
        'create',
        'edit',
        'delete',
        'export',
        'manage_categories',
        'service_reviews',
      ],
    ),

    // ── Advertisements ────────────────────────────────────────────────────
    ModuleDefinition(
      id: Modules.advertisement,
      displayName: 'Advertisements',
      actions: [
        'view',
        'create',
        'edit',
        'delete',
        'publish_ad',
        'unpublish_ad',
        'save_draft',
      ],
    ),
    // ── Bookings ──────────────────────────────────────────────────────────
    ModuleDefinition(
      id: Modules.bookings,
      displayName: 'Bookings',
      actions: [
        'view',
        'edit',
        'delete',
        'update_payment',
        'export',
        'view_ongoing',
        'view_completed',
        'view_cancelled',
      ],
    ),
    // ── Payments ──────────────────────────────────────────────────────────
    ModuleDefinition(
      id: Modules.payments,
      displayName: 'Payments',
      actions: ['view', 'create_payment', 'export', 'payment_status'],
    ),
    // ── Bus Routes ────────────────────────────────────────────────────────
    ModuleDefinition(
      id: Modules.bus,
      displayName: 'Bus Routes',
      actions: [
        'view',
        'create',
        'edit',
        'delete',
        'active_inactive',
        'export',
      ],
    ),
    ModuleDefinition(
      id: Modules.taxi,
      displayName: 'Taxi Drivers',
      actions: [
        'view',
        'create',
        'edit',
        'delete',
        'active_inactive',
        'export',
      ],
    ),
    // ── Truck & JCB ───────────────────────────────────────────────────────
    ModuleDefinition(
      id: Modules.truck,
      displayName: 'Truck & JCB',
      actions: [
        'view',
        'create',
        'edit',
        'delete',
        'active_inactive',
        'export',
      ],
    ),
    // ── Healthcare ────────────────────────────────────────────────────────
    ModuleDefinition(
      id: Modules.healthcare,
      displayName: 'Healthcare',
      actions: [
        'view',
        'create',
        'edit',
        'delete',
        'active_inactive',
        'export',
      ],
    ),
    // ── Businesses ────────────────────────────────────────────────────────
    ModuleDefinition(
      id: Modules.business,
      displayName: 'Businesses',
      actions: [
        'view',
        'approve_business',
        'reject_business',
        'edit',
        'delete',
      ],
    ),
    // ── Store Products ────────────────────────────────────────────────────
    ModuleDefinition(
      id: Modules.storeProducts,
      displayName: 'Store Products',
      actions: ['view', 'create', 'edit', 'delete', 'manage_categories'],
    ),
    // ── Store Orders ──────────────────────────────────────────────────────
    ModuleDefinition(
      id: Modules.storeOrders,
      displayName: 'Store Orders',
      actions: ['view', 'edit', 'view_details'],
    ),
    // ── Notifications ─────────────────────────────────────────────────────
    ModuleDefinition(
      id: Modules.notifications,
      displayName: 'Notifications',
      actions: ['view', 'create', 'edit', 'delete'],
    ),
    // ── Reports & Analytics ───────────────────────────────────────────────
    ModuleDefinition(
      id: Modules.reports,
      displayName: 'Reports & Analytics',
      actions: ['view', 'export'],
    ),
    // ── Settings ──────────────────────────────────────────────────────────
    ModuleDefinition(
      id: Modules.settings,
      displayName: 'Settings',
      actions: ['view', 'edit'],
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

  /// The plain-text password for the web-panel account (stored for cleanup/reset).
  final String? webPassword;

  /// The timestamp when the web account was created.
  final DateTime? webAccountCreatedAt;

  final String? fullName;
  final String? username;
  final String? email;
  final String? assignedRole;

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
    this.webPassword,
    this.webAccountCreatedAt,
    this.fullName,
    this.username,
    this.email,
    this.assignedRole,
  });

  factory AdminUserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    final overrides = d['permissionOverrides'] as Map<String, dynamic>? ?? {};
    final added = overrides['added'] as Map<String, dynamic>? ?? {};
    final removed = overrides['removed'] as Map<String, dynamic>? ?? {};
    final roleId = d['roleId'] as String? ?? d['role'] as String? ?? 'staff';
    final roleIds =
        (d['roleIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        [roleId];

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
      webPassword: d['webPassword'] as String?,
      webAccountCreatedAt: (d['webAccountCreatedAt'] as Timestamp?)?.toDate(),
      fullName: d['fullName'] as String?,
      username: d['username'] as String?,
      email: d['email'] as String?,
      assignedRole: d['assignedRole'] as String?,
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
    if (webPassword != null) 'webPassword': webPassword,
    if (webAccountCreatedAt != null)
      'webAccountCreatedAt': Timestamp.fromDate(webAccountCreatedAt!),
    if (fullName != null) 'fullName': fullName,
    if (username != null) 'username': username,
    if (email != null) 'email': email,
    if (assignedRole != null) 'assignedRole': assignedRole,
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

