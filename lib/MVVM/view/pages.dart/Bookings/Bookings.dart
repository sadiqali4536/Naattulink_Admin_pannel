import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swiftclean_admin/MVVM/model/models/admin_model.dart';
import 'dart:async';
import 'package:swiftclean_admin/MVVM/utils/printer_helper.dart';
import 'package:swiftclean_admin/MVVM/utils/rbac_session.dart';

class BookingModel {
  final String id;
  final String date;
  final String customerName;
  final String customerPhone;
  final String customerAvatarUrl;
  final String customerAddress;
  final String workerName;
  final String workerPhone;
  final String workerAvatarUrl;
  final String serviceName;
  final String serviceDetails;
  final String serviceImageUrl;
  final String category;
  final String dateTime;
  final double amount;
  final String paymentStatus;
  final String paymentMethod;
  final String status;
  final String workStatus;
  final String completedStatus;

  BookingModel({
    required this.id,
    required this.date,
    required this.customerName,
    required this.customerPhone,
    required this.customerAvatarUrl,
    required this.customerAddress,
    required this.workerName,
    required this.workerPhone,
    required this.workerAvatarUrl,
    required this.serviceName,
    required this.serviceDetails,
    required this.serviceImageUrl,
    required this.category,
    required this.dateTime,
    required this.amount,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.status,
    required this.workStatus,
    required this.completedStatus,
  });

  factory BookingModel.fromMap(Map<String, dynamic> data, String docId) {
    String date = (data['date'] ?? data['selectedDate'])?.toString() ?? '';
    String time = (data['Time'] ?? data['selectedTimeSlot'])?.toString() ?? '';
    String cName =
        (data['customerName'] ?? data['userEmail'])?.toString() ?? 'Unknown';
    String wImage = data['workerimage']?.toString() ?? '';

    double amt = 0.0;
    var amountData =
        data['amount'] ??
        data['price'] ??
        data['discountPrice'] ??
        data['originalPrice'];
    if (amountData != null) {
      if (amountData is String) {
        amt = double.tryParse(amountData) ?? 0.0;
      } else if (amountData is num) {
        amt = amountData.toDouble();
      }
    }

    String stat =
        (data['booking_status'] ?? data['status'])?.toString().trim() ??
        'Pending';
    if (stat.isNotEmpty) {
      stat = stat[0].toUpperCase() + stat.substring(1).toLowerCase();
    }

    String wStat = data['work_status']?.toString().trim() ?? 'Pending';
    if (wStat.isNotEmpty) {
      wStat = wStat[0].toUpperCase() + wStat.substring(1).toLowerCase();
    }

    String cStat = data['completed_status']?.toString().trim() ?? '';
    if (cStat.isNotEmpty) {
      cStat = cStat[0].toUpperCase() + cStat.substring(1).toLowerCase();
    }

    return BookingModel(
      id: data['id']?.toString() ?? docId,
      date: date,
      customerName: cName,
      customerPhone: data['customerPhone']?.toString() ?? 'N/A',
      customerAvatarUrl:
          "https://ui-avatars.com/api/?name=${Uri.encodeComponent(cName)}",
      customerAddress: data['customerAddress']?.toString() ?? 'N/A',
      workerName:
          (data['workerName'] ?? data['providerName'])?.toString() ??
          'Unassigned',
      workerPhone:
          (data['workerPhone'] ?? data['providerPhone'])?.toString() ?? 'N/A',
      workerAvatarUrl:
          wImage.isNotEmpty
              ? wImage
              : "https://ui-avatars.com/api/?name=${Uri.encodeComponent((data['workerName'] ?? data['providerName'])?.toString() ?? 'W')}",
      serviceName:
          (data['serviceName'] ?? data['serviceTitle'])?.toString() ??
          'Unknown Service',
      serviceDetails: "Standard",
      serviceImageUrl:
          data['serviceImage']?.toString() ??
          data['imageUrl']?.toString() ??
          data['image']?.toString() ??
          '',
      category:
          (data['category'] ?? data['serviceCategory'])?.toString() ??
          'Uncategorized',
      dateTime: time.isNotEmpty ? "$date\n$time" : date,
      amount: amt,
      paymentStatus: data['paymentStatus']?.toString() ?? 'Pending',
      paymentMethod: data['paymentMethod']?.toString() ?? 'Unknown',
      status: stat,
      workStatus: wStat,
      completedStatus: cStat,
    );
  }
}

class Bookings extends StatefulWidget {
  final String initialFilter;
  final ValueChanged<String>? onTabChanged;

  const Bookings({super.key, this.initialFilter = "All", this.onTabChanged});

  @override
  State<Bookings> createState() => _BookingsState();
}

class _BookingsState extends State<Bookings> {
  late int _selectedTabIndex;
  String _searchQuery = "";
  String _selectedCategory = "All Categories";
  String _selectedStatus = "All Status";
  String _selectedPaymentStatus = "All Payment Status";
  String _selectedDate = "All Dates";

  List<BookingModel> _bookings = [];
  StreamSubscription<QuerySnapshot>? _bookingsSubscription;

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void dispose() {
    _bookingsSubscription?.cancel();
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _parseInitialFilter();
    _bookingsSubscription = FirebaseFirestore.instance
        .collection('service_bookings')
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            setState(() {
              _bookings =
                  snapshot.docs
                      .map((doc) {
                        try {
                          return BookingModel.fromMap(doc.data(), doc.id);
                        } catch (e) {
                          print("Error parsing booking ${doc.id}: $e");
                          return null;
                        }
                      })
                      .where((b) => b != null)
                      .cast<BookingModel>()
                      .toList();
            });
          }
        });
  }

  void _parseInitialFilter() {
    switch (widget.initialFilter) {
      case "Pending Bookings":
      case "Pending":
        _selectedTabIndex = 1;
        break;
      case "On Going Works":
      case "Ongoing":
      case "On Going":
        _selectedTabIndex = 2;
        break;
      case "Completed Bookings":
      case "Completed":
        _selectedTabIndex = 3;
        break;
      case "Cancelled Bookings":
      case "Cancelled":
        _selectedTabIndex = 4;
        break;
      case "All Bookings":
      case "All":
      default:
        _selectedTabIndex = 0;
        break;
    }
  }

  @override
  void didUpdateWidget(covariant Bookings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFilter != widget.initialFilter) {
      setState(() {
        _parseInitialFilter();
      });
    }
  }

  List<BookingModel> _getFilteredBookings() {
    return _bookings.where((booking) {
      // Tab selection filter
      if (_selectedTabIndex == 1 &&
          !(booking.status == "Confirmed" &&
              booking.workStatus == "Pending" &&
              booking.completedStatus != "Ongoing")) {
        return false;
      }
      if (_selectedTabIndex == 2 && booking.completedStatus != "Ongoing") {
        return false;
      }
      if (_selectedTabIndex == 3 &&
          !(booking.status == "Completed" ||
              booking.completedStatus == "Completed")) {
        return false;
      }
      if (_selectedTabIndex == 4 && booking.status != "Cancelled") {
        return false;
      }

      // Dropdown / Search filters
      final matchesSearch =
          booking.customerName.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          booking.workerName.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          booking.serviceName.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          booking.id.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory =
          _selectedCategory == "All Categories" ||
          booking.category == _selectedCategory;
      final matchesStatus =
          _selectedStatus == "All Status" || booking.status == _selectedStatus;
      final matchesPayment =
          _selectedPaymentStatus == "All Payment Status" ||
          booking.paymentStatus == _selectedPaymentStatus;
      final matchesDate =
          _selectedDate == "All Dates" ||
          _formatDateDDMMYY(booking.date) == _selectedDate;

      return matchesSearch &&
          matchesCategory &&
          matchesStatus &&
          matchesPayment &&
          matchesDate;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final isSmall = width < 600;

        // Filtering
        final filteredList = _getFilteredBookings();

        return Scrollbar(
          controller: _verticalScrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _verticalScrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header & Breadcrumbs
                _buildHeaderAndBreadcrumbs(),
                const SizedBox(height: 24),

                // 5 Statistics Cards
                _buildStatsGrid(isSmall),
                const SizedBox(height: 24),

                // Filter Controls Card
                _buildFiltersCard(isSmall),
                const SizedBox(height: 20),

                // Tabs & Table Card
                _buildTableCard(filteredList, width),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderAndBreadcrumbs() {
    String subPath = "All Bookings";
    if (_selectedTabIndex == 1) subPath = "Pending Bookings";
    if (_selectedTabIndex == 2) subPath = "Confirmed Bookings";
    if (_selectedTabIndex == 3) subPath = "Completed Bookings";
    if (_selectedTabIndex == 4) subPath = "Cancelled Bookings";

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Bookings",
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Row(
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
                  "Bookings",
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
                  subPath,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid(bool isSmall) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        int crossAxisCount = 5;
        if (width < 1200 && width >= 800) {
          crossAxisCount = 3;
        } else if (isSmall) {
          crossAxisCount = 2;
        }

        final double itemWidth =
            (constraints.maxWidth - (crossAxisCount - 1) * 16) / crossAxisCount;
        const double itemHeight = 115;
        final double aspectRatio = itemWidth / itemHeight;

        int total = _bookings.length;
        int pending =
            _bookings
                .where(
                  (b) =>
                      b.status == "Confirmed" &&
                      b.workStatus == "Pending" &&
                      b.completedStatus != "Ongoing",
                )
                .length;
        int ongoing =
            _bookings.where((b) => b.completedStatus == "Ongoing").length;
        int completed =
            _bookings
                .where(
                  (b) =>
                      b.status == "Completed" ||
                      b.completedStatus == "Completed",
                )
                .length;
        int cancelled = _bookings.where((b) => b.status == "Cancelled").length;

        final cards = [
          _buildStatsCard(
            title: "Total Bookings",
            value: total.toString(),
            subtitle: "All time bookings",
            icon: Icons.calendar_today_outlined,
            color: const Color(0xFF3B82F6),
            bgColor: const Color(0xFFEFF6FF),
          ),
          _buildStatsCard(
            title: "Pending Workers",
            value: pending.toString(),
            subtitle: "Awaiting worker confirmation",
            icon: Icons.access_time_rounded,
            color: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFFEF3C7),
          ),
          _buildStatsCard(
            title: "On Going Works",
            value: ongoing.toString(),
            subtitle: "Currently in progress",
            icon: Icons.play_circle_outline_rounded,
            color: const Color(0xFF8B5CF6),
            bgColor: const Color(0xFFF5F3FF),
          ),
          _buildStatsCard(
            title: "Completed Bookings",
            value: completed.toString(),
            subtitle: "Successfully completed",
            icon: Icons.assignment_outlined,
            color: const Color(0xFF06B6D4),
            bgColor: const Color(0xFFECFEFF),
          ),
          _buildStatsCard(
            title: "Cancelled Bookings",
            value: cancelled.toString(),
            subtitle: "Cancelled by user/admin",
            icon: Icons.cancel_outlined,
            color: const Color(0xFFEF4444),
            bgColor: const Color(0xFFFEF2F2),
          ),
        ];

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: aspectRatio,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: cards,
        );
      },
    );
  }

  Widget _buildStatsCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: const Color(0xFF94A3B8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersCard(bool isSmall) {
    final searchField = SizedBox(
      width: isSmall ? double.infinity : 240,
      height: 38,
      child: TextFormField(
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          fillColor: Colors.white,
          filled: true,
          hintText: "Search by customer, worker, service...",
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

    // ── Tab-scoped source: filter bookings by the active tab so dropdown
    //    options only show values relevant to the currently visible section.
    final tabScopedBookings =
        _bookings.where((b) {
          switch (_selectedTabIndex) {
            case 1: // Pending Bookings
              return b.status == "Confirmed" &&
                  b.workStatus == "Pending" &&
                  b.completedStatus != "Ongoing";
            case 2: // On Going Works
              return b.completedStatus == "Ongoing";
            case 3: // Completed Bookings
              return b.status == "Completed" ||
                  b.completedStatus == "Completed";
            case 4: // Cancelled Bookings
              return b.status == "Cancelled";
            default: // All Bookings
              return true;
          }
        }).toList();

    // Build unique formatted dates mapped to their raw dates (needed for day names)
    final Map<String, String> formattedToRaw = {};
    for (final b in tabScopedBookings) {
      if (b.date.isNotEmpty) {
        final formatted = _formatDateDDMMYY(b.date);
        if (formatted.isNotEmpty && !formattedToRaw.containsKey(formatted)) {
          formattedToRaw[formatted] = b.date;
        }
      }
    }
    final sortedFormattedDates = formattedToRaw.keys.toList()..sort();
    // Ensure _selectedDate is still valid; reset if it no longer exists
    final validDateValue =
        (_selectedDate == "All Dates" ||
                sortedFormattedDates.contains(_selectedDate))
            ? _selectedDate
            : "All Dates";

    final dateDropdown = SizedBox(
      width: isSmall ? double.infinity : 165,
      height: 38,
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        dropdownColor: Colors.white,
        value: validDateValue,
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
        // selectedItemBuilder: what is shown inside the closed button — must be single line
        selectedItemBuilder: (context) {
          final allValues = ['All Dates', ...sortedFormattedDates];
          return allValues.map((val) {
            if (val == 'All Dates') {
              return Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'All Dates',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              );
            }
            final rawDate = formattedToRaw[val] ?? val;
            final dayName = _getDayName(rawDate);
            final label = dayName.isNotEmpty ? '$val · $dayName' : val;
            return Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF1E293B),
                ),
              ),
            );
          }).toList();
        },
        // items: what appears in the open dropdown menu (two-line layout)
        items: [
          const DropdownMenuItem(
            value: 'All Dates',
            child: Text(
              'All Dates',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ...sortedFormattedDates.map((formatted) {
            final rawDate = formattedToRaw[formatted]!;
            final dayName = _getDayName(rawDate);
            return DropdownMenuItem<String>(
              value: formatted,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatted,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (dayName.isNotEmpty)
                    Text(
                      dayName,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
        onChanged: (val) => setState(() => _selectedDate = val ?? 'All Dates'),
      ),
    );

    final statusDropdown = const SizedBox.shrink();

    // Build unique categories from tab-scoped booking data
    final uniqueCategories =
        tabScopedBookings
            .map((b) => b.category)
            .where((c) => c.isNotEmpty && c != 'Uncategorized')
            .toSet()
            .toList()
          ..sort();

    // Ensure _selectedCategory is still valid; reset if it no longer exists
    final validCategoryValue =
        (_selectedCategory == 'All Categories' ||
                uniqueCategories.contains(_selectedCategory))
            ? _selectedCategory
            : 'All Categories';

    final categoryDropdown = SizedBox(
      width: isSmall ? double.infinity : 160,
      height: 38,
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        dropdownColor: Colors.white,
        value: validCategoryValue,
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
        items: [
          const DropdownMenuItem(
            value: 'All Categories',
            child: Text(
              'All Categories',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ...uniqueCategories.map(
            (cat) => DropdownMenuItem(
              value: cat,
              child: Text(cat, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: (val) => setState(() => _selectedCategory = val!),
      ),
    );

    // Build unique payment statuses from tab-scoped booking data
    // (only the 3 supported values are surfaced)
    const _allowedPayments = {'Paid', 'Pending', 'Refunded'};
    final uniquePayments =
        tabScopedBookings
            .map((b) => b.paymentStatus)
            .where((p) => _allowedPayments.contains(p))
            .toSet()
            .toList()
          ..sort();
    final validPaymentValue =
        (_selectedPaymentStatus == 'All Payment Status' ||
                uniquePayments.contains(_selectedPaymentStatus))
            ? _selectedPaymentStatus
            : 'All Payment Status';

    final paymentDropdown = SizedBox(
      width: isSmall ? double.infinity : 170,
      height: 38,
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        dropdownColor: Colors.white,
        value: validPaymentValue,
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
        items: [
          const DropdownMenuItem(
            value: 'All Payment Status',
            child: Text(
              'All Payment Status',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ...uniquePayments.map(
            (p) => DropdownMenuItem(
              value: p,
              child: Text(p, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged:
            (val) => setState(
              () => _selectedPaymentStatus = val ?? 'All Payment Status',
            ),
      ),
    );

    final filterButton = const SizedBox.shrink();

    final exportButton = ElevatedButton.icon(
      onPressed: _exportToPdf,
      icon: const Icon(Icons.download_rounded, size: 14),
      label: Text(
        "Export",
        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF475569),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );

    if (isSmall) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          searchField,
          const SizedBox(height: 12),
          dateDropdown,
          const SizedBox(height: 12),
          categoryDropdown,
          const SizedBox(height: 12),
          paymentDropdown,
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [exportButton],
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          searchField,
          const SizedBox(width: 12),
          dateDropdown,
          const SizedBox(width: 12),
          categoryDropdown,
          const SizedBox(width: 12),
          paymentDropdown,
          const Spacer(),
          exportButton,
        ],
      ),
    );
  }

  Widget _buildTableCard(List<BookingModel> bookings, double screenWidth) {
    final allCount = _bookings.length;
    final pendingCount =
        _bookings
            .where(
              (b) =>
                  b.status == "Confirmed" &&
                  b.workStatus == "Pending" &&
                  b.completedStatus != "Ongoing",
            )
            .length;
    final ongoingCount =
        _bookings.where((b) => b.completedStatus == "Ongoing").length;
    final completedCount =
        _bookings
            .where(
              (b) =>
                  b.status == "Completed" || b.completedStatus == "Completed",
            )
            .length;
    final cancelledCount =
        _bookings.where((b) => b.status == "Cancelled").length;

    final tabs = [
      {"label": "All Bookings", "count": allCount},
      {"label": "Pending Bookings", "count": pendingCount},
      {"label": "On Going Works", "count": ongoingCount},
      {"label": "Completed Bookings", "count": completedCount},
      {"label": "Cancelled Bookings", "count": cancelledCount},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scrollable Data Table
          Scrollbar(
            controller: _horizontalScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _horizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1600,
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(0.8), // S.No
                    1: FlexColumnWidth(1.4), // Booking ID
                    2: FlexColumnWidth(2.2), // Customer
                    3: FlexColumnWidth(2.2), // Worker
                    4: FlexColumnWidth(2.0), // Service
                    5: FlexColumnWidth(1.8), // Date & Time
                    6: FlexColumnWidth(1.2), // Amount
                    7: FlexColumnWidth(1.3), // Payment
                    8: FlexColumnWidth(1.4), // Status
                    9: FlexColumnWidth(1.4), // Accept Work
                    10: FlexColumnWidth(1.2), // Actions
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    // Table Header
                    TableRow(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                      ),
                      children: [
                        _buildHeaderCell("No."),
                        _buildHeaderCell("Booking ID"),
                        _buildHeaderCell("Customer"),
                        _buildHeaderCell("Worker Assigned"),
                        _buildHeaderCell("Service"),
                        _buildHeaderCell("Booking Date & Time"),
                        _buildHeaderCell("Amount"),
                        _buildHeaderCell("Payment"),
                        _buildHeaderCell("Booking Status"),
                        _buildHeaderCell("Work Status"),
                        _buildHeaderCell("Actions"),
                      ],
                    ),

                    // Table Rows
                    ...bookings.asMap().entries.map((entry) {
                      final index = entry.key;
                      final booking = entry.value;
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
                          // S.No
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12.0,
                              horizontal: 16.0,
                            ),
                            child: Text(
                              (index + 1).toString(),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),

                          // Booking ID
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12.0,
                              horizontal: 16.0,
                            ),
                            child: Text(
                              booking.id,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),

                          // Customer Details
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12.0,
                              horizontal: 16.0,
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    booking.customerAvatarUrl,
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
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        booking.customerName,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1E293B),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        booking.customerPhone,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: const Color(0xFF64748B),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Worker Details
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12.0,
                              horizontal: 16.0,
                            ),
                            child:
                                (booking.workerName == 'Unassigned' ||
                                        booking.workerName == 'Unknown')
                                    ? Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFFEF3C7),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.hourglass_empty_rounded,
                                            color: Color(0xFFF59E0B),
                                            size: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            "Waiting for worker",
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: const Color(0xFFD97706),
                                              fontStyle: FontStyle.italic,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    )
                                    : Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          child: Image.network(
                                            booking.workerAvatarUrl,
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
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                booking.workerName,
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: const Color(
                                                    0xFF1E293B,
                                                  ),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                booking.workerPhone,
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  color: const Color(
                                                    0xFF64748B,
                                                  ),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                          ),

                          // Service Details
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12.0,
                              horizontal: 16.0,
                            ),
                            child: _buildServiceCell(
                              booking.serviceName,
                              booking.category,
                              booking.category,
                              booking.serviceImageUrl,
                            ),
                          ),

                          // Booking Date & Time
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12.0,
                              horizontal: 16.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatDateTimeDisplay(booking.dateTime),
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF475569),
                                    height: 1.3,
                                  ),
                                ),
                                if (_getDayName(booking.date).isNotEmpty)
                                  Text(
                                    _getDayName(booking.date),
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: const Color(0xFF94A3B8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Amount Cell
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12.0,
                              horizontal: 16.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "₹${booking.amount.toStringAsFixed(0)}",
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Payment Cell
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12.0,
                              horizontal: 16.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildPaymentStatusIndicator(
                                  booking.paymentStatus,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  booking.paymentMethod,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Status Cell
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12.0,
                              horizontal: 16.0,
                            ),
                            child: _buildStatusBadge(booking.status),
                          ),

                          // Work Status Column
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12.0,
                              horizontal: 16.0,
                            ),
                            child: _buildStatusBadge(
                              booking.completedStatus.isNotEmpty
                                  ? booking.completedStatus
                                  : booking.workStatus,
                            ),
                          ),

                          // Actions Cell
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12.0,
                              horizontal: 4.0,
                            ),
                            child: Row(
                              children: [
                                _buildActionButton(
                                  Icons.visibility_outlined,
                                  Colors.blue,
                                  () {
                                    _showBookingDetailsDialog(
                                      booking,
                                      tabIndex: _selectedTabIndex,
                                    );
                                  },
                                  'view',
                                ),
                                const SizedBox(width: 4),
                                _buildActionButton(
                                  Icons.edit_outlined,
                                  Colors.blue,
                                  () {
                                    _showEditBookingStatusDialog(booking);
                                  },
                                  'edit',
                                ),
                                const SizedBox(width: 4),
                                _buildActionButton(
                                  Icons.delete_outline_rounded,
                                  Colors.red,
                                  () {
                                    _showDeleteConfirmationDialog(booking);
                                  },
                                  'delete',
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
          ),

          // Pagination Footer
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildTableFooter(bookings.length, _bookings.length),
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
          color: const Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _buildServiceCell(
    String title,
    String subtitle,
    String categoryForIcon,
    String imageUrl,
  ) {
    IconData icon;
    Color color;
    Color bgColor;

    switch (categoryForIcon) {
      case "Home Cleaning":
      case "Room Cleaning":
        icon = Icons.home_repair_service_rounded;
        color = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFEF3C7);
        break;
      case "Pet Grooming":
        icon = Icons.pets_rounded;
        color = const Color(0xFF8B5CF6);
        bgColor = const Color(0xFFF5F3FF);
        break;
      case "Garden Services":
        icon = Icons.local_florist_rounded;
        color = const Color(0xFF10B981);
        bgColor = const Color(0xFFECFDF5);
        break;
      case "Vehicle Cleaning":
        icon = Icons.directions_car_rounded;
        color = const Color(0xFF3B82F6);
        bgColor = const Color(0xFFEFF6FF);
        break;
      case "Interior Cleaning":
      default:
        icon = Icons.chair_rounded;
        color = const Color(0xFF06B6D4);
        bgColor = const Color(0xFFECFEFF);
        break;
    }

    return Row(
      children: [
        if (imageUrl.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              imageUrl,
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(child: Icon(icon, color: color, size: 16)),
                );
              },
            ),
          )
        else
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(child: Icon(icon, color: color, size: 16)),
          ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF1E293B),
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF64748B),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStatusIndicator(String pStatus) {
    Color color;
    Color bgColor;

    switch (pStatus) {
      case "Paid":
        color = const Color(0xFF10B981);
        bgColor = const Color(0xFFECFDF5);
        break;
      case "Failed":
        color = const Color(0xFFEF4444);
        bgColor = const Color(0xFFFEF2F2);
        break;
      case "Pending":
      default:
        color = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFEF3C7);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        pStatus,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    Color bgColor;

    String trimmedStatus = status.trim();
    String displayStatus =
        trimmedStatus.isNotEmpty
            ? trimmedStatus[0].toUpperCase() +
                trimmedStatus.substring(1).toLowerCase()
            : trimmedStatus;

    switch (displayStatus) {
      case "Completed":
        color = const Color(0xFF3B82F6);
        bgColor = const Color(0xFFEFF6FF);
        break;
      case "Confirmed":
      case "Accepted":
        color = const Color(0xFF10B981);
        bgColor = const Color(0xFFECFDF5);
        break;
      case "Rejected":
      case "Cancelled":
        color = const Color(0xFFEF4444);
        bgColor = const Color(0xFFFEF2F2);
        break;
      case "Ongoing":
        color = const Color(0xFF8B5CF6);
        bgColor = const Color(0xFFF5F3FF);
        break;
      case "Pending":
      default:
        color = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFEF3C7);
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                displayStatus,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
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
        !RbacSession().hasPermission(Modules.bookings, permissionAction)) {
      return const SizedBox.shrink();
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }

  Widget _buildTableFooter(int totalFiltered, int totalBookings) {
    return Row(
      children: [
        Text(
          "Showing 1 to $totalFiltered of $totalBookings bookings",
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
            Text(
              "...",
              style: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
            ),
            InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                child: Center(
                  child: Text(
                    "157",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            ),
            const IconButton(
              icon: Icon(Icons.chevron_right_rounded, size: 18),
              onPressed: null,
            ),
          ],
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 115,
          height: 32,
          child: DropdownButtonFormField<int>(
            isExpanded: true,
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

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onEdit,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF64748B), size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
        if (onEdit != null)
          IconButton(
            icon: const Icon(
              Icons.edit_outlined,
              size: 16,
              color: Color(0xFF64748B),
            ),
            onPressed: onEdit,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 16,
          ),
      ],
    );
  }

  /// Formats a raw date string (various formats) to DD/MM/YYYY.
  /// Handles full ISO timestamps like 2026-07-29T15:34:38.4... by
  /// stripping the time portion before parsing.
  String _formatDateDDMMYY(String raw) {
    if (raw.isEmpty) return raw;
    String cleaned = raw.trim();
    // Strip time portion from full ISO timestamps (e.g. 2026-07-29T15:34:38...)
    if (cleaned.contains('T')) {
      cleaned = cleaned.split('T').first;
    }
    // Try ISO date format: 2026-08-11
    final isoPattern = RegExp(r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})$');
    final isoMatch = isoPattern.firstMatch(cleaned);
    if (isoMatch != null) {
      final day = isoMatch.group(3)!.padLeft(2, '0');
      final month = isoMatch.group(2)!.padLeft(2, '0');
      final year = isoMatch.group(1)!; // full 4-digit year
      return '$day/$month/$year';
    }
    // Try DD-MM-YYYY or DD/MM/YYYY
    final dmyPattern = RegExp(r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})$');
    final dmyMatch = dmyPattern.firstMatch(cleaned);
    if (dmyMatch != null) {
      final day = dmyMatch.group(1)!.padLeft(2, '0');
      final month = dmyMatch.group(2)!.padLeft(2, '0');
      final year = dmyMatch.group(3)!;
      return '$day/$month/$year';
    }
    // Already in expected format or unrecognised – return as-is
    return raw;
  }

  /// Returns the full weekday name (e.g. "Tuesday") for a raw date string.
  /// Handles full ISO timestamps like 2026-07-29T15:34:38.4...
  String _getDayName(String raw) {
    if (raw.isEmpty) return '';
    try {
      String cleaned = raw.trim();
      // Strip time portion from full ISO timestamps
      if (cleaned.contains('T')) {
        cleaned = cleaned.split('T').first;
      }
      DateTime? dt;
      final isoPattern = RegExp(r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})$');
      final isoMatch = isoPattern.firstMatch(cleaned);
      if (isoMatch != null) {
        dt = DateTime(
          int.parse(isoMatch.group(1)!),
          int.parse(isoMatch.group(2)!),
          int.parse(isoMatch.group(3)!),
        );
      } else {
        final dmyPattern = RegExp(r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})$');
        final dmyMatch = dmyPattern.firstMatch(cleaned);
        if (dmyMatch != null) {
          dt = DateTime(
            int.parse(dmyMatch.group(3)!),
            int.parse(dmyMatch.group(2)!),
            int.parse(dmyMatch.group(1)!),
          );
        }
      }
      if (dt == null) return '';
      const days = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      return days[dt.weekday - 1];
    } catch (_) {
      return '';
    }
  }

  /// Formats a dateTime string (which may have a newline separating date and time)
  /// to "DD/MM/YYYY HH:MM" display form.
  String _formatDateTimeDisplay(String dateTime) {
    final parts = dateTime.split('\n');
    final datePart = _formatDateDDMMYY(parts[0].trim());
    if (parts.length > 1 && parts[1].trim().isNotEmpty) {
      return '$datePart ${parts[1].trim()}';
    }
    return datePart;
  }

  void _showBookingDetailsDialog(BookingModel booking, {int tabIndex = 0}) {
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
                    color: Color(0x14000000), // 8% opacity
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    "Booking Details",
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(height: 1, color: const Color(0xFFE2E8F0)),
                  const SizedBox(height: 24),

                  // Wrap details body in Flexible + SingleChildScrollView to prevent overflow
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  booking.id,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildStatusBadge(booking.status),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Details Grid / List
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFF1F5F9),
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildDetailRow(
                                  Icons.calendar_today_outlined,
                                  "Booking Date & Time",
                                  _getDayName(booking.date).isNotEmpty
                                      ? "${_formatDateTimeDisplay(booking.dateTime)}\n${_getDayName(booking.date)}"
                                      : _formatDateTimeDisplay(
                                        booking.dateTime,
                                      ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Divider(color: Color(0xFFE2E8F0)),
                                ),
                                _buildDetailRow(
                                  Icons.person_outline,
                                  "Customer Name",
                                  booking.customerName,
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Divider(color: Color(0xFFE2E8F0)),
                                ),
                                _buildDetailRow(
                                  Icons.phone_outlined,
                                  "Customer Phone",
                                  booking.customerPhone,
                                  onEdit:
                                      () => _showEditFieldDialog(
                                        booking,
                                        "Customer Phone",
                                        booking.customerPhone,
                                        "customerPhone",
                                      ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Divider(color: Color(0xFFE2E8F0)),
                                ),
                                _buildDetailRow(
                                  Icons.location_on_outlined,
                                  "Customer Address",
                                  booking.customerAddress,
                                  onEdit:
                                      () => _showEditFieldDialog(
                                        booking,
                                        "Customer Address",
                                        booking.customerAddress,
                                        "customerAddress",
                                      ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Divider(color: Color(0xFFE2E8F0)),
                                ),
                                _buildDetailRow(
                                  Icons.engineering_outlined,
                                  "Worker Name",
                                  booking.workerName,
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Divider(color: Color(0xFFE2E8F0)),
                                ),
                                _buildDetailRow(
                                  Icons.phone_outlined,
                                  "Worker Phone",
                                  booking.workerPhone,
                                  onEdit:
                                      () => _showEditFieldDialog(
                                        booking,
                                        "Worker Phone",
                                        booking.workerPhone,
                                        "workerPhone",
                                      ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Divider(color: Color(0xFFE2E8F0)),
                                ),
                                _buildDetailRow(
                                  Icons.category_outlined,
                                  "Service & Category",
                                  "${booking.serviceName} - ${booking.category}",
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Divider(color: Color(0xFFE2E8F0)),
                                ),
                                _buildDetailRow(
                                  Icons.attach_money_rounded,
                                  "Amount",
                                  "₹${booking.amount.toStringAsFixed(2)}",
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Divider(color: Color(0xFFE2E8F0)),
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.payment_outlined,
                                      color: Color(0xFF64748B),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Payment Details",
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: const Color(0xFF94A3B8),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              _buildPaymentStatusIndicator(
                                                booking.paymentStatus,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                "via ${booking.paymentMethod}",
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: const Color(
                                                    0xFF1E293B,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 16,
                                        color: Color(0xFF64748B),
                                      ),
                                      onPressed:
                                          () => _showEditPaymentDetailsDialog(
                                            booking,
                                          ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      splashRadius: 16,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // ── Status Section (tab-contextual) ──────────────
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Divider(color: Color(0xFFE2E8F0)),
                          ),
                          // Work Status – shown on: All Bookings (0), Pending (1), Ongoing (2)
                          if (tabIndex != 3 &&
                              tabIndex !=
                                  4) // hide on Completed-only and Cancelled tabs
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.work_outline_rounded,
                                  color: Color(0xFF64748B),
                                  size: 18,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Booking Status",
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF94A3B8),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      _buildStatusBadge(booking.workStatus),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                          // Completed Status – shown on: All Bookings (0), Ongoing (2), Completed (3)
                          if (tabIndex != 1 &&
                              tabIndex !=
                                  4) // hide on Pending-only and Cancelled tabs
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Divider(color: Color(0xFFE2E8F0)),
                            ),
                          if (tabIndex != 1 &&
                              tabIndex !=
                                  4) // hide on Pending-only and Cancelled tabs
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: Color(0xFF64748B),
                                  size: 18,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Work Status",
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF94A3B8),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      booking.completedStatus.isNotEmpty
                                          ? _buildStatusBadge(
                                            booking.completedStatus,
                                          )
                                          : Text(
                                            "—",
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: const Color(0xFF94A3B8),
                                            ),
                                          ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          "Close",
                          style: GoogleFonts.inter(
                            color: const Color(0xFF475569),
                            fontWeight: FontWeight.w600,
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
    );
  }

  void _showEditFieldDialog(
    BookingModel booking,
    String fieldTitle,
    String currentValue,
    String firestoreField,
  ) {
    if (!_can(Modules.bookings, Perms.edit)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Access Denied: You do not have permission to edit bookings.",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final TextEditingController controller = TextEditingController(
      text: currentValue,
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Edit $fieldTitle",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: fieldTitle,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: GoogleFonts.inter(color: Colors.grey[700]),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('service_bookings')
                      .doc(booking.id)
                      .update({firestoreField: controller.text});
                  if (mounted) {
                    final nav = Navigator.of(context);
                    nav.pop(); // Close the edit dialog
                    nav.pop(); // Close the details dialog so old data doesn't persist on screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("$fieldTitle updated successfully!"),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error updating: $e")),
                    );
                  }
                }
              },
              child: Text(
                "Save",
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditBookingStatusDialog(BookingModel booking) {
    if (!RbacSession().hasPermission(Modules.bookings, Perms.edit)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Access Denied: You do not have permission to edit bookings.",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    String selectedStatus = booking.completedStatus;
    if (selectedStatus.isEmpty) selectedStatus = "Pending";
    List<String> validStatuses = ["Completed", "Ongoing", "Pending"];
    if (!validStatuses.contains(selectedStatus)) {
      validStatuses.add(selectedStatus);
    }

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
                  width: 400,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000), // 8% opacity
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Update Booking Worker Status",
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
                      Container(height: 1, color: const Color(0xFFE2E8F0)),
                      const SizedBox(height: 20),

                      Text(
                        "Booking ID: ${booking.id}",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 16),
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
                        value: selectedStatus,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
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
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF1E293B),
                        ),
                        items:
                            validStatuses
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setDialogState(() {
                              selectedStatus = v;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 24),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
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
                              try {
                                String newWorkStatus =
                                    (selectedStatus == "Completed" ||
                                            selectedStatus == "Ongoing")
                                        ? "Accepted"
                                        : "Pending";

                                Map<String, dynamic> updateData = {
                                  'completed_status': selectedStatus,
                                  'work_status': newWorkStatus,
                                };

                                if (selectedStatus == "Completed" ||
                                    selectedStatus == "Ongoing") {
                                  updateData['status'] = "Confirmed";
                                }

                                await FirebaseFirestore.instance
                                    .collection('service_bookings')
                                    .doc(booking.id)
                                    .update(updateData);

                                if (mounted) {
                                  Navigator.pop(dialogContext);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Status updated to $selectedStatus",
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Error updating status: $e",
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
                                vertical: 12,
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
              );
            },
          ),
    );
  }

  void _showEditPaymentDetailsDialog(BookingModel booking) {
    if (!_can(Modules.bookings, Perms.edit)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Access Denied: You do not have permission to edit bookings.",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    String selectedStatus = booking.paymentStatus;
    final validStatuses = ["Pending", "Paid", "Failed", "Refunded"];
    if (!validStatuses.contains(selectedStatus)) {
      validStatuses.add(selectedStatus);
    }

    String selectedMethod = booking.paymentMethod;
    final validMethods = ["Wallet", "Online Pay", "Cash", "Card"];
    if (!validMethods.contains(selectedMethod)) {
      validMethods.add(selectedMethod);
    }

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
                  width: 400,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000), // 8% opacity
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Update Payment Details",
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
                      Container(height: 1, color: const Color(0xFFE2E8F0)),
                      const SizedBox(height: 20),

                      Text(
                        "Booking ID: ${booking.id}",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Payment Status",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
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
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF1E293B),
                        ),
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF64748B),
                        ),
                        items:
                            validStatuses
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setDialogState(() {
                              selectedStatus = v;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Payment Method",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: selectedMethod,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
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
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF1E293B),
                        ),
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF64748B),
                        ),
                        items:
                            validMethods
                                .map(
                                  (m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(m),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setDialogState(() {
                              selectedMethod = v;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 24),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
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
                              try {
                                await FirebaseFirestore.instance
                                    .collection('service_bookings')
                                    .doc(booking.id)
                                    .update({
                                      'paymentStatus': selectedStatus,
                                      'paymentMethod': selectedMethod,
                                    });

                                if (mounted) {
                                  final nav = Navigator.of(context);
                                  nav.pop();
                                  nav.pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Payment Details updated successfully",
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Error updating status: $e",
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
                                vertical: 12,
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
              );
            },
          ),
    );
  }

  void _showDeleteConfirmationDialog(BookingModel booking) {
    if (!RbacSession().hasPermission(Modules.bookings, Perms.delete)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Access Denied: You do not have permission to delete bookings.",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
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
              width: 400,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000), // 8% opacity
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFEF4444),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Delete Booking",
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Are you sure you want to delete ${booking.id}? This action cannot be undone.",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF64748B),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                            vertical: 12,
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
                          try {
                            await FirebaseFirestore.instance
                                .collection('service_bookings')
                                .doc(booking.id)
                                .delete();

                            if (mounted) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Booking ${booking.id} deleted",
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error deleting: $e")),
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
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          "Delete",
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
    );
  }

  Future<void> _exportToPdf() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Preparing export... Please wait.")),
    );

    try {
      final filteredBookings = _getFilteredBookings();
      printBookingsList(filteredBookings);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error exporting: $e")));
      }
    }
  }

  bool _can(String module, String action) {
    return RbacSession().hasPermission(module, action);
  }
}
