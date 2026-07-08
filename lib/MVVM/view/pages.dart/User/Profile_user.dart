import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserModel {
  final String no;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String userType;
  final String status;
  final String joinedDate;
  final int points;
  final String userId;

  UserModel({
    required this.no,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.userType,
    required this.status,
    required this.joinedDate,
    required this.points,
    required this.userId,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id, int index) {
    final List<String> statuses = [
      "Active",
      "Active",
      "Suspended",
      "Active",
      "Inactive",
    ];
    final String status = map['status'] ?? statuses[index % statuses.length];

    final List<int> pointValues = [
      1250,
      850,
      1500,
      700,
      1100,
      2300,
      1450,
      600,
      950,
      1300,
    ];
    final int points = map['points'] ?? pointValues[index % pointValues.length];

    final String userType = map['userType'] ?? "Customer";
    final String joinedDate = map['joinedDate'] ?? "May 18, 2024";
    final String userId = map['userId'] ?? "#USR12${58 - index}";

    return UserModel(
      no: id,
      name: map['username'] ?? map['name'] ?? 'User ${index + 1}',
      phone: map['phone'] ?? '+91 98765 43210',
      email: map['email'] ?? 'user${index + 1}@email.com',
      address: map['address'] ?? 'Street ${index + 1}, City',
      userType: userType,
      status: status,
      joinedDate: joinedDate,
      points: points,
      userId: userId,
    );
  }
}

class ProfileUser extends StatefulWidget {
  const ProfileUser({super.key});

  @override
  State<ProfileUser> createState() => _ProfileUserState();
}

class _ProfileUserState extends State<ProfileUser> {
  UserModel? selectedUser;
  final Set<String> _selectedUserIds = {};

  // Filter States
  String _searchQuery = "";
  String _selectedStatus = "All Status";
  String _selectedType = "All Types";
  DateTimeRange? _selectedDateRange;

  // Pagination States
  int _currentPage = 1;
  int _pageSize = 10;

  final List<UserModel> _mockUsers = [
    UserModel(
      no: "1",
      name: "Arun Kumar",
      phone: "+91 98765 43210",
      email: "arun.kumar@email.com",
      address: "Kochi, Kerala",
      userType: "Customer",
      status: "Active",
      joinedDate: "May 18, 2024",
      points: 1250,
      userId: "#USR1258",
    ),
    UserModel(
      no: "2",
      name: "Fathima Ali",
      phone: "+91 98765 43211",
      email: "fathima.ali@email.com",
      address: "Trivandrum, Kerala",
      userType: "Customer",
      status: "Active",
      joinedDate: "May 18, 2024",
      points: 850,
      userId: "#USR1257",
    ),
    UserModel(
      no: "3",
      name: "Ramesh Babu",
      phone: "+91 98765 43212",
      email: "ramesh.babu@email.com",
      address: "Calicut, Kerala",
      userType: "Customer",
      status: "Suspended",
      joinedDate: "May 18, 2024",
      points: 1500,
      userId: "#USR1256",
    ),
    UserModel(
      no: "4",
      name: "Neha Nair",
      phone: "+91 98765 43213",
      email: "neha.nair@email.com",
      address: "Ernakulam, Kerala",
      userType: "Customer",
      status: "Active",
      joinedDate: "May 18, 2024",
      points: 700,
      userId: "#USR1255",
    ),
    UserModel(
      no: "5",
      name: "Sujith K",
      phone: "+91 98765 43214",
      email: "sujith.k@email.com",
      address: "Thrissur, Kerala",
      userType: "Customer",
      status: "Inactive",
      joinedDate: "May 17, 2024",
      points: 1100,
      userId: "#USR1254",
    ),
    UserModel(
      no: "6",
      name: "Aisha Rahman",
      phone: "+91 98765 43215",
      email: "aisha.rahman@email.com",
      address: "Palakkad, Kerala",
      userType: "Customer",
      status: "Active",
      joinedDate: "May 17, 2024",
      points: 2300,
      userId: "#USR1253",
    ),
    UserModel(
      no: "7",
      name: "Muhammed Shakeel",
      phone: "+91 98765 43216",
      email: "shakeel@email.com",
      address: "Kannur, Kerala",
      userType: "Customer",
      status: "Active",
      joinedDate: "May 17, 2024",
      points: 1450,
      userId: "#USR1252",
    ),
    UserModel(
      no: "8",
      name: "Anjana P",
      phone: "+91 98765 43217",
      email: "anjana.p@email.com",
      address: "Kollam, Kerala",
      userType: "Customer",
      status: "Suspended",
      joinedDate: "May 16, 2024",
      points: 600,
      userId: "#USR1251",
    ),
    UserModel(
      no: "9",
      name: "Vivek R",
      phone: "+91 98765 43218",
      email: "vivek.r@email.com",
      address: "Alappuzha, Kerala",
      userType: "Customer",
      status: "Active",
      joinedDate: "May 16, 2024",
      points: 950,
      userId: "#USR1250",
    ),
    UserModel(
      no: "10",
      name: "Sreelakshmi",
      phone: "+91 98765 43219",
      email: "sreelakshmir@email.com",
      address: "Kottayam, Kerala",
      userType: "Customer",
      status: "Active",
      joinedDate: "May 16, 2024",
      points: 1300,
      userId: "#USR1249",
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
          "Users",
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showConfirmationDialog({
    required String title,
    required String content,
    required String confirmText,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(
              title,
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            content: Text(content, style: GoogleFonts.inter()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.inter(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  onConfirm();
                },
                child: Text(
                  confirmText,
                  style: GoogleFonts.inter(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;

        return StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection("users")
                  .where("role", isEqualTo: 'user')
                  .snapshots(),
          builder: (context, snapshot) {
            List<UserModel> users = [];
            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              users =
                  snapshot.data!.docs.asMap().entries.map((entry) {
                    return UserModel.fromMap(
                      entry.value.data() as Map<String, dynamic>,
                      entry.value.id,
                      entry.key,
                    );
                  }).toList();
            } else {
              // Fallback to mock users if Firestore is empty/loading/error
              users = _mockUsers;
            }

            // Apply Filters
            List<UserModel> filteredUsers =
                users.where((user) {
                  final matchesSearch =
                      user.name.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      user.email.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      user.phone.contains(_searchQuery);

                  final matchesStatus =
                      _selectedStatus == "All Status" ||
                      user.status == _selectedStatus;
                  final matchesType =
                      _selectedType == "All Types" ||
                      user.userType == _selectedType;

                  return matchesSearch && matchesStatus && matchesType;
                }).toList();

            // Pagination
            final int totalItems = filteredUsers.length;
            final int startIndex = (_currentPage - 1) * _pageSize;
            final int endIndex =
                startIndex + _pageSize < totalItems
                    ? startIndex + _pageSize
                    : totalItems;
            final List<UserModel> paginatedUsers =
                totalItems > 0
                    ? filteredUsers.sublist(startIndex, endIndex)
                    : [];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (selectedUser != null)
                    _buildUserProfile(selectedUser!)
                  else ...[
                    // Breadcrumbs
                    _buildBreadcrumbs(),
                    const SizedBox(height: 8),

                    // Title
                    Text(
                      "User Management",
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Stats Cards Grid
                    _buildStatsCardsGrid(width),
                    const SizedBox(height: 24),

                    // Filter Row
                    _buildFilterRow(context, width),
                    const SizedBox(height: 24),

                    // Users Table
                    _buildUsersTable(paginatedUsers),
                    const SizedBox(height: 16),

                    // Pagination Footer
                    _buildPaginationFooter(totalItems, startIndex, endIndex),
                  ],
                ],
              ),
            );
          },
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
          title: "Total Users",
          value: "12,458",
          trendPercentage: "12.5%",
          trendPeriod: "from last week",
          isPositiveTrend: true,
          icon: Icons.people_alt_rounded,
          iconColor: Color(0xFF3B82F6),
          iconBgColor: Color(0xFFEFF6FF),
        ),
        StatsCard(
          title: "Active Users",
          value: "11,236",
          trendPercentage: "10.3%",
          trendPeriod: "from last week",
          isPositiveTrend: true,
          icon: Icons.group_add_rounded,
          iconColor: Color(0xFF10B981),
          iconBgColor: Color(0xFFECFDF5),
        ),
        StatsCard(
          title: "Suspended Users",
          value: "156",
          trendPercentage: "2.4%",
          trendPeriod: "from last week",
          isPositiveTrend: false,
          icon: Icons.block_rounded,
          iconColor: Color(0xFFF59E0B),
          iconBgColor: Color(0xFFFEF3C7),
        ),
        StatsCard(
          title: "New Users (This Week)",
          value: "342",
          trendPercentage: "8.7%",
          trendPeriod: "from last week",
          isPositiveTrend: true,
          icon: Icons.person_add_rounded,
          iconColor: Color(0xFF8B5CF6),
          iconBgColor: Color(0xFFF5F3FF),
        ),
      ],
    );
  }

  Widget _buildFilterRow(BuildContext context, double width) {
    final bool isSmall = width < 850;

    final searchField = SizedBox(
      width: isSmall ? double.infinity : 260,
      height: 38,
      child: TextFormField(
        onChanged:
            (val) => setState(() {
              _searchQuery = val;
              _currentPage = 1;
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

    final statusDropdown = SizedBox(
      width: isSmall ? double.infinity : 140,
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
            ["All Status", "Active", "Suspended", "Inactive"]
                .map(
                  (status) =>
                      DropdownMenuItem(value: status, child: Text(status)),
                )
                .toList(),
        onChanged:
            (val) => setState(() {
              _selectedStatus = val!;
              _currentPage = 1;
            }),
      ),
    );

    final typeDropdown = SizedBox(
      width: isSmall ? double.infinity : 140,
      height: 38,
      child: DropdownButtonFormField<String>(
        initialValue: _selectedType,
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
            ["All Types", "Customer", "Admin"]
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(),
        onChanged:
            (val) => setState(() {
              _selectedType = val!;
              _currentPage = 1;
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
                style: GoogleFonts.inter(
                  color: const Color(0xFF475569),
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: Color(0xFF64748B),
            ),
          ],
        ),
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

    final addUserButton = ElevatedButton.icon(
      onPressed: () {
        // Trigger dialog to create/add user
      },
      icon: const Icon(Icons.add, size: 14),
      label: Text(
        "Add User",
        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
              Expanded(child: statusDropdown),
              const SizedBox(width: 12),
              Expanded(child: typeDropdown),
            ],
          ),
          const SizedBox(height: 12),
          dateRangeButton,
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [exportButton, const SizedBox(width: 12), addUserButton],
          ),
        ],
      );
    } else {
      return Row(
        children: [
          searchField,
          const SizedBox(width: 12),
          statusDropdown,
          const SizedBox(width: 12),
          typeDropdown,
          const SizedBox(width: 12),
          dateRangeButton,
          const Spacer(),
          exportButton,
          const SizedBox(width: 12),
          addUserButton,
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

  Widget _buildUsersTable(List<UserModel> users) {
    final allChecked =
        users.isNotEmpty && users.every((u) => _selectedUserIds.contains(u.no));

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
                  0: FixedColumnWidth(50), // Checkbox
                  1: FlexColumnWidth(2.0), // User Details (Avatar & Name/ID)
                  2: FlexColumnWidth(2.2), // Email
                  3: FlexColumnWidth(1.8), // Phone
                  4: FlexColumnWidth(1.2), // User Type badge
                  5: FlexColumnWidth(1.2), // Status dot
                  6: FlexColumnWidth(1.6), // Joined Date
                  7: FlexColumnWidth(1.2), // Points
                  8: FlexColumnWidth(2.2), // Actions
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  // Table Header
                  TableRow(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Checkbox(
                          value: allChecked,
                          activeColor: const Color(0xFF10B981),
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedUserIds.addAll(users.map((u) => u.no));
                              } else {
                                _selectedUserIds.removeAll(
                                  users.map((u) => u.no),
                                );
                              }
                            });
                          },
                        ),
                      ),
                      _buildHeaderCell("User"),
                      _buildHeaderCell("Email"),
                      _buildHeaderCell("Phone"),
                      _buildHeaderCell("User Type"),
                      _buildHeaderCell("Status"),
                      _buildHeaderCell("Joined Date"),
                      _buildHeaderCell("Points"),
                      _buildHeaderCell("Actions"),
                    ],
                  ),

                  // Data Rows
                  ...users.map((user) {
                    final isChecked = _selectedUserIds.contains(user.no);
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
                        Checkbox(
                          value: isChecked,
                          activeColor: const Color(0xFF10B981),
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedUserIds.add(user.no);
                              } else {
                                _selectedUserIds.remove(user.no);
                              }
                            });
                          },
                        ),
                        // User Column (Avatar + Details)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  'https://randomuser.me/api/portraits/men/32.jpg',
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
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
                        Text(
                          user.email,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF475569),
                          ),
                        ),
                        Text(
                          user.phone,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF475569),
                          ),
                        ),
                        _buildUserTypeBadge(user.userType),
                        _buildStatusIndicator(user.status),
                        Text(
                          user.joinedDate,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        // Points
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Color(0xFFF59E0B),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              user.points.toString(),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        // Actions row
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildActionButton(
                              Icons.visibility_outlined,
                              Colors.blue,
                              () {
                                setState(() {
                                  selectedUser = user;
                                });
                              },
                            ),
                            const SizedBox(width: 6),
                            _buildActionButton(
                              Icons.edit_outlined,
                              Colors.blue,
                              () {
                                // Action for edit
                              },
                            ),
                            const SizedBox(width: 6),
                            _buildActionButton(
                              Icons.lock_outline_rounded,
                              Colors.orange,
                              () {
                                _showConfirmationDialog(
                                  title: "Confirm Suspension",
                                  content:
                                      "Are you sure you want to suspend ${user.name}?",
                                  confirmText: "Suspend",
                                  onConfirm: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "${user.name} suspended successfully.",
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                            const SizedBox(width: 6),
                            _buildActionButton(
                              Icons.delete_outline_rounded,
                              Colors.red,
                              () {
                                _showConfirmationDialog(
                                  title: "Confirm Delete",
                                  content:
                                      "Are you sure you want to delete ${user.name}?",
                                  confirmText: "Delete",
                                  onConfirm: () {
                                    FirebaseFirestore.instance
                                        .collection("users")
                                        .doc(user.no)
                                        .delete();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "${user.name} has been deleted.",
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                            const SizedBox(width: 6),
                            _buildActionButton(
                              Icons.list_rounded,
                              Colors.grey,
                              () {
                                // Extra options
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
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
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

  Widget _buildUserTypeBadge(String type) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF), // Tinted blue
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          type,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3B82F6),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String status) {
    Color dotColor;
    Color textColor = const Color(0xFF1E293B);

    switch (status) {
      case "Active":
        dotColor = const Color(0xFF10B981);
        textColor = const Color(0xFF047857);
        break;
      case "Suspended":
        dotColor = const Color(0xFFEF4444);
        textColor = const Color(0xFFB91C1C);
        break;
      case "Inactive":
      default:
        dotColor = const Color(0xFF94A3B8);
        textColor = const Color(0xFF475569);
    }

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

  Widget _buildPaginationFooter(int totalItems, int startIndex, int endIndex) {
    final int totalPages = (totalItems / _pageSize).ceil();

    return Row(
      children: [
        Text(
          "Showing ${startIndex + 1} to $endIndex of $totalItems users",
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF64748B),
          ),
        ),
        const Spacer(),
        // Pages
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, size: 18),
              onPressed:
                  _currentPage > 1
                      ? () => setState(() => _currentPage--)
                      : null,
            ),
            ...List.generate(totalPages, (index) {
              final int page = index + 1;
              final bool isSelected = page == _currentPage;
              return InkWell(
                onTap: () => setState(() => _currentPage = page),
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
              onPressed:
                  _currentPage < totalPages
                      ? () => setState(() => _currentPage++)
                      : null,
            ),
          ],
        ),
        const SizedBox(width: 16),
        // Page Size
        SizedBox(
          width: 110,
          height: 32,
          child: DropdownButtonFormField<int>(
            initialValue: _pageSize,
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
            items:
                [10, 20, 50]
                    .map(
                      (size) => DropdownMenuItem(
                        value: size,
                        child: Text("$size / page"),
                      ),
                    )
                    .toList(),
            onChanged:
                (val) => setState(() {
                  _pageSize = val!;
                  _currentPage = 1;
                }),
          ),
        ),
      ],
    );
  }

  Widget _buildUserProfile(UserModel user) {
    return Container(
      width: 600,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F3F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => setState(() => selectedUser = null),
                icon: const Icon(Icons.arrow_back_rounded, size: 14),
                label: Text(
                  "Back",
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  foregroundColor: const Color(0xFF475569),
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
          Center(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: Image.network(
                    'https://randomuser.me/api/portraits/men/32.jpg',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: const Color(0xFFE2E8F0),
                        child: const Icon(
                          Icons.person,
                          color: Color(0xFF64748B),
                          size: 40,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.name,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.userId,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          _buildProfileDetailRow("Email", user.email),
          _buildProfileDetailRow("Phone", user.phone),
          _buildProfileDetailRow("User Type", user.userType),
          _buildProfileDetailRow("Status", user.status),
          _buildProfileDetailRow("Points", "${user.points} Points"),
          _buildProfileDetailRow("Joined Date", user.joinedDate),
          _buildProfileDetailRow("Address", user.address),
        ],
      ),
    );
  }

  Widget _buildProfileDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
  final String trendPercentage;
  final String trendPeriod;
  final bool isPositiveTrend;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.trendPercentage,
    required this.trendPeriod,
    required this.isPositiveTrend,
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
              Icon(
                isPositiveTrend ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color:
                    isPositiveTrend
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
              ),
              const SizedBox(width: 4),
              Text(
                trendPercentage,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color:
                      isPositiveTrend
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 4),
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
