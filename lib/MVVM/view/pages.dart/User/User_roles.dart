import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RoleModel {
  final String name;
  final String description;
  final int usersCount;
  final String status;
  final String createdAt;
  final String initials;
  final Color badgeColor;

  RoleModel({
    required this.name,
    required this.description,
    required this.usersCount,
    required this.status,
    required this.createdAt,
    required this.initials,
    required this.badgeColor,
  });
}

class UserRolesPage extends StatefulWidget {
  const UserRolesPage({super.key});

  @override
  State<UserRolesPage> createState() => _UserRolesPageState();
}

class _UserRolesPageState extends State<UserRolesPage> {
  String _searchQuery = "";
  String _selectedStatus = "All Status";

  final List<RoleModel> _roles = [
    RoleModel(
      name: "Super Admin",
      description: "Full access to all modules and settings.",
      usersCount: 2,
      status: "Active",
      createdAt: "Jan 10, 2024 10:30 AM",
      initials: "SA",
      badgeColor: const Color(0xFF8B5CF6),
    ),
    RoleModel(
      name: "Admin",
      description: "Access to manage most modules.",
      usersCount: 8,
      status: "Active",
      createdAt: "Jan 12, 2024 11:15 AM",
      initials: "A",
      badgeColor: const Color(0xFF3B82F6),
    ),
    RoleModel(
      name: "Moderator",
      description: "Can manage users, bookings and reports.",
      usersCount: 15,
      status: "Active",
      createdAt: "Jan 15, 2024 09:45 AM",
      initials: "MO",
      badgeColor: const Color(0xFF0D9488),
    ),
    RoleModel(
      name: "Support Manager",
      description: "Handle customer support and complaints.",
      usersCount: 12,
      status: "Active",
      createdAt: "Jan 18, 2024 02:20 PM",
      initials: "SM",
      badgeColor: const Color(0xFFF59E0B),
    ),
    RoleModel(
      name: "Customer Support",
      description: "Support users and resolve queries.",
      usersCount: 35,
      status: "Active",
      createdAt: "Jan 20, 2024 03:50 PM",
      initials: "CS",
      badgeColor: const Color(0xFFEC4899),
    ),
    RoleModel(
      name: "Viewer",
      description: "View only access to limited reports.",
      usersCount: 5,
      status: "Inactive",
      createdAt: "Feb 01, 2024 04:10 PM",
      initials: "V",
      badgeColor: const Color(0xFF64748B),
    ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;

        // Filter logic
        final filteredRoles =
            _roles.where((role) {
              final matchesSearch =
                  role.name.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  role.description.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  );
              final matchesStatus =
                  _selectedStatus == "All Status" ||
                  role.status == _selectedStatus;
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
                    onPressed: () => _showAddRoleDialog(context),
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
              _buildStatsCardsGrid(width),
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
  }

  Widget _buildStatsCardsGrid(double width) {
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

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: aspectRatio > 0 ? aspectRatio : 2.0,
      children: const [
        StatsCard(
          title: "Total Roles",
          value: "6",
          trendPeriod: "All user roles in the system",
          icon: Icons.people_alt_rounded,
          iconColor: Color(0xFF3B82F6),
          iconBgColor: Color(0xFFEFF6FF),
        ),
        StatsCard(
          title: "Active Roles",
          value: "5",
          trendPeriod: "Currently active roles",
          icon: Icons.check_circle_outline_rounded,
          iconColor: Color(0xFF10B981),
          iconBgColor: Color(0xFFECFDF5),
        ),
        StatsCard(
          title: "Inactive Roles",
          value: "1",
          trendPeriod: "Currently inactive roles",
          icon: Icons.cancel_outlined,
          iconColor: Color(0xFFF59E0B),
          iconBgColor: Color(0xFFFEF3C7),
        ),
        StatsCard(
          title: "Total Users by Roles",
          value: "12,458",
          trendPeriod: "Users across all roles",
          icon: Icons.group_add_rounded,
          iconColor: Color(0xFF8B5CF6),
          iconBgColor: Color(0xFFF5F3FF),
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
              width: 1000,
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(2.0), // Role Name + Initials badge
                  1: FlexColumnWidth(3.0), // Description
                  2: FlexColumnWidth(1.2), // Users count
                  3: FlexColumnWidth(1.2), // Status
                  4: FlexColumnWidth(2.0), // Created At
                  5: FlexColumnWidth(1.5), // Actions
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
                      _buildHeaderCell("Users"),
                      _buildHeaderCell("Status"),
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            role.description,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ),
                        // Users count with icon
                        Row(
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
                        _buildStatusIndicator(role.status),
                        Text(
                          role.createdAt,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        // Actions
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildActionButton(
                              Icons.edit_outlined,
                              Colors.blue,
                              "Edit",
                              () => _showEditRoleDialog(context, role),
                            ),
                            const SizedBox(width: 8),
                            _buildActionButton(
                              Icons.visibility_outlined,
                              const Color(0xFF10B981),
                              "View",
                              () => _showViewRoleDialog(context, role),
                            ),
                            const SizedBox(width: 8),
                            _buildActionButton(
                              Icons.delete_outline_rounded,
                              Colors.red,
                              "Delete",
                              () => _showDeleteConfirmation(context, role.name),
                            ),
                          ],
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

  Widget _buildHeaderCell(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
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

  void _showDeleteConfirmation(BuildContext context, String roleName) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              "Delete Role",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            content: Text(
              "Are you sure you want to delete the '$roleName' role? This action cannot be undone.",
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
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Role '$roleName' deleted successfully."),
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
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              "Add New Role",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    labelText: "Role Name",
                    labelStyle: GoogleFonts.inter(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: "Description",
                    labelStyle: GoogleFonts.inter(fontSize: 13),
                  ),
                ),
              ],
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
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Role added successfully.")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                ),
                child: Text("Save", style: GoogleFonts.inter()),
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
