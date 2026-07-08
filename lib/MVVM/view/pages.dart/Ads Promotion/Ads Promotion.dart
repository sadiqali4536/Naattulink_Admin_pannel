import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swiftclean_admin/MVVM/utils/imagekit_service.dart';

/// Models representing an advertisement banner
class AdBanner {
  final String id;
  final String title;
  final String description;
  final String category;
  final String imageUrl;
  final String buttonText;
  final String bannerAction;
  final String actionValue;
  final String advertiserName;
  final String phone;
  final String email;
  final String website;
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final int priority;
  final bool isActive;
  final bool isFeatured;
  final String bannerPosition;
  final int totalViews;
  final int totalClicks;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? localAdsConfig;

  AdBanner({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.buttonText,
    required this.bannerAction,
    required this.actionValue,
    required this.advertiserName,
    required this.phone,
    required this.email,
    required this.website,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.priority,
    required this.isActive,
    required this.isFeatured,
    required this.bannerPosition,
    required this.totalViews,
    required this.totalClicks,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.localAdsConfig,
  });

  factory AdBanner.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdBanner(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      buttonText: data['buttonText'] ?? '',
      bannerAction: data['bannerAction'] ?? data['buttonAction'] ?? '',
      actionValue: data['actionValue'] ?? '',
      advertiserName: data['advertiserName'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      website: data['website'] ?? '',
      location: data['location'] ?? '',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      priority: data['priority'] ?? 50,
      isActive: data['isActive'] ?? false,
      isFeatured: data['isFeatured'] ?? false,
      bannerPosition: data['bannerPosition'] ?? 'Home -> For You',
      totalViews: data['totalViews'] ?? 0,
      totalClicks: data['totalClicks'] ?? 0,
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      localAdsConfig:
          data['localAdsConfig'] != null
              ? Map<String, dynamic>.from(data['localAdsConfig'])
              : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'buttonText': buttonText,
      'bannerAction': bannerAction,
      'buttonAction':
          bannerAction, // for backward compatibility with old mobile clients
      'actionValue': actionValue,
      'advertiserName': advertiserName,
      'phone': phone,
      'email': email,
      'website': website,
      'location': location,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'priority': priority,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'bannerPosition': bannerPosition,
      'totalViews': totalViews,
      'totalClicks': totalClicks,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
      'localAdsConfig': localAdsConfig,
    };
  }
}

class Adspromotion extends StatefulWidget {
  const Adspromotion({super.key});

  @override
  State<Adspromotion> createState() => _AdspromotionState();
}

class _AdspromotionState extends State<Adspromotion> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  String _selectedFilterPosition = 'All';
  String _selectedFilterStatus = 'All';
  String _selectedSortBy = 'Priority (High to Low)';

  // Design Theme Constants
  static const Color primaryNavy = Color(0xFF0F2D62);
  static const Color secondaryYellow = Color(0xFFF4B400);
  static const Color backgroundGrey = Color(0xFFF5F7FA);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color textDark = Color(0xFF1F2937);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: backgroundGrey,
        body: Center(
          child: Text(
            "Please login to access the admin panel.",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    // Default admin bypass
    if (user.email == 'swiftcleanaccount@gmail.com') {
      return _buildAdminDashboard();
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: backgroundGrey,
            body: Center(child: CircularProgressIndicator(color: primaryNavy)),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildAccessDenied("User document not found in Firestore.");
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final role = userData?['role'];

        if (role != 'admin') {
          return _buildAccessDenied(
            "Required administrator role ('admin') missing.",
          );
        }

        return _buildAdminDashboard();
      },
    );
  }

  Widget _buildAccessDenied(String reason) {
    return Scaffold(
      backgroundColor: backgroundGrey,
      body: Center(
        child: Container(
          width: 500,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.gpp_bad_rounded,
                size: 80,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 24),
              Text(
                "Access Denied",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "This section is restricted to NaattuLink System Administrators only.",
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  color: textGrey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Reason: $reason",
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Colors.red[400],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => FirebaseAuth.instance.signOut(),
                icon: const Icon(Icons.logout),
                label: const Text("Log Out"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  foregroundColor: textDark,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminDashboard() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('advertisements').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: primaryNavy),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final allBanners =
            docs.map((doc) => AdBanner.fromFirestore(doc)).toList();

        // Calculate statistics
        final now = DateTime.now();
        int totalCount = allBanners.length;
        int activeCount = 0;
        int scheduledCount = 0;
        int expiredCount = 0;

        for (var b in allBanners) {
          final status = _calculateStatus(b, now);
          if (status == 'Active') activeCount++;
          if (status == 'Scheduled') scheduledCount++;
          if (status == 'Expired') expiredCount++;
        }

        // Apply filters
        var filteredBanners =
            allBanners.where((banner) {
              // Search query matching title, advertiser name, category
              final query = _searchQuery.toLowerCase();
              final matchesSearch =
                  banner.title.toLowerCase().contains(query) ||
                  banner.advertiserName.toLowerCase().contains(query) ||
                  banner.category.toLowerCase().contains(query);

              // Position filter
              final matchesPosition =
                  _selectedFilterPosition == 'All' ||
                  banner.bannerPosition == _selectedFilterPosition;

              // Status filter
              final status = _calculateStatus(banner, now);
              final matchesStatus =
                  _selectedFilterStatus == 'All' ||
                  status == _selectedFilterStatus;

              return matchesSearch && matchesPosition && matchesStatus;
            }).toList();

        // Sorting
        filteredBanners.sort((a, b) {
          if (_selectedSortBy == 'Priority (High to Low)') {
            return b.priority.compareTo(a.priority);
          } else if (_selectedSortBy == 'Priority (Low to High)') {
            return a.priority.compareTo(b.priority);
          } else if (_selectedSortBy == 'Created Date') {
            return b.createdAt.compareTo(a.createdAt);
          } else {
            return a.title.toLowerCase().compareTo(b.title.toLowerCase());
          }
        });

        return Container(
          color: backgroundGrey,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dashboard Header Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Advertisement Banners",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Configure sliding banners, category campaigns, and Local Ads details",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: textGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openBannerFormDialog(null),
                    icon: const Icon(
                      Icons.add_photo_alternate_rounded,
                      color: Colors.white,
                    ),
                    label: Text(
                      "Create Advertisement",
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryNavy,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Overview Metric Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 750;
                  return isMobile
                      ? Column(
                        children: [
                          _buildMetricCard(
                            "Total Banners",
                            totalCount.toString(),
                            Icons.campaign_rounded,
                            primaryNavy,
                          ),
                          const SizedBox(height: 12),
                          _buildMetricCard(
                            "Active Ads",
                            activeCount.toString(),
                            Icons.check_circle_outline_rounded,
                            Colors.green,
                          ),
                          const SizedBox(height: 12),
                          _buildMetricCard(
                            "Scheduled",
                            scheduledCount.toString(),
                            Icons.schedule_rounded,
                            secondaryYellow,
                          ),
                          const SizedBox(height: 12),
                          _buildMetricCard(
                            "Expired / Draft",
                            expiredCount.toString(),
                            Icons.history_rounded,
                            textGrey,
                          ),
                        ],
                      )
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              "Total Banners",
                              totalCount.toString(),
                              Icons.campaign_rounded,
                              primaryNavy,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildMetricCard(
                              "Active Ads",
                              activeCount.toString(),
                              Icons.check_circle_outline_rounded,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildMetricCard(
                              "Scheduled",
                              scheduledCount.toString(),
                              Icons.schedule_rounded,
                              secondaryYellow,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildMetricCard(
                              "Expired / Draft",
                              (expiredCount +
                                      (totalCount -
                                          activeCount -
                                          scheduledCount -
                                          expiredCount))
                                  .toString(),
                              Icons.history_rounded,
                              textGrey,
                            ),
                          ),
                        ],
                      );
                },
              ),
              const SizedBox(height: 24),

              // Filter & Search Toolbar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.01),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, toolbarConstraints) {
                    final isToolbarCompact = toolbarConstraints.maxWidth < 900;
                    final searchField = Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: backgroundGrey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: textDark,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              "Search banners, advertisers, categories...",
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: textGrey,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: textGrey,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    );

                    final filters = [
                      _buildToolbarDropdown(
                        label: "Placement",
                        value: _selectedFilterPosition,
                        items: [
                          'All',
                          'Home -> For You',
                          'Home -> Workers',
                          'Home -> Bus',
                          'Home -> Local Ads',
                          'Home -> Online Shops',
                        ],
                        onChanged:
                            (val) =>
                                setState(() => _selectedFilterPosition = val!),
                      ),
                      const SizedBox(width: 12),
                      _buildToolbarDropdown(
                        label: "Status",
                        value: _selectedFilterStatus,
                        items: [
                          'All',
                          'Active',
                          'Scheduled',
                          'Expired',
                          'Inactive',
                        ],
                        onChanged:
                            (val) =>
                                setState(() => _selectedFilterStatus = val!),
                      ),
                      const SizedBox(width: 12),
                      _buildToolbarDropdown(
                        label: "Sort By",
                        value: _selectedSortBy,
                        items: [
                          'Priority (High to Low)',
                          'Priority (Low to High)',
                          'Created Date',
                          'Title',
                        ],
                        onChanged:
                            (val) => setState(() => _selectedSortBy = val!),
                      ),
                    ];

                    return isToolbarCompact
                        ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: searchField,
                            ),
                            const SizedBox(height: 12),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(children: filters),
                            ),
                          ],
                        )
                        : Row(
                          children: [
                            Expanded(flex: 3, child: searchField),
                            const SizedBox(width: 20),
                            ...filters,
                          ],
                        );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Banners Grid Layout
              filteredBanners.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.broken_image_outlined,
                          size: 64,
                          color: textGrey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No advertisements match the criteria.",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            color: textGrey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                  : LayoutBuilder(
                    builder: (context, gridConstraints) {
                      int columns = 1;
                      if (gridConstraints.maxWidth > 1200) {
                        columns = 4;
                      } else if (gridConstraints.maxWidth > 800) {
                        columns = 2;
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredBanners.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.76,
                        ),
                        itemBuilder: (context, index) {
                          return _buildBannerCard(filteredBanners[index], now);
                        },
                      );
                    },
                  ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: textGrey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: backgroundGrey,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: textDark,
            fontWeight: FontWeight.w600,
          ),
          onChanged: onChanged,
          items:
              items.map((item) {
                return DropdownMenuItem<String>(value: item, child: Text(item));
              }).toList(),
        ),
      ),
    );
  }

  String _calculateStatus(AdBanner b, DateTime now) {
    if (!b.isActive) return 'Inactive';
    if (now.isBefore(b.startDate)) return 'Scheduled';
    if (now.isAfter(b.endDate)) return 'Expired';
    return 'Active';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.green;
      case 'Scheduled':
        return secondaryYellow;
      case 'Expired':
        return Colors.red;
      default:
        return textGrey;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  Widget _buildBannerCard(AdBanner banner, DateTime now) {
    final status = _calculateStatus(banner, now);
    final statusColor = _getStatusColor(status);
    final double ctr =
        banner.totalViews > 0
            ? (banner.totalClicks / banner.totalViews) * 100
            : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image & Badge Overlay
          AspectRatio(
            aspectRatio: 12 / 5,
            child: Stack(
              children: [
                Positioned.fill(
                  child:
                      banner.imageUrl.isNotEmpty
                          ? Image.network(
                            banner.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => Container(
                                  color: Colors.grey[100],
                                  child: const Icon(
                                    Icons.broken_image,
                                    size: 40,
                                    color: textGrey,
                                  ),
                                ),
                          )
                          : Container(
                            color: Colors.grey[100],
                            child: const Icon(
                              Icons.image,
                              color: textGrey,
                              size: 40,
                            ),
                          ),
                ),
                // Position tag overlay
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primaryNavy,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      banner.bannerPosition,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Priority Tag Right
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: secondaryYellow,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "Prio: ${banner.priority}",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        color: textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details Section — compact, no Expanded so it doesn't over-stretch
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category + Status row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: primaryNavy.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        banner.category,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: primaryNavy,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Title
                Text(
                  banner.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 3),

                // Description
                Text(
                  banner.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: textGrey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),

                // Advertiser info
                Row(
                  children: [
                    const Icon(
                      Icons.business_rounded,
                      size: 12,
                      color: textGrey,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        banner.advertiserName.isNotEmpty
                            ? banner.advertiserName
                            : 'Direct Booking',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: textDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),

                // Date range
                Row(
                  children: [
                    const Icon(
                      Icons.date_range_rounded,
                      size: 12,
                      color: textGrey,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${_formatDate(banner.startDate)} – ${_formatDate(banner.endDate)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: textGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),

                // Analytics + action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${banner.totalViews} Views | ${banner.totalClicks} Clicks',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: textGrey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'CTR: ${ctr.toStringAsFixed(1)}%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: primaryNavy,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.scale(
                          scale: 0.7,
                          child: Switch(
                            value: banner.isActive,
                            activeThumbColor: Colors.green,
                            inactiveTrackColor: Colors.grey[200],
                            onChanged: (bool newVal) {
                              _firestore
                                  .collection('advertisements')
                                  .doc(banner.id)
                                  .update({'isActive': newVal});
                            },
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: textGrey,
                          ),
                          onPressed: () => _openBannerFormDialog(banner),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _confirmDeleteBanner(banner),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteBanner(AdBanner banner) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              "Delete Advertisement",
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            ),
            content: Text(
              "Are you sure you want to permanently delete '${banner.title}'? This action cannot be undone.",
              style: GoogleFonts.plusJakartaSans(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.plusJakartaSans(color: textGrey),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  try {
                    await _firestore
                        .collection('advertisements')
                        .doc(banner.id)
                        .delete();
                    // Note: ImageKit images are managed separately.
                    // To delete from ImageKit, use the ImageKit Media Management API.
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Advertisement deleted successfully!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Error deleting: $e"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text(
                  "Delete",
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _openBannerFormDialog(AdBanner? existingBanner) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => BannerFormDialog(
            existingBanner: existingBanner,
            onSaved: () {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      existingBanner == null
                          ? "Banner created successfully!"
                          : "Banner updated successfully!",
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
    );
  }
}

class BannerFormDialog extends StatefulWidget {
  final AdBanner? existingBanner;
  final VoidCallback onSaved;

  const BannerFormDialog({
    super.key,
    this.existingBanner,
    required this.onSaved,
  });

  @override
  State<BannerFormDialog> createState() => _BannerFormDialogState();
}

class _BannerFormDialogState extends State<BannerFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _advertiserController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  late TextEditingController _locationController;
  late TextEditingController _actionValueController;
  late TextEditingController _customButtonTextController;
  late TextEditingController _imageUrlController;

  // Local Ads Config Controllers
  late TextEditingController _localProductNameController;
  late TextEditingController _localOriginalPriceController;
  late TextEditingController _localOfferPriceController;
  late TextEditingController _localDiscountController;
  late TextEditingController _localOfferBadgeController;
  late TextEditingController _localShortDescController;

  // Selected values
  String _selectedCategory = 'Business';
  String _selectedButtonText = 'Learn More';
  String _selectedBannerAction = 'Open URL';
  String _selectedPosition = 'Home -> For You';
  String _localOfferType = 'Product Offer';

  bool _noTextButton = false;

  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 0, minute: 0);
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  TimeOfDay _endTime = const TimeOfDay(hour: 23, minute: 59);

  bool _isActive = true;
  bool _isFeatured = false;
  double _priority = 50.0;

  // Image upload states
  Uint8List? _imageBytes;
  String? _imageName;
  String? _currentImageUrl;

  Uint8List? _localProductBytes;
  String? _localProductName;
  String? _currentLocalProductImageUrl;

  double _uploadProgress = 0.0;
  bool _isUploading = false;

  String _dimensionsText = "No image selected";
  String _localDimensionsText = "No product image selected";
  bool _isImageValid = true;

  @override
  void initState() {
    super.initState();
    final b = widget.existingBanner;

    _titleController = TextEditingController(text: b?.title ?? '');
    _descController = TextEditingController(text: b?.description ?? '');
    _advertiserController = TextEditingController(
      text: b?.advertiserName ?? '',
    );
    _phoneController = TextEditingController(text: b?.phone ?? '');
    _emailController = TextEditingController(text: b?.email ?? '');
    _websiteController = TextEditingController(text: b?.website ?? '');
    _locationController = TextEditingController(text: b?.location ?? '');
    _actionValueController = TextEditingController(text: b?.actionValue ?? '');
    _imageUrlController = TextEditingController(text: b?.imageUrl ?? '');
    _imageUrlController.addListener(() {
      if (mounted) setState(() {});
    });

    // Local Ads configuration initialization
    final lac = b?.localAdsConfig;
    _localProductNameController = TextEditingController(
      text: lac?['productName'] ?? '',
    );
    _localOriginalPriceController = TextEditingController(
      text: lac?['originalPrice']?.toString() ?? '',
    );
    _localOfferPriceController = TextEditingController(
      text: lac?['offerPrice']?.toString() ?? '',
    );
    _localDiscountController = TextEditingController(
      text: lac?['discountPercentage']?.toString() ?? '',
    );
    _localOfferBadgeController = TextEditingController(
      text: lac?['offerBadge'] ?? '',
    );
    _localShortDescController = TextEditingController(
      text: lac?['shortDescription'] ?? '',
    );

    _localOriginalPriceController.addListener(_autoCalculateDiscount);
    _localOfferPriceController.addListener(_autoCalculateDiscount);

    if (b != null) {
      _selectedCategory = b.category;
      _selectedBannerAction = b.bannerAction;
      _selectedPosition = b.bannerPosition;
      _currentImageUrl = b.imageUrl;
      _isActive = b.isActive;
      _isFeatured = b.isFeatured;
      _priority = b.priority.toDouble();
      _startDate = b.startDate;
      _startTime = TimeOfDay.fromDateTime(b.startDate);
      _endDate = b.endDate;
      _endTime = TimeOfDay.fromDateTime(b.endDate);

      _noTextButton = b.buttonText == 'No Text';

      if (_noTextButton) {
        _selectedButtonText = 'Learn More';
        _customButtonTextController = TextEditingController();
      } else {
        const predefined = [
          'Contact Us',
          'Learn More',
          'Book Now',
          'Shop Now',
          'View Details',
          'Call Now',
        ];
        if (predefined.contains(b.buttonText)) {
          _selectedButtonText = b.buttonText;
          _customButtonTextController = TextEditingController();
        } else {
          _selectedButtonText = 'Custom';
          _customButtonTextController = TextEditingController(
            text: b.buttonText,
          );
        }
      }

      if (lac != null) {
        _localOfferType = lac['offerType'] ?? 'Product Offer';
        _currentLocalProductImageUrl = lac['productImageUrl'];
      }
    } else {
      _customButtonTextController = TextEditingController();
    }
  }

  void _autoCalculateDiscount() {
    final double orig =
        double.tryParse(_localOriginalPriceController.text) ?? 0.0;
    final double offer =
        double.tryParse(_localOfferPriceController.text) ?? 0.0;
    if (orig > 0 && offer > 0 && offer <= orig) {
      final double discount = ((orig - offer) / orig) * 100;
      _localDiscountController.text = discount.toStringAsFixed(0);
      _localOfferBadgeController.text = "${discount.toStringAsFixed(0)}% OFF";
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _advertiserController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _locationController.dispose();
    _actionValueController.dispose();
    _customButtonTextController.dispose();
    _imageUrlController.dispose();

    _localProductNameController.dispose();
    _localOriginalPriceController.dispose();
    _localOfferPriceController.dispose();
    _localDiscountController.dispose();
    _localOfferBadgeController.dispose();
    _localShortDescController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isMainBanner) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ImageKitService.allowedExtensions,
      );
      if (!mounted) return;
      if (result != null) {
        final pickedFile = result.files.single;
        final fileBytes = pickedFile.bytes;
        final fileSize = pickedFile.size;
        final fileName = pickedFile.name;

        // Validate file extension
        if (!ImageKitService.isAllowedExtension(fileName)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Error: Only JPG, JPEG, PNG, and WEBP images are allowed.",
              ),
              backgroundColor: _AdspromotionState.secondaryYellow,
            ),
          );
          return;
        }

        // Validate file size (10 MB limit)
        if (fileSize > ImageKitService.maxFileSizeBytes) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Error: Image exceeds the maximum limit of 10 MB."),
              backgroundColor: _AdspromotionState.secondaryYellow,
            ),
          );
          return;
        }

        Uint8List resolvedBytes;

        if (kIsWeb) {
          resolvedBytes = fileBytes!;
        } else {
          final path = pickedFile.path!;
          resolvedBytes = await File(path).readAsBytes();
        }

        final decodedImage = await decodeImageFromList(resolvedBytes);
        final dimText =
            "${decodedImage.width} × ${decodedImage.height} px "
            "(${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB)";

        setState(() {
          if (isMainBanner) {
            _imageBytes = resolvedBytes;
            _imageName = fileName;
            _dimensionsText = dimText;
            _isImageValid = true;
          } else {
            _localProductBytes = resolvedBytes;
            _localProductName = fileName;
            _localDimensionsText = dimText;
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to pick image: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (pickedDate != null) {
      setState(() {
        if (isStart) {
          _startDate = pickedDate;
        } else {
          _endDate = pickedDate;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (pickedTime != null) {
      setState(() {
        if (isStart) {
          _startTime = pickedTime;
        } else {
          _endTime = pickedTime;
        }
      });
    }
  }

  Future<void> _saveForm(bool makeActive) async {
    debugPrint("DEBUG: _saveForm called. makeActive: $makeActive");
    if (!_formKey.currentState!.validate()) {
      debugPrint("DEBUG: Form validation failed.");
      return;
    }
    if (_imageBytes == null && _currentImageUrl == null) {
      debugPrint("DEBUG: Image bytes and current image URL are both null.");
      setState(() => _isImageValid = false);
      return;
    }

    setState(() {
      _isUploading = true;
      _isActive = makeActive;
    });

    try {
      String finalImageUrl = _currentImageUrl ?? '';
      String finalProductImageUrl = _currentLocalProductImageUrl ?? '';

      // 1. Upload Main Banner Image via ImageKit
      if (_imageBytes != null) {
        debugPrint('DEBUG: Starting main banner ImageKit upload...');
        final filename = ImageKitService.generateFileName(
          _imageName ?? 'banner.png',
          'banner',
        );
        debugPrint('DEBUG: ImageKit target filename: $filename, folder: banners');

        finalImageUrl = await ImageKitService.uploadImage(
          imageBytes: _imageBytes!,
          fileName: filename,
          folder: 'banners',
          onProgress: (progress) {
            debugPrint(
              'DEBUG: ImageKit upload progress: ${(progress * 100).toStringAsFixed(1)}%',
            );
            if (mounted) {
              setState(() => _uploadProgress = progress);
            }
          },
        );
        debugPrint('DEBUG: ImageKit upload successful. URL: $finalImageUrl');
      }

      // 2. Upload Local Ads Product Image via ImageKit
      if (_selectedPosition == 'Home -> Local Ads' &&
          _localProductBytes != null) {
        debugPrint('DEBUG: Starting local product ImageKit upload...');
        final filename = ImageKitService.generateFileName(
          _localProductName ?? 'product.png',
          'prod',
        );

        finalProductImageUrl = await ImageKitService.uploadImage(
          imageBytes: _localProductBytes!,
          fileName: filename,
          folder: 'local_products',
          onProgress: (progress) {
            if (mounted) {
              setState(() => _uploadProgress = progress);
            }
          },
        );
        debugPrint(
          'DEBUG: Local product ImageKit upload successful. URL: $finalProductImageUrl',
        );
      }

      // Compile CTA button display text
      final String resolvedButtonText =
          _noTextButton
              ? 'No Text'
              : (_selectedButtonText == 'Custom'
                  ? _customButtonTextController.text.trim()
                  : _selectedButtonText);

      final startDateTime = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      final endDateTime = DateTime(
        _endDate.year,
        _endDate.month,
        _endDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      final adminEmail =
          FirebaseAuth.instance.currentUser?.email ?? 'System Admin';

      // Compile Local Ads configurations map if selected
      Map<String, dynamic>? localConfig;
      if (_selectedPosition == 'Home -> Local Ads') {
        localConfig = {
          'offerType': _localOfferType,
          'productName': _localProductNameController.text.trim(),
          'productImageUrl': finalProductImageUrl,
          'originalPrice':
              double.tryParse(_localOriginalPriceController.text) ?? 0.0,
          'offerPrice': double.tryParse(_localOfferPriceController.text) ?? 0.0,
          'discountPercentage':
              double.tryParse(_localDiscountController.text) ?? 0.0,
          'offerBadge': _localOfferBadgeController.text.trim(),
          'shortDescription': _localShortDescController.text.trim(),
        };
      }

      final docData = {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'category': _selectedCategory,
        'imageUrl': finalImageUrl,
        'buttonText': resolvedButtonText,
        'bannerAction': _selectedBannerAction,
        'buttonAction': _selectedBannerAction, // backward compatibility
        'actionValue': _actionValueController.text.trim(),
        'advertiserName': _advertiserController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'website': _websiteController.text.trim(),
        'location': _locationController.text.trim(),
        'startDate': Timestamp.fromDate(startDateTime),
        'endDate': Timestamp.fromDate(endDateTime),
        'priority': _priority.toInt(),
        'isActive': _isActive,
        'isFeatured': _isFeatured,
        'bannerPosition': _selectedPosition,
        'totalViews': widget.existingBanner?.totalViews ?? 0,
        'totalClicks': widget.existingBanner?.totalClicks ?? 0,
        'createdBy':
            widget.existingBanner?.createdBy.isNotEmpty == true
                ? widget.existingBanner!.createdBy
                : adminEmail,
        'createdAt':
            widget.existingBanner != null
                ? Timestamp.fromDate(widget.existingBanner!.createdAt)
                : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'localAdsConfig': localConfig,
      };

      debugPrint(
        "DEBUG: Document compiled. Writing to Firestore advertisements collection...",
      );
      if (widget.existingBanner == null) {
        await FirebaseFirestore.instance
            .collection('advertisements')
            .add(docData);
        debugPrint(
          "DEBUG: Document added successfully to advertisements collection.",
        );
      } else {
        await FirebaseFirestore.instance
            .collection('advertisements')
            .doc(widget.existingBanner!.id)
            .update(docData);
        debugPrint(
          "DEBUG: Document updated successfully in advertisements collection.",
        );
      }

      widget.onSaved();
      debugPrint("DEBUG: onSaved callback invoked.");
      if (mounted) {
        debugPrint("DEBUG: Navigator.pop(context) about to be called.");
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("DEBUG: Exception caught during _saveForm execution: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving advertisement: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double dialogWidth =
        MediaQuery.of(context).size.width > 900 ? 880 : double.infinity;
    final bool isWide = MediaQuery.of(context).size.width > 900;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 4,
      child: Container(
        width: dialogWidth,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Dialog Bar
            Container(
              padding: const EdgeInsets.all(20),
              color: _AdspromotionState.primaryNavy.withValues(alpha: 0.04),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.add_photo_alternate_rounded,
                        color: _AdspromotionState.primaryNavy,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.existingBanner == null
                            ? "Create Advertisement"
                            : "Edit Advertisement",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _AdspromotionState.textDark,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed:
                        _isUploading ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Scrollable Forms Contents
            Expanded(
              child:
                  _isUploading
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              value:
                                  _uploadProgress > 0 ? _uploadProgress : null,
                              color: _AdspromotionState.primaryNavy,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _uploadProgress > 0
                                  ? "Uploading media file: ${(_uploadProgress * 100).toStringAsFixed(0)}%"
                                  : "Publishing database campaign...",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _AdspromotionState.textDark,
                              ),
                            ),
                          ],
                        ),
                      )
                      : SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isWide)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _buildBasicInfoSection()),
                                    const SizedBox(width: 24),
                                    Expanded(child: _buildBannerMediaSection()),
                                  ],
                                )
                              else ...[
                                _buildBasicInfoSection(),
                                const SizedBox(height: 24),
                                _buildBannerMediaSection(),
                              ],
                              const Divider(
                                height: 40,
                                color: _AdspromotionState.borderLight,
                              ),
                              if (isWide)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _buildCtaSection()),
                                    const SizedBox(width: 24),
                                    Expanded(child: _buildDetailsSection()),
                                  ],
                                )
                              else ...[
                                _buildCtaSection(),
                                const SizedBox(height: 24),
                                _buildDetailsSection(),
                              ],

                              // Dynamically revealed Local Ads section
                              if (_selectedPosition == 'Home -> Local Ads') ...[
                                const Divider(
                                  height: 40,
                                  color: _AdspromotionState.borderLight,
                                ),
                                _buildLocalAdsSection(isWide),
                              ],

                              const Divider(
                                height: 40,
                                color: _AdspromotionState.borderLight,
                              ),
                              if (isWide)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _buildSchedulingSection()),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: _buildDisplaySettingsSection(),
                                    ),
                                  ],
                                )
                              else ...[
                                _buildSchedulingSection(),
                                const SizedBox(height: 24),
                                _buildDisplaySettingsSection(),
                              ],
                            ],
                          ),
                        ),
                      ),
            ),

            // Bottom sticky action bar
            if (!_isUploading)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: _AdspromotionState.borderLight),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        side: const BorderSide(
                          color: _AdspromotionState.primaryNavy,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.plusJakartaSans(
                          color: _AdspromotionState.primaryNavy,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => _saveForm(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _AdspromotionState.primaryNavy,
                        elevation: 0,
                        side: const BorderSide(
                          color: _AdspromotionState.borderLight,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "Save Draft",
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => _saveForm(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _AdspromotionState.primaryNavy,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "Publish Advertisement",
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
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
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Basic Information"),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _titleController,
          label: "Advertisement Title *",
          validator:
              (value) =>
                  value == null || value.trim().isEmpty
                      ? "Title is required"
                      : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _descController,
          label: "Short Description *",
          maxLines: 3,
          validator:
              (value) =>
                  value == null || value.trim().isEmpty
                      ? "Description is required"
                      : null,
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: "Advertisement Category *",
          value: _selectedCategory,
          items: [
            'Business',
            'Product',
            'Service',
            'Vehicle',
            'Property',
            'Job',
            'Event',
            'Education',
            'Travel',
            'Shopping',
            'Other',
          ],
          onChanged: (val) => setState(() => _selectedCategory = val!),
        ),
      ],
    );
  }

  Widget _buildBannerMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Banner Media"),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _AdspromotionState.backgroundGrey,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  _isImageValid ? _AdspromotionState.borderLight : Colors.red,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Upload Banner Image *",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _AdspromotionState.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Recommended Size: 1200 × 500 px",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: _AdspromotionState.textGrey,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(true),
                    icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                    label: const Text("Choose File"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _AdspromotionState.primaryNavy,
                      elevation: 0,
                      side: const BorderSide(
                        color: _AdspromotionState.primaryNavy,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "Image State: $_dimensionsText",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color:
                      _isImageValid ? _AdspromotionState.textGrey : Colors.red,
                  fontWeight:
                      _isImageValid ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Visual Interactive Crop Frame
              AspectRatio(
                aspectRatio: 12 / 5,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _AdspromotionState.borderLight),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child:
                      _imageBytes != null
                          ? VisualCropPreview(
                            imageBytes: _imageBytes!,
                            onCropChanged: (scale, offset) {
                              // Crop parameters can be used here if needed
                            },
                          )
                          : _currentImageUrl != null
                          ? Image.network(_currentImageUrl!, fit: BoxFit.cover)
                          : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.add_photo_alternate_rounded,
                                  size: 36,
                                  color: _AdspromotionState.textGrey,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "No banner media selected",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: _AdspromotionState.textGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCtaSection() {
    String actionLabel = "Action Value";
    String hintText = "";
    TextInputType inputType = TextInputType.text;
    String? Function(String?)? validator;

    switch (_selectedBannerAction) {
      case 'Open URL':
        actionLabel = "Website URL *";
        hintText = "https://example.com/promo";
        inputType = TextInputType.url;
        validator = (val) {
          if (val == null || val.trim().isEmpty) return "URL is required";
          if (!val.trim().startsWith("http://") &&
              !val.trim().startsWith("https://")) {
            return "Must start with http:// or https://";
          }
          return null;
        };
        break;
      case 'Open WhatsApp':
        actionLabel = "WhatsApp Phone Number *";
        hintText = "+919876543210 (Country code mandatory)";
        inputType = TextInputType.phone;
        validator =
            (val) =>
                val == null || val.trim().isEmpty
                    ? "WhatsApp phone is required"
                    : null;
        break;
      case 'Call Phone':
        actionLabel = "Dial Phone Number *";
        hintText = "+919876543210";
        inputType = TextInputType.phone;
        validator =
            (val) =>
                val == null || val.trim().isEmpty
                    ? "Phone number is required"
                    : null;
        break;
      case 'Open In-App Page':
        actionLabel = "In-App Deep Link / Path *";
        hintText = "nattulink://homescreen/promo";
        validator =
            (val) =>
                val == null || val.trim().isEmpty
                    ? "Deep link target path is required"
                    : null;
        break;
      case 'Open Product':
        actionLabel = "Specific Product ID *";
        hintText = "prod_98a3b5c";
        validator =
            (val) =>
                val == null || val.trim().isEmpty
                    ? "Product ID is required"
                    : null;
        break;
      case 'Open Service':
        actionLabel = "Specific Service ID *";
        hintText = "serv_32d5e6f";
        validator =
            (val) =>
                val == null || val.trim().isEmpty
                    ? "Service ID is required"
                    : null;
        break;
      case 'Open Category':
        actionLabel = "Service Category Deep Link *";
        hintText = "exterior_cleaning";
        validator =
            (val) =>
                val == null || val.trim().isEmpty
                    ? "Category name key is required"
                    : null;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Call To Action (CTA)"),
        const SizedBox(height: 16),

        // No Text Button Checkbox
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            "No Text Button",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _AdspromotionState.textDark,
            ),
          ),
          subtitle: Text(
            "Hides action button in the mobile app. The entire banner becomes clickable.",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: _AdspromotionState.textGrey,
            ),
          ),
          value: _noTextButton,
          activeColor: _AdspromotionState.primaryNavy,
          onChanged: (val) {
            setState(() {
              _noTextButton = val ?? false;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            // Conditionally show Button Text dropdown only if No Text Button is unchecked
            if (!_noTextButton)
              Expanded(
                child: _buildDropdownField(
                  label: "Button Display Text",
                  value: _selectedButtonText,
                  items: [
                    'Contact Us',
                    'Learn More',
                    'Book Now',
                    'Shop Now',
                    'View Details',
                    'Call Now',
                    'Custom',
                  ],
                  onChanged:
                      (val) => setState(() => _selectedButtonText = val!),
                ),
              ),
            if (!_noTextButton) const SizedBox(width: 16),
            Expanded(
              child: _buildDropdownField(
                label: "Banner Action Type",
                value: _selectedBannerAction,
                items: [
                  'Open URL',
                  'Open WhatsApp',
                  'Call Phone',
                  'Open In-App Page',
                  'Open Product',
                  'Open Service',
                  'Open Category',
                ],
                onChanged:
                    (val) => setState(() => _selectedBannerAction = val!),
              ),
            ),
          ],
        ),
        if (!_noTextButton && _selectedButtonText == 'Custom') ...[
          const SizedBox(height: 16),
          _buildTextField(
            controller: _customButtonTextController,
            label: "Custom Button Label Text *",
            validator:
                (value) =>
                    !_noTextButton &&
                            _selectedButtonText == 'Custom' &&
                            (value == null || value.trim().isEmpty)
                        ? "Custom label required"
                        : null,
          ),
        ],
        const SizedBox(height: 16),
        _buildTextField(
          controller: _actionValueController,
          label: actionLabel,
          hintText: hintText,
          keyboardType: inputType,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Advertiser Details (Internal Admin Only)"),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _advertiserController,
                label: "Advertiser / Company Name",
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _phoneController,
                label: "Contact Phone Number",
                keyboardType: TextInputType.phone,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _emailController,
                label: "Contact Email Address",
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _websiteController,
                label: "Advertiser Website",
                keyboardType: TextInputType.url,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _locationController,
          label: "Physical Location / Target Bounds",
        ),
      ],
    );
  }

  // New section revealed ONLY for Local Ads position
  Widget _buildLocalAdsSection(bool isWide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Local Ads Configuration",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _AdspromotionState.secondaryYellow,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "This section is revealed because 'Home -> Local Ads' placement is selected. Details below will only display inside the Local Ads screen of the mobile client.",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: _AdspromotionState.textGrey,
          ),
        ),
        const SizedBox(height: 16),
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildDropdownField(
                      label: "Offer Type *",
                      value: _localOfferType,
                      items: [
                        'Product Offer',
                        'Service Offer',
                        'Discount Offer',
                        'Coupon',
                        'Flash Sale',
                      ],
                      onChanged:
                          (val) => setState(() => _localOfferType = val!),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _localProductNameController,
                      label: "Product / Service Name *",
                      validator:
                          (value) =>
                              _selectedPosition == 'Home -> Local Ads' &&
                                      (value == null || value.trim().isEmpty)
                                  ? "Product name is required for local ads"
                                  : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _localOriginalPriceController,
                            label: "Original Price (₹)",
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _localOfferPriceController,
                            label: "Offer Price (₹)",
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _localDiscountController,
                            label: "Discount (%)",
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _localOfferBadgeController,
                            label: "Offer Badge Label",
                            hintText: "e.g. 20% OFF",
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLocalAdsImagePicker(),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _localShortDescController,
                      label: "Product Short Description *",
                      maxLines: 4,
                      validator:
                          (value) =>
                              _selectedPosition == 'Home -> Local Ads' &&
                                      (value == null || value.trim().isEmpty)
                                  ? "Description is required for local ads"
                                  : null,
                    ),
                  ],
                ),
              ),
            ],
          )
        else ...[
          _buildDropdownField(
            label: "Offer Type *",
            value: _localOfferType,
            items: [
              'Product Offer',
              'Service Offer',
              'Discount Offer',
              'Coupon',
              'Flash Sale',
            ],
            onChanged: (val) => setState(() => _localOfferType = val!),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _localProductNameController,
            label: "Product / Service Name *",
            validator:
                (value) =>
                    _selectedPosition == 'Home -> Local Ads' &&
                            (value == null || value.trim().isEmpty)
                        ? "Product name is required for local ads"
                        : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _localOriginalPriceController,
                  label: "Original Price (₹)",
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _localOfferPriceController,
                  label: "Offer Price (₹)",
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _localDiscountController,
                  label: "Discount (%)",
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _localOfferBadgeController,
                  label: "Offer Badge Label",
                  hintText: "e.g. 20% OFF",
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLocalAdsImagePicker(),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _localShortDescController,
            label: "Product Short Description *",
            maxLines: 3,
            validator:
                (value) =>
                    _selectedPosition == 'Home -> Local Ads' &&
                            (value == null || value.trim().isEmpty)
                        ? "Description is required for local ads"
                        : null,
          ),
        ],
      ],
    );
  }

  Widget _buildLocalAdsImagePicker() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _AdspromotionState.backgroundGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _AdspromotionState.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Product / Service Image",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _AdspromotionState.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Enforces square or landscape card ratios",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: _AdspromotionState.textGrey,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _pickImage(false),
                icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                label: const Text("Choose"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _AdspromotionState.primaryNavy,
                  elevation: 0,
                  side: const BorderSide(color: _AdspromotionState.primaryNavy),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _localDimensionsText,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: _AdspromotionState.textGrey,
            ),
          ),
          const SizedBox(height: 10),
          AspectRatio(
            aspectRatio: 2.1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _AdspromotionState.borderLight),
              ),
              clipBehavior: Clip.antiAlias,
              child:
                  _localProductBytes != null
                      ? Image.memory(_localProductBytes!, fit: BoxFit.cover)
                      : _currentLocalProductImageUrl != null
                      ? Image.network(
                        _currentLocalProductImageUrl!,
                        fit: BoxFit.cover,
                      )
                      : const Center(
                        child: Icon(
                          Icons.image_outlined,
                          color: _AdspromotionState.textGrey,
                          size: 30,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulingSection() {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    String formatValDate(DateTime date) =>
        "${date.day} ${months[date.month - 1]} ${date.year}";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Campaign Scheduling"),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildPickerCard(
                label: "Start Date",
                value: formatValDate(_startDate),
                icon: Icons.calendar_month_rounded,
                onTap: () => _selectDate(context, true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildPickerCard(
                label: "Start Time",
                value: _startTime.format(context),
                icon: Icons.access_time_rounded,
                onTap: () => _selectTime(context, true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildPickerCard(
                label: "End Date",
                value: formatValDate(_endDate),
                icon: Icons.calendar_month_rounded,
                onTap: () => _selectDate(context, false),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildPickerCard(
                label: "End Time",
                value: _endTime.format(context),
                icon: Icons.access_time_rounded,
                onTap: () => _selectTime(context, false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDisplaySettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Display & Priority Configuration"),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: "Banner Layout Placement",
          value: _selectedPosition,
          items: [
            'Home -> For You',
            'Home -> Workers',
            'Home -> Bus',
            'Home -> Local Ads',
            'Home -> Online Shops',
          ],
          onChanged: (val) {
            setState(() {
              _selectedPosition = val!;
            });
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  "Active Status",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  "Make immediately available",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: _AdspromotionState.textGrey,
                  ),
                ),
                value: _isActive,
                activeThumbColor: _AdspromotionState.primaryNavy,
                onChanged: (val) => setState(() => _isActive = val),
              ),
            ),
            Expanded(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  "Featured Status",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  "Highlight in positions",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: _AdspromotionState.textGrey,
                  ),
                ),
                value: _isFeatured,
                activeThumbColor: _AdspromotionState.primaryNavy,
                onChanged: (val) => setState(() => _isFeatured = val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          "Display Priority Index: ${_priority.toInt()}",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _AdspromotionState.textDark,
          ),
        ),
        const SizedBox(height: 4),
        Slider(
          value: _priority,
          min: 1.0,
          max: 100.0,
          divisions: 99,
          activeColor: _AdspromotionState.primaryNavy,
          inactiveColor: Colors.grey[200],
          label: _priority.toInt().toString(),
          onChanged: (val) => setState(() => _priority = val),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: _AdspromotionState.primaryNavy,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: _AdspromotionState.textDark,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: _AdspromotionState.textGrey,
        ),
        hintText: hintText,
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: Colors.grey[400],
        ),
        filled: true,
        fillColor: _AdspromotionState.backgroundGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _AdspromotionState.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _AdspromotionState.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _AdspromotionState.primaryNavy),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: _AdspromotionState.textGrey,
        ),
        filled: true,
        fillColor: _AdspromotionState.backgroundGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _AdspromotionState.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _AdspromotionState.borderLight),
        ),
      ),
      items:
          items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: GoogleFonts.plusJakartaSans(fontSize: 14),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildPickerCard({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _AdspromotionState.backgroundGrey,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _AdspromotionState.borderLight),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: _AdspromotionState.textGrey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _AdspromotionState.textDark,
                  ),
                ),
              ],
            ),
            Icon(icon, color: _AdspromotionState.primaryNavy, size: 20),
          ],
        ),
      ),
    );
  }
}

// Widget for the crop preview using InteractiveViewer
class VisualCropPreview extends StatefulWidget {
  final Uint8List imageBytes;
  final Function(double scale, Offset offset) onCropChanged;

  const VisualCropPreview({
    super.key,
    required this.imageBytes,
    required this.onCropChanged,
  });

  @override
  State<VisualCropPreview> createState() => _VisualCropPreviewState();
}

class _VisualCropPreviewState extends State<VisualCropPreview> {
  final TransformationController _controller = TransformationController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final matrix = _controller.value;
      final scale = matrix.getMaxScaleOnAxis();
      final translation = matrix.getTranslation();
      widget.onCropChanged(scale, Offset(translation.x, translation.y));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: InteractiveViewer(
            transformationController: _controller,
            boundaryMargin: const EdgeInsets.all(120),
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.memory(widget.imageBytes, fit: BoxFit.contain),
          ),
        ),
        // Alignment grid guide overlay
        IgnorePointer(
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.white30, width: 0.7),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.white30, width: 0.7),
                    ),
                  ),
                ),
              ),
              Expanded(child: Container()),
            ],
          ),
        ),
        IgnorePointer(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.white30, width: 0.7),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.white30, width: 0.7),
                    ),
                  ),
                ),
              ),
              Expanded(child: Container()),
            ],
          ),
        ),
        Positioned(
          bottom: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Icon(Icons.zoom_in, color: Colors.white, size: 12),
                SizedBox(width: 4),
                Text(
                  "Interactive crop box: Pan and zoom image to adjust fit",
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
