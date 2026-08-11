import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swiftclean_admin/MVVM/model/models/admin_model.dart';
import 'package:swiftclean_admin/MVVM/utils/printer_helper.dart';
import 'package:swiftclean_admin/MVVM/utils/rbac_session.dart';

class SuspendedUserModel {
  final String name;
  final String userId;
  final String email;
  final String phone;
  final String reason;
  final String suspensionType;
  final String suspendedOn;
  final String suspendedBy;
  final String suspensionDuration;
  final String status;
  final String avatarUrl;

  SuspendedUserModel({
    required this.name,
    required this.userId,
    required this.email,
    required this.phone,
    required this.reason,
    required this.suspensionType,
    required this.suspendedOn,
    required this.suspendedBy,
    required this.suspensionDuration,
    required this.status,
    required this.avatarUrl,
  });
}

class SuspendedUsersPage extends StatefulWidget {
  const SuspendedUsersPage({super.key});

  @override
  State<SuspendedUsersPage> createState() => _SuspendedUsersPageState();
}

class _SuspendedUsersPageState extends State<SuspendedUsersPage> {
  String _searchQuery = "";
  String _selectedsuspensionType = "All Types";
  String _selectedDuration = "All Durations";
  DateTimeRange? _selectedDateRange;

  List<DocumentSnapshot> _suspendedDocs = [];
  bool _isLoading = false;

  final Set<String> _selectedUserIds = {};

  Future<void> _bulkRestoreUsers() async {
    if (_selectedUserIds.isEmpty) return;

    if (!RbacSession().hasPermission('user_management', 'suspend_user')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Access Denied: You do not have permission to restore users."), backgroundColor: Colors.red));
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
            child: CircularProgressIndicator(color: Color(0xFFEF4444)),
          ),
    );

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final id in _selectedUserIds) {
        final docRef = FirebaseFirestore.instance.collection('users').doc(id);
        batch.update(docRef, {
          'status': 'Active',
          'suspensionType': FieldValue.delete(),
          'suspensionDuration': FieldValue.delete(),
          'suspendedOn': FieldValue.delete(),
          'suspendedBy': FieldValue.delete(),
          'banReason': FieldValue.delete(),
          'reason': FieldValue.delete(),
        });
      }
      await batch.commit();

      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedUserIds.length} users restored successfully.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _selectedUserIds.clear();
        });
        _fetchSuspendedUsers(); // Refresh
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error restoring users: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _bulkDeleteUsers() async {
    if (_selectedUserIds.isEmpty) return;

    if (!RbacSession().hasPermission('user_management', 'delete')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Access Denied: You do not have permission to delete users."), backgroundColor: Colors.red));
      return;
    }

    // Show confirmation dialog first
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              "Delete Users",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            content: Text(
              "Are you sure you want to permanently delete ${_selectedUserIds.length} users? This action cannot be undone.",
              style: GoogleFonts.inter(),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.inter(color: Colors.grey.shade700),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Delete",
                  style: GoogleFonts.inter(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
            child: CircularProgressIndicator(color: Color(0xFFEF4444)),
          ),
    );

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final id in _selectedUserIds) {
        final docRef = FirebaseFirestore.instance.collection('users').doc(id);
        batch.delete(docRef);
      }
      await batch.commit();

      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedUserIds.length} users deleted successfully.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _selectedUserIds.clear();
        });
        _fetchSuspendedUsers(); // Refresh
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting users: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSelectionActionBar(double width) {
    final bool isSmall = width < 600;
    final bool canDelete = RbacSession().hasPermission(
      'user_management',
      'delete',
    );
    final bool canRestore = RbacSession().hasPermission(
      'user_management',
      'suspend_user',
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Dark slate background
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child:
          isSmall
              ? Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Color(0xFF0F172A),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "${_selectedUserIds.length} users selected",
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (canRestore) ...[
                            _buildActionOutlineButton(
                              icon: Icons.restore_page_rounded,
                              label: "Restore",
                              color: const Color(0xFFD97706),
                              onPressed: _bulkRestoreUsers,
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (canDelete)
                            _buildActionOutlineButton(
                              icon: Icons.delete_outline_rounded,
                              label: "Delete",
                              color: const Color(0xFFEF4444),
                              onPressed: _bulkDeleteUsers,
                            ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed:
                            () => setState(() => _selectedUserIds.clear()),
                        icon: const Icon(
                          Icons.close,
                          color: Color(0xFF94A3B8),
                          size: 16,
                        ),
                        label: Text(
                          "Clear",
                          style: GoogleFonts.inter(
                            color: const Color(0xFF94A3B8),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
              : Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Color(0xFF0F172A),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "${_selectedUserIds.length} users selected",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  if (canRestore) ...[
                    _buildActionOutlineButton(
                      icon: Icons.restore_page_rounded,
                      label: "Restore All",
                      color: const Color(0xFFD97706), // Orange
                      onPressed: _bulkRestoreUsers,
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (canDelete)
                    _buildActionOutlineButton(
                      icon: Icons.delete_outline_rounded,
                      label: "Delete All",
                      color: const Color(0xFFEF4444), // Red
                      onPressed: _bulkDeleteUsers,
                    ),
                  const SizedBox(width: 16),
                  TextButton.icon(
                    onPressed: () => setState(() => _selectedUserIds.clear()),
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFF94A3B8),
                      size: 16,
                    ),
                    label: Text(
                      "Clear",
                      style: GoogleFonts.inter(
                        color: const Color(0xFF94A3B8),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildActionOutlineButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: color, size: 16),
      label: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: color.withOpacity(0.1),
      ),
    );
  }

  // Table scroll controllers for sticky header + scrollable body
  final ScrollController _suspendedTableVerticalController = ScrollController();
  final ScrollController _suspendedTableHorizontalHeaderController =
      ScrollController();
  final ScrollController _suspendedTableHorizontalBodyController =
      ScrollController();
  bool _isSuspendedSyncingScroll = false;

  @override
  void initState() {
    super.initState();
    _fetchSuspendedUsers();
    _suspendedTableHorizontalHeaderController.addListener(
      _onSuspendedHeaderHScroll,
    );
    _suspendedTableHorizontalBodyController.addListener(
      _onSuspendedBodyHScroll,
    );
  }

  @override
  void dispose() {
    _suspendedTableVerticalController.dispose();
    _suspendedTableHorizontalHeaderController.dispose();
    _suspendedTableHorizontalBodyController.dispose();
    super.dispose();
  }

  void _onSuspendedHeaderHScroll() {
    if (_isSuspendedSyncingScroll) return;
    _isSuspendedSyncingScroll = true;
    if (_suspendedTableHorizontalBodyController.hasClients) {
      _suspendedTableHorizontalBodyController.jumpTo(
        _suspendedTableHorizontalHeaderController.offset,
      );
    }
    _isSuspendedSyncingScroll = false;
  }

  void _onSuspendedBodyHScroll() {
    if (_isSuspendedSyncingScroll) return;
    _isSuspendedSyncingScroll = true;
    if (_suspendedTableHorizontalHeaderController.hasClients) {
      _suspendedTableHorizontalHeaderController.jumpTo(
        _suspendedTableHorizontalBodyController.offset,
      );
    }
    _isSuspendedSyncingScroll = false;
  }

  Future<void> _fetchSuspendedUsers() async {
    setState(() => _isLoading = true);
    try {
      final snap =
          await FirebaseFirestore.instance
              .collection("users")
              .where("status", whereIn: ["Suspended", "Suspended"])
              .get();
      setState(() {
        _suspendedDocs = snap.docs;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching Suspended Users: $e");
      setState(() => _isLoading = false);
    }
  }

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
          "Suspended Users",
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

        final List<SuspendedUserModel> SuspendedUsersList =
            _suspendedDocs.asMap().entries.map((entry) {
              final doc = entry.value;
              final data = doc.data() as Map<String, dynamic>? ?? {};
              final name = data['name'] ?? data['username'] ?? 'User';
              final email = data['email'] ?? 'No email';
              final phone = data['phone'] ?? 'No phone';
              final reason =
                  data['banReason'] ??
                  data['reason'] ??
                  'Violation of community guidelines';
              final suspensionType = data['suspensionType'] ?? 'Suspended';
              final suspendedOn =
                  data['suspendedOn'] ?? data['joinedDate'] ?? 'Recently';
              final suspendedBy = data['suspendedBy'] ?? 'Admin';
              final suspensionDuration = data['suspensionDuration'] ?? '-';

              return SuspendedUserModel(
                name: name,
                userId: doc.id,
                email: email,
                phone: phone,
                reason: reason,
                suspensionType: suspensionType,
                suspendedOn: suspendedOn,
                suspendedBy: suspendedBy,
                suspensionDuration: suspensionDuration,
                status: "Suspended",
                avatarUrl:
                    "https://randomuser.me/api/portraits/men/${entry.key % 10 + 1}.jpg",
              );
            }).toList();

        // Apply filters
        final filteredUsers =
            SuspendedUsersList.where((user) {
              final matchesSearch =
                  user.name.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  user.email.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  user.phone.contains(_searchQuery) ||
                  user.reason.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  );

              final matchesType =
                  _selectedsuspensionType == "All Types" ||
                  user.suspensionType == _selectedsuspensionType;
              final matchesDuration =
                  _selectedDuration == "All Durations" ||
                  (_selectedDuration == "1 Day" &&
                      user.suspensionDuration.contains("1 Day")) ||
                  (_selectedDuration == "7 Days" &&
                      user.suspensionDuration.contains("7 Days")) ||
                  (_selectedDuration == "30 Days" &&
                      user.suspensionDuration.contains("30 Days"));

              bool matchesDate = true;
              if (_selectedDateRange != null) {
                try {
                  DateTime? cellDateTime = DateTime.tryParse(user.suspendedOn);
                  if (cellDateTime == null) {
                    final parts = user.suspendedOn
                        .replaceAll(',', '')
                        .split(' ');
                    if (parts.length >= 3) {
                      const months = {
                        'Jan': 1,
                        'Feb': 2,
                        'Mar': 3,
                        'Apr': 4,
                        'May': 5,
                        'Jun': 6,
                        'Jul': 7,
                        'Aug': 8,
                        'Sep': 9,
                        'Oct': 10,
                        'Nov': 11,
                        'Dec': 12,
                      };
                      final month = months[parts[0]];
                      final day = int.tryParse(parts[1]);
                      final year = int.tryParse(parts[2]);
                      if (month != null && day != null && year != null) {
                        cellDateTime = DateTime(year, month, day);
                      }
                    }
                  }
                  if (cellDateTime != null) {
                    final rangeEnd = _selectedDateRange!.end.add(
                      const Duration(days: 1),
                    );
                    if (cellDateTime.isBefore(_selectedDateRange!.start) ||
                        cellDateTime.isAfter(rangeEnd)) {
                      matchesDate = false;
                    }
                  }
                } catch (_) {}
              }

              return matchesSearch &&
                  matchesType &&
                  matchesDuration &&
                  matchesDate;
            }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selection Action Bar
              if (_selectedUserIds.isNotEmpty) ...[
                _buildSelectionActionBar(width),
                const SizedBox(height: 24),
              ],

              // Breadcrumbs
              _buildBreadcrumbs(),
              const SizedBox(height: 8),

              // Page Title
              Text(
                "Suspended Users Management",
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 24),

              // Stats Cards
              _buildStatsGrid(width, SuspendedUsersList),
              const SizedBox(height: 24),

              // Filter Controls
              _buildFilterRow(context, width, filteredUsers),
              const SizedBox(height: 24),

              // Suspended Users Table
              _isLoading
                  ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  )
                  : _buildsuspendedTable(filteredUsers),
              const SizedBox(height: 16),

              // Table Footer
              _buildTableFooter(
                filteredUsers.length,
                SuspendedUsersList.length,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsGrid(
    double width,
    List<SuspendedUserModel> SuspendedUsersList,
  ) {
    int crossAxisCount = 3;
    if (width < 600) {
      crossAxisCount = 1;
    } else if (width < 1100) {
      crossAxisCount = 2;
    }

    final double itemWidth =
        (width - (crossAxisCount - 1) * 16) / crossAxisCount;
    const double itemHeight = 115;
    final double aspectRatio = itemWidth / itemHeight;

    final totalSuspended = SuspendedUsersList.length;
    final permanentBans =
        SuspendedUsersList.where((u) => u.suspensionType == "Suspended").length;
    final temporaryBans =
        SuspendedUsersList.where((u) => u.suspensionType == "Temporary").length;

    int thisMonthBans = 0;
    try {
      final now = DateTime.now();
      final monthsShort = [
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
      final currentMonthStr = monthsShort[now.month - 1];
      final currentYearStr = now.year.toString();
      thisMonthBans =
          SuspendedUsersList.where((u) {
            return (u.suspendedOn.contains(currentMonthStr) &&
                    u.suspendedOn.contains(currentYearStr)) ||
                u.suspendedOn == 'Recently';
          }).length;
    } catch (_) {}

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: aspectRatio > 0 ? aspectRatio : 2.0,
      children: [
        StatsCard(
          title: "Total Suspended Users",
          value: totalSuspended.toString(),
          trendPeriod: "Users are Suspended from the platform",
          icon: Icons.person_off_rounded,
          iconColor: const Color(0xFFEF4444),
          iconBgColor: const Color(0xFFFEF2F2),
        ),
        StatsCard(
          title: "This Month",
          value: thisMonthBans.toString(),
          trendPeriod: "Users Suspended this month",
          icon: Icons.calendar_month_rounded,
          iconColor: const Color(0xFFF59E0B),
          iconBgColor: const Color(0xFFFEF3C7),
        ),
        StatsCard(
          title: "Suspended",
          value: permanentBans.toString(),
          trendPeriod: "Suspended Users",
          icon: Icons.lock_outline_rounded,
          iconColor: const Color(0xFF6366F1),
          iconBgColor: const Color(0xFFEEF2FF),
        ),
      ],
    );
  }

  Widget _buildFilterRow(
    BuildContext context,
    double width,
    List<SuspendedUserModel> filteredUsers,
  ) {
    final bool isSmall = width < 800;

    final searchField = SizedBox(
      width: isSmall ? double.infinity : 280,
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
          hintText: "Search by name, email or phone...",
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

    final exportButton = ElevatedButton.icon(
      onPressed: () {
        // ignore: argument_type_not_assignable
        printSuspendedUsersList(filteredUsers);
      },
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
          const SizedBox(height: 16),
          Align(alignment: Alignment.centerRight, child: exportButton),
        ],
      );
    } else {
      return Row(children: [searchField, const Spacer(), exportButton]);
    }
  }

  String _formatDate(DateTime date) {
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
    return "${months[date.month - 1]} ${date.day}, ${date.year}";
  }

  Widget _buildsuspendedTable(List<SuspendedUserModel> users) {
    final bool canSelectUsers =
        RbacSession().hasPermission('user_management', 'delete') ||
        RbacSession().hasPermission('user_management', 'ban_user');

    const columnWidths = <int, TableColumnWidth>{
      0: FlexColumnWidth(0.5), // Checkbox
      1: FlexColumnWidth(2.6), // User Profile
      2: FlexColumnWidth(2.6), // Email / Phone
      3: FlexColumnWidth(2.3), // Reason
      4: FlexColumnWidth(1.5), // Suspended On
      5: FlexColumnWidth(1.4), // Suspended By
      6: FlexColumnWidth(1.4), // Status
      7: FlexColumnWidth(1.6), // Actions
    };
    const double tableWidth = 1450;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F3F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // â”€â”€ STICKY HEADER â”€â”€
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _suspendedTableHorizontalHeaderController,
            physics: const ClampingScrollPhysics(),
            child: SizedBox(
              width: tableWidth,
              child: Table(
                columnWidths: columnWidths,
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child:
                            canSelectUsers
                                ? Checkbox(
                                  value:
                                      users.isNotEmpty &&
                                      _selectedUserIds.length == users.length,
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selectedUserIds.addAll(
                                          users.map((e) => e.userId),
                                        );
                                      } else {
                                        _selectedUserIds.clear();
                                      }
                                    });
                                  },
                                  activeColor: const Color(0xFFD97706),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                )
                                : const SizedBox(),
                      ),
                      _buildHeaderCell("User"),
                      _buildHeaderCell("Email / Phone"),
                      _buildHeaderCell("Reason"),
                      _buildHeaderCell("Suspended On"),
                      _buildHeaderCell("Suspended By"),
                      _buildHeaderCell("Status"),
                      _buildHeaderCell("Actions"),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // â”€â”€ SCROLLABLE BODY â”€â”€
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 500),
            child: Scrollbar(
              thumbVisibility: true,
              controller: _suspendedTableVerticalController,
              child: Scrollbar(
                thumbVisibility: true,
                controller: _suspendedTableHorizontalBodyController,
                notificationPredicate:
                    (notification) => notification.depth == 1,
                child: SingleChildScrollView(
                  controller: _suspendedTableVerticalController,
                  physics: const ClampingScrollPhysics(),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    controller: _suspendedTableHorizontalBodyController,
                    physics: const ClampingScrollPhysics(),
                    child: SizedBox(
                      width: tableWidth,
                      child: Table(
                        columnWidths: columnWidths,
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        children: [
                          ...users.map((user) {
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
                                // Checkbox column
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                  ),
                                  child:
                                      canSelectUsers
                                          ? Checkbox(
                                            value: _selectedUserIds.contains(
                                              user.userId,
                                            ),
                                            onChanged: (val) {
                                              setState(() {
                                                if (val == true) {
                                                  _selectedUserIds.add(
                                                    user.userId,
                                                  );
                                                } else {
                                                  _selectedUserIds.remove(
                                                    user.userId,
                                                  );
                                                }
                                              });
                                            },
                                            activeColor: const Color(
                                              0xFFD97706,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          )
                                          : const SizedBox(),
                                ),
                                // User Profile column
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10.0,
                                    horizontal: 16.0,
                                  ),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.network(
                                          user.avatarUrl,
                                          width: 32,
                                          height: 32,
                                          fit: BoxFit.cover,
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return Container(
                                              width: 32,
                                              height: 32,
                                              color: const Color(0xFFE2E8F0),
                                              child: const Icon(
                                                Icons.person,
                                                color: Color(0xFF64748B),
                                                size: 16,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: const Color(0xFF94A3B8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Email / Phone
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10.0,
                                    horizontal: 16.0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.email,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: const Color(0xFF1E293B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        user.phone,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Reason
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10.0,
                                    horizontal: 16.0,
                                  ),
                                  child: Text(
                                    user.reason,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFF475569),
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // Suspended On
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10.0,
                                    horizontal: 16.0,
                                  ),
                                  child: Text(
                                    user.suspendedOn,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                                // Suspended By
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10.0,
                                    horizontal: 16.0,
                                  ),
                                  child: Text(
                                    user.suspendedBy,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                                _buildStatusBadge(user.status),
                                // Actions row
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildActionButton(
                                      Icons.visibility_outlined,
                                      Colors.blue,
                                      () {
                                        _showSuspendedUserDetailsDialog(
                                          context,
                                          user,
                                        );
                                      },
                                      'view',
                                    ),
                                    const SizedBox(width: 8),
                                    _buildActionButton(
                                      Icons.restore_page_rounded,
                                      Colors.grey,
                                      () {
                                        _showUnbanConfirmation(context, user);
                                      },
                                      'suspend_user',
                                    ),
                                    if (RbacSession().hasPermission(Modules.userManagement, 'delete')) ...[
                                      const SizedBox(width: 8),
                                      _buildActionButton(
                                        Icons.delete_outline_rounded,
                                        Colors.red,
                                        () {
                                          _showDeleteConfirmation(context, user);
                                        },
                                        'delete',
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
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

  Widget _buildsuspensionTypeBadge(String type) {
    final bool isPermanent = type == "Suspended";
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color:
              isPermanent ? const Color(0xFFFFFBEB) : const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          type,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color:
                isPermanent ? const Color(0xFFD97706) : const Color(0xFFD97706),
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
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          status,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFD97706),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    Color color,
    VoidCallback onTap, [
    String? permissionAction,
  ]) {
    if (permissionAction != null &&
        !RbacSession().hasPermission(
          Modules.userManagement,
          permissionAction,
        )) {
      return const SizedBox.shrink();
    }
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

  Widget _buildTableFooter(int totalFiltered, int totalSuspended) {
    return Row(
      children: [
        Text(
          "Showing 1 to $totalFiltered of $totalSuspended Suspended Users",
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF64748B),
          ),
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
                    color:
                        isSelected
                            ? const Color(0xFF10B981)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      page.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color:
                            isSelected ? Colors.white : const Color(0xFF475569),
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

  void _showUnbanConfirmation(BuildContext context, SuspendedUserModel user) {
    if (!RbacSession().hasPermission(Modules.userManagement, 'suspend_user')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Access Denied: You do not have permission to unsuspend users.",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            title: Text(
              "Restore User",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            content: Text(
              "Are you sure you want to restore and unban '${user.name}'? they will regain access to their account.",
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
                  try {
                    await FirebaseFirestore.instance
                        .collection("users")
                        .doc(user.userId)
                        .update({"status": "Active"});
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "User '${user.name}' has been restored and unSuspended.",
                        ),
                      ),
                    );
                    _fetchSuspendedUsers();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error restoring user: $e")),
                    );
                  }
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

  void _showDeleteConfirmation(BuildContext context, SuspendedUserModel user) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            title: Text(
              "Delete User Permanently",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            content: Text(
              "Are you sure you want to permanently delete the profile of '${user.name}'? This action is irreversible.",
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
                  try {
                    await FirebaseFirestore.instance
                        .collection("users")
                        .doc(user.userId)
                        .delete();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "User '${user.name}' deleted permanently.",
                        ),
                      ),
                    );
                    _fetchSuspendedUsers();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error deleting user: $e")),
                    );
                  }
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

  void _showSuspendedUserDetailsDialog(
    BuildContext context,
    SuspendedUserModel user,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              width: 500,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFD97706),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_off_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Suspended User Details",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  // Body
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: const Color(0xFFFFFBEB),
                              backgroundImage: NetworkImage(user.avatarUrl),
                              onBackgroundImageError: (_, __) {},
                              child:
                                  user.avatarUrl.isEmpty
                                      ? const Icon(
                                        Icons.person,
                                        size: 30,
                                        color: Color(0xFFD97706),
                                      )
                                      : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "ID: ${user.userId}",
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "Suspended",
                                style: GoogleFonts.inter(
                                  color: const Color(0xFFD97706),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(color: Color(0xFFF1F5F9)),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          "Email Address",
                          user.email,
                          Icons.email_outlined,
                        ),
                        _buildDetailRow(
                          "Phone Number",
                          user.phone,
                          Icons.phone_outlined,
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Color(0xFFF1F5F9)),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          "Ban Type",
                          user.suspensionType,
                          Icons.lock_outline_rounded,
                        ),
                        _buildDetailRow(
                          "Ban Duration",
                          user.suspensionDuration,
                          Icons.timer_outlined,
                        ),
                        _buildDetailRow(
                          "Suspended On",
                          user.suspendedOn,
                          Icons.calendar_today_rounded,
                        ),
                        _buildDetailRow(
                          "Suspended By",
                          user.suspendedBy,
                          Icons.admin_panel_settings_outlined,
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Color(0xFFF1F5F9)),
                        const SizedBox(height: 16),
                        Text(
                          "Violation Reason",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAFBFD),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            user.reason,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF475569),
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Footer
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            "Close",
                            style: GoogleFonts.inter(
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF1E293B),
                fontWeight: FontWeight.w500,
              ),
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

class PremiumDateRangePickerDialog extends StatefulWidget {
  final DateTimeRange? initialDateRange;

  const PremiumDateRangePickerDialog({super.key, this.initialDateRange});

  @override
  State<PremiumDateRangePickerDialog> createState() =>
      _PremiumDateRangePickerDialogState();
}

class _PremiumDateRangePickerDialogState
    extends State<PremiumDateRangePickerDialog> {
  late DateTime _currentMonth;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialDateRange?.start;
    _endDate = widget.initialDateRange?.end;
    _currentMonth = _startDate ?? DateTime.now();
  }

  String _formatDateString(DateTime? date) {
    if (date == null) return "";
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
    return "${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}";
  }

  String _formatHeaderDate(DateTimeRange? range) {
    if (range == null) return "No date selected";
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
    return "${months[range.start.month - 1]} ${range.start.day} â€“ ${months[range.end.month - 1]} ${range.end.day}";
  }

  int _daysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  String _getMonthName(int month) {
    final months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDayInstance = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    );
    final int firstDayOffset = firstDayInstance.weekday % 7;
    final int totalDays = _daysInMonth(_currentMonth);

    final bool hasSelection = _startDate != null && _endDate != null;
    final int daysCount =
        hasSelection ? _endDate!.difference(_startDate!).inDays + 1 : 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 18,
      backgroundColor: const Color(0xFFFCFCFD),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 440,
        decoration: BoxDecoration(
          color: const Color(0xFFFCFCFD),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 40,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // â”€â”€ Header (Gradient) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Container(
              height: 90,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "SELECT DATE RANGE",
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasSelection
                              ? _formatHeaderDate(
                                DateTimeRange(
                                  start: _startDate!,
                                  end: _endDate!,
                                ),
                              )
                              : "Choose Date Range",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // â”€â”€ Body â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // â”€â”€ Selected Range Summary or Empty State â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child:
                        hasSelection
                            ? Container(
                              key: const ValueKey('summary_selected'),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFA7F3D0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.calendar_today_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Selected Range",
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF065F46),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(
                                              _formatDateString(_startDate),
                                              style: GoogleFonts.inter(
                                                color: const Color(0xFF047857),
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            const Icon(
                                              Icons.arrow_right_alt_rounded,
                                              color: Color(0xFF059669),
                                              size: 16,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              _formatDateString(_endDate),
                                              style: GoogleFonts.inter(
                                                color: const Color(0xFF047857),
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD1FAE5),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      "$daysCount Days",
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF065F46),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : Container(
                              key: const ValueKey('summary_empty'),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE2E8F0),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.calendar_month_rounded,
                                      color: Color(0xFF64748B),
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Choose a date range",
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF1E293B),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          "Filter reports between any two dates.",
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF64748B),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                  ),
                  const SizedBox(height: 20),

                  // â”€â”€ Month Selector Row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${_getMonthName(_currentMonth.month)} ${_currentMonth.year}",
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Row(
                        children: [
                          _buildNavButton(
                            icon: Icons.chevron_left_rounded,
                            onTap: () {
                              setState(() {
                                _currentMonth = DateTime(
                                  _currentMonth.year,
                                  _currentMonth.month - 1,
                                  1,
                                );
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildNavButton(
                            icon: Icons.chevron_right_rounded,
                            onTap: () {
                              setState(() {
                                _currentMonth = DateTime(
                                  _currentMonth.year,
                                  _currentMonth.month + 1,
                                  1,
                                );
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // â”€â”€ Calendar Month Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children:
                              ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"].map((
                                day,
                              ) {
                                return Expanded(
                                  child: Center(
                                    child: Text(
                                      day,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                        const SizedBox(height: 8),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                childAspectRatio: 1.1,
                              ),
                          itemCount: totalDays + firstDayOffset,
                          itemBuilder: (context, index) {
                            if (index < firstDayOffset) {
                              return const SizedBox.shrink();
                            }
                            final int dayNum = index - firstDayOffset + 1;
                            final DateTime cellDate = DateTime(
                              _currentMonth.year,
                              _currentMonth.month,
                              dayNum,
                            );

                            return _buildDayCell(cellDate, dayNum, now);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // â”€â”€ Action Buttons â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  Row(
                    children: [
                      if (_startDate != null || _endDate != null)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _startDate = null;
                              _endDate = null;
                            });
                          },
                          icon: const Icon(
                            Icons.clear_rounded,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                          label: Text(
                            "Clear",
                            style: GoogleFonts.inter(
                              color: const Color(0xFF64748B),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const Spacer(),
                      SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                          ),
                          child: Text(
                            "Cancel",
                            style: GoogleFonts.inter(
                              color: const Color(0xFF64748B),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed:
                              hasSelection
                                  ? () {
                                    Navigator.pop(
                                      context,
                                      DateTimeRange(
                                        start: _startDate!,
                                        end: _endDate!,
                                      ),
                                    );
                                  }
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                          ),
                          child: Text(
                            "Apply",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF64748B)),
      ),
    );
  }

  Widget _buildDayCell(DateTime date, int dayNum, DateTime today) {
    final bool isStart =
        _startDate != null &&
        date.year == _startDate!.year &&
        date.month == _startDate!.month &&
        date.day == _startDate!.day;
    final bool isEnd =
        _endDate != null &&
        date.year == _endDate!.year &&
        date.month == _endDate!.month &&
        date.day == _endDate!.day;
    final bool isSelected = isStart || isEnd;

    final bool inRange =
        _startDate != null &&
        _endDate != null &&
        date.isAfter(_startDate!) &&
        date.isBefore(_endDate!);

    final bool isToday =
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;

    BoxDecoration? cellDecoration;
    TextStyle textStyle = GoogleFonts.inter(
      fontSize: 12,
      color: const Color(0xFF1E293B),
      fontWeight: FontWeight.w500,
    );

    if (isSelected) {
      cellDecoration = const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF34D399), Color(0xFF10B981)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x4010B981),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      );
      textStyle = GoogleFonts.inter(
        fontSize: 12,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      );
    } else if (inRange) {
      cellDecoration = const BoxDecoration(
        color: Color(0x33DCFCE7),
        shape: BoxShape.circle,
      );
      textStyle = GoogleFonts.inter(
        fontSize: 12,
        color: const Color(0xFF047857),
        fontWeight: FontWeight.w600,
      );
    } else if (isToday) {
      cellDecoration = BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF10B981), width: 2),
      );
      textStyle = GoogleFonts.inter(
        fontSize: 12,
        color: const Color(0xFF10B981),
        fontWeight: FontWeight.bold,
      );
    }

    return InkWell(
      onTap: () {
        setState(() {
          if (_startDate == null || (_startDate != null && _endDate != null)) {
            _startDate = date;
            _endDate = null;
          } else if (date.isBefore(_startDate!)) {
            _startDate = date;
          } else {
            _endDate = date;
          }
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.all(2),
        alignment: Alignment.center,
        decoration: cellDecoration,
        child: Text(dayNum.toString(), style: textStyle),
      ),
    );
  }
}
