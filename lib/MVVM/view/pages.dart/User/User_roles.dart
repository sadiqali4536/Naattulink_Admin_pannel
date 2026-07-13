import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swiftclean_admin/MVVM/utils/rbac_session.dart';
import 'package:swiftclean_admin/MVVM/model/services/firebaseauthservices.dart';
import 'package:swiftclean_admin/MVVM/model/models/admin_model.dart';

class RoleModel {
  final String id;
  final String name;
  final String description;
  final int usersCount;
  final String status;
  final String createdAt;
  final String initials;
  final Color badgeColor;
  final Map<String, dynamic> permissions;

  RoleModel({
    required this.id,
    required this.name,
    required this.description,
    required this.usersCount,
    required this.status,
    required this.createdAt,
    required this.initials,
    required this.badgeColor,
    required this.permissions,
  });

  factory RoleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoleModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      usersCount: data['usersCount'] ?? 0,
      status: data['status'] ?? 'Active',
      createdAt:
          data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate().toIso8601String()
              : (data['createdAt']?.toString() ?? ''),
      initials: data['initials'] ?? '',
      badgeColor: Color(data['badgeColor'] ?? 0xFF8B5CF6),
      permissions: data['permissions'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'usersCount': usersCount,
      'status': status,
      'createdAt': createdAt,
      'initials': initials,
      'badgeColor': badgeColor.toARGB32(),
      'permissions': permissions,
    };
  }
}

class UserRolesPage extends StatefulWidget {
  final ValueChanged<String>? onTabChanged;
  const UserRolesPage({super.key, this.onTabChanged});

  @override
  State<UserRolesPage> createState() => _UserRolesPageState();
}

class _UserRolesPageState extends State<UserRolesPage> {
  Stream<QuerySnapshot>? _rolesStream;
  Stream<QuerySnapshot>? _adminUsersStream;

  Stream<QuerySnapshot> get rolesStream {
    _rolesStream ??= FirebaseFirestore.instance.collection("roles").snapshots();
    return _rolesStream!;
  }

  Stream<QuerySnapshot> get adminUsersStream {
    _adminUsersStream ??=
        FirebaseFirestore.instance.collection("admin_users").snapshots();
    return _adminUsersStream!;
  }

  @override
  void initState() {
    super.initState();
    _rolesStream = FirebaseFirestore.instance.collection("roles").snapshots();
    _adminUsersStream =
        FirebaseFirestore.instance.collection("admin_users").snapshots();
  }

  String _searchQuery = "";
  String _selectedStatus = "All Status";

  final List<String> _modules = [
    "Advertisement",
    "Bus",
    "Taxi",
    "User Management",
    "Worker Management",
    "Bookings",
    "Payments",
    "Reports",
    "Notifications",
    "Settings",
  ];

  final List<String> _actions = [
    "View",
    "Create",
    "Edit",
    "Delete",
    "Approve",
    "Manage",
  ];

  Widget _buildBreadcrumbs() {
    return Row(
      children: [
        Text(
          "Dashboard",
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const Icon(
          Icons.chevron_right_rounded,
          size: 14,
          color: Color(0xFF94A3B8),
        ),
        Text(
          "User Management",
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const Icon(
          Icons.chevron_right_rounded,
          size: 14,
          color: Color(0xFF94A3B8),
        ),
        Text(
          "User Roles",
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: rolesStream,
      builder: (context, rolesSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: adminUsersStream,
          builder: (context, adminUsersSnapshot) {
            List<RoleModel> roles = [];

            // Map user roles counts dynamically
            final Map<String, int> roleUserCounts = {};
            if (adminUsersSnapshot.hasData) {
              for (var doc in adminUsersSnapshot.data!.docs) {
                final adminData = doc.data() as Map<String, dynamic>?;
                if (adminData != null && adminData['status'] == 'Active') {
                  final email =
                      (adminData['email'] ?? '').toString().toLowerCase();
                  final rId = (adminData['roleId'] ?? '').toString();
                  final username =
                      (adminData['username'] ?? '').toString().toLowerCase();
                  if (email == 'developer@naattulink.com' ||
                      rId == 'developer' ||
                      username == 'developer') {
                    continue;
                  }
                  final rName = (adminData['roleDisplayName'] ?? '').toString();
                  if (rName.isNotEmpty) {
                    roleUserCounts[rName] = (roleUserCounts[rName] ?? 0) + 1;
                  }
                  if (rId.isNotEmpty) {
                    String normName = rId;
                    if (rId == 'super_admin')
                      normName = 'Super Admin';
                    else if (rId == 'admin')
                      normName = 'Admin';
                    else if (rId == 'manager')
                      normName = 'Manager';
                    else if (rId == 'staff')
                      normName = 'Staff';
                    else if (rId == 'operator')
                      normName = 'Operator';
                    else if (rId == 'support')
                      normName = 'Support';
                    else if (rId == 'developer')
                      normName = 'Developer';

                    if (normName != rName) {
                      roleUserCounts[normName] =
                          (roleUserCounts[normName] ?? 0) + 1;
                    }
                  }
                }
              }
            }

            if (rolesSnapshot.hasData && rolesSnapshot.data!.docs.isNotEmpty) {
              roles =
                  rolesSnapshot.data!.docs.map((doc) {
                    final baseRole = RoleModel.fromFirestore(doc);
                    final dynamicCount = roleUserCounts[baseRole.name] ?? 0;
                    return RoleModel(
                      id: baseRole.id,
                      name: baseRole.name,
                      description: baseRole.description,
                      usersCount: dynamicCount,
                      status: baseRole.status,
                      createdAt: baseRole.createdAt,
                      initials: baseRole.initials,
                      badgeColor: baseRole.badgeColor,
                      permissions: baseRole.permissions,
                    );
                  }).toList();
            }

            final int totalRoles = roles.length;
            final int activeRoles =
                roles.where((r) => r.status == "Active").length;
            final int inactiveRoles =
                roles.where((r) => r.status == "Inactive").length;
            final int totalUsers = roles.fold(
              0,
              (total, r) => total + r.usersCount,
            );

            return LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;

                // Filter logic
                final filteredRoles =
                    roles.where((role) {
                      // Hide Developer role from user roles list completely
                      if (role.name.toLowerCase() == "developer") {
                        return false;
                      }

                      // Hide Super Admin from roles list for non-Developers / non-SuperAdmins
                      if (role.name == "Super Admin" &&
                          !RbacSession().isDev &&
                          !RbacSession().isSuperAdmin) {
                        return false;
                      }

                      final matchesSearch =
                          role.name.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ||
                          role.description.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          );
                      final matchesStatus =
                          _selectedStatus == "All Status" ||
                          role.status.toLowerCase() == _selectedStatus.toLowerCase();
                      return matchesSearch && matchesStatus;
                    }).toList();

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Breadcrumbs
                      _buildBreadcrumbs(),
                      const SizedBox(height: 8),

                      // Title Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "User Roles Management",
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              if (widget.onTabChanged != null) {
                                widget.onTabChanged!("Grant Access");
                              } else {
                                _showAddRoleDialog(context);
                              }
                            },
                            icon: const Icon(Icons.add, size: 14),
                            label: Text(
                              "Add New Role",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Stats Cards
                      _buildStatsCardsGrid(
                        width,
                        totalRoles: totalRoles,
                        activeRoles: activeRoles,
                        inactiveRoles: inactiveRoles,
                        totalUsers: totalUsers,
                      ),
                      const SizedBox(height: 24),

                      // Filter row
                      _buildFilterRow(context, width),
                      const SizedBox(height: 24),

                      // Table
                      _buildRolesTable(filteredRoles),
                      const SizedBox(height: 16),

                      // Footer counters
                      _buildTableFooter(filteredRoles.length),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatsCardsGrid(
    double width, {
    required int totalRoles,
    required int activeRoles,
    required int inactiveRoles,
    required int totalUsers,
  }) {
    int crossAxisCount = 4;
    if (width < 600) {
      crossAxisCount = 1;
    } else if (width < 1100) {
      crossAxisCount = 2;
    }

    final double itemWidth =
        (width - (crossAxisCount - 1) * 16) / crossAxisCount;
    const double itemHeight = 115;
    final double aspectRatio = itemWidth / itemHeight;

    final String formattedTotalUsers = totalUsers.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: aspectRatio > 0 ? aspectRatio : 2.0,
      children: [
        StatsCard(
          title: "Total Roles",
          value: totalRoles.toString(),
          trendPeriod: "All user roles in the system",
          icon: Icons.people_alt_rounded,
          iconColor: const Color(0xFF3B82F6),
          iconBgColor: const Color(0xFFEFF6FF),
        ),
        StatsCard(
          title: "Active Roles",
          value: activeRoles.toString(),
          trendPeriod: "Currently active roles",
          icon: Icons.check_circle_outline_rounded,
          iconColor: const Color(0xFF10B981),
          iconBgColor: const Color(0xFFECFDF5),
        ),
        StatsCard(
          title: "Inactive Roles",
          value: inactiveRoles.toString(),
          trendPeriod: "Currently inactive roles",
          icon: Icons.cancel_outlined,
          iconColor: const Color(0xFFF59E0B),
          iconBgColor: const Color(0xFFFEF3C7),
        ),
        StatsCard(
          title: "Total Users by Roles",
          value: formattedTotalUsers,
          trendPeriod: "Users across all roles",
          icon: Icons.group_add_rounded,
          iconColor: const Color(0xFF8B5CF6),
          iconBgColor: const Color(0xFFF5F3FF),
        ),
      ],
    );
  }

  Widget _buildFilterRow(BuildContext context, double width) {
    final bool isSmall = width < 700;

    final searchField = SizedBox(
      width: isSmall ? double.infinity : 300,
      height: 38,
      child: TextFormField(
        onChanged:
            (val) => setState(() {
              _searchQuery = val;
            }),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          fillColor: Colors.white,
          filled: true,
          hintText: "Search roles by name or description...",
          hintStyle: GoogleFonts.inter(
            color: const Color(0xFF94A3B8),
            fontSize: 12,
          ),
          prefixIcon: const Icon(
            CupertinoIcons.search,
            color: Color(0xFF94A3B8),
            size: 16,
          ),
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        style: GoogleFonts.inter(color: const Color(0xFF1E293B), fontSize: 12),
      ),
    );

    final statusDropdown = SizedBox(
      width: isSmall ? double.infinity : 150,
      height: 38,
      child: DropdownButtonFormField<String>(
        initialValue: _selectedStatus,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          fillColor: Colors.white,
          filled: true,
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        style: GoogleFonts.inter(color: const Color(0xFF1E293B), fontSize: 12),
        items:
            ["All Status", "Active", "Inactive"]
                .map(
                  (status) =>
                      DropdownMenuItem(value: status, child: Text(status)),
                )
                .toList(),
        onChanged:
            (val) => setState(() {
              _selectedStatus = val!;
            }),
      ),
    );

    final exportButton = ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.download_rounded, size: 14),
      label: Text(
        "Export",
        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF475569),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    if (isSmall) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          searchField,
          const SizedBox(height: 12),
          statusDropdown,
          const SizedBox(height: 12),
          Align(alignment: Alignment.centerRight, child: exportButton),
        ],
      );
    } else {
      return Row(
        children: [
          searchField,
          const SizedBox(width: 12),
          statusDropdown,
          const Spacer(),
          exportButton,
        ],
      );
    }
  }

  Widget _buildRolesTable(List<RoleModel> roles) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F3F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 1100,
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(2.0), // Role Name + Initials badge
                  1: FlexColumnWidth(2.0), // Description
                  2: FlexColumnWidth(0.8), // Users count
                  3: FlexColumnWidth(0.8), // Status
                  4: FlexColumnWidth(1.4), // Created At
                  5: FlexColumnWidth(4.0), // Actions
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  TableRow(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                      ),
                    ),
                    children: [
                      _buildHeaderCell("Role Name"),
                      _buildHeaderCell("Description"),
                      _buildHeaderCell("Users", horizontalPadding: 8.0),
                      _buildHeaderCell("Status", horizontalPadding: 8.0),
                      _buildHeaderCell("Created At"),
                      _buildHeaderCell("Actions"),
                    ],
                  ),
                  ...roles.map((role) {
                    return TableRow(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFFF1F5F9),
                            width: 1,
                          ),
                        ),
                      ),
                      children: [
                        // Role Name + Initials
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12.0,
                            horizontal: 16.0,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: role.badgeColor,
                                child: Text(
                                  role.initials,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  role.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Description
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12.0,
                            horizontal: 16.0,
                          ),
                          child: Text(
                            role.description.isEmpty ? "—" : role.description,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ),
                        // Users count with icon
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12.0,
                            horizontal: 8.0,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.people_outline_rounded,
                                size: 16,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                role.usersCount.toString(),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF1E293B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Status
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12.0,
                            horizontal: 8.0,
                          ),
                          child: _buildStatusIndicator(role.status),
                        ),
                        // Created At
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12.0,
                            horizontal: 16.0,
                          ),
                          child: Text(
                            role.createdAt,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        // Actions
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12.0,
                            horizontal: 16.0,
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            alignment: WrapAlignment.start,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _buildActionButton(
                                Icons.person_add_outlined,
                                const Color(0xFF8B5CF6),
                                "Assign",
                                () => _showAssignUserDialog(context, role),
                              ),
                              _buildActionButton(
                                Icons.edit_outlined,
                                Colors.blue,
                                "Edit",
                                () => _showEditRoleDialog(context, role),
                              ),
                              _buildActionButton(
                                Icons.visibility_outlined,
                                const Color(0xFF10B981),
                                "View",
                                () => _showViewRoleDialog(context, role),
                              ),
                              _buildActionButton(
                                Icons.delete_outline_rounded,
                                Colors.red,
                                "Delete",
                                () => _showDeleteConfirmation(context, role),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String label, {double horizontalPadding = 16.0}) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 12.0,
        horizontal: horizontalPadding,
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF94A3B8),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String status) {
    Color dotColor =
        status == "Active" ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    Color textColor =
        status == "Active" ? const Color(0xFF047857) : const Color(0xFFB91C1C);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          status,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    IconData icon,
    Color color,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableFooter(int totalFiltered) {
    return Row(
      children: [
        Text(
          "Showing 1 to $totalFiltered of $totalFiltered roles",
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF64748B),
          ),
        ),
        const Spacer(),
        // Simple page navigators
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF10B981),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              "1",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 110,
          height: 32,
          child: DropdownButtonFormField<int>(
            initialValue: 10,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(6),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            style: GoogleFonts.inter(
              color: const Color(0xFF1E293B),
              fontSize: 11,
            ),
            items: const [
              DropdownMenuItem(value: 10, child: Text("10 / page")),
            ],
            onChanged: (val) {},
          ),
        ),
      ],
    );
  }

  String _formatCurrentDateTime() {
    final now = DateTime.now();
    final months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    final String month = months[now.month - 1];
    final int day = now.day;
    final int year = now.year;
    final int hour24 = now.hour;
    final int minute = now.minute;
    final String period = hour24 >= 12 ? "PM" : "AM";
    int hour = hour24 % 12;
    if (hour == 0) hour = 12;
    final String minuteStr = minute.toString().padLeft(2, '0');
    final String hourStr = hour.toString().padLeft(2, '0');
    return "$month $day, $year $hourStr:$minuteStr $period";
  }

  void _showAssignUserDialog(BuildContext context, RoleModel role) {
    final searchController = TextEditingController();
    String searchQuery = "";
    final adminUsersStream =
        FirebaseFirestore.instance.collection("admin_users").snapshots();
    final usersStream =
        FirebaseFirestore.instance.collection("users").snapshots();

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: Colors.transparent,
                child: Container(
                  width: 560,
                  height: 640,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Header ────────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: role.badgeColor,
                              child: Text(
                                role.initials,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Assign Users",
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    "Role: ${role.name}",
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Color(0xFF94A3B8),
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),

                      // ── Search ────────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                        child: TextField(
                          controller: searchController,
                          onChanged:
                              (v) => setDialogState(
                                () => searchQuery = v.toLowerCase(),
                              ),
                          style: GoogleFonts.inter(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: "Search by name or email…",
                            hintStyle: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF94A3B8),
                            ),
                            prefixIcon: const Icon(
                              CupertinoIcons.search,
                              size: 18,
                              color: Color(0xFF94A3B8),
                            ),
                            isDense: true,
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFF10B981),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),

                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: adminUsersStream,
                          builder: (context, adminSnapshot) {
                            final Map<String, Map<String, dynamic>> adminDocs =
                                {};
                            if (adminSnapshot.hasData) {
                              for (var doc in adminSnapshot.data!.docs) {
                                final d = doc.data() as Map<String, dynamic>?;
                                if (d != null) {
                                  adminDocs[doc.id] = d;
                                }
                              }
                            }

                            return StreamBuilder<QuerySnapshot>(
                              stream: usersStream,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF10B981),
                                      strokeWidth: 2,
                                    ),
                                  );
                                }

                                final docs = snapshot.data?.docs ?? [];
                                final filtered =
                                    docs.where((doc) {
                                      if (!adminDocs.containsKey(doc.id)) {
                                        return false;
                                      }
                                      final adminData = adminDocs[doc.id]!;
                                      final rId =
                                          (adminData['roleId'] ?? '')
                                              .toString();
                                      final rIds =
                                          (adminData['roleIds']
                                                  as List<dynamic>?)
                                              ?.map((e) => e.toString())
                                              .toList() ??
                                          [rId];

                                      final data =
                                          doc.data() as Map<String, dynamic>;
                                      final name =
                                          (data['username'] ??
                                                  data['name'] ??
                                                  '')
                                              .toString()
                                              .toLowerCase();
                                      final email =
                                          (data['email'] ?? '')
                                              .toString()
                                              .toLowerCase();

                                      if (email == 'developer@naattulink.com' ||
                                          email ==
                                              'superadmin@naattulink.com' ||
                                          name == 'developer' ||
                                          name == 'superadmin' ||
                                          rId == 'super_admin' ||
                                          rId == 'developer' ||
                                          rIds.contains('super_admin') ||
                                          rIds.contains('developer')) {
                                        return false;
                                      }

                                      return searchQuery.isEmpty ||
                                          name.contains(searchQuery) ||
                                          email.contains(searchQuery);
                                    }).toList();

                                if (filtered.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.search_off_rounded,
                                          size: 40,
                                          color: Colors.grey.shade300,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "No users found",
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF94A3B8),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                return ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    0,
                                    12,
                                    12,
                                  ),
                                  itemCount: filtered.length,
                                  separatorBuilder:
                                      (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final doc = filtered[index];
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    final name =
                                        data['username'] ??
                                        data['name'] ??
                                        'Unknown';
                                    final email = data['email'] ?? '';
                                    final adminData = adminDocs[doc.id];
                                    final currentRole =
                                        adminData?['roleDisplayName']
                                            ?.toString() ??
                                        '';
                                    final rId =
                                        (adminData?['roleId'] ?? '').toString();
                                    final rIds =
                                        (adminData?['roleIds']
                                                as List<dynamic>?)
                                            ?.map((e) => e.toString())
                                            .toList() ??
                                        [rId];
                                    final targetRoleId = role.name
                                        .toLowerCase()
                                        .replaceAll(' ', '_');
                                    final isAssigned = rIds.contains(
                                      targetRoleId,
                                    );
                                    final hasOtherRole =
                                        currentRole.isNotEmpty && !isAssigned;

                                    return Container(
                                      decoration: BoxDecoration(
                                        color:
                                            isAssigned
                                                ? const Color(0xFFECFDF5)
                                                : const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color:
                                              isAssigned
                                                  ? const Color(0xFF6EE7B7)
                                                  : const Color(0xFFE2E8F0),
                                          width: 1,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor:
                                                isAssigned
                                                    ? const Color(0xFF10B981)
                                                    : const Color(0xFFE0E7FF),
                                            child: Text(
                                              name.isNotEmpty
                                                  ? name[0].toUpperCase()
                                                  : '?',
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    isAssigned
                                                        ? Colors.white
                                                        : const Color(
                                                          0xFF4F46E5,
                                                        ),
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        name,
                                                        style:
                                                            GoogleFonts.inter(
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color:
                                                                  const Color(
                                                                    0xFF1E293B,
                                                                  ),
                                                            ),
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                    ),
                                                    if (isAssigned) ...[
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: const Color(
                                                            0xFF10B981,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          "Assigned",
                                                          style:
                                                              GoogleFonts.inter(
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color:
                                                                    Colors
                                                                        .white,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  email,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 11,
                                                    color: const Color(
                                                      0xFF94A3B8,
                                                    ),
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                if (currentRole.isNotEmpty)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 4,
                                                        ),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 7,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                          0xFFEEF2FF,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        currentRole,
                                                        style:
                                                            GoogleFonts.inter(
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color:
                                                                  const Color(
                                                                    0xFF4F46E5,
                                                                  ),
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          if (isAssigned)
                                            const Icon(
                                              Icons.check_circle_rounded,
                                              color: Color(0xFF10B981),
                                              size: 24,
                                            )
                                          else
                                            ElevatedButton(
                                              onPressed: () async {
                                                try {
                                                  // Prevent reassigning Super Admin or modifying Super Admin role
                                                  if (currentRole
                                                              .toLowerCase() ==
                                                          "super admin" ||
                                                      role.name ==
                                                          "Super Admin") {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          "Error: Cannot modify a Super Admin role or reassign a Super Admin user.",
                                                        ),
                                                        backgroundColor:
                                                            Colors.red,
                                                      ),
                                                    );
                                                    return;
                                                  }

                                                  await FirebaseAuthService
                                                      .instance
                                                      .grantAdminAccess(
                                                        targetUid: doc.id,
                                                        targetDisplayName: name,
                                                        roleId: role.name
                                                            .toLowerCase()
                                                            .replaceAll(
                                                              ' ',
                                                              '_',
                                                            ),
                                                        roleDisplayName:
                                                            role.name,
                                                        roleLevel:
                                                            RoleLevels.levelFor(
                                                              role.name,
                                                            ),
                                                      );
                                                  setDialogState(() {});
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        "Successfully assigned $name to ${role.name}.",
                                                      ),
                                                    ),
                                                  );
                                                } catch (e) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        "Error: $e",
                                                      ),
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                  );
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    hasOtherRole
                                                        ? const Color(
                                                          0xFFF59E0B,
                                                        )
                                                        : const Color(
                                                          0xFF10B981,
                                                        ),
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                minimumSize: Size.zero,
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                              child: Text(
                                                hasOtherRole
                                                    ? "Reassign"
                                                    : "Assign",
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),

                      // ── Footer ────────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(16),
                          ),
                          border: Border(
                            top: BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Changes are saved automatically",
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF94A3B8),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F172A),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                "Done",
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
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
          ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, RoleModel role) {
    // Safety check
    if (role.name == "Super Admin") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error: The Super Admin role cannot be deleted."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              "Delete Role",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            content: Text(
              "Are you sure you want to delete the '${role.name}' role? This action cannot be undone.",
              style: GoogleFonts.inter(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.inter(color: const Color(0xFF64748B)),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  await FirebaseFirestore.instance
                      .collection("roles")
                      .doc(role.id)
                      .delete();
                  navigator.pop();
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        "Role '${role.name}' deleted successfully.",
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                ),
                child: Text("Delete", style: GoogleFonts.inter()),
              ),
            ],
          ),
    );
  }

  void _showAddRoleDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final usernameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool obscurePassword = true;
    bool createAccount = false; // toggle to create a user account
    bool useExistingEmail = false;
    String? selectedUserId;
    String? selectedUserEmail;

    // permissions structure: Map<String, List<String>>
    final Map<String, List<String>> selectedPermissions = {};
    for (var module in _modules) {
      selectedPermissions[module] = [];
    }

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Row(
                    children: [
                      const Icon(
                        Icons.admin_panel_settings_outlined,
                        color: Color(0xFF10B981),
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Add New Role",
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  content: SizedBox(
                    width: 800,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Role Info ──────────────────────────────────────────
                          _sectionHeader(
                            "Role Information",
                            Icons.badge_outlined,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: nameController,
                            decoration: InputDecoration(
                              labelText: "Role Name *",
                              labelStyle: GoogleFonts.inter(fontSize: 13),
                              hintText: "e.g. Operations Manager",
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: descriptionController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: "Description",
                              labelStyle: GoogleFonts.inter(fontSize: 13),
                              hintText:
                                  "Brief description of this role's responsibilities",
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── Account Credentials ────────────────────────────────
                          _sectionHeader(
                            "Account Credentials",
                            Icons.lock_person_outlined,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Switch(
                                value: createAccount,
                                activeColor: const Color(0xFF10B981),
                                onChanged:
                                    (v) =>
                                        setDialogState(() => createAccount = v),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Create or assign a login account for this role",
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (createAccount) ...[
                            const SizedBox(height: 12),
                            // Toggle Segment: New Email vs Existing User
                            Row(
                              children: [
                                Expanded(
                                  child: ChoiceChip(
                                    label: const Text("New Email Account"),
                                    selected: !useExistingEmail,
                                    selectedColor: const Color(0xFFE0F2FE),
                                    labelStyle: GoogleFonts.inter(
                                      fontSize: 12,
                                      color:
                                          !useExistingEmail
                                              ? const Color(0xFF0369A1)
                                              : const Color(0xFF475569),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    onSelected: (selected) {
                                      if (selected) {
                                        setDialogState(() {
                                          useExistingEmail = false;
                                          selectedUserId = null;
                                          selectedUserEmail = null;
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ChoiceChip(
                                    label: const Text(
                                      "Use Existing User Email",
                                    ),
                                    selected: useExistingEmail,
                                    selectedColor: const Color(0xFFE0F2FE),
                                    labelStyle: GoogleFonts.inter(
                                      fontSize: 12,
                                      color:
                                          useExistingEmail
                                              ? const Color(0xFF0369A1)
                                              : const Color(0xFF475569),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    onSelected: (selected) {
                                      if (selected) {
                                        setDialogState(() {
                                          useExistingEmail = true;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            if (useExistingEmail) ...[
                              // Dropdown of existing users
                              StreamBuilder<QuerySnapshot>(
                                stream:
                                    FirebaseFirestore.instance
                                        .collection("users")
                                        .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF10B981),
                                        strokeWidth: 2,
                                      ),
                                    );
                                  }
                                  final docs = snapshot.data?.docs ?? [];
                                  return DropdownButtonFormField<String>(
                                    value: selectedUserId,
                                    decoration: const InputDecoration(
                                      labelText: "Select Existing User *",
                                      prefixIcon: Icon(Icons.people_outline),
                                      border: OutlineInputBorder(),
                                    ),
                                    items:
                                        docs
                                            .where((doc) {
                                              final data =
                                                  doc.data()
                                                      as Map<String, dynamic>;
                                              final name =
                                                  (data['name'] ??
                                                          data['username'] ??
                                                          '')
                                                      .toString()
                                                      .toLowerCase();
                                              final email =
                                                  (data['email'] ?? '')
                                                      .toString()
                                                      .toLowerCase();
                                              return email !=
                                                      'developer@naattulink.com' &&
                                                  name != 'developer';
                                            })
                                            .map((doc) {
                                              final data =
                                                  doc.data()
                                                      as Map<String, dynamic>;
                                              final name =
                                                  data['name'] ??
                                                  data['username'] ??
                                                  'No Name';
                                              final email =
                                                  data['email'] ?? 'No Email';
                                              return DropdownMenuItem<String>(
                                                value: doc.id,
                                                child: Text(
                                                  "$name ($email)",
                                                  style: GoogleFonts.inter(
                                                    fontSize: 13,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              );
                                            })
                                            .toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        final matchedDoc = docs.firstWhere(
                                          (d) => d.id == val,
                                        );
                                        final matchedData =
                                            matchedDoc.data()
                                                as Map<String, dynamic>;
                                        setDialogState(() {
                                          selectedUserId = val;
                                          selectedUserEmail =
                                              matchedData['email'];
                                        });
                                      }
                                    },
                                  );
                                },
                              ),
                            ] else ...[
                              // New email textfield
                              TextFormField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: "Email Address *",
                                  prefixIcon: const Icon(
                                    Icons.mail_outline_rounded,
                                    size: 18,
                                  ),
                                  labelStyle: GoogleFonts.inter(fontSize: 13),
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ],

                            const SizedBox(height: 12),
                            TextFormField(
                              controller: passwordController,
                              obscureText: obscurePassword,
                              decoration: InputDecoration(
                                labelText: "Password *",
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 18,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 18,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                  onPressed:
                                      () => setDialogState(
                                        () =>
                                            obscurePassword = !obscurePassword,
                                      ),
                                ),
                                labelStyle: GoogleFonts.inter(fontSize: 13),
                                helperText: "Minimum 6 characters",
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),

                          // ── Permissions ────────────────────────────────────────
                          _sectionHeader(
                            "Module Permissions",
                            Icons.tune_rounded,
                          ),
                          const SizedBox(height: 12),
                          ..._modules.map((module) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    module,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF475569),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 8,
                                    children:
                                        _actions.map((action) {
                                          final isChecked =
                                              selectedPermissions[module]!
                                                  .contains(action);
                                          return Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: Checkbox(
                                                  value: isChecked,
                                                  activeColor: const Color(
                                                    0xFF10B981,
                                                  ),
                                                  onChanged: (val) {
                                                    setDialogState(() {
                                                      if (val == true) {
                                                        selectedPermissions[module]!
                                                            .add(action);
                                                      } else {
                                                        selectedPermissions[module]!
                                                            .remove(action);
                                                      }
                                                    });
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                action,
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                  ),
                                  const SizedBox(height: 8),
                                  const Divider(color: Color(0xFFF1F5F9)),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.inter(
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        final String name = nameController.text.trim();
                        final String description =
                            descriptionController.text.trim();

                        if (name.isEmpty) {
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(
                              content: Text("Role name is required."),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }

                        // Prevent creating Super Admin
                        if (name.toLowerCase() == "super admin") {
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Error: Cannot create or modify a Super Admin role.",
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // Validate credentials
                        if (createAccount) {
                          if (useExistingEmail) {
                            if (selectedUserId == null ||
                                passwordController.text.trim().length < 6) {
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Please select an existing user and enter a password (min 6 chars).",
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }
                          } else {
                            if (emailController.text.trim().isEmpty ||
                                passwordController.text.trim().length < 6) {
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Please enter an email and password (min 6 chars).",
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }
                          }
                        }

                        try {
                          final String initials =
                              name.length >= 2
                                  ? name.substring(0, 2).toUpperCase()
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
                              colors[name.hashCode % colors.length];

                          // 1. Save the role document
                          await FirebaseFirestore.instance
                              .collection("roles")
                              .add({
                                'name': name,
                                'description': description,
                                'usersCount': 0,
                                'status': 'Active',
                                'createdAt': _formatCurrentDateTime(),
                                'initials': initials,
                                'badgeColor': color.toARGB32(),
                                'permissions': selectedPermissions,
                              });

                          // 2. Optionally create/update user account
                          if (createAccount) {
                            if (useExistingEmail) {
                              // Attempt to create credentials for existing email
                              try {
                                await FirebaseAuth.instance
                                    .createUserWithEmailAndPassword(
                                      email: selectedUserEmail!,
                                      password: passwordController.text.trim(),
                                    );
                                // Update existing user doc
                                await FirebaseAuthService.instance
                                    .grantAdminAccess(
                                      targetUid: selectedUserId!,
                                      targetDisplayName: selectedUserEmail!,
                                      roleId: name.toLowerCase().replaceAll(
                                        ' ',
                                        '_',
                                      ),
                                      roleDisplayName: name,
                                      roleLevel: RoleLevels.levelFor(name),
                                      permissionsAdded: {},
                                      permissionsRemoved: {},
                                    );
                              } on FirebaseAuthException catch (authErr) {
                                if (authErr.code == 'email-already-in-use') {
                                  // Already registered in Auth, just assign the role
                                  await FirebaseAuthService.instance
                                      .grantAdminAccess(
                                        targetUid: selectedUserId!,
                                        targetDisplayName: selectedUserEmail!,
                                        roleId: name.toLowerCase().replaceAll(
                                          ' ',
                                          '_',
                                        ),
                                        roleDisplayName: name,
                                        roleLevel: RoleLevels.levelFor(name),
                                        permissionsAdded: {},
                                        permissionsRemoved: {},
                                      );
                                } else {
                                  rethrow;
                                }
                              }
                            } else {
                              // Create new Auth account
                              final targetEmail = emailController.text.trim();
                              final credential = await FirebaseAuth.instance
                                  .createUserWithEmailAndPassword(
                                    email: targetEmail,
                                    password: passwordController.text.trim(),
                                  );
                              await FirebaseFirestore.instance
                                  .collection("users")
                                  .doc(credential.user!.uid)
                                  .set({
                                    'username': targetEmail.split('@')[0],
                                    'name': targetEmail.split('@')[0],
                                    'email': targetEmail,
                                    'status': 'Active',
                                    'userType': 'Admin',
                                    'points': 0,
                                    'joinedDate': _formatCurrentDateTime(),
                                    'createdAt': FieldValue.serverTimestamp(),
                                  });

                              await FirebaseAuthService.instance
                                  .grantAdminAccess(
                                    targetUid: credential.user!.uid,
                                    targetDisplayName:
                                        targetEmail.split('@')[0],
                                    roleId: name.toLowerCase().replaceAll(
                                      ' ',
                                      '_',
                                    ),
                                    roleDisplayName: name,
                                    roleLevel: RoleLevels.levelFor(name),
                                    permissionsAdded: {},
                                    permissionsRemoved: {},
                                  );
                            }
                          }

                          navigator.pop();
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                createAccount
                                    ? "Role and login account setup completed."
                                    : "Role added successfully.",
                              ),
                              backgroundColor: const Color(0xFF10B981),
                            ),
                          );
                        } catch (e) {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text("Error: $e"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: Text("Save Role", style: GoogleFonts.inter()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  /// Helper to render a bold section header with icon
  Widget _sectionHeader(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF10B981)),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
      ],
    );
  }

  Future<void> _updateUserRoles(
    String targetUid,
    String targetName,
    List<String> newRoleIds,
  ) async {
    if (newRoleIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "A user must have at least one role assigned. Use 'Unassign' to remove all access.",
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final primaryRoleId = newRoleIds.first;
      final joinedDisplayNames = newRoleIds
          .map(
            (id) => id
                .split('_')
                .map((w) => w[0].toUpperCase() + w.substring(1))
                .join(' '),
          )
          .join(', ');
      final maxLevel = newRoleIds
          .map((id) => RoleLevels.levelFor(id))
          .reduce((a, b) => a > b ? a : b);

      await FirebaseAuthService.instance.grantAdminAccess(
        targetUid: targetUid,
        targetDisplayName: targetName,
        roleId: primaryRoleId,
        roleDisplayName: joinedDisplayNames,
        roleLevel: maxLevel,
        roleIds: newRoleIds,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("User role allocation updated successfully."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update user roles: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEditRoleDialog(BuildContext context, RoleModel role) {
    // Safety check
    if (role.name == "Super Admin") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error: The Super Admin role cannot be modified."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              "Edit Role",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            content: SizedBox(
              width: 700,
              height: MediaQuery.of(context).size.height * 0.75,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Current Assigned Users",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection("admin_users")
                              .snapshots(),
                      builder: (context, adminSnapshot) {
                        if (adminSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (!adminSnapshot.hasData ||
                            adminSnapshot.data!.docs.isEmpty) {
                          return Text(
                            "No users assigned to this role.",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          );
                        }

                        return StreamBuilder<QuerySnapshot>(
                          stream:
                              FirebaseFirestore.instance
                                  .collection("users")
                                  .snapshots(),
                          builder: (context, usersSnapshot) {
                            if (usersSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (!usersSnapshot.hasData ||
                                usersSnapshot.data!.docs.isEmpty) {
                              return Text(
                                "No users found.",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              );
                            }

                            // Get mapping of uid -> user doc data
                            final Map<String, Map<String, dynamic>> userDocs =
                                {};
                            for (var doc in usersSnapshot.data!.docs) {
                              userDocs[doc.id] =
                                  doc.data() as Map<String, dynamic>;
                            }

                            // Filter admin users assigned to this role (either by roleId or in roleIds list)
                            final canonicalRoleId = role.name
                                .toLowerCase()
                                .replaceAll(' ', '_');
                            final assignedAdminDocs =
                                adminSnapshot.data!.docs.where((doc) {
                                  final d =
                                      doc.data() as Map<String, dynamic>? ?? {};
                                  final status =
                                      d['status'] as String? ?? 'Active';
                                  if (status != 'Active') return false;

                                  final rId = (d['roleId'] ?? '').toString();
                                  final rIds =
                                      (d['roleIds'] as List<dynamic>?)
                                          ?.map((e) => e.toString())
                                          .toList() ??
                                      [rId];
                                  final uDoc = userDocs[doc.id] ?? {};
                                  final email =
                                      (uDoc['email'] ?? '')
                                          .toString()
                                          .toLowerCase();
                                  final username =
                                      (uDoc['username'] ?? uDoc['name'] ?? '')
                                          .toString()
                                          .toLowerCase();

                                  if (rId == 'super_admin' ||
                                      rId == 'developer' ||
                                      rIds.contains('super_admin') ||
                                      rIds.contains('developer') ||
                                      email == 'superadmin@naattulink.com' ||
                                      email == 'developer@naattulink.com' ||
                                      username == 'superadmin' ||
                                      username == 'developer') {
                                    return false;
                                  }
                                  return rIds.contains(canonicalRoleId);
                                }).toList();

                            if (assignedAdminDocs.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    "No users currently assigned to this role.",
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                              );
                            }

                            return StreamBuilder<QuerySnapshot>(
                              stream:
                                  FirebaseFirestore.instance
                                      .collection("roles")
                                      .snapshots(),
                              builder: (context, rolesSnap) {
                                if (rolesSnap.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                final List<RoleModel> allRoles =
                                    (rolesSnap.data?.docs ?? [])
                                        .map((d) => RoleModel.fromFirestore(d))
                                        .toList();

                                return ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: assignedAdminDocs.length,
                                  itemBuilder: (context, index) {
                                    final adminDoc = assignedAdminDocs[index];
                                    final adminModel =
                                        AdminUserModel.fromFirestore(adminDoc);
                                    final userData =
                                        userDocs[adminDoc.id] ??
                                        {
                                          'fullName':
                                              adminModel.roleDisplayName,
                                          'username': adminDoc.id,
                                          'email': 'No Email',
                                        };

                                    return _AssignedUserCard(
                                      userData: userData,
                                      adminData: adminModel,
                                      allRoles: allRoles,
                                      allModules: _modules,
                                      allActions: _actions,
                                      isSuperAdmin: RbacSession().isSuperAdmin,
                                      onUpdateRoles:
                                          (newIds) => _updateUserRoles(
                                            adminDoc.id,
                                            userData['fullName'] ??
                                                userData['username'] ??
                                                'Unknown',
                                            newIds,
                                          ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Close",
                  style: GoogleFonts.inter(color: const Color(0xFF64748B)),
                ),
              ),
            ],
          ),
    );
  }

  void _showViewRoleDialog(BuildContext context, RoleModel role) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: role.badgeColor,
                  child: Text(
                    role.initials,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    role.name,
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Description",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  role.description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Users Count",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            role.usersCount.toString(),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Status",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildStatusIndicator(role.status),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  "Created At",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  role.createdAt,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Close",
                  style: GoogleFonts.inter(color: const Color(0xFF64748B)),
                ),
              ),
            ],
          ),
    );
  }
}

class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String trendPeriod;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.trendPeriod,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F3F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  trendPeriod,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF94A3B8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssignedUserCard extends StatefulWidget {
  final Map<String, dynamic> userData;
  final AdminUserModel adminData;
  final List<RoleModel> allRoles;
  final Function(List<String>) onUpdateRoles;
  final bool isSuperAdmin;
  final List<String>? allModules;
  final List<String>? allActions;

  const _AssignedUserCard({
    required this.userData,
    required this.adminData,
    required this.allRoles,
    required this.onUpdateRoles,
    required this.isSuperAdmin,
    this.allModules,
    this.allActions,
  });

  @override
  State<_AssignedUserCard> createState() => _AssignedUserCardState();
}

class _AssignedUserCardState extends State<_AssignedUserCard> {
  bool _isExpanded = false;
  List<String> _localRoleIds = [];
  Map<String, List<String>> _localPermissionOverridesAdded = {};
  Map<String, List<String>> _localPermissionOverridesRemoved = {};
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _resetLocalData();
  }

  void _resetLocalData() {
    _localRoleIds = List<String>.from(widget.adminData.roleIds);
    _localPermissionOverridesAdded = {};
    widget.adminData.permissionOverridesAdded.forEach((k, v) {
      _localPermissionOverridesAdded[k.toLowerCase().replaceAll(' ', '_')] =
          List<String>.from(v).map((e) => e.toLowerCase()).toList();
    });
    _localPermissionOverridesRemoved = {};
    widget.adminData.permissionOverridesRemoved.forEach((k, v) {
      _localPermissionOverridesRemoved[k.toLowerCase().replaceAll(' ', '_')] =
          List<String>.from(v).map((e) => e.toLowerCase()).toList();
    });
    _isDirty = false;
  }

  @override
  void didUpdateWidget(_AssignedUserCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDirty) {
      _resetLocalData();
    }
  }

  void _checkIfDirty() {
    final bool rolesChanged =
        !_listsAreEqual(_localRoleIds, widget.adminData.roleIds);
    final bool addedChanged =
        !_mapsAreEqual(
          _localPermissionOverridesAdded,
          widget.adminData.permissionOverridesAdded,
        );
    final bool removedChanged =
        !_mapsAreEqual(
          _localPermissionOverridesRemoved,
          widget.adminData.permissionOverridesRemoved,
        );
    setState(() {
      _isDirty = rolesChanged || addedChanged || removedChanged;
    });
  }

  bool _listsAreEqual(List<dynamic> a, List<dynamic> b) {
    if (a.length != b.length) return false;
    final setA = Set.from(a);
    final setB = Set.from(b);
    return setA.length == setB.length && setA.containsAll(setB);
  }

  bool _mapsAreEqual(Map<String, List<String>> a, Map<String, List<String>> b) {
    final cleanA = a.map(
      (k, v) => MapEntry(
        k.toLowerCase().replaceAll(' ', '_'),
        v.where((e) => e.isNotEmpty).map((e) => e.toLowerCase()).toList(),
      ),
    )..removeWhere((k, v) => v.isEmpty);
    final cleanB = b.map(
      (k, v) => MapEntry(
        k.toLowerCase().replaceAll(' ', '_'),
        v.where((e) => e.isNotEmpty).map((e) => e.toLowerCase()).toList(),
      ),
    )..removeWhere((k, v) => v.isEmpty);
    if (cleanA.length != cleanB.length) return false;
    for (final key in cleanA.keys) {
      if (!cleanB.containsKey(key)) return false;
      if (!_listsAreEqual(cleanA[key]!, cleanB[key]!)) return false;
    }
    return true;
  }

  void _toggleLocalPermissionOverride(
    String module,
    String action,
    bool enable,
    bool hasBase,
  ) {
    final canonicalModule = module.toLowerCase().replaceAll(' ', '_');
    final canonicalAction = action.toLowerCase();
    setState(() {
      if (hasBase) {
        if (enable) {
          if (_localPermissionOverridesRemoved.containsKey(canonicalModule)) {
            _localPermissionOverridesRemoved[canonicalModule]!.remove(
              canonicalAction,
            );
            if (_localPermissionOverridesRemoved[canonicalModule]!.isEmpty) {
              _localPermissionOverridesRemoved.remove(canonicalModule);
            }
          }
        } else {
          final list = _localPermissionOverridesRemoved[canonicalModule] ?? [];
          if (!list.contains(canonicalAction)) {
            list.add(canonicalAction);
            _localPermissionOverridesRemoved[canonicalModule] = list;
          }
        }
      } else {
        if (enable) {
          final list = _localPermissionOverridesAdded[canonicalModule] ?? [];
          if (!list.contains(canonicalAction)) {
            list.add(canonicalAction);
            _localPermissionOverridesAdded[canonicalModule] = list;
          }
        } else {
          if (_localPermissionOverridesAdded.containsKey(canonicalModule)) {
            _localPermissionOverridesAdded[canonicalModule]!.remove(
              canonicalAction,
            );
            if (_localPermissionOverridesAdded[canonicalModule]!.isEmpty) {
              _localPermissionOverridesAdded.remove(canonicalModule);
            }
          }
        }
      }
    });
    _checkIfDirty();
  }

  Future<void> _applyChanges() async {
    try {
      final bool rolesChanged =
          !_listsAreEqual(_localRoleIds, widget.adminData.roleIds);
      if (rolesChanged) {
        await widget.onUpdateRoles(_localRoleIds);
      }

      final bool permissionsChanged =
          !_mapsAreEqual(
            _localPermissionOverridesAdded,
            widget.adminData.permissionOverridesAdded,
          ) ||
          !_mapsAreEqual(
            _localPermissionOverridesRemoved,
            widget.adminData.permissionOverridesRemoved,
          );

      if (permissionsChanged) {
        await FirebaseFirestore.instance
            .collection("admin_users")
            .doc(widget.adminData.uid)
            .update({
              'permissionOverrides.added': _localPermissionOverridesAdded,
              'permissionOverrides.removed': _localPermissionOverridesRemoved,
            });
      }

      setState(() {
        _isDirty = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Changes applied successfully."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to apply changes: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allocatedRoleIds = _localRoleIds;
    final modulesList =
        widget.allModules ??
        const [
          "Dashboard",
          "Workers",
          "Users",
          "Bookings",
          "Payments",
          "Reports",
          "Notifications",
          "Settings",
        ];
    final actionsList =
        widget.allActions ??
        const ["View", "Create", "Edit", "Delete", "Approve", "Manage"];

    final Map<String, Set<String>> basePermissions = {};
    final Map<String, Set<String>> userPermissions = {};
    for (final roleId in allocatedRoleIds) {
      final roleObj = widget.allRoles.firstWhere(
        (r) => r.id == roleId,
        orElse:
            () => RoleModel(
              id: roleId,
              name: roleId
                  .split('_')
                  .map((w) => w[0].toUpperCase() + w.substring(1))
                  .join(' '),
              description: '',
              permissions: {},
              status: 'Active',
              initials: '',
              badgeColor: Colors.blue,
              createdAt: '',
              usersCount: 0,
            ),
      );
      for (final entry in roleObj.permissions.entries) {
        final canonicalKey = entry.key.toLowerCase().replaceAll(' ', '_');
        final currentBaseSet = basePermissions[canonicalKey] ?? {};
        currentBaseSet.addAll(
          List<String>.from(entry.value).map((e) => e.toLowerCase()),
        );
        basePermissions[canonicalKey] = currentBaseSet;

        final currentSet = userPermissions[canonicalKey] ?? {};
        currentSet.addAll(
          List<String>.from(entry.value).map((e) => e.toLowerCase()),
        );
        userPermissions[canonicalKey] = currentSet;
      }
    }

    for (final entry in _localPermissionOverridesAdded.entries) {
      final canonicalKey = entry.key.toLowerCase().replaceAll(' ', '_');
      final currentSet = userPermissions[canonicalKey] ?? {};
      currentSet.addAll(
        List<String>.from(entry.value).map((e) => e.toLowerCase()),
      );
      userPermissions[canonicalKey] = currentSet;
    }

    for (final entry in _localPermissionOverridesRemoved.entries) {
      final canonicalKey = entry.key.toLowerCase().replaceAll(' ', '_');
      final currentSet = userPermissions[canonicalKey] ?? {};
      currentSet.removeAll(
        List<String>.from(entry.value).map((e) => e.toLowerCase()),
      );
      if (currentSet.isEmpty) {
        userPermissions.remove(canonicalKey);
      } else {
        userPermissions[canonicalKey] = currentSet;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      elevation: 0,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text(
              widget.userData['fullName'] ??
                  widget.userData['username'] ??
                  'No Name',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userData['email'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children:
                      allocatedRoleIds.map((rId) {
                        final displayName = rId
                            .split('_')
                            .map((w) => w[0].toUpperCase() + w.substring(1))
                            .join(' ');
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            displayName,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4F46E5),
                            ),
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 6),
                if (userPermissions.isNotEmpty) ...[
                  Text(
                    "Permissions:",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children:
                        userPermissions.entries.map((entry) {
                          final displayKey = entry.key
                              .split('_')
                              .map(
                                (w) =>
                                    w.isNotEmpty
                                        ? w[0].toUpperCase() + w.substring(1)
                                        : '',
                              )
                              .join(' ');
                          return Tooltip(
                            message:
                                "$displayKey: ${entry.value.map((e) => e.isNotEmpty ? e[0].toUpperCase() + e.substring(1) : '').join(', ')}",
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "$displayKey (${entry.value.length})",
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ],
            ),
            trailing: TextButton.icon(
              icon: Icon(
                _isDirty
                    ? Icons.close_rounded
                    : _isExpanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.edit_outlined,
                size: 16,
                color: _isDirty ? Colors.red : const Color(0xFF4F46E5),
              ),
              label: Text(
                _isDirty
                    ? "Discard"
                    : _isExpanded
                    ? "Collapse"
                    : "Edit",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _isDirty ? Colors.red : const Color(0xFF4F46E5),
                ),
              ),
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                  if (!_isExpanded) {
                    _resetLocalData();
                  }
                });
              },
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Allocate / Deallocate Roles",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children:
                        widget.allRoles.map((roleDef) {
                          final canonicalId = roleDef.name
                              .toLowerCase()
                              .replaceAll(' ', '_');
                          final isSelected =
                              _localRoleIds.contains(roleDef.id) ||
                              _localRoleIds.contains(canonicalId);
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                  value: isSelected,
                                  activeColor: const Color(0xFF10B981),
                                  onChanged:
                                      widget.isSuperAdmin
                                          ? (val) {
                                            setState(() {
                                              final canonicalId = roleDef.name
                                                  .toLowerCase()
                                                  .replaceAll(' ', '_');
                                              if (val == true) {
                                                _localRoleIds.add(canonicalId);
                                              } else {
                                                _localRoleIds.remove(
                                                  canonicalId,
                                                );
                                                _localRoleIds.remove(
                                                  roleDef.id,
                                                );
                                              }
                                            });
                                            _checkIfDirty();
                                          }
                                          : null,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                roleDef.name,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color:
                                      isSelected
                                          ? const Color(0xFF1E293B)
                                          : const Color(0xFF64748B),
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 8),
                  Text(
                    "Override Module Permissions",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...modulesList.map((module) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            module,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children:
                                actionsList.map((action) {
                                  final canonicalModule = module
                                      .toLowerCase()
                                      .replaceAll(' ', '_');
                                  final canonicalAction = action.toLowerCase();

                                  final hasBase =
                                      basePermissions[canonicalModule]
                                          ?.contains(canonicalAction) ??
                                      false;
                                  final isAdded =
                                      _localPermissionOverridesAdded[canonicalModule]
                                          ?.contains(canonicalAction) ??
                                      false;
                                  final isRemoved =
                                      _localPermissionOverridesRemoved[canonicalModule]
                                          ?.contains(canonicalAction) ??
                                      false;
                                  final isActive =
                                      (hasBase || isAdded) && !isRemoved;

                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: Checkbox(
                                          value: isActive,
                                          activeColor: const Color(0xFF10B981),
                                          onChanged:
                                              widget.isSuperAdmin
                                                  ? (val) {
                                                    _toggleLocalPermissionOverride(
                                                      module,
                                                      action,
                                                      val == true,
                                                      hasBase,
                                                    );
                                                  }
                                                  : null,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        action,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color:
                                              isActive
                                                  ? const Color(0xFF1E293B)
                                                  : const Color(0xFF94A3B8),
                                          fontWeight:
                                              isActive
                                                  ? FontWeight.w500
                                                  : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  if (_isDirty) ...[
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _resetLocalData();
                            });
                          },
                          child: Text(
                            "Discard Changes",
                            style: GoogleFonts.inter(
                              color: const Color(0xFFEF4444),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _applyChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            "Apply Changes",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
