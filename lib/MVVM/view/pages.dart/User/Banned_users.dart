import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BannedUserModel {
  final String name;
  final String userId;
  final String email;
  final String phone;
  final String reason;
  final String banType;
  final String bannedOn;
  final String bannedBy;
  final String banDuration;
  final String status;
  final String avatarUrl;

  BannedUserModel({
    required this.name,
    required this.userId,
    required this.email,
    required this.phone,
    required this.reason,
    required this.banType,
    required this.bannedOn,
    required this.bannedBy,
    required this.banDuration,
    required this.status,
    required this.avatarUrl,
  });
}

class BannedUsersPage extends StatefulWidget {
  const BannedUsersPage({super.key});

  @override
  State<BannedUsersPage> createState() => _BannedUsersPageState();
}

class _BannedUsersPageState extends State<BannedUsersPage> {
  String _searchQuery = "";
  String _selectedBanType = "All Types";
  String _selectedDuration = "All Durations";
  DateTimeRange? _selectedDateRange;

  final List<BannedUserModel> _bannedUsers = [
    BannedUserModel(
      name: "Rakesh Kumar",
      userId: "#USR1245",
      email: "rakesh.kumar@email.com",
      phone: "+91 98765 43210",
      reason: "Multiple fake bookings and cancellations",
      banType: "Permanent",
      bannedOn: "May 18, 2024 10:30 AM",
      bannedBy: "Admin (Super Admin)",
      banDuration: "-",
      status: "Banned",
      avatarUrl: "https://randomuser.me/api/portraits/men/1.jpg",
    ),
    BannedUserModel(
      name: "Priya Sharma",
      userId: "#USR1123",
      email: "priya.sharma@email.com",
      phone: "+91 98765 43211",
      reason: "Abusive behavior in chat",
      banType: "Temporary",
      bannedOn: "May 17, 2024 03:15 PM",
      bannedBy: "Admin (Moderator)",
      banDuration: "7 Days (May 24, 2024)",
      status: "Banned",
      avatarUrl: "https://randomuser.me/api/portraits/women/2.jpg",
    ),
    BannedUserModel(
      name: "Suresh Babu",
      userId: "#USR1098",
      email: "suresh.babu@email.com",
      phone: "+91 98765 43212",
      reason: "Violation of community guidelines",
      banType: "Permanent",
      bannedOn: "May 16, 2024 11:45 AM",
      bannedBy: "Admin (Super Admin)",
      banDuration: "-",
      status: "Banned",
      avatarUrl: "https://randomuser.me/api/portraits/men/3.jpg",
    ),
    BannedUserModel(
      name: "Arun Raj",
      userId: "#USR1087",
      email: "arun.raj@email.com",
      phone: "+91 98765 43213",
      reason: "Fraudulent payment activities",
      banType: "Permanent",
      bannedOn: "May 15, 2024 09:20 AM",
      bannedBy: "Admin (Super Admin)",
      banDuration: "-",
      status: "Banned",
      avatarUrl: "https://randomuser.me/api/portraits/men/4.jpg",
    ),
    BannedUserModel(
      name: "Meena Devi",
      userId: "#USR1056",
      email: "meena.devi@email.com",
      phone: "+91 98765 43214",
      reason: "Misuse of discount coupons",
      banType: "Temporary",
      bannedOn: "May 14, 2024 02:10 PM",
      bannedBy: "Admin (Moderator)",
      banDuration: "3 Days (May 17, 2024)",
      status: "Banned",
      avatarUrl: "https://randomuser.me/api/portraits/women/5.jpg",
    ),
    BannedUserModel(
      name: "Vikram Singh",
      userId: "#USR1044",
      email: "vikram.singh@email.com",
      phone: "+91 98765 43215",
      reason: "Spam and unwanted promotions",
      banType: "Temporary",
      bannedOn: "May 13, 2024 04:05 PM",
      bannedBy: "Admin (Moderator)",
      banDuration: "7 Days (May 20, 2024)",
      status: "Banned",
      avatarUrl: "https://randomuser.me/api/portraits/men/6.jpg",
    ),
    BannedUserModel(
      name: "Anjali Nair",
      userId: "#USR1007",
      email: "anjali.nair@email.com",
      phone: "+91 98765 43216",
      reason: "Harassment and inappropriate content",
      banType: "Permanent",
      bannedOn: "May 12, 2024 12:30 PM",
      bannedBy: "Admin (Super Admin)",
      banDuration: "-",
      status: "Banned",
      avatarUrl: "https://randomuser.me/api/portraits/women/7.jpg",
    ),
    BannedUserModel(
      name: "Manoj Varma",
      userId: "#USR0991",
      email: "manoj.varma@email.com",
      phone: "+91 98765 43217",
      reason: "Multiple account creation",
      banType: "Permanent",
      bannedOn: "May 11, 2024 08:50 AM",
      bannedBy: "Admin (Super Admin)",
      banDuration: "-",
      status: "Banned",
      avatarUrl: "https://randomuser.me/api/portraits/men/8.jpg",
    ),
  ];

  Widget _buildBreadcrumbs() {
    return Row(
      children: [
        Text(
          "Dashboard",
          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
        const Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF94A3B8)),
        Text(
          "User Management",
          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
        const Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF94A3B8)),
        Text(
          "Banned Users",
          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF0F172A), fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;

        // Apply filters
        final filteredUsers = _bannedUsers.where((user) {
          final matchesSearch = user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              user.phone.contains(_searchQuery) ||
              user.reason.toLowerCase().contains(_searchQuery.toLowerCase());

          final matchesType = _selectedBanType == "All Types" || user.banType == _selectedBanType;
          final matchesDuration = _selectedDuration == "All Durations" ||
              (_selectedDuration == "1 Day" && user.banDuration.contains("1 Day")) ||
              (_selectedDuration == "7 Days" && user.banDuration.contains("7 Days")) ||
              (_selectedDuration == "30 Days" && user.banDuration.contains("30 Days"));

          return matchesSearch && matchesType && matchesDuration;
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Breadcrumbs
              _buildBreadcrumbs(),
              const SizedBox(height: 8),

              // Page Title
              Text(
                "Banned Users Management",
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 24),

              // Stats Cards
              _buildStatsGrid(width),
              const SizedBox(height: 24),

              // Filter Controls
              _buildFilterRow(context, width),
              const SizedBox(height: 24),

              // Banned Users Table
              _buildBannedTable(filteredUsers),
              const SizedBox(height: 16),

              // Table Footer
              _buildTableFooter(filteredUsers.length),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsGrid(double width) {
    int crossAxisCount = 4;
    if (width < 600) {
      crossAxisCount = 1;
    } else if (width < 1100) {
      crossAxisCount = 2;
    }

    final double itemWidth = (width - (crossAxisCount - 1) * 16) / crossAxisCount;
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
          title: "Total Banned Users",
          value: "86",
          trendPeriod: "Users are banned from the platform",
          icon: Icons.person_off_rounded,
          iconColor: Color(0xFFEF4444),
          iconBgColor: Color(0xFFFEF2F2),
        ),
        StatsCard(
          title: "This Month",
          value: "12",
          trendPeriod: "Users banned this month",
          icon: Icons.calendar_month_rounded,
          iconColor: Color(0xFFF59E0B),
          iconBgColor: Color(0xFFFEF3C7),
        ),
        StatsCard(
          title: "Permanent Bans",
          value: "64",
          trendPeriod: "Permanent banned users",
          icon: Icons.lock_outline_rounded,
          iconColor: Color(0xFF6366F1),
          iconBgColor: Color(0xFFEEF2FF),
        ),
        StatsCard(
          title: "Temporary Bans",
          value: "22",
          trendPeriod: "Temporary banned users",
          icon: Icons.timer_outlined,
          iconColor: Color(0xFF3B82F6),
          iconBgColor: Color(0xFFEFF6FF),
        ),
      ],
    );
  }

  Widget _buildFilterRow(BuildContext context, double width) {
    final bool isSmall = width < 800;

    final searchField = SizedBox(
      width: isSmall ? double.infinity : 280,
      height: 38,
      child: TextFormField(
        onChanged: (val) => setState(() {
          _searchQuery = val;
        }),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          fillColor: Colors.white,
          filled: true,
          hintText: "Search by name, email or phone...",
          hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12),
          prefixIcon: const Icon(CupertinoIcons.search, color: Color(0xFF94A3B8), size: 16),
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

    final typeDropdown = SizedBox(
      width: isSmall ? double.infinity : 140,
      height: 38,
      child: DropdownButtonFormField<String>(
        initialValue: _selectedBanType,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        items: ["All Types", "Permanent", "Temporary"]
            .map((type) => DropdownMenuItem(value: type, child: Text(type)))
            .toList(),
        onChanged: (val) => setState(() {
          _selectedBanType = val!;
        }),
      ),
    );

    final durationDropdown = SizedBox(
      width: isSmall ? double.infinity : 150,
      height: 38,
      child: DropdownButtonFormField<String>(
        initialValue: _selectedDuration,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        items: ["All Durations", "1 Day", "7 Days", "30 Days"]
            .map((duration) => DropdownMenuItem(value: duration, child: Text(duration)))
            .toList(),
        onChanged: (val) => setState(() {
          _selectedDuration = val!;
        }),
      ),
    );

    final dateRangeButton = InkWell(
      onTap: () async {
        final DateTimeRange? picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          initialDateRange: _selectedDateRange,
        );
        if (picked != null) {
          setState(() {
            _selectedDateRange = picked;
          });
        }
      },
      child: Container(
        width: isSmall ? double.infinity : 180,
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _selectedDateRange == null
                    ? "Select Date Range"
                    : "${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}",
                style: GoogleFonts.inter(color: const Color(0xFF475569), fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF64748B)),
          ],
        ),
      ),
    );

    final exportButton = ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.download_rounded, size: 14),
      label: Text("Export", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
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
          Row(
            children: [
              Expanded(child: typeDropdown),
              const SizedBox(width: 12),
              Expanded(child: durationDropdown),
            ],
          ),
          const SizedBox(height: 12),
          dateRangeButton,
          const SizedBox(height: 16),
          Align(alignment: Alignment.centerRight, child: exportButton),
        ],
      );
    } else {
      return Row(
        children: [
          searchField,
          const SizedBox(width: 12),
          typeDropdown,
          const SizedBox(width: 12),
          durationDropdown,
          const SizedBox(width: 12),
          dateRangeButton,
          const Spacer(),
          exportButton,
        ],
      );
    }
  }

  String _formatDate(DateTime date) {
    final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return "${months[date.month - 1]} ${date.day}, ${date.year}";
  }

  Widget _buildBannedTable(List<BannedUserModel> users) {
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
              width: 1200,
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(2.0), // User Profile
                  1: FlexColumnWidth(2.2), // Email / Phone
                  2: FlexColumnWidth(2.5), // Reason
                  3: FlexColumnWidth(1.2), // Ban Type Badge
                  4: FlexColumnWidth(1.8), // Banned On
                  5: FlexColumnWidth(1.8), // Banned By
                  6: FlexColumnWidth(1.8), // Ban Duration
                  7: FlexColumnWidth(1.0), // Status
                  8: FlexColumnWidth(1.6), // Actions
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  // Table Header
                  TableRow(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
                    ),
                    children: [
                      _buildHeaderCell("User"),
                      _buildHeaderCell("Email / Phone"),
                      _buildHeaderCell("Reason"),
                      _buildHeaderCell("Ban Type"),
                      _buildHeaderCell("Banned On"),
                      _buildHeaderCell("Banned By"),
                      _buildHeaderCell("Ban Duration"),
                      _buildHeaderCell("Status"),
                      _buildHeaderCell("Actions"),
                    ],
                  ),

                  // Table Rows
                  ...users.map((user) {
                    return TableRow(
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
                      ),
                      children: [
                        // User Profile column
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  user.avatarUrl,
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 32,
                                      height: 32,
                                      color: const Color(0xFFE2E8F0),
                                      child: const Icon(Icons.person, color: Color(0xFF64748B), size: 16),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.name,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      user.userId,
                                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Email / Phone details
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.email, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1E293B))),
                              const SizedBox(height: 2),
                              Text(user.phone, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            user.reason,
                            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569)),
                          ),
                        ),
                        _buildBanTypeBadge(user.banType),
                        Text(
                          user.bannedOn,
                          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                        ),
                        Text(
                          user.bannedBy,
                          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569)),
                        ),
                        Text(
                          user.banDuration,
                          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569)),
                        ),
                        _buildStatusBadge(user.status),
                        // Actions row
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildActionButton(Icons.visibility_outlined, Colors.blue, () {}),
                            const SizedBox(width: 8),
                            _buildActionButton(Icons.restore_page_rounded, Colors.grey, () {
                              _showUnbanConfirmation(context, user.name);
                            }),
                            const SizedBox(width: 8),
                            _buildActionButton(Icons.delete_outline_rounded, Colors.red, () {
                              _showDeleteConfirmation(context, user.name);
                            }),
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

  Widget _buildBanTypeBadge(String type) {
    final bool isPermanent = type == "Permanent";
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isPermanent ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          type,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isPermanent ? const Color(0xFFEF4444) : const Color(0xFFD97706),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          status,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFEF4444),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: color, size: 14),
      ),
    );
  }

  Widget _buildTableFooter(int totalFiltered) {
    return Row(
      children: [
        Text(
          "Showing 1 to $totalFiltered of 86 banned users",
          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
        ),
        const Spacer(),
        Row(
          children: [
            const IconButton(
              icon: Icon(Icons.chevron_left_rounded, size: 18),
              onPressed: null,
            ),
            ...[1, 2, 3, 4, 5].map((page) {
              final bool isSelected = page == 1;
              return InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      page.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
              );
            }),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, size: 18),
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 110,
          height: 32,
          child: DropdownButtonFormField<int>(
            initialValue: 10,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            style: GoogleFonts.inter(color: const Color(0xFF1E293B), fontSize: 11),
            items: const [
              DropdownMenuItem(value: 10, child: Text("10 / page")),
            ],
            onChanged: (val) {},
          ),
        ),
      ],
    );
  }

  void _showUnbanConfirmation(BuildContext context, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Restore User", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to restore and unban '$name'? they will regain access to their account.", style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("User '$name' has been restored and unbanned.")),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: Text("Restore", style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete User Permanently", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to permanently delete the profile of '$name'? This action is irreversible.", style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("User '$name' deleted permanently.")),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: Text("Delete Permanently", style: GoogleFonts.inter()),
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
