import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swiftclean_admin/MVVM/utils/printer_helper.dart';

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

  List<DocumentSnapshot> _bannedDocs = [];
  bool _isLoading = false;

  // Table scroll controllers for sticky header + scrollable body
  final ScrollController _bannedTableVerticalController = ScrollController();
  final ScrollController _bannedTableHorizontalHeaderController =
      ScrollController();
  final ScrollController _bannedTableHorizontalBodyController =
      ScrollController();
  bool _isBannedSyncingScroll = false;

  @override
  void initState() {
    super.initState();
    _fetchBannedUsers();
    _bannedTableHorizontalHeaderController.addListener(_onBannedHeaderHScroll);
    _bannedTableHorizontalBodyController.addListener(_onBannedBodyHScroll);
  }

  @override
  void dispose() {
    _bannedTableVerticalController.dispose();
    _bannedTableHorizontalHeaderController.dispose();
    _bannedTableHorizontalBodyController.dispose();
    super.dispose();
  }

  void _onBannedHeaderHScroll() {
    if (_isBannedSyncingScroll) return;
    _isBannedSyncingScroll = true;
    if (_bannedTableHorizontalBodyController.hasClients) {
      _bannedTableHorizontalBodyController.jumpTo(
        _bannedTableHorizontalHeaderController.offset,
      );
    }
    _isBannedSyncingScroll = false;
  }

  void _onBannedBodyHScroll() {
    if (_isBannedSyncingScroll) return;
    _isBannedSyncingScroll = true;
    if (_bannedTableHorizontalHeaderController.hasClients) {
      _bannedTableHorizontalHeaderController.jumpTo(
        _bannedTableHorizontalBodyController.offset,
      );
    }
    _isBannedSyncingScroll = false;
  }

  Future<void> _fetchBannedUsers() async {
    setState(() => _isLoading = true);
    try {
      final snap =
          await FirebaseFirestore.instance
              .collection("users")
              .where("status", whereIn: ["Banned", "banned"])
              .get();
      setState(() {
        _bannedDocs = snap.docs;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching banned users: $e");
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
          "Banned Users",
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

        final List<BannedUserModel> bannedUsersList =
            _bannedDocs.asMap().entries.map((entry) {
              final doc = entry.value;
              final data = doc.data() as Map<String, dynamic>? ?? {};
              final name = data['name'] ?? data['username'] ?? 'User';
              final email = data['email'] ?? 'No email';
              final phone = data['phone'] ?? 'No phone';
              final reason =
                  data['banReason'] ??
                  data['reason'] ??
                  'Violation of community guidelines';
              final banType = data['banType'] ?? 'Permanent';
              final bannedOn =
                  data['bannedOn'] ?? data['joinedDate'] ?? 'Recently';
              final bannedBy = data['bannedBy'] ?? 'Admin';
              final banDuration = data['banDuration'] ?? '-';

              return BannedUserModel(
                name: name,
                userId: doc.id,
                email: email,
                phone: phone,
                reason: reason,
                banType: banType,
                bannedOn: bannedOn,
                bannedBy: bannedBy,
                banDuration: banDuration,
                status: "Banned",
                avatarUrl:
                    "https://randomuser.me/api/portraits/men/${entry.key % 10 + 1}.jpg",
              );
            }).toList();

        // Apply filters
        final filteredUsers =
            bannedUsersList.where((user) {
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
                  _selectedBanType == "All Types" ||
                  user.banType == _selectedBanType;
              final matchesDuration =
                  _selectedDuration == "All Durations" ||
                  (_selectedDuration == "1 Day" &&
                      user.banDuration.contains("1 Day")) ||
                  (_selectedDuration == "7 Days" &&
                      user.banDuration.contains("7 Days")) ||
                  (_selectedDuration == "30 Days" &&
                      user.banDuration.contains("30 Days"));

              bool matchesDate = true;
              if (_selectedDateRange != null) {
                try {
                  DateTime? cellDateTime = DateTime.tryParse(user.bannedOn);
                  if (cellDateTime == null) {
                    final parts = user.bannedOn.replaceAll(',', '').split(' ');
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
              _buildStatsGrid(width, bannedUsersList),
              const SizedBox(height: 24),

              // Filter Controls
              _buildFilterRow(context, width, filteredUsers),
              const SizedBox(height: 24),

              // Banned Users Table
              _isLoading
                  ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  )
                  : _buildBannedTable(filteredUsers),
              const SizedBox(height: 16),

              // Table Footer
              _buildTableFooter(filteredUsers.length, bannedUsersList.length),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsGrid(double width, List<BannedUserModel> bannedUsersList) {
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

    final totalBanned = bannedUsersList.length;
    final permanentBans =
        bannedUsersList.where((u) => u.banType == "Permanent").length;
    final temporaryBans =
        bannedUsersList.where((u) => u.banType == "Temporary").length;

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
          bannedUsersList.where((u) {
            return u.bannedOn.contains(currentMonthStr) &&
                u.bannedOn.contains(currentYearStr);
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
          title: "Total Banned Users",
          value: totalBanned.toString(),
          trendPeriod: "Users are banned from the platform",
          icon: Icons.person_off_rounded,
          iconColor: const Color(0xFFEF4444),
          iconBgColor: const Color(0xFFFEF2F2),
        ),
        StatsCard(
          title: "This Month",
          value: thisMonthBans.toString(),
          trendPeriod: "Users banned this month",
          icon: Icons.calendar_month_rounded,
          iconColor: const Color(0xFFF59E0B),
          iconBgColor: const Color(0xFFFEF3C7),
        ),
        StatsCard(
          title: "Permanent Bans",
          value: permanentBans.toString(),
          trendPeriod: "Permanent banned users",
          icon: Icons.lock_outline_rounded,
          iconColor: const Color(0xFF6366F1),
          iconBgColor: const Color(0xFFEEF2FF),
        ),
        StatsCard(
          title: "Temporary Bans",
          value: temporaryBans.toString(),
          trendPeriod: "Temporary banned users",
          icon: Icons.timer_outlined,
          iconColor: const Color(0xFF3B82F6),
          iconBgColor: const Color(0xFFEFF6FF),
        ),
      ],
    );
  }

  Widget _buildFilterRow(
    BuildContext context,
    double width,
    List<BannedUserModel> filteredUsers,
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

    final typeDropdown = SizedBox(
      width: isSmall ? double.infinity : 140,
      height: 38,
      child: DropdownButtonFormField<String>(
        initialValue: _selectedBanType,
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
            ["All Types", "Permanent", "Temporary"]
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(),
        onChanged:
            (val) => setState(() {
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
            ["All Durations", "1 Day", "7 Days", "30 Days"]
                .map(
                  (duration) =>
                      DropdownMenuItem(value: duration, child: Text(duration)),
                )
                .toList(),
        onChanged:
            (val) => setState(() {
              _selectedDuration = val!;
            }),
      ),
    );

    final dateRangeButton = InkWell(
      onTap: () async {
        final DateTimeRange? picked = await showGeneralDialog<DateTimeRange>(
          context: context,
          barrierDismissible: true,
          barrierLabel: "Dismiss",
          barrierColor: Colors.black.withValues(alpha: 0.4),
          transitionDuration: const Duration(milliseconds: 220),
          pageBuilder: (context, anim1, anim2) {
            return PremiumDateRangePickerDialog(
              initialDateRange: _selectedDateRange,
            );
          },
          transitionBuilder: (context, anim1, anim2, child) {
            return FadeTransition(
              opacity: anim1,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                  CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
                ),
                child: child,
              ),
            );
          },
        );
        if (picked != null) {
          setState(() {
            _selectedDateRange = picked;
          });
        }
      },
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 38,
        width: isSmall ? double.infinity : 200,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                _selectedDateRange != null
                    ? const Color(0xFF10B981)
                    : const Color(0xFFE2E8F0),
            width: 1,
          ),
          gradient:
              _selectedDateRange != null
                  ? const LinearGradient(
                    colors: [Color(0xFFECFDF5), Color(0xFFF0FDF4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                  : null,
        ),
        child: Row(
          children: [
            Icon(
              _selectedDateRange != null
                  ? Icons.calendar_month_rounded
                  : Icons.calendar_today_outlined,
              color:
                  _selectedDateRange != null
                      ? const Color(0xFF10B981)
                      : const Color(0xFF64748B),
              size: 14,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedDateRange == null
                    ? "Select Date Range"
                    : "${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][_selectedDateRange!.start.month - 1]} ${_selectedDateRange!.start.day.toString().padLeft(2, '0')} • ${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][_selectedDateRange!.end.month - 1]} ${_selectedDateRange!.end.day.toString().padLeft(2, '0')}",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight:
                      _selectedDateRange == null
                          ? FontWeight.normal
                          : FontWeight.w600,
                  color:
                      _selectedDateRange == null
                          ? const Color(0xFF475569)
                          : const Color(0xFF1E293B),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _selectedDateRange != null
                    ? Icons.check_circle_rounded
                    : Icons.arrow_drop_down_rounded,
                key: ValueKey(_selectedDateRange != null),
                color:
                    _selectedDateRange != null
                        ? const Color(0xFF10B981)
                        : const Color(0xFF64748B),
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );

    final exportButton = ElevatedButton.icon(
      onPressed: () {
        // ignore: argument_type_not_assignable
        printBannedUsersList(filteredUsers);
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

  Widget _buildBannedTable(List<BannedUserModel> users) {
    const columnWidths = <int, TableColumnWidth>{
      0: FlexColumnWidth(2.0), // User Profile
      1: FlexColumnWidth(2.2), // Email / Phone
      2: FlexColumnWidth(2.5), // Reason
      3: FlexColumnWidth(1.2), // Ban Type Badge
      4: FlexColumnWidth(1.8), // Banned On
      5: FlexColumnWidth(1.8), // Banned By
      6: FlexColumnWidth(1.8), // Ban Duration
      7: FlexColumnWidth(1.0), // Status
      8: FlexColumnWidth(1.6), // Actions
    };
    const double tableWidth = 1200;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F3F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── STICKY HEADER ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _bannedTableHorizontalHeaderController,
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
                ],
              ),
            ),
          ),

          // ── SCROLLABLE BODY ──
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 500),
            child: Scrollbar(
              thumbVisibility: true,
              controller: _bannedTableVerticalController,
              child: Scrollbar(
                thumbVisibility: true,
                controller: _bannedTableHorizontalBodyController,
                notificationPredicate:
                    (notification) => notification.depth == 1,
                child: SingleChildScrollView(
                  controller: _bannedTableVerticalController,
                  physics: const ClampingScrollPhysics(),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    controller: _bannedTableHorizontalBodyController,
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
                                // Ban Type Badge
                                _buildBanTypeBadge(user.banType),
                                // Banned On
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10.0,
                                    horizontal: 16.0,
                                  ),
                                  child: Text(
                                    user.bannedOn,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                                // Banned By
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10.0,
                                    horizontal: 16.0,
                                  ),
                                  child: Text(
                                    user.bannedBy,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                                // Ban Duration
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10.0,
                                    horizontal: 16.0,
                                  ),
                                  child: Text(
                                    user.banDuration,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: const Color(0xFF475569),
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
                                        _showBannedUserDetailsDialog(
                                          context,
                                          user,
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    _buildActionButton(
                                      Icons.restore_page_rounded,
                                      Colors.grey,
                                      () {
                                        _showUnbanConfirmation(context, user);
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    _buildActionButton(
                                      Icons.delete_outline_rounded,
                                      Colors.red,
                                      () {
                                        _showDeleteConfirmation(context, user);
                                      },
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

  Widget _buildBanTypeBadge(String type) {
    final bool isPermanent = type == "Permanent";
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color:
              isPermanent ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          type,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color:
                isPermanent ? const Color(0xFFEF4444) : const Color(0xFFD97706),
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

  Widget _buildTableFooter(int totalFiltered, int totalBanned) {
    return Row(
      children: [
        Text(
          "Showing 1 to $totalFiltered of $totalBanned banned users",
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

  void _showUnbanConfirmation(BuildContext context, BannedUserModel user) {
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
                          "User '${user.name}' has been restored and unbanned.",
                        ),
                      ),
                    );
                    _fetchBannedUsers();
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

  void _showDeleteConfirmation(BuildContext context, BannedUserModel user) {
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
                    _fetchBannedUsers();
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

  void _showBannedUserDetailsDialog(
    BuildContext context,
    BannedUserModel user,
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
                      color: Color(0xFFEF4444),
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
                            "Banned User Details",
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
                              backgroundColor: const Color(0xFFFEE2E2),
                              backgroundImage: NetworkImage(user.avatarUrl),
                              onBackgroundImageError: (_, __) {},
                              child:
                                  user.avatarUrl.isEmpty
                                      ? const Icon(
                                        Icons.person,
                                        size: 30,
                                        color: Color(0xFFEF4444),
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
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "Banned",
                                style: GoogleFonts.inter(
                                  color: const Color(0xFFEF4444),
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
                          user.banType,
                          Icons.lock_outline_rounded,
                        ),
                        _buildDetailRow(
                          "Ban Duration",
                          user.banDuration,
                          Icons.timer_outlined,
                        ),
                        _buildDetailRow(
                          "Banned On",
                          user.bannedOn,
                          Icons.calendar_today_rounded,
                        ),
                        _buildDetailRow(
                          "Banned By",
                          user.bannedBy,
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
    return "${months[range.start.month - 1]} ${range.start.day} – ${months[range.end.month - 1]} ${range.end.day}";
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
            // ── Header (Gradient) ──────────────────────────────────────────
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

            // ── Body ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Selected Range Summary or Empty State ────────────────────
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

                  // ── Month Selector Row ───────────────────────────────────────
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

                  // ── Calendar Month Card ──────────────────────────────────────
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

                  // ── Action Buttons ───────────────────────────────────────────
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
