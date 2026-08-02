import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:swiftclean_admin/core/imagekit/imagekit_base_service.dart';
import 'package:swiftclean_admin/modules/advertisements/advertisement_service.dart';
import 'package:swiftclean_admin/MVVM/model/models/admin_model.dart';
import 'package:swiftclean_admin/MVVM/utils/rbac_session.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:country_picker/country_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

/// Top-level function for compute to run image optimization in an isolate
Uint8List _optimizeImage(Uint8List resolvedBytes) {
  final img.Image? originalImg = img.decodeImage(resolvedBytes);
  if (originalImg != null) {
    const int targetWidth = 1080;
    const int targetHeight = 600;

    final img.Image canvas = img.Image(
      width: targetWidth,
      height: targetHeight,
    );
    img.fill(canvas, color: img.ColorRgb8(255, 255, 255));

    final double aspectRatio = originalImg.width / originalImg.height;
    final double targetRatio = targetWidth / targetHeight;

    int newWidth;
    int newHeight;
    if (aspectRatio > targetRatio) {
      newWidth = targetWidth;
      newHeight = (targetWidth / aspectRatio).round();
    } else {
      newHeight = targetHeight;
      newWidth = (targetHeight * aspectRatio).round();
    }

    final img.Image resizedImage = img.copyResize(
      originalImg,
      width: newWidth,
      height: newHeight,
      interpolation: img.Interpolation.cubic,
    );

    final int dstX = (targetWidth - newWidth) ~/ 2;
    final int dstY = (targetHeight - newHeight) ~/ 2;
    img.compositeImage(canvas, resizedImage, dstX: dstX, dstY: dstY);

    return Uint8List.fromList(img.encodeJpg(canvas, quality: 100));
  }
  return resolvedBytes;
}

/// Models representing an advertisement banner
class AdBanner {
  final String id;
  final String title;
  final String description;
  final String category;
  final String imageUrl;
  final String imageFileId;
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
  final bool showInForYou;
  final String buttonBackgroundColor;
  final String buttonTextColor;
  final String productId;
  final String productName;
  final String serviceId;
  final String serviceName;
  final String inAppPageId;
  final String inAppPageName;

  AdBanner({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.imageFileId,
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
    required this.showInForYou,
    required this.bannerPosition,
    required this.totalViews,
    required this.totalClicks,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.localAdsConfig,
    this.buttonBackgroundColor = '#0F2E5A',
    this.buttonTextColor = '#FFFFFF',
    this.productId = '',
    this.productName = '',
    this.serviceId = '',
    this.serviceName = '',
    this.inAppPageId = '',
    this.inAppPageName = '',
  });

  factory AdBanner.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdBanner(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      imageFileId: data['imageFileId'] ?? '',
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
      showInForYou: data['showInForYou'] ?? true,
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
      buttonBackgroundColor:
          data['buttonBackgroundColor'] as String? ?? '#0F2E5A',
      buttonTextColor: data['buttonTextColor'] as String? ?? '#FFFFFF',
      productId: data['productId'] as String? ?? '',
      productName: data['productName'] as String? ?? '',
      serviceId: data['serviceId'] as String? ?? '',
      serviceName: data['serviceName'] as String? ?? '',
      inAppPageId: data['inAppPageId'] as String? ?? '',
      inAppPageName: data['inAppPageName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'imageFileId': imageFileId,
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
      'showInForYou': showInForYou,
      'bannerPosition': bannerPosition,
      'totalViews': totalViews,
      'totalClicks': totalClicks,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
      'localAdsConfig': localAdsConfig,
      'buttonBackgroundColor': buttonBackgroundColor,
      'buttonTextColor': buttonTextColor,
      'productId': productId,
      'productName': productName,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'inAppPageId': inAppPageId,
      'inAppPageName': inAppPageName,
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
  String _selectedSortBy = 'Created Date';
  late Stream<QuerySnapshot> _advertisementsStream;
  late Stream<DocumentSnapshot> _adsContactStream;

  @override
  void initState() {
    super.initState();
    _advertisementsStream = _firestore.collection('advertisements').snapshots();
    _adsContactStream =
        _firestore
            .collection('advertisements')
            .doc('global_contact')
            .collection('ads_contact')
            .doc('contact')
            .snapshots();
  }

  // Design Theme Constants
  static const Color primaryNavy = Color(0xFF0F2D62);
  static const Color secondaryYellow = Color(0xFFF4B400);
  static const Color backgroundGrey = Colors.white;
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

    if (RbacSession().hasPermission(Modules.advertisement, Perms.view)) {
      return _buildAdminDashboard();
    } else {
      return _buildAccessDenied(
        "You don't have permission to access the Advertisement module.",
      );
    }
  }

  Widget _buildAccessDenied(String reason) {
    return Scaffold(
      backgroundColor: backgroundGrey,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
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
      stream: _advertisementsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: const Color(0xFFFFC107)),
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
          if (!a.isActive && b.isActive) return -1;
          if (a.isActive && !b.isActive) return 1;

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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dashboard Header Section and Ads Contact
                StreamBuilder<DocumentSnapshot>(
                  stream: _adsContactStream,
                  builder: (context, contactSnap) {
                    final contactData =
                        contactSnap.data?.data() as Map<String, dynamic>?;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _openAdsContactDialog(),
                                  icon: const Icon(
                                    Icons.contact_phone_rounded,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    "Ads Contact",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[800],
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
                                const SizedBox(width: 12),
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
                          ],
                        ),
                        if (contactData != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderLight),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.support_agent_rounded,
                                      color: primaryNavy,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Ads Support",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: textDark,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (contactData['bannerImageUrl'] != null &&
                                    contactData['bannerImageUrl']
                                        .toString()
                                        .isNotEmpty) ...[
                                  GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder:
                                            (context) => Dialog(
                                              backgroundColor:
                                                  Colors.transparent,
                                              insetPadding:
                                                  const EdgeInsets.all(16),
                                              child: Stack(
                                                alignment: Alignment.topRight,
                                                children: [
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    child: Image.network(
                                                      contactData['bannerImageUrl'],
                                                      fit: BoxFit.contain,
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          8.0,
                                                        ),
                                                    child: IconButton(
                                                      icon: const Icon(
                                                        Icons.close,
                                                        color: Colors.white,
                                                      ),
                                                      style:
                                                          IconButton.styleFrom(
                                                            backgroundColor:
                                                                Colors.black54,
                                                          ),
                                                      onPressed:
                                                          () =>
                                                              Navigator.of(
                                                                context,
                                                              ).pop(),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                      );
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        contactData['bannerImageUrl'],
                                        width: 80,
                                        height: 44, // 1080/600 aspect ratio
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                Row(
                                  children: [
                                    if (contactData['whatsappNumber'] != null &&
                                        contactData['whatsappNumber']
                                            .toString()
                                            .isNotEmpty) ...[
                                      const FaIcon(
                                        FontAwesomeIcons.whatsapp,
                                        color: Colors.green,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "WhatsApp: ${contactData['whatsappCountryIso'] != null ? String.fromCharCodes(contactData['whatsappCountryIso'].toString().codeUnits.map((c) => c + 127397)) : ''} ${contactData['whatsappCountryCode'] ?? ''} ${contactData['whatsappNumber']}",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          color: textGrey,
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                    ],
                                    const Icon(
                                      Icons.phone,
                                      color: Colors.blue,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Phone: ${contactData['phoneNumber']}",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        color: textGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  },
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
                      final isToolbarCompact =
                          toolbarConstraints.maxWidth < 900;
                      final searchField = Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: backgroundGrey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          onChanged:
                              (val) => setState(() => _searchQuery = val),
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
                              (val) => setState(
                                () => _selectedFilterPosition = val!,
                              ),
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
                        int columns = (gridConstraints.maxWidth / 350).floor();
                        if (columns < 1) columns = 1;

                        const double spacing = 16.0;
                        final double cardWidth =
                            (gridConstraints.maxWidth -
                                (columns - 1) * spacing) /
                            columns;
                        final double childAspectRatio = cardWidth / 168.0;

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredBanners.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: spacing,
                                mainAxisSpacing: spacing,
                                childAspectRatio: childAspectRatio,
                              ),
                          itemBuilder: (context, index) {
                            return _buildBannerCard(
                              filteredBanners[index],
                              now,
                            );
                          },
                        );
                      },
                    ),
              ],
            ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: Colors.white,
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image & Badge Overlay - Left side horizontal layout
          SizedBox(
            width: 140,
            height: double.infinity,
            child: Stack(
              children: [
                Positioned.fill(
                  child:
                      banner.imageUrl.isNotEmpty
                          ? GestureDetector(
                            onTap:
                                () => _showImagePreviewDialog(banner.imageUrl),
                            child: Image.network(
                              banner.imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder:
                                  (context, error, stackTrace) => Container(
                                    color: Colors.grey[100],
                                    child: const Icon(
                                      Icons.broken_image,
                                      size: 40,
                                      color: textGrey,
                                    ),
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
                // Position tag overlay - Top Left
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: primaryNavy,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      banner.bannerPosition,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 8,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Priority Tag Overlay - Bottom Left
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: secondaryYellow,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "Prio: ${banner.priority}",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 8,
                        color: textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details Section — Right side horizontal layout
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Column(
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
                  const SizedBox(height: 6),

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
                  const SizedBox(height: 2),

                  // Description
                  Text(
                    banner.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: textGrey,
                      height: 1.4,
                    ),
                  ),

                  if (banner.description.isNotEmpty)
                    const SizedBox(height: 6)
                  else
                    const SizedBox(height: 4),

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
                  const SizedBox(height: 2),

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

                  Spacer(),

                  const Divider(height: 1, thickness: 1, color: borderLight),
                  const SizedBox(height: 4),

                  // Analytics + action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              '${banner.totalViews} Views | ${banner.totalClicks} Clicks',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: textGrey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
                              Icons.remove_red_eye_outlined,
                              size: 18,
                              color: primaryNavy,
                            ),
                            onPressed: () => _showBannerDetails(banner),
                          ),
                          const SizedBox(width: 8),
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
          ),
        ],
      ),
    );
  }

  void _showImagePreviewDialog(String imageUrl) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(24),
            child: Stack(
              alignment: Alignment.center,
              children: [
                InteractiveViewer(
                  child: Image.network(imageUrl, fit: BoxFit.contain),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      padding: const EdgeInsets.all(8),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showBannerDetails(AdBanner banner) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    banner.title,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: primaryNavy,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                        _calculateStatus(
                                          banner,
                                          DateTime.now(),
                                        ),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _calculateStatus(banner, DateTime.now()),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              icon: const Icon(
                                Icons.close_rounded,
                                color: textGrey,
                              ),
                            ),
                          ],
                        ),
                        if (banner.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            banner.description,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: textGrey,
                              height: 1.5,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),

                        _buildSectionHeaderIcon(
                          "General Information",
                          Icons.info_outline_rounded,
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            _buildDetailItem(
                              "Category",
                              banner.category,
                              Icons.category_outlined,
                            ),
                            _buildDetailItem(
                              "Placement",
                              banner.bannerPosition,
                              Icons.layers_outlined,
                            ),
                            _buildDetailItem(
                              "Start Date",
                              _formatDate(banner.startDate),
                              Icons.date_range_rounded,
                            ),
                            _buildDetailItem(
                              "End Date",
                              _formatDate(banner.endDate),
                              Icons.event_busy_rounded,
                            ),
                            _buildDetailItem(
                              "Priority",
                              banner.priority.toString(),
                              Icons.sort_rounded,
                            ),
                            _buildDetailItem(
                              "Featured",
                              banner.isFeatured ? "Yes" : "No",
                              Icons.star_border_rounded,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                        _buildSectionHeaderIcon(
                          "Advertiser Details",
                          Icons.business_rounded,
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            _buildDetailItem(
                              "Name",
                              banner.advertiserName,
                              Icons.person_outline_rounded,
                            ),
                            _buildDetailItem(
                              "Phone",
                              banner.phone,
                              Icons.phone_outlined,
                            ),
                            if (banner.email.isNotEmpty)
                              _buildDetailItem(
                                "Email",
                                banner.email,
                                Icons.email_outlined,
                              ),
                            if (banner.website.isNotEmpty)
                              _buildDetailItem(
                                "Website",
                                banner.website,
                                Icons.language_rounded,
                              ),
                            if (banner.location.isNotEmpty)
                              _buildDetailItem(
                                "Location",
                                banner.location,
                                Icons.location_on_outlined,
                              ),
                          ],
                        ),

                        const SizedBox(height: 24),
                        _buildSectionHeaderIcon(
                          "Analytics & System",
                          Icons.analytics_outlined,
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            _buildDetailItem(
                              "Total Views",
                              banner.totalViews.toString(),
                              Icons.visibility_outlined,
                            ),
                            _buildDetailItem(
                              "Total Clicks",
                              banner.totalClicks.toString(),
                              Icons.ads_click_rounded,
                            ),
                            _buildDetailItem(
                              "Created By",
                              banner.createdBy,
                              Icons.admin_panel_settings_outlined,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: 220,
      color: backgroundGrey,
      child: const Center(
        child: Icon(Icons.campaign_rounded, size: 64, color: textGrey),
      ),
    );
  }

  Widget _buildSectionHeaderIcon(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: textGrey),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return SizedBox(
      width: 250,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: backgroundGrey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: primaryNavy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: textDark,
                    fontWeight: FontWeight.w600,
                  ),
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
            backgroundColor: Colors.white,
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

  Future<void> _openAdsContactDialog() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Color(0xFFFFC107)),
                  const SizedBox(height: 20),
                  Text(
                    "Loading Ads Contact...",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
    );

    try {
      // Fetch the global contact document
      final docSnapshot =
          await _firestore
              .collection('advertisements')
              .doc('global_contact')
              .collection('ads_contact')
              .doc('contact')
              .get();

      if (!mounted) return;

      // Dismiss the loading dialog
      Navigator.of(context).pop();

      // Extract data (null if document doesn't exist)
      final Map<String, dynamic>? contactData =
          docSnapshot.exists ? docSnapshot.data() : null;

      // Open the AdsContactDialog with the fetched data
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) =>
                AdsContactDialog(existingContact: contactData, onSaved: () {}),
      );
    } catch (e) {
      if (!mounted) return;

      // Dismiss the loading dialog
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load Ads Contact: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
  bool _noBannerAction = false;

  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;

  bool _scheduleError = false;

  bool _isActive = true;
  bool _isFeatured = false;
  bool _showInForYou = true;
  double _priority = 50.0;
  bool _isOptimizingImage = false;

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

  // CTA Button Colors
  Color _buttonBgColor = const Color(0xFF0F2E5A);
  Color _buttonTextColor = const Color(0xFFFFFFFF);
  late TextEditingController _buttonBgHexController;
  late TextEditingController _buttonTextHexController;

  // Product Selection (for Open Product action)
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _isLoadingProducts = false;
  String? _productLoadError;
  String? _selectedProductId;
  String? _selectedProductName;
  String? _selectedProductCategory;
  String? _selectedProductImage;
  bool _productFieldError = false;
  late TextEditingController _productSearchController;

  // Service Selection (for Open Service action)
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _filteredServices = [];
  bool _isLoadingServices = false;
  String? _serviceLoadError;
  String? _selectedServiceId;
  String? _selectedServiceName;
  String? _selectedServiceCategory;
  bool _serviceFieldError = false;
  late TextEditingController _serviceSearchController;

  // In-App Page Selection (for Open In-App Page action)
  String? _selectedInAppPageId;
  String? _selectedInAppPageName;
  bool _inAppPageFieldError = false;

  /// Master list of all supported in-app pages.
  static const List<Map<String, String>> _inAppPages = [
    {'id': 'home', 'name': 'Home'},
    {'id': 'for_you', 'name': 'For You'},
    {'id': 'workers', 'name': 'Workers'},
    {'id': 'bus', 'name': 'Bus'},
    {'id': 'shopping', 'name': 'Shopping'},
    {'id': 'healthcare', 'name': 'Healthcare'},
    {'id': 'taxi', 'name': 'Taxi'},
    {'id': 'truck_jcb', 'name': 'Truck / JCB'},
    {'id': 'notifications', 'name': 'Notifications'},
    {'id': 'profile', 'name': 'Profile'},
    {'id': 'orders', 'name': 'Orders'},
    {'id': 'settings', 'name': 'Settings'},
  ];

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
      _noBannerAction =
          b.bannerAction == 'None' ||
          b.bannerAction == '' ||
          b.bannerAction == 'none';
      if (_noBannerAction) {
        _selectedBannerAction = 'Open URL';
      }
      _selectedPosition = b.bannerPosition;
      _currentImageUrl = b.imageUrl;
      _isActive = b.isActive;
      _isFeatured = b.isFeatured;
      _showInForYou = b.showInForYou;
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

    // Product selection — load from existing banner if action is Open Product
    _productSearchController = TextEditingController();
    if (b != null &&
        b.bannerAction == 'Open Product' &&
        b.productId.isNotEmpty) {
      _selectedProductId = b.productId;
      _selectedProductName = b.productName;
    }

    // Service selection — load from existing banner if action is Open Service
    _serviceSearchController = TextEditingController();
    if (b != null &&
        b.bannerAction == 'Open Service' &&
        b.serviceId.isNotEmpty) {
      _selectedServiceId = b.serviceId;
      _selectedServiceName = b.serviceName;
    }

    // In-App Page selection — load from existing banner if action is Open In-App Page
    if (b != null &&
        b.bannerAction == 'Open In-App Page' &&
        b.inAppPageId.isNotEmpty) {
      _selectedInAppPageId = b.inAppPageId;
      _selectedInAppPageName = b.inAppPageName;
    }

    // Initialize CTA button colors from Firestore or defaults
    _buttonBgColor = _hexToColor(
      _getFirestoreColorField(b, 'buttonBackgroundColor'),
      const Color(0xFF0F2E5A),
    );
    _buttonTextColor = _hexToColor(
      _getFirestoreColorField(b, 'buttonTextColor'),
      const Color(0xFFFFFFFF),
    );
    _buttonBgHexController = TextEditingController(
      text: _colorToHex(_buttonBgColor),
    );
    _buttonTextHexController = TextEditingController(
      text: _colorToHex(_buttonTextColor),
    );
  }

  /// Helper: get a color string from the AdBanner model.
  String? _getFirestoreColorField(AdBanner? b, String field) {
    if (b == null) return null;
    if (field == 'buttonBackgroundColor') return b.buttonBackgroundColor;
    if (field == 'buttonTextColor') return b.buttonTextColor;
    return null;
  }

  Color _hexToColor(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    try {
      final h = hex.replaceAll('#', '').trim();
      if (h.length == 6) {
        return Color(int.parse('FF$h', radix: 16));
      } else if (h.length == 8) {
        return Color(int.parse(h, radix: 16));
      }
    } catch (_) {}
    return fallback;
  }

  String _colorToHex(Color color) {
    return '#${color.r.toInt().toRadixString(16).padLeft(2, '0').toUpperCase()}${color.g.toInt().toRadixString(16).padLeft(2, '0').toUpperCase()}${color.b.toInt().toRadixString(16).padLeft(2, '0').toUpperCase()}';
  }

  Future<void> _fetchProducts() async {
    if (_products.isNotEmpty) return; // already loaded
    setState(() {
      _isLoadingProducts = true;
      _productLoadError = null;
    });
    try {
      final snap =
          await FirebaseFirestore.instance
              .collection('products')
              .where('isActive', isEqualTo: true)
              .orderBy('name')
              .get();
      final list =
          snap.docs.map((doc) {
            final d = doc.data();
            return {
              'id': doc.id,
              'name': (d['name'] ?? d['productName'] ?? '').toString(),
              'category': (d['category'] ?? d['categoryName'] ?? '').toString(),
              'price': d['price'] ?? d['offerPrice'] ?? '',
              'imageUrl':
                  (d['imageUrl'] ?? d['productImageUrl'] ?? '').toString(),
            };
          }).toList();
      if (mounted) {
        setState(() {
          _products = list;
          _filteredProducts = list;
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _productLoadError = 'Failed to load products: $e';
          _isLoadingProducts = false;
        });
      }
    }
  }

  void _filterProducts(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      if (q.isEmpty) {
        _filteredProducts = _products;
      } else {
        _filteredProducts =
            _products.where((p) {
              return p['name'].toString().toLowerCase().contains(q) ||
                  p['category'].toString().toLowerCase().contains(q) ||
                  p['id'].toString().toLowerCase().contains(q);
            }).toList();
      }
    });
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
    _buttonBgHexController.dispose();
    _buttonTextHexController.dispose();
    _productSearchController.dispose();
    _serviceSearchController.dispose();

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
        allowedExtensions: ImageKitBaseService.allowedExtensions,
      );
      if (!mounted) return;
      if (result != null) {
        setState(() {
          _isOptimizingImage = true;
        });

        final pickedFile = result.files.single;
        final fileBytes = pickedFile.bytes;
        final fileSize = pickedFile.size;
        final fileName = pickedFile.name;

        // Validate file extension
        if (!ImageKitBaseService.isAllowedExtension(fileName)) {
          setState(() {
            _isOptimizingImage = false;
          });
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
        if (fileSize > ImageKitBaseService.maxFileSizeBytes) {
          setState(() {
            _isOptimizingImage = false;
          });
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
        String dimText =
            "${decodedImage.width} × ${decodedImage.height} px "
            "(${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB)";

        Uint8List finalBytes = resolvedBytes;

        if (isMainBanner) {
          finalBytes = await compute(_optimizeImage, resolvedBytes);
          dimText = "1080 × 600 px (Optimized)";

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Your banner has been automatically optimized to 1080 × 600 px while preserving the original image.",
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        }

        setState(() {
          _isOptimizingImage = false;
          if (isMainBanner) {
            _imageBytes = finalBytes;
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
      setState(() {
        _isOptimizingImage = false;
      });
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
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              surface: Colors.white,
              surfaceContainerHigh: Colors.white,
              surfaceContainer: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
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
      initialTime: (isStart ? _startTime : _endTime) ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              surface: Colors.white,
              surfaceContainerHigh: Colors.white,
              surfaceContainer: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
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
    if (_startDate == null ||
        _startTime == null ||
        _endDate == null ||
        _endTime == null) {
      setState(() {
        _scheduleError = true;
      });
      return;
    }

    if (!_formKey.currentState!.validate()) {
      debugPrint("DEBUG: Form validation failed.");
      return;
    }
    if (_imageBytes == null && _currentImageUrl == null) {
      debugPrint("DEBUG: Image bytes and current image URL are both null.");
      setState(() => _isImageValid = false);
      return;
    }

    if (_selectedBannerAction == 'Open Product' &&
        (_selectedProductId == null || _selectedProductId!.isEmpty)) {
      setState(() => _productFieldError = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a product.')));
      return;
    }

    if (_selectedBannerAction == 'Open Service' &&
        (_selectedServiceId == null || _selectedServiceId!.isEmpty)) {
      setState(() => _serviceFieldError = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a service.')));
      return;
    }

    if (_selectedBannerAction == 'Open In-App Page' &&
        (_selectedInAppPageId == null || _selectedInAppPageId!.isEmpty)) {
      setState(() => _inAppPageFieldError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an in-app page.')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _isActive = makeActive;
    });

    try {
      String finalImageUrl = _currentImageUrl ?? '';
      String finalProductImageUrl = _currentLocalProductImageUrl ?? '';

      String finalImageFileId = widget.existingBanner?.imageFileId ?? '';
      String finalProductImageFileId =
          widget.existingBanner?.localAdsConfig?['productImageFileId'] ?? '';

      // 1. Upload Main Banner Image via ImageKit
      if (_imageBytes != null) {
        debugPrint('DEBUG: Starting main banner ImageKit upload...');
        final service = AdvertisementImageService();
        final result = await service.uploadBanner(
          imageBytes: _imageBytes!,
          fileName: _imageName ?? 'banner.png',
          onProgress: (progress) {
            debugPrint(
              'DEBUG: ImageKit upload progress: ${(progress * 100).toStringAsFixed(1)}%',
            );
            if (mounted) {
              setState(() => _uploadProgress = progress);
            }
          },
        );
        finalImageUrl = result.imageUrl;
        finalImageFileId = result.fileId;
        debugPrint('DEBUG: ImageKit upload successful. URL: $finalImageUrl');
      }

      // 2. Upload Local Ads Product Image via ImageKit
      if (_selectedPosition == 'Home -> Local Ads' &&
          _localProductBytes != null) {
        debugPrint('DEBUG: Starting local product ImageKit upload...');
        final service = AdvertisementImageService();
        final result = await service.uploadLocalProduct(
          imageBytes: _localProductBytes!,
          fileName: _localProductName ?? 'product.png',
          onProgress: (progress) {
            if (mounted) {
              setState(() => _uploadProgress = progress);
            }
          },
        );
        finalProductImageUrl = result.imageUrl;
        finalProductImageFileId = result.fileId;
        debugPrint(
          'DEBUG: Local product ImageKit upload successful. URL: $finalProductImageUrl',
        );
      }

      // Compile CTA button display text
      final String resolvedButtonText =
          (_noTextButton || _noBannerAction)
              ? 'No Text'
              : (_selectedButtonText == 'Custom'
                  ? _customButtonTextController.text.trim()
                  : _selectedButtonText);

      final startDateTime = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
        _startTime!.hour,
        _startTime!.minute,
      );

      final endDateTime = DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
        _endTime!.hour,
        _endTime!.minute,
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
          'productImageFileId': finalProductImageFileId,
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
        'imageFileId': finalImageFileId,
        'storage': 'advertisement',
        'buttonText': resolvedButtonText,
        'bannerAction': _noBannerAction ? 'None' : _selectedBannerAction,
        'buttonAction':
            _noBannerAction
                ? 'None'
                : _selectedBannerAction, // backward compatibility
        'actionValue':
            _noBannerAction
                ? ''
                : (_selectedBannerAction == 'Open Product'
                    ? _selectedProductId ?? ''
                    : _selectedBannerAction == 'Open Service'
                    ? _selectedServiceId ?? ''
                    : _selectedBannerAction == 'Open In-App Page'
                    ? _selectedInAppPageId ?? ''
                    : _actionValueController.text.trim()),
        'productId':
            _selectedBannerAction == 'Open Product'
                ? (_selectedProductId ?? '')
                : '',
        'productName':
            _selectedBannerAction == 'Open Product'
                ? (_selectedProductName ?? '')
                : '',
        'serviceId':
            _selectedBannerAction == 'Open Service'
                ? (_selectedServiceId ?? '')
                : '',
        'serviceName':
            _selectedBannerAction == 'Open Service'
                ? (_selectedServiceName ?? '')
                : '',
        'inAppPageId':
            _selectedBannerAction == 'Open In-App Page'
                ? (_selectedInAppPageId ?? '')
                : '',
        'inAppPageName':
            _selectedBannerAction == 'Open In-App Page'
                ? (_selectedInAppPageName ?? '')
                : '',
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
        'showInForYou': _showInForYou,
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
        'buttonBackgroundColor': _colorToHex(_buttonBgColor),
        'buttonTextColor': _colorToHex(_buttonTextColor),
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
        String errorMessage = "Error saving advertisement: $e";
        final errorString = e.toString().toLowerCase();

        if (errorString.contains('network error') ||
            errorString.contains('failed to fetch') ||
            errorString.contains('clientexception') ||
            errorString.contains('socketexception') ||
            errorString.contains('xmlhttprequest error')) {
          errorMessage =
              "Internet connection lost. Please check your network and try again.";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double dialogWidth =
        MediaQuery.of(context).size.width > 900 ? 880 : double.infinity;
    final bool isWide = MediaQuery.of(context).size.width > 900;

    return Dialog(
      backgroundColor: Colors.white,
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
                              const Divider(
                                height: 40,
                                color: _AdspromotionState.borderLight,
                              ),
                              _buildAdsSupportSection(),
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
                      onPressed:
                          _isOptimizingImage ? null : () => _saveForm(false),
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
                      onPressed:
                          _isOptimizingImage ? null : () => _saveForm(true),
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
                        "Recommended Size: 1080 × 600 px",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: _AdspromotionState.textGrey,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed:
                        _isOptimizingImage ? null : () => _pickImage(true),
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
                      _isOptimizingImage
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 16),
                                Text(
                                  "Optimizing banner... Please wait.",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: _AdspromotionState.textGrey,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : _imageBytes != null
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
        // Product picker replaces the text field — handled separately below.
        break;
      case 'Open Service':
        // Service picker replaces the text field — handled separately below.
        break;
      case 'Open In-App Page':
        // In-App Page picker replaces the text field — handled separately below.
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

        // No Banner Action Checkbox
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            "No Banner Action",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _AdspromotionState.textDark,
            ),
          ),
          subtitle: Text(
            "Disables any clicks or CTA actions on this banner.",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: _AdspromotionState.textGrey,
            ),
          ),
          value: _noBannerAction,
          activeColor: _AdspromotionState.primaryNavy,
          onChanged: (val) {
            setState(() {
              _noBannerAction = val ?? false;
              if (_noBannerAction) {
                _actionValueController.clear();
              }
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),

        if (!_noBannerAction) ...[
          const SizedBox(height: 16),
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
          if (_selectedBannerAction == 'Open Product')
            _buildProductPickerField()
          else if (_selectedBannerAction == 'Open Service')
            _buildServicePickerField()
          else if (_selectedBannerAction == 'Open In-App Page')
            _buildInAppPagePickerField()
          else
            _buildTextField(
              controller: _actionValueController,
              label: actionLabel,
              hintText: hintText,
              keyboardType: inputType,
              validator: validator,
            ),
        ],

        // CTA Button Color Customization
        if (!_noTextButton) ...[
          const SizedBox(height: 20),
          const Divider(height: 1, color: _AdspromotionState.borderLight),
          const SizedBox(height: 16),
          Text(
            "Button Color Customization",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _AdspromotionState.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Customize the CTA button appearance shown in the mobile app.",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: _AdspromotionState.textGrey,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Button Background Color Picker
              Expanded(
                child: _buildColorPickerField(
                  label: "Button Background Color",
                  currentColor: _buttonBgColor,
                  hexController: _buttonBgHexController,
                  onColorChanged: (color) {
                    setState(() {
                      _buttonBgColor = color;
                      _buttonBgHexController.text = _colorToHex(color);
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Button Text Color Picker
              Expanded(
                child: _buildColorPickerField(
                  label: "Button Text Color",
                  currentColor: _buttonTextColor,
                  hexController: _buttonTextHexController,
                  onColorChanged: (color) {
                    setState(() {
                      _buttonTextColor = color;
                      _buttonTextHexController.text = _colorToHex(color);
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Live Preview
          Center(
            child: Column(
              children: [
                Text(
                  "Live Preview",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: _AdspromotionState.textGrey,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _buttonBgColor,
                    foregroundColor: _buttonTextColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _selectedButtonText == 'Custom' &&
                            _customButtonTextController.text.isNotEmpty
                        ? _customButtonTextController.text
                        : _selectedButtonText,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: _buttonTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildColorPickerField({
    required String label,
    required Color currentColor,
    required TextEditingController hexController,
    required ValueChanged<Color> onColorChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _AdspromotionState.textDark,
          ),
        ),
        const SizedBox(height: 8),
        // Color Swatches
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Custom preset colors
            for (final c in [
              const Color(0xFF0F2E5A),
              const Color(0xFF0D47A1),
              const Color(0xFF1565C0),
              const Color(0xFF1976D2),
              const Color(0xFF2196F3),
              const Color(0xFF00897B),
              const Color(0xFF388E3C),
              const Color(0xFFF4B400),
              const Color(0xFFFF6F00),
              const Color(0xFFE53935),
              const Color(0xFF6A1B9A),
              const Color(0xFF212121),
              const Color(0xFF616161),
              const Color(0xFFFFFFFF),
            ])
              GestureDetector(
                onTap: () => onColorChanged(c),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color:
                          currentColor.value == c.value
                              ? _AdspromotionState.primaryNavy
                              : _AdspromotionState.borderLight,
                      width: currentColor.value == c.value ? 2.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child:
                      currentColor.value == c.value
                          ? Icon(
                            Icons.check,
                            size: 16,
                            color:
                                c.computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white,
                          )
                          : null,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        // HEX Input
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: currentColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _AdspromotionState.borderLight),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: hexController,
                decoration: InputDecoration(
                  labelText: "HEX value",
                  hintText: "#0F2E5A",
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: _AdspromotionState.borderLight,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: _AdspromotionState.borderLight,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: _AdspromotionState.primaryNavy,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return null;
                  final h = val.replaceAll('#', '').trim();
                  if (h.length != 6 && h.length != 8) {
                    return 'Invalid HEX';
                  }
                  if (!RegExp(r'^[0-9A-Fa-f]+$').hasMatch(h)) {
                    return 'Invalid HEX';
                  }
                  return null;
                },
                onChanged: (val) {
                  final parsed = _hexToColor(val, currentColor);
                  onColorChanged(parsed);
                },
              ),
            ),
          ],
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
                label: "Advertiser / Company Name *",
                textCapitalization: TextCapitalization.characters,
                validator:
                    (val) =>
                        val == null || val.trim().isEmpty
                            ? "Advertiser name is required"
                            : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _phoneController,
                label: "Contact Phone Number *",
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return "Phone number is required";
                  if (val.trim().length != 10)
                    return "Must be exactly 10 digits";
                  return null;
                },
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
                label: "Start Date *",
                value:
                    _startDate != null
                        ? formatValDate(_startDate!)
                        : "Select Start Date",
                icon: Icons.calendar_month_rounded,
                onTap: () => _selectDate(context, true),
                isError: _scheduleError && _startDate == null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildPickerCard(
                label: "Start Time *",
                value:
                    _startTime != null
                        ? _startTime!.format(context)
                        : "Select Start Time",
                icon: Icons.access_time_rounded,
                onTap: () => _selectTime(context, true),
                isError: _scheduleError && _startTime == null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildPickerCard(
                label: "End Date *",
                value:
                    _endDate != null
                        ? formatValDate(_endDate!)
                        : "Select End Date",
                icon: Icons.calendar_month_rounded,
                onTap: () => _selectDate(context, false),
                isError: _scheduleError && _endDate == null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildPickerCard(
                label: "End Time *",
                value:
                    _endTime != null
                        ? _endTime!.format(context)
                        : "Select End Time",
                icon: Icons.access_time_rounded,
                onTap: () => _selectTime(context, false),
                isError: _scheduleError && _endTime == null,
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
        SwitchListTile(
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
        const SizedBox(height: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            "Show on Home (For You)",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            "Also display this banner in the For You section",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: _AdspromotionState.textGrey,
            ),
          ),
          value: _showInForYou,
          activeThumbColor: _AdspromotionState.primaryNavy,
          onChanged: (val) => setState(() => _showInForYou = val),
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

  Widget _buildAdsSupportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Ads Support"),
        const SizedBox(height: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            "Status",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            "active",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: _AdspromotionState.textGrey,
            ),
          ),
          value: _isActive,
          activeThumbColor: _AdspromotionState.primaryNavy,
          onChanged: (val) => setState(() => _isActive = val),
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

  Widget _buildProductPickerField() {
    return _buildSearchablePicker(
      collectionName: 'products',
      label: 'Specific Product *',
      nameKey: 'title',
      altNameKey: 'productName',
      selectedId: _selectedProductId,
      selectedName: _selectedProductName,
      onSelected: (id, name) {
        setState(() {
          _selectedProductId = id;
          _selectedProductName = name;
          _productFieldError = false;
        });
      },
    );
  }

  Widget _buildServicePickerField() {
    return _buildSearchablePicker(
      collectionName: 'services',
      label: 'Specific Service *',
      nameKey: 'title',
      altNameKey: 'serviceName',
      selectedId: _selectedServiceId,
      selectedName: _selectedServiceName,
      onSelected: (id, name) {
        setState(() {
          _selectedServiceId = id;
          _selectedServiceName = name;
          _serviceFieldError = false;
        });
      },
    );
  }

  Widget _buildInAppPagePickerField() {
    return GestureDetector(
      onTap: () => _showInAppPageDialog(),
      child: AbsorbPointer(
        child: TextFormField(
          readOnly: true,
          controller: TextEditingController(text: _selectedInAppPageName ?? ''),
          validator:
              (val) =>
                  (val == null || val.isEmpty)
                      ? 'Please select an in-app page.'
                      : null,
          decoration: InputDecoration(
            labelText: 'In-App Page *',
            labelStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: _AdspromotionState.textGrey,
            ),
            hintText: 'Tap to select a page',
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: _AdspromotionState.textGrey,
            ),
            filled: true,
            fillColor: _AdspromotionState.backgroundGrey,
            suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
            errorText:
                _inAppPageFieldError ? 'Please select an in-app page.' : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _AdspromotionState.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color:
                    _inAppPageFieldError
                        ? Colors.red
                        : _AdspromotionState.borderLight,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _AdspromotionState.primaryNavy,
                width: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showInAppPageDialog() {
    String localSearch = '';
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filtered =
                _inAppPages.where((page) {
                  if (localSearch.isEmpty) return true;
                  return page['name']!.toLowerCase().contains(localSearch);
                }).toList();

            return AlertDialog(
              title: Text(
                'Select In-App Page',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Search pages...',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          localSearch = val.toLowerCase().trim();
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child:
                          filtered.isEmpty
                              ? Center(
                                child: Text(
                                  'No pages found.',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: _AdspromotionState.textGrey,
                                  ),
                                ),
                              )
                              : ListView.builder(
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final page = filtered[index];
                                  final isSelected =
                                      _selectedInAppPageId == page['id'];
                                  return ListTile(
                                    leading: Icon(
                                      Icons.phone_iphone_rounded,
                                      color:
                                          isSelected
                                              ? _AdspromotionState.primaryNavy
                                              : Colors.grey,
                                      size: 22,
                                    ),
                                    title: Text(
                                      page['name']!,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                        color:
                                            isSelected
                                                ? _AdspromotionState.primaryNavy
                                                : _AdspromotionState.textDark,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'ID: ${page['id']}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: _AdspromotionState.textGrey,
                                      ),
                                    ),
                                    trailing:
                                        isSelected
                                            ? Icon(
                                              Icons.check_circle,
                                              color:
                                                  _AdspromotionState
                                                      .primaryNavy,
                                            )
                                            : null,
                                    onTap: () {
                                      setState(() {
                                        _selectedInAppPageId = page['id'];
                                        _selectedInAppPageName = page['name'];
                                        _inAppPageFieldError = false;
                                      });
                                      Navigator.pop(context);
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
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSearchablePicker({
    required String collectionName,
    required String label,
    required String nameKey,
    required String altNameKey,
    required String? selectedId,
    required String? selectedName,
    required Function(String, String) onSelected,
  }) {
    final controller = TextEditingController(text: selectedName ?? '');
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () {
        _showSearchableDialog(
          collectionName: collectionName,
          title: label.replaceAll(' *', ''),
          nameKey: nameKey,
          altNameKey: altNameKey,
          onSelected: onSelected,
        );
      },
      validator:
          (val) =>
              (val == null || val.isEmpty) ? "Selection is required" : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: _AdspromotionState.textGrey,
        ),
        filled: true,
        fillColor: _AdspromotionState.backgroundGrey,
        suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _AdspromotionState.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _AdspromotionState.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _AdspromotionState.primaryNavy,
            width: 2,
          ),
        ),
      ),
    );
  }

  void _showSearchableDialog({
    required String collectionName,
    required String title,
    required String nameKey,
    required String altNameKey,
    required Function(String, String) onSelected,
  }) {
    String localSearch = '';
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Select $title'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          localSearch = val.toLowerCase();
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection(collectionName)
                                .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData)
                            return const Center(
                              child: CircularProgressIndicator(),
                            );

                          var docs = snapshot.data!.docs;
                          if (localSearch.isNotEmpty) {
                            docs =
                                docs.where((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  final name =
                                      (data[nameKey] ??
                                              data[altNameKey] ??
                                              'Unnamed')
                                          .toString()
                                          .toLowerCase();
                                  return name.contains(localSearch);
                                }).toList();
                          }

                          return ListView.builder(
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final doc = docs[index];
                              final data = doc.data() as Map<String, dynamic>;
                              final name =
                                  (data[nameKey] ??
                                          data[altNameKey] ??
                                          'Unnamed')
                                      .toString();
                              final category =
                                  (data['category'] ?? '').toString();
                              final type =
                                  (data['serviceType'] ?? data['type'] ?? '')
                                      .toString();

                              String subtitle = '';
                              if (category.isNotEmpty)
                                subtitle += 'Category: $category';
                              if (type.isNotEmpty) {
                                if (subtitle.isNotEmpty) subtitle += '\n';
                                subtitle += 'Type: $type';
                              }

                              return ListTile(
                                title: Text(name),
                                subtitle:
                                    subtitle.isNotEmpty ? Text(subtitle) : null,
                                isThreeLine:
                                    category.isNotEmpty && type.isNotEmpty,
                                onTap: () {
                                  onSelected(doc.id, name);
                                  Navigator.pop(context);
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
            );
          },
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      validator: validator,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: _AdspromotionState.textDark,
      ),
      decoration: InputDecoration(
        label: RichText(
          text: TextSpan(
            text: label.replaceAll(' *', '').replaceAll('*', ''),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: _AdspromotionState.textGrey,
            ),
            children:
                label.contains('*')
                    ? [
                      TextSpan(
                        text: ' *',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ]
                    : [],
          ),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
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
        label: RichText(
          text: TextSpan(
            text: label.replaceAll(' *', '').replaceAll('*', ''),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: _AdspromotionState.textGrey,
            ),
            children:
                label.contains('*')
                    ? [
                      TextSpan(
                        text: ' *',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ]
                    : [],
          ),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
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
    bool isError = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _AdspromotionState.backgroundGrey,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isError ? Colors.red : _AdspromotionState.borderLight,
            width: isError ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    text: label.replaceAll(' *', '').replaceAll('*', ''),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: _AdspromotionState.textGrey,
                    ),
                    children:
                        label.contains('*')
                            ? [
                              TextSpan(
                                text: ' *',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ]
                            : [],
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

class AdsContactDialog extends StatefulWidget {
  final Map<String, dynamic>? existingContact;
  final VoidCallback onSaved;

  const AdsContactDialog({
    super.key,
    this.existingContact,
    required this.onSaved,
  });

  @override
  State<AdsContactDialog> createState() => _AdsContactDialogState();
}

class _AdsContactDialogState extends State<AdsContactDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _phoneController;
  late TextEditingController _whatsappController;
  bool _isSaving = false;

  Uint8List? _bannerImageBytes;
  String? _bannerImageName;
  String? _bannerImageUrl;
  String? _bannerImagePath;
  bool _isUploadingBanner = false;
  double _uploadProgress = 0.0;

  String _whatsappCountryCode = '+91';
  String _whatsappCountryIso = 'IN';

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(
      text: widget.existingContact?['phoneNumber'] ?? '',
    );
    _whatsappCountryCode =
        widget.existingContact?['whatsappCountryCode'] ?? '+91';
    _whatsappCountryIso = widget.existingContact?['whatsappCountryIso'] ?? 'IN';
    _whatsappController = TextEditingController(
      text: widget.existingContact?['whatsappNumber'] ?? '',
    );

    _bannerImageUrl = widget.existingContact?['bannerImageUrl'];
    _bannerImagePath = widget.existingContact?['bannerImagePath'];
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _pickBannerImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ImageKitBaseService.allowedExtensions,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        if (!ImageKitBaseService.isAllowedExtension(file.name)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Only JPG, PNG, WEBP files are allowed'),
              ),
            );
          }
          return;
        }

        if (file.size > ImageKitBaseService.maxFileSizeBytes) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File size must be under 5MB')),
            );
          }
          return;
        }

        setState(() {
          _isUploadingBanner = true;
          _uploadProgress = 0.0;
        });

        // Optimize image
        final optimizedBytes = await compute(_optimizeImage, file.bytes!);

        // Upload to ImageKit
        final service = AdvertisementImageService();
        final uploadResult = await service.uploadBanner(
          imageBytes: optimizedBytes,
          fileName: file.name,
          onProgress: (progress) {
            if (mounted) setState(() => _uploadProgress = progress);
          },
        );

        if (mounted) {
          setState(() {
            _bannerImageBytes = optimizedBytes;
            _bannerImageName = file.name;
            _bannerImageUrl = uploadResult.imageUrl;
            _bannerImagePath = uploadResult.fileId;
            _isUploadingBanner = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to upload banner: $e')));
        setState(() => _isUploadingBanner = false);
      }
    }
  }

  void _removeBanner() {
    setState(() {
      _bannerImageBytes = null;
      _bannerImageName = null;
      _bannerImageUrl = null;
      _bannerImagePath = null;
    });
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final docRef = FirebaseFirestore.instance
          .collection('advertisements')
          .doc('global_contact')
          .collection('ads_contact')
          .doc('contact');

      final data = {
        'phoneNumber': _phoneController.text.trim(),
        'whatsappNumber':
            _whatsappController.text.trim().isEmpty
                ? null
                : _whatsappController.text.trim(),
        'whatsappCountryCode':
            _whatsappController.text.trim().isEmpty
                ? null
                : _whatsappCountryCode,
        'whatsappCountryIso':
            _whatsappController.text.trim().isEmpty
                ? null
                : _whatsappCountryIso,
        'bannerImageUrl': _bannerImageUrl,
        'bannerImagePath': _bannerImagePath,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.existingContact == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        await docRef.set(data);
      } else {
        await docRef.update(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ads Contact saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSaved();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving contact: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        width: 420,
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Ads Contact Details",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Set the global support contact numbers for your ads.",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              // Banner Upload Section
              Text(
                "Advertisement Banner (Image Upload)",
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              if (_bannerImageUrl != null)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.network(
                            _bannerImageUrl!,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          if (_isUploadingBanner)
                            Container(
                              height: 120,
                              width: double.infinity,
                              color: Colors.black54,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed:
                                  _isUploadingBanner ? null : _pickBannerImage,
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Replace'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.blue,
                              ),
                            ),
                            TextButton.icon(
                              onPressed:
                                  _isUploadingBanner ? null : _removeBanner,
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: const Text('Remove'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                InkWell(
                  onTap: _isUploadingBanner ? null : _pickBannerImage,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey[300]!,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[50],
                    ),
                    child: Column(
                      children: [
                        if (_isUploadingBanner) ...[
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Uploading ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.grey[600],
                            ),
                          ),
                        ] else ...[
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 32,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Upload Banner Image",
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "JPG, PNG, WEBP • Max 5MB",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  labelText: "Phone Number *",
                  labelStyle: GoogleFonts.plusJakartaSans(
                    color: Colors.grey[700],
                  ),
                  hintText: "10-digit mobile number",
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: Colors.grey[400],
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.teal, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  counterText: "",
                  prefixIcon: const Icon(
                    Icons.phone_rounded,
                    color: Colors.teal,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return "Required";
                  if (val.trim().length != 10)
                    return "Must be exactly 10 digits";
                  if (double.tryParse(val.trim()) == null)
                    return "Numeric only";
                  return null;
                },
              ),
              const SizedBox(height: 20),
              IntlPhoneField(
                controller: _whatsappController,
                initialCountryCode: _whatsappCountryIso,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  labelText: "WhatsApp Number (Optional)",
                  labelStyle: GoogleFonts.plusJakartaSans(
                    color: Colors.grey[700],
                  ),
                  hintText: "Mobile number",
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: Colors.grey[400],
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                ),
                onCountryChanged: (country) {
                  _whatsappCountryCode = '+${country.dialCode}';
                  _whatsappCountryIso = country.code;
                },
                validator: (phone) {
                  if (phone == null || phone.number.isEmpty) return null;
                  if (!RegExp(r'^[0-9]+$').hasMatch(phone.number)) {
                    return "Numeric only";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveContact,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[800],
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
                    child:
                        _isSaving
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : Text(
                              "Save Details",
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
