import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swiftclean_admin/MVVM/utils/rbac_session.dart';
import 'package:swiftclean_admin/MVVM/utils/printer_helper.dart';

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
  final String role;

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
    required this.role,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id, int index) {
    final List<String> statuses = [
      "Active",
      "Active",
      "Suspended",
      "Active",
      "Inactive",
    ];
    final String rawStatus = map['status'] ?? statuses[index % statuses.length];
    String status = "Active";
    if (rawStatus.toLowerCase() == "active") {
      status = "Active";
    } else if (rawStatus.toLowerCase() == "suspended") {
      status = "Suspended";
    } else if (rawStatus.toLowerCase() == "inactive") {
      status = "Inactive";
    } else {
      if (rawStatus.isNotEmpty) {
        status =
            rawStatus[0].toUpperCase() + rawStatus.substring(1).toLowerCase();
      }
    }

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

    final String rawUserType = map['userType'] ?? "Customer";
    String userType = "Customer";
    if (rawUserType.toLowerCase() == "customer") {
      userType = "Customer";
    } else if (rawUserType.toLowerCase() == "admin") {
      userType = "Admin";
    } else {
      if (rawUserType.isNotEmpty) {
        userType =
            rawUserType[0].toUpperCase() +
            rawUserType.substring(1).toLowerCase();
      }
    }

    final String joinedDate = map['joinedDate'] ?? "May 18, 2024";
    final String userId = map['userId'] ?? "#USR12${58 - index}";
    final String role = map['role'] ?? "Customer";

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
      role: role,
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

  List<DocumentSnapshot> _allFetchedDocs = [];
  bool _isFetching = false;
  bool _hasMore = true;
  int _totalCount = 0;
  int _statTotalUsers = 0;
  int _statActiveUsers = 0;
  int _statSuspendedUsers = 0;
  int _statNewUsersThisWeek = 0;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Map<String, String> _userRoles = {};
  final Set<String> _superAdminUids = {};
  StreamSubscription<QuerySnapshot>? _adminUsersSub;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _refreshData();

    _adminUsersSub = FirebaseFirestore.instance
        .collection("admin_users")
        .snapshots()
        .listen((snapshot) {
          final Map<String, String> updatedRoles = {};
          final Set<String> updatedSuperAdminUids = {};
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>?;
            final role = (data?['roleDisplayName'] ?? '').toString();
            final roleId = (data?['roleId'] ?? '').toString().toLowerCase();
            final roleIds =
                (data?['roleIds'] as List<dynamic>?)
                    ?.map((e) => e.toString().toLowerCase())
                    .toList() ??
                [];
            final isSuper =
                role.toLowerCase() == 'super admin' ||
                role.toLowerCase() == 'developer' ||
                roleId == 'super_admin' ||
                roleId == 'developer' ||
                roleIds.contains('super_admin') ||
                roleIds.contains('developer');
            if (isSuper) {
              updatedSuperAdminUids.add(doc.id);
              continue;
            }
            if (role.isNotEmpty) {
              updatedRoles[doc.id] = role;
            }
          }
          if (mounted) {
            setState(() {
              _userRoles = updatedRoles;
              _superAdminUids.clear();
              _superAdminUids.addAll(updatedSuperAdminUids);
            });
          }
        });
  }

  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    _adminUsersSub?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = val;
      });
      _refreshData();
    });
  }

  void _onFilterChanged() {
    _refreshData();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final totalLoadedPages = (_allFetchedDocs.length / _pageSize).ceil();
      if (_currentPage == totalLoadedPages && _hasMore) {
        _fetchNextBatch();
      }
    }
  }

  Future<void> _refreshData() async {
    if (_isFetching) return;
    _allFetchedDocs.clear();
    _hasMore = true;
    _currentPage = 1;
    await _fetchNextBatch();
    _fetchTotalCount();
    _fetchStats();
  }

  Future<void> _fetchNextBatch() async {
    if (_isFetching || !_hasMore) return;
    setState(() {
      _isFetching = true;
    });

    try {
      Query query = FirebaseFirestore.instance.collection("users");

      // Only apply status filter server-side (safe single-field filter, no composite index needed).
      // All other filters (type, date range, search) are applied client-side in paginatedUsers.
      if (_selectedStatus != "All Status") {
        query = query.where(
          "status",
          whereIn: [_selectedStatus, _selectedStatus.toLowerCase()],
        );
      }

      // Use orderBy only when no server-side filter is active (avoids composite index requirement).
      if (_selectedStatus == "All Status") {
        query = query.orderBy(FieldPath.documentId);
      }

      if (_allFetchedDocs.isNotEmpty) {
        query = query.startAfterDocument(_allFetchedDocs.last);
      }

      // Fetch a large batch so client-side filters still leave enough visible rows.
      query = query.limit(200);

      final snapshot = await query.get();
      if (snapshot.docs.length < 200) {
        _hasMore = false;
      }
      setState(() {
        _allFetchedDocs.addAll(snapshot.docs);
      });
    } catch (e) {
      print("Error fetching users batch: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isFetching = false;
        });
      }
    }
  }

  Future<void> _fetchTotalCount() async {
    try {
      Query query = FirebaseFirestore.instance.collection("users");
      if (_selectedStatus != "All Status") {
        query = query.where(
          "status",
          whereIn: [_selectedStatus, _selectedStatus.toLowerCase()],
        );
      }
      if (_selectedType != "All Types") {
        query = query.where("userType", isEqualTo: _selectedType);
      }
      if (_selectedDateRange != null) {
        query = query
            .where(
              "createdAt",
              isGreaterThanOrEqualTo: Timestamp.fromDate(
                _selectedDateRange!.start,
              ),
            )
            .where(
              "createdAt",
              isLessThanOrEqualTo: Timestamp.fromDate(
                _selectedDateRange!.end.add(const Duration(days: 1)),
              ),
            );
      }
      if (_searchQuery.isNotEmpty) {
        query = query
            .where("username", isGreaterThanOrEqualTo: _searchQuery)
            .where("username", isLessThanOrEqualTo: _searchQuery + '\uf8ff');
      }
      final countSnapshot = await query.count().get();
      if (mounted) {
        setState(() {
          _totalCount = countSnapshot.count ?? 0;
        });
      }
    } catch (e) {
      print("Error fetching total count: $e");
    }
  }

  Future<void> _fetchStats() async {
    try {
      final db = FirebaseFirestore.instance;

      final totalSnap = await db.collection("users").count().get();
      final activeSnap =
          await db
              .collection("users")
              .where("status", whereIn: ["Active", "active"])
              .count()
              .get();
      final suspendedSnap =
          await db
              .collection("users")
              .where("status", whereIn: ["Suspended", "suspended"])
              .count()
              .get();
      final bannedSnap =
          await db
              .collection("users")
              .where("status", whereIn: ["Banned", "banned"])
              .count()
              .get();

      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final newUsersSnap =
          await db
              .collection("users")
              .where(
                "createdAt",
                isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart),
              )
              .count()
              .get();

      int total = totalSnap.count ?? 0;
      int banned = bannedSnap.count ?? 0;
      int active = activeSnap.count ?? 0;
      int suspended = suspendedSnap.count ?? 0;
      int newUsers = newUsersSnap.count ?? 0;

      // Adjust total to exclude banned users
      total = total - banned;

      if (total > 0) total--;
      if (active > 0) active--;

      if (mounted) {
        setState(() {
          _statTotalUsers = total;
          _statActiveUsers = active;
          _statSuspendedUsers = suspended;
          _statNewUsersThisWeek = newUsers;
        });
      }
    } catch (e) {
      print("Error fetching stats: $e");
    }
  }

  void _changePage(int page) {
    if (page < 1) return;

    final totalLoadedPages = (_allFetchedDocs.length / _pageSize).ceil();
    if (page > totalLoadedPages && _hasMore) {
      _fetchNextBatch().then((_) {
        setState(() {
          _currentPage = page;
        });
      });
    } else {
      setState(() {
        _currentPage = page;
      });
    }
  }

  List<UserModel> get paginatedUsers {
    // ── Step 1: Map ALL fetched docs to UserModel with resolved role ───────────
    final allUsers =
        _allFetchedDocs.asMap().entries.map((entry) {
          final doc = entry.value;
          final data = doc.data() as Map<String, dynamic>;
          final rawUser = UserModel.fromMap(data, doc.id, entry.key);
          final role = _userRoles[rawUser.no];
          final finalUserType =
              (role != null && role.isNotEmpty) ? role : "Customer";
          return UserModel(
            no: rawUser.no,
            name: rawUser.name,
            phone: rawUser.phone,
            email: rawUser.email,
            address: rawUser.address,
            userType: finalUserType,
            status: rawUser.status,
            joinedDate: rawUser.joinedDate,
            points: rawUser.points,
            userId: rawUser.userId,
            role: rawUser.role,
          );
        }).toList();

    // ── Step 2: Apply ALL client-side filters ────────────────────────────────
    final q = _searchQuery.trim().toLowerCase();

    final filtered =
        allUsers.where((user) {
          // Always exclude banned, super-admin, developer, admin accounts
          if (user.status.toLowerCase() == "banned") return false;
          if (_superAdminUids.contains(user.userId)) return false;

          final email = user.email.toLowerCase();
          final name = user.name.toLowerCase();
          final userType = user.userType.toLowerCase();

          final isDeveloper =
              email.contains('developer') ||
              name == 'developer' ||
              userType == 'developer';
          final isSuperAdmin =
              email.contains('superadmin') ||
              name == 'superadmin' ||
              userType == 'superadmin';
          final isAdmin = email == 'admin@naattulink.com' || name == 'admin';
          if (isDeveloper || isSuperAdmin || isAdmin) return false;

          // Status filter
          if (_selectedStatus != "All Status" &&
              user.status.toLowerCase() != _selectedStatus.toLowerCase()) {
            return false;
          }

          // Type filter (uses role-resolved userType)
          if (_selectedType != "All Types" &&
              user.userType.toLowerCase() != _selectedType.toLowerCase()) {
            return false;
          }

          // Date range filter — compare joinedDate string by parsing it
          if (_selectedDateRange != null) {
            try {
              // joinedDate is stored like "May 18, 2024" — parse it
              final parts = user.joinedDate.replaceAll(',', '').split(' ');
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
                  final joinedDateTime = DateTime(year, month, day);
                  final rangeEnd = _selectedDateRange!.end.add(
                    const Duration(days: 1),
                  );
                  if (joinedDateTime.isBefore(_selectedDateRange!.start) ||
                      joinedDateTime.isAfter(rangeEnd)) {
                    return false;
                  }
                }
              }
            } catch (_) {}
          }

          // Search filter — matches name, email, phone, or userId
          if (q.isNotEmpty) {
            final matchesName = user.name.toLowerCase().contains(q);
            final matchesEmail = user.email.toLowerCase().contains(q);
            final matchesPhone = user.phone.contains(q);
            final matchesId = user.userId.toLowerCase().contains(q);
            if (!matchesName && !matchesEmail && !matchesPhone && !matchesId) {
              return false;
            }
          }

          return true;
        }).toList();

    // ── Step 3: Paginate from the fully-filtered list ────────────────────────
    final startIndex = (_currentPage - 1) * _pageSize;
    if (startIndex >= filtered.length) return [];
    final endIndex = (startIndex + _pageSize).clamp(0, filtered.length);

    // Re-number the visible rows sequentially
    return filtered.sublist(startIndex, endIndex).asMap().entries.map((e) {
      final u = e.value;
      return UserModel(
        no: u.no,
        name: u.name,
        phone: u.phone,
        email: u.email,
        address: u.address,
        userType: u.userType,
        status: u.status,
        joinedDate: u.joinedDate,
        points: u.points,
        userId: u.userId,
        role: u.role,
      );
    }).toList();
  }

  /// Total number of rows after all client-side filters are applied.
  /// Used by the table footer and pagination controls.
  int get filteredUserCount {
    final q = _searchQuery.trim().toLowerCase();
    return _allFetchedDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final rawUser = UserModel.fromMap(data, doc.id, 0);
      final role = _userRoles[rawUser.no];
      final finalUserType =
          (role != null && role.isNotEmpty) ? role : "Customer";

      if (rawUser.status.toLowerCase() == "banned") return false;
      if (_superAdminUids.contains(rawUser.userId)) return false;

      final email = rawUser.email.toLowerCase();
      final name = rawUser.name.toLowerCase();
      final userType = finalUserType.toLowerCase();
      if (email.contains('developer') ||
          name == 'developer' ||
          userType == 'developer')
        return false;
      if (email.contains('superadmin') ||
          name == 'superadmin' ||
          userType == 'superadmin')
        return false;
      if (email == 'admin@naattulink.com' || name == 'admin') return false;

      if (_selectedStatus != "All Status" &&
          rawUser.status.toLowerCase() != _selectedStatus.toLowerCase()) {
        return false;
      }
      if (_selectedType != "All Types" &&
          finalUserType.toLowerCase() != _selectedType.toLowerCase()) {
        return false;
      }
      if (q.isNotEmpty) {
        if (!rawUser.name.toLowerCase().contains(q) &&
            !rawUser.email.toLowerCase().contains(q) &&
            !rawUser.phone.contains(q) &&
            !rawUser.userId.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).length;
  }

  // No mock data - all users are loaded live from Firestore

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

  void _showAddUserDialog() {
    final formKey = GlobalKey<FormState>();
    String name = "";
    String username = "";
    String email = "";
    String password = "";
    String phone = "";
    String address = "";
    String status = "Active";
    int points = 0;
    String? selectedRole;
    bool obscurePassword = true;
    List<String> availableRoles = [];
    bool rolesLoading = true;

    // Pre-fetch roles
    FirebaseFirestore.instance.collection("roles").get().then((snap) {
      // filtered in dialog state
    });

    showDialog(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder: (context, setDialogState) {
              // Fetch roles once
              if (rolesLoading) {
                rolesLoading = false;
                FirebaseFirestore.instance.collection("roles").get().then((
                  snap,
                ) {
                  final roles =
                      snap.docs
                          .map((d) => d.data()['name'] as String? ?? '')
                          .where((n) => n.isNotEmpty)
                          .toList();

                  // Hide Super Admin unless current user is Super Admin
                  final filtered =
                      RbacSession().isSuperAdmin
                          ? roles
                          : roles.where((r) => r != "Super Admin").toList();

                  setDialogState(() {
                    availableRoles = filtered;
                    if (filtered.isNotEmpty) selectedRole = filtered.first;
                  });
                });
              }

              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                backgroundColor: Colors.transparent,
                child: Container(
                  width: 520,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Add New User",
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Color(0xFF64748B),
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                splashRadius: 18,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(height: 1, color: const Color(0xFFE2E8F0)),
                          const SizedBox(height: 20),

                          // Full Name
                          Text(
                            "Full Name",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            decoration: _inputDecoration(
                              "Enter full name",
                              Icons.person_outline_rounded,
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF1E293B),
                            ),
                            validator:
                                (v) =>
                                    v == null || v.isEmpty
                                        ? "Name is required"
                                        : null,
                            onSaved: (v) => name = v!,
                          ),
                          const SizedBox(height: 16),

                          // Username
                          Text(
                            "Username",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            decoration: _inputDecoration(
                              "Enter username",
                              Icons.alternate_email_rounded,
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF1E293B),
                            ),
                            validator:
                                (v) =>
                                    v == null || v.isEmpty
                                        ? "Username is required"
                                        : null,
                            onSaved: (v) => username = v!,
                          ),
                          const SizedBox(height: 16),

                          // Email Address
                          Text(
                            "Email Address",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            decoration: _inputDecoration(
                              "Enter email address",
                              Icons.mail_outline_rounded,
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF1E293B),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return "Email is required";
                              if (!RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              ).hasMatch(v)) {
                                return "Enter a valid email address";
                              }
                              return null;
                            },
                            onSaved: (v) => email = v!,
                          ),
                          const SizedBox(height: 16),

                          // Password
                          Text(
                            "Password",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            obscureText: obscurePassword,
                            decoration: _inputDecoration(
                              "Enter password",
                              Icons.lock_outline_rounded,
                            ).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 18,
                                  color: const Color(0xFF94A3B8),
                                ),
                                onPressed: () {
                                  setDialogState(
                                    () => obscurePassword = !obscurePassword,
                                  );
                                },
                              ),
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF1E293B),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return "Password is required";
                              if (v.length < 6)
                                return "Password must be at least 6 characters";
                              return null;
                            },
                            onSaved: (v) => password = v!,
                          ),
                          const SizedBox(height: 16),

                          // Phone Number
                          Text(
                            "Phone Number",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            decoration: _inputDecoration(
                              "+91 XXXXX XXXXX",
                              Icons.phone_outlined,
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF1E293B),
                            ),
                            validator:
                                (v) =>
                                    v == null || v.isEmpty
                                        ? "Phone number is required"
                                        : null,
                            onSaved: (v) => phone = v!,
                          ),
                          const SizedBox(height: 16),

                          // Address
                          Text(
                            "Address",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            decoration: _inputDecoration(
                              "Enter address",
                              Icons.location_on_outlined,
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF1E293B),
                            ),
                            validator:
                                (v) =>
                                    v == null || v.isEmpty
                                        ? "Address is required"
                                        : null,
                            onSaved: (v) => address = v!,
                          ),
                          const SizedBox(height: 16),

                          // Assign Role + Status row
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Assign Role",
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF475569),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    availableRoles.isEmpty
                                        ? const SizedBox(
                                          height: 48,
                                          child: Center(
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Color(0xFF10B981),
                                              ),
                                            ),
                                          ),
                                        )
                                        : DropdownButtonFormField<String>(
                                          value: selectedRole,
                                          decoration: _inputDecoration(
                                            "",
                                            null,
                                          ),
                                          items:
                                              availableRoles
                                                  .map(
                                                    (r) => DropdownMenuItem(
                                                      value: r,
                                                      child: Text(
                                                        r,
                                                        style:
                                                            GoogleFonts.inter(
                                                              fontSize: 13,
                                                            ),
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                          onChanged: (v) {
                                            setDialogState(
                                              () => selectedRole = v,
                                            );
                                          },
                                          validator:
                                              (v) =>
                                                  v == null || v.isEmpty
                                                      ? "Role is required"
                                                      : null,
                                        ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Status",
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF475569),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<String>(
                                      initialValue: status,
                                      decoration: _inputDecoration("", null),
                                      items:
                                          ["Active", "Inactive"]
                                              .map(
                                                (st) => DropdownMenuItem(
                                                  value: st,
                                                  child: Text(st),
                                                ),
                                              )
                                              .toList(),
                                      onChanged: (v) => status = v!,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Initial Loyalty Points
                          Text(
                            "Initial Loyalty Points",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            decoration: _inputDecoration(
                              "e.g. 100",
                              Icons.star_border_rounded,
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF1E293B),
                            ),
                            keyboardType: TextInputType.number,
                            onSaved:
                                (v) => points = int.tryParse(v ?? "0") ?? 0,
                          ),
                          const SizedBox(height: 24),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  "Cancel",
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF475569),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () async {
                                  if (formKey.currentState!.validate()) {
                                    formKey.currentState!.save();
                                    Navigator.pop(dialogContext);
                                    try {
                                      // Create Firebase Auth account
                                      final credential = await FirebaseAuth
                                          .instance
                                          .createUserWithEmailAndPassword(
                                            email: email,
                                            password: password,
                                          );
                                      final uid = credential.user!.uid;

                                      // Save user profile in Firestore
                                      await FirebaseFirestore.instance
                                          .collection("users")
                                          .doc(uid)
                                          .set({
                                            'username': username,
                                            'name': name,
                                            'email': email,
                                            'phone': phone,
                                            'address': address,
                                            'role': selectedRole ?? 'Customer',
                                            'status': status,
                                            'userType': 'Admin',
                                            'points': points,
                                            'joinedDate': _formatDate(
                                              DateTime.now(),
                                            ),
                                            'createdAt':
                                                FieldValue.serverTimestamp(),
                                            'userId':
                                                '#USR12' +
                                                DateTime.now().millisecond
                                                    .toString()
                                                    .padLeft(2, '0'),
                                          });

                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "User added successfully.",
                                          ),
                                        ),
                                      );
                                      _refreshData();
                                    } catch (e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Error adding user: $e",
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  "Add User",
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }

  void _showEditUserDialog(UserModel user) {
    final formKey = GlobalKey<FormState>();
    String name = user.name;
    String email = user.email;
    String phone = user.phone;
    String address = user.address;
    String userType = user.userType;
    String status = user.status;
    int points = user.points;

    showDialog(
      context: context,
      builder:
          (dialogContext) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              width: 480,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Edit User",
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFF64748B),
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            splashRadius: 18,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(height: 1, color: const Color(0xFFE2E8F0)),
                      const SizedBox(height: 20),
                      Text(
                        "Full Name",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        initialValue: name,
                        decoration: _inputDecoration(
                          "Enter full name",
                          Icons.person_outline_rounded,
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF1E293B),
                        ),
                        validator:
                            (v) =>
                                v == null || v.isEmpty
                                    ? "Name is required"
                                    : null,
                        onSaved: (v) => name = v!,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Email Address",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        initialValue: email,
                        decoration: _inputDecoration(
                          "Enter email address",
                          Icons.mail_outline_rounded,
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF1E293B),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return "Email is required";
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(v)) {
                            return "Enter a valid email address";
                          }
                          return null;
                        },
                        onSaved: (v) => email = v!,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Phone Number",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        initialValue: phone,
                        decoration: _inputDecoration(
                          "+91 XXXXX XXXXX",
                          Icons.phone_outlined,
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF1E293B),
                        ),
                        validator:
                            (v) =>
                                v == null || v.isEmpty
                                    ? "Phone number is required"
                                    : null,
                        onSaved: (v) => phone = v!,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Address",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        initialValue: address,
                        decoration: _inputDecoration(
                          "Enter address",
                          Icons.location_on_outlined,
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF1E293B),
                        ),
                        validator:
                            (v) =>
                                v == null || v.isEmpty
                                    ? "Address is required"
                                    : null,
                        onSaved: (v) => address = v!,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "User Type",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  initialValue: userType,
                                  decoration: _inputDecoration("", null),
                                  items:
                                      ["Customer", "Admin"]
                                          .map(
                                            (type) => DropdownMenuItem(
                                              value: type,
                                              child: Text(type),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (v) => userType = v!,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Status",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  initialValue: status,
                                  decoration: _inputDecoration("", null),
                                  items:
                                      ["Active", "Suspended", "Inactive"]
                                          .map(
                                            (st) => DropdownMenuItem(
                                              value: st,
                                              child: Text(st),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (v) => status = v!,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Loyalty Points",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        initialValue: points.toString(),
                        decoration: _inputDecoration(
                          "Loyalty Points",
                          Icons.star_border_rounded,
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF1E293B),
                        ),
                        keyboardType: TextInputType.number,
                        onSaved: (v) => points = int.tryParse(v ?? "0") ?? 0,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              "Cancel",
                              style: GoogleFonts.inter(
                                color: const Color(0xFF475569),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                formKey.currentState!.save();
                                Navigator.pop(dialogContext);
                                try {
                                  await FirebaseFirestore.instance
                                      .collection("users")
                                      .doc(user.no)
                                      .update({
                                        'username': name,
                                        'email': email,
                                        'phone': phone,
                                        'address': address,
                                        'status': status,
                                        'userType': userType,
                                        'points': points,
                                      });
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "User updated successfully.",
                                      ),
                                    ),
                                  );
                                  _refreshData();
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Error updating user: $e"),
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              "Save Changes",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
          (dialogContext) => AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            title: Text(
              title,
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            content: Text(content, style: GoogleFonts.inter()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.inter(color: const Color(0xFF64748B)),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  onConfirm();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      confirmText == "Delete"
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFF97316),
                  foregroundColor: Colors.white,
                ),
                child: Text(confirmText, style: GoogleFonts.inter()),
              ),
            ],
          ),
    );
  }

  void _showBanUserDialog(UserModel user) {
    final formKey = GlobalKey<FormState>();
    String reason = "Violation of community guidelines";
    String banType = "Permanent";
    String banDuration = "7 Days";

    showDialog(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder: (context, setDialogState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                backgroundColor: Colors.transparent,
                child: Container(
                  width: 460,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Ban User: ${user.name}",
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Color(0xFF64748B),
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                splashRadius: 18,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildDialogDivider(),
                          const SizedBox(height: 20),

                          // Ban Type
                          Text(
                            "Ban Type",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: banType,
                            decoration: _inputDecoration("", null),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF1E293B),
                            ),
                            items:
                                ["Permanent", "Temporary"]
                                    .map(
                                      (type) => DropdownMenuItem(
                                        value: type,
                                        child: Text(type),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (val) {
                              setDialogState(() {
                                banType = val!;
                              });
                            },
                          ),
                          if (banType == "Temporary") ...[
                            const SizedBox(height: 16),
                            Text(
                              "Duration",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: banDuration,
                              decoration: _inputDecoration("", null),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF1E293B),
                              ),
                              items:
                                  ["1 Day", "7 Days", "30 Days"]
                                      .map(
                                        (dur) => DropdownMenuItem(
                                          value: dur,
                                          child: Text(dur),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (val) {
                                setDialogState(() {
                                  banDuration = val!;
                                });
                              },
                            ),
                          ],
                          const SizedBox(height: 16),

                          // Reason for Ban
                          Text(
                            "Reason for Ban",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            initialValue: reason,
                            decoration: _inputDecoration(
                              "Enter ban reason...",
                              null,
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF1E293B),
                            ),
                            maxLines: 3,
                            onSaved: (val) {
                              reason = val ?? "";
                            },
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return "Please enter a reason";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: Text(
                                  "Cancel",
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () async {
                                  if (formKey.currentState!.validate()) {
                                    formKey.currentState!.save();
                                    Navigator.pop(dialogContext);
                                    try {
                                      await FirebaseFirestore.instance
                                          .collection("users")
                                          .doc(user.no)
                                          .update({
                                            "status": "Banned",
                                            "banType": banType,
                                            "banReason": reason,
                                            "bannedOn": _formatDate(
                                              DateTime.now(),
                                            ),
                                            "bannedBy": "Admin",
                                            "banDuration":
                                                banType == "Temporary"
                                                    ? banDuration
                                                    : "-",
                                          });
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "${user.name} has been banned.",
                                          ),
                                        ),
                                      );
                                      _refreshData();
                                    } catch (e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Error banning user: $e",
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF4444),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  "Ban User",
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }

  void _showUserDetailsDialog(UserModel user) {
    // Status color helpers
    Color statusBg;
    Color statusFg;
    switch (user.status) {
      case "Active":
        statusBg = const Color(0xFFDCFCE7);
        statusFg = const Color(0xFF16A34A);
        break;
      case "Suspended":
        statusBg = const Color(0xFFFFEDD5);
        statusFg = const Color(0xFFEA580C);
        break;
      default:
        statusBg = const Color(0xFFF1F5F9);
        statusFg = const Color(0xFF64748B);
    }

    showDialog(
      context: context,
      builder:
          (dialogContext) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              width: 440,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Gradient header with avatar ──────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        // close button top-right
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(dialogContext),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white70,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Avatar
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white30, width: 3),
                          ),
                          child: ClipOval(
                            child: Image.network(
                              'https://randomuser.me/api/portraits/men/32.jpg',
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => Container(
                                    width: 80,
                                    height: 80,
                                    color: const Color(0xFF334155),
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.white54,
                                      size: 40,
                                    ),
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Name
                        Text(
                          user.name,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // User ID
                        Text(
                          user.userId,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white54,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: statusFg,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                user.status,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: statusFg,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Info rows ─────────────────────────────────────────────────
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      child: Column(
                        children: [
                          _buildDialogInfoRow(
                            Icons.email_outlined,
                            "Email",
                            user.email,
                          ),
                          _buildDialogDivider(),
                          _buildDialogInfoRow(
                            Icons.phone_outlined,
                            "Phone",
                            user.phone,
                          ),
                          _buildDialogDivider(),
                          _buildDialogInfoRow(
                            Icons.badge_outlined,
                            "User Type",
                            user.userType,
                          ),
                          _buildDialogDivider(),
                          _buildDialogInfoRow(
                            Icons.star_outline_rounded,
                            "Points",
                            "${user.points} pts",
                          ),
                          _buildDialogDivider(),
                          _buildDialogInfoRow(
                            Icons.calendar_today_outlined,
                            "Joined",
                            user.joinedDate,
                          ),
                          _buildDialogDivider(),
                          _buildDialogInfoRow(
                            Icons.location_on_outlined,
                            "Address",
                            user.address,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Footer close button ────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          "Close",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildDialogInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF475569)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF94A3B8),
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogDivider() {
    return Container(height: 1, color: const Color(0xFFF1F5F9));
  }

  InputDecoration _inputDecoration(String hint, IconData? prefixIcon) {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      hintText: hint.isNotEmpty ? hint : null,
      hintStyle: GoogleFonts.inter(
        color: const Color(0xFF94A3B8),
        fontSize: 13,
      ),
      prefixIcon:
          prefixIcon != null
              ? Icon(prefixIcon, color: const Color(0xFF94A3B8), size: 18)
              : null,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;

        final List<UserModel> currentPageUsers = paginatedUsers;
        final int totalItems = _totalCount;
        final int startIndex = (_currentPage - 1) * _pageSize;
        final int endIndex = startIndex + currentPageUsers.length;

        return SingleChildScrollView(
          controller: _scrollController,
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

                // Bulk Action Bar (only visible when users are selected)
                if (_selectedUserIds.isNotEmpty)
                  _buildBulkActionBar(currentPageUsers),

                if (_selectedUserIds.isNotEmpty) const SizedBox(height: 16),

                // Stats Cards Grid
                _buildStatsCardsGrid(width, currentPageUsers),
                const SizedBox(height: 24),

                // Filter Row
                _buildFilterRow(context, width, currentPageUsers),
                const SizedBox(height: 24),

                // Users Table
                _isFetching && _allFetchedDocs.isEmpty
                    ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF10B981),
                        ),
                      ),
                    )
                    : _buildUsersTable(currentPageUsers),
                const SizedBox(height: 16),

                // Pagination Footer
                _buildPaginationFooter(totalItems, startIndex, endIndex),

                if (_isFetching && _allFetchedDocs.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildBulkActionBar(List<UserModel> allUsers) {
    final int count = _selectedUserIds.length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Checkbox icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_box_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          // Count label
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "$count ",
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                TextSpan(
                  text: count == 1 ? "user selected" : "users selected",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Suspend All button
          _buildBulkButton(
            icon: Icons.lock_outline_rounded,
            label: "Suspend All",
            color: const Color(0xFFF97316),
            onTap: () {
              _showConfirmationDialog(
                title: "Suspend $count User${count > 1 ? 's' : ''}",
                content:
                    "Are you sure you want to suspend the $count selected user${count > 1 ? 's' : ''}?",
                confirmText: "Suspend",
                onConfirm: () async {
                  final batch = FirebaseFirestore.instance.batch();
                  for (final id in _selectedUserIds) {
                    batch.update(
                      FirebaseFirestore.instance.collection("users").doc(id),
                      {"status": "Suspended"},
                    );
                  }
                  await batch.commit();
                  if (!mounted) return;
                  setState(() => _selectedUserIds.clear());
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "$count user${count > 1 ? 's' : ''} suspended successfully.",
                      ),
                    ),
                  );
                  _refreshData();
                },
              );
            },
          ),
          const SizedBox(width: 10),
          // Delete All button
          _buildBulkButton(
            icon: Icons.delete_outline_rounded,
            label: "Delete All",
            color: const Color(0xFFEF4444),
            onTap: () {
              _showConfirmationDialog(
                title: "Delete $count User${count > 1 ? 's' : ''}",
                content:
                    "Are you sure you want to permanently delete the $count selected user${count > 1 ? 's' : ''}? This cannot be undone.",
                confirmText: "Delete",
                onConfirm: () async {
                  final batch = FirebaseFirestore.instance.batch();
                  for (final id in _selectedUserIds) {
                    batch.delete(
                      FirebaseFirestore.instance.collection("users").doc(id),
                    );
                  }
                  await batch.commit();
                  if (!mounted) return;
                  setState(() => _selectedUserIds.clear());
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "$count user${count > 1 ? 's' : ''} deleted.",
                      ),
                    ),
                  );
                  _refreshData();
                },
              );
            },
          ),
          const SizedBox(width: 10),
          // Clear Selection button
          TextButton.icon(
            onPressed: () => setState(() => _selectedUserIds.clear()),
            icon: const Icon(
              Icons.close_rounded,
              size: 16,
              color: Colors.white54,
            ),
            label: Text(
              "Clear",
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white54),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCardsGrid(double width, [List<UserModel>? users]) {
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

    final int totalUsers = _statTotalUsers;
    final int activeUsers = _statActiveUsers;
    final int suspendedUsers = _statSuspendedUsers;
    final int newUsersThisWeek = _statNewUsersThisWeek;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: aspectRatio > 0 ? aspectRatio : 2.0,
      children: [
        StatsCard(
          title: "Total Users",
          value: totalUsers.toString(),
          trendPercentage: "",
          trendPeriod: "All registered users",
          isPositiveTrend: true,
          icon: Icons.people_alt_rounded,
          iconColor: const Color(0xFF3B82F6),
          iconBgColor: const Color(0xFFEFF6FF),
          onTap: () {
            setState(() {
              _selectedStatus = "All Status";
            });
            _onFilterChanged();
          },
        ),
        StatsCard(
          title: "Active Users",
          value: activeUsers.toString(),
          trendPercentage: "",
          trendPeriod: "Currently active",
          isPositiveTrend: true,
          icon: Icons.group_add_rounded,
          iconColor: const Color(0xFF10B981),
          iconBgColor: const Color(0xFFECFDF5),
          onTap: () {
            setState(() {
              _selectedStatus = "Active";
            });
            _onFilterChanged();
          },
        ),
        StatsCard(
          title: "Suspended Users",
          value: suspendedUsers.toString(),
          trendPercentage: "",
          trendPeriod: "Accounts suspended",
          isPositiveTrend: false,
          icon: Icons.block_rounded,
          iconColor: const Color(0xFFF59E0B),
          iconBgColor: const Color(0xFFFEF3C7),
          onTap: () {
            setState(() {
              _selectedStatus = "Suspended";
            });
            _onFilterChanged();
          },
        ),
        StatsCard(
          title: "New Users (This Week)",
          value: newUsersThisWeek.toString(),
          trendPercentage: "",
          trendPeriod: "Joined this week",
          isPositiveTrend: true,
          icon: Icons.person_add_rounded,
          iconColor: const Color(0xFF8B5CF6),
          iconBgColor: const Color(0xFFF5F3FF),
        ),
      ],
    );
  }

  Widget _buildFilterRow(
    BuildContext context,
    double width,
    List<UserModel> filteredUsers,
  ) {
    final bool isSmall = width < 850;

    final searchField = SizedBox(
      width: isSmall ? double.infinity : 260,
      height: 38,
      child: TextFormField(
        controller: _searchController,
        onChanged: _onSearchChanged,
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
        onChanged: (val) {
          setState(() {
            _selectedStatus = val!;
          });
          _onFilterChanged();
        },
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
        onChanged: (val) {
          setState(() {
            _selectedType = val!;
          });
          _onFilterChanged();
        },
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
          _onFilterChanged();
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
        printUsersList(filteredUsers);
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

    final addUserButton = ElevatedButton.icon(
      onPressed: () => _showAddUserDialog(),
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
              width: 1300,
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
                  8: FixedColumnWidth(380), // Actions
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
                              "View",
                              () {
                                _showUserDetailsDialog(user);
                              },
                            ),
                            const SizedBox(width: 6),
                            _buildActionButton(
                              Icons.edit_outlined,
                              Colors.blue,
                              "Edit",
                              () {
                                _showEditUserDialog(user);
                              },
                            ),
                            const SizedBox(width: 6),
                            if (user.status == "Suspended")
                              _buildActionButton(
                                Icons.lock_open_rounded,
                                Colors.green,
                                "Activate",
                                () {
                                  _showConfirmationDialog(
                                    title: "Confirm Activation",
                                    content:
                                        "Are you sure you want to activate ${user.name}?",
                                    confirmText: "Activate",
                                    onConfirm: () async {
                                      try {
                                        await FirebaseFirestore.instance
                                            .collection("users")
                                            .doc(user.no)
                                            .update({"status": "Active"});
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "${user.name} activated successfully.",
                                            ),
                                          ),
                                        );
                                        _refreshData();
                                      } catch (e) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "Error activating user: $e",
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  );
                                },
                              )
                            else
                              _buildActionButton(
                                Icons.lock_outline_rounded,
                                Colors.orange,
                                "Suspend",
                                () {
                                  _showConfirmationDialog(
                                    title: "Confirm Suspension",
                                    content:
                                        "Are you sure you want to suspend ${user.name}?",
                                    confirmText: "Suspend",
                                    onConfirm: () async {
                                      try {
                                        await FirebaseFirestore.instance
                                            .collection("users")
                                            .doc(user.no)
                                            .update({"status": "Suspended"});
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "${user.name} suspended successfully.",
                                            ),
                                          ),
                                        );
                                        _refreshData();
                                      } catch (e) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "Error suspending user: $e",
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  );
                                },
                              ),
                            const SizedBox(width: 6),
                            _buildActionButton(
                              Icons.delete_outline_rounded,
                              Colors.red,
                              "Delete",
                              () {
                                _showConfirmationDialog(
                                  title: "Confirm Delete",
                                  content:
                                      "Are you sure you want to delete ${user.name}?",
                                  confirmText: "Delete",
                                  onConfirm: () async {
                                    try {
                                      await FirebaseFirestore.instance
                                          .collection("users")
                                          .doc(user.no)
                                          .delete();
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "${user.name} has been deleted.",
                                          ),
                                        ),
                                      );
                                      _refreshData();
                                    } catch (e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Error deleting user: $e",
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                            const SizedBox(width: 6),
                            _buildActionButton(
                              Icons.gavel_rounded,
                              Colors.red,
                              "Ban",
                              () {
                                _showBanUserDialog(user);
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

  // Widget _buildUserTypeBadge(String type) {
  //   return Align(
  //     alignment: Alignment.centerLeft,
  //     child: Container(
  //       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //       decoration: BoxDecoration(
  //         color: const Color(0xFFEFF6FF), // Tinted blue
  //         borderRadius: BorderRadius.circular(6),
  //       ),
  //       child: Text(
  //         type,
  //         style: GoogleFonts.inter(
  //           fontSize: 11,
  //           fontWeight: FontWeight.bold,
  //           color: const Color(0xFF3B82F6),
  //         ),
  //       ),
  //     ),
  //   );
  // }
  Widget _buildUserTypeBadge(String type) {
    final isAdmin = type.toLowerCase() == 'admin';

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isAdmin ? const Color(0xFFF3F4F6) : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          type,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isAdmin ? Colors.black : const Color(0xFF3B82F6),
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

  Widget _buildActionButton(
    IconData icon,
    Color color,
    String label,
    VoidCallback onTap,
  ) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
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
                  _currentPage > 1 ? () => _changePage(_currentPage - 1) : null,
            ),
            ...List.generate(totalPages, (index) {
              final int page = index + 1;
              final bool isSelected = page == _currentPage;
              return InkWell(
                onTap: () => _changePage(page),
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
                  _currentPage < totalPages || _hasMore
                      ? () => _changePage(_currentPage + 1)
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
            onChanged: (val) {
              setState(() {
                _pageSize = val!;
                _currentPage = 1;
              });
              _refreshData();
            },
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
  final VoidCallback? onTap;

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
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
