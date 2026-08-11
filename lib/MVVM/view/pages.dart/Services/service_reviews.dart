import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_stars/flutter_rating_stars.dart';
import 'package:swiftclean_admin/MVVM/utils/printer_helper.dart';

class ServiceReviewsPage extends StatefulWidget {
  const ServiceReviewsPage({super.key});

  @override
  State<ServiceReviewsPage> createState() => _ServiceReviewsPageState();
}

class _ServiceReviewsPageState extends State<ServiceReviewsPage> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String _searchQuery = "";
  String _selectedStatus = "All Status";
  String _selectedRating = "All Ratings";
  int _rowsPerPage = 10;
  int _currentPage = 1;
  late Stream<QuerySnapshot> _reviewsStream;

  @override
  void initState() {
    super.initState();
    _reviewsStream =
        FirebaseFirestore.instance.collection('service_reviews').snapshots();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: StreamBuilder<QuerySnapshot>(
        stream: _reviewsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];

          final uniqueRatings =
              docs
                  .map((doc) {
                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    final r = data['rating'];
                    return (r is num) ? r.toDouble().toStringAsFixed(1) : "0.0";
                  })
                  .toSet()
                  .toList()
                ..sort();

          // Apply local filtering
          final filteredDocs =
              docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>? ?? {};

                final serviceName =
                    data['serviceName']?.toString().toLowerCase() ?? '';
                final userName =
                    data['userName']?.toString().toLowerCase() ?? '';
                final reviewText =
                    data['review']?.toString().toLowerCase() ?? '';
                final status = data['status']?.toString() ?? 'Pending';

                final r = data['rating'];
                final ratingStr =
                    (r is num) ? r.toDouble().toStringAsFixed(1) : "0.0";

                bool matchesSearch =
                    _searchQuery.isEmpty ||
                    serviceName.contains(_searchQuery) ||
                    userName.contains(_searchQuery) ||
                    reviewText.contains(_searchQuery);

                bool matchesStatus =
                    _selectedStatus == 'All Status' ||
                    status == _selectedStatus;

                bool matchesRating =
                    _selectedRating == 'All Ratings' ||
                    ratingStr == _selectedRating;

                return matchesSearch && matchesStatus && matchesRating;
              }).toList();

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildStatsCards(docs),
                const SizedBox(height: 24),
                _buildFiltersCard(filteredDocs, uniqueRatings),
                const SizedBox(height: 20),
                Expanded(
                  child: Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Expanded(child: _buildDataTable(filteredDocs)),
                        _buildPagination(filteredDocs.length),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Service Reviews",
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
                  "Services",
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
                  "Service Reviews",
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
        ElevatedButton.icon(
          onPressed: _showAddReviewDialog,
          icon: const Icon(Icons.add, size: 16),
          label: Text(
            "Add Review",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF047857),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersCard(
    List<QueryDocumentSnapshot> filteredDocs,
    List<String> uniqueRatings,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 250,
            height: 38,
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                isDense: true,
                hintText: "Search by service, user or review...",
                hintStyle: GoogleFonts.inter(
                  color: const Color(0xFF94A3B8),
                  fontSize: 12,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF64748B),
                  size: 18,
                ),
                fillColor: const Color(0xFFF8FAFC),
                filled: true,
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              style: GoogleFonts.inter(
                color: const Color(0xFF1E293B),
                fontSize: 12,
              ),
              onChanged:
                  (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 140,
            height: 38,
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              value: _selectedStatus,
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
              style: GoogleFonts.inter(
                color: const Color(0xFF1E293B),
                fontSize: 12,
              ),
              items:
                  ['All Status', 'Approved', 'Pending', 'Rejected']
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(
                            status,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (val) => setState(() => _selectedStatus = val!),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 140,
            height: 38,
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              value: _selectedRating,
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
              style: GoogleFonts.inter(
                color: const Color(0xFF1E293B),
                fontSize: 12,
              ),
              items:
                  ['All Ratings', ...uniqueRatings]
                      .map(
                        (rating) => DropdownMenuItem(
                          value: rating,
                          child: Text(
                            rating == 'All Ratings' ? rating : "$rating Stars",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (val) => setState(() => _selectedRating = val!),
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _exportReviews(filteredDocs),
            icon: const Icon(Icons.download_rounded, size: 14),
            label: Text(
              "Export",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF475569),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(List<QueryDocumentSnapshot> docs) {
    int totalReviews = docs.length;
    int approvedReviews =
        docs.where((d) => (d.data() as Map)['status'] == 'Approved').length;
    int pendingReviews =
        docs.where((d) => (d.data() as Map)['status'] == 'Pending').length;
    int rejectedReviews =
        docs.where((d) => (d.data() as Map)['status'] == 'Rejected').length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double itemWidth = (constraints.maxWidth - 48) / 4;
        const double itemHeight = 115;
        final double aspectRatio = itemWidth / itemHeight;

        final cards = [
          _buildStatsCard(
            title: "Total Reviews",
            value: totalReviews.toString(),
            icon: Icons.star,
            color: const Color(0xFF3B82F6),
            bgColor: const Color(0xFFEFF6FF),
          ),
          _buildStatsCard(
            title: "Approved",
            value: approvedReviews.toString(),
            icon: Icons.thumb_up,
            color: const Color(0xFF10B981),
            bgColor: const Color(0xFFECFDF5),
          ),
          _buildStatsCard(
            title: "Pending",
            value: pendingReviews.toString(),
            icon: Icons.access_time,
            color: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFFEF3C7),
          ),
          _buildStatsCard(
            title: "Rejected",
            value: rejectedReviews.toString(),
            icon: Icons.thumb_down,
            color: const Color(0xFFEF4444),
            bgColor: const Color(0xFFFEF2F2),
          ),
        ];

        return GridView.count(
          crossAxisCount: 4,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(List<QueryDocumentSnapshot> docs) {
    // Implement simple local pagination logic
    final int startIndex = (_currentPage - 1) * _rowsPerPage;
    final int endIndex = startIndex + _rowsPerPage;
    final paginatedDocs = docs.sublist(
      startIndex > docs.length ? 0 : startIndex,
      endIndex > docs.length ? docs.length : endIndex,
    );

    return Scrollbar(
      controller: _verticalScrollController,
      thumbVisibility: true,
      child: Scrollbar(
        controller: _horizontalScrollController,
        thumbVisibility: true,
        notificationPredicate: (notif) => notif.depth == 1,
        child: SingleChildScrollView(
          controller: _verticalScrollController,
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.white),
              headingRowHeight: 54,
              headingTextStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
                fontSize: 15,
              ),
              dataRowMaxHeight: 60,
              dataRowMinHeight: 48,
              columnSpacing: 20,
              horizontalMargin: 20,
              dividerThickness: 1,
              columns: const [
                DataColumn(label: SizedBox(width: 40, child: Text("No."))),
                DataColumn(
                  label: SizedBox(width: 150, child: Text("Review Details")),
                ),
                DataColumn(label: SizedBox(width: 150, child: Text("Service"))),
                DataColumn(label: SizedBox(width: 150, child: Text("User"))),
                DataColumn(label: SizedBox(width: 100, child: Text("Rating"))),
                DataColumn(label: SizedBox(width: 250, child: Text("Review"))),
                DataColumn(label: SizedBox(width: 100, child: Text("Status"))),
                DataColumn(label: SizedBox(width: 120, child: Text("Date"))),
                DataColumn(label: SizedBox(width: 60, child: Text("Actions"))),
              ],
              rows:
                  paginatedDocs.asMap().entries.map((entry) {
                    final int index = startIndex + entry.key + 1;
                    final doc = entry.value;
                    final review = doc.data() as Map<String, dynamic>? ?? {};
                    final rating =
                        review['rating'] is num
                            ? (review['rating'] as num).toDouble()
                            : 0.0;
                    final serviceImage = review['serviceImage']?.toString();
                    final serviceTitle = review['serviceName']?.toString();
                    final serviceId = review['serviceId']?.toString();
                    final category = review['serviceCategory']?.toString();
                    final userName = review['userName']?.toString();
                    final userPhone = review['userPhone']?.toString();
                    final reviewText =
                        review['review']?.toString() ?? 'No review provided';
                    final status = review['status']?.toString() ?? 'Pending';

                    String date = 'N/A';
                    String time = 'N/A';
                    if (review['createdAt'] != null) {
                      try {
                        final dt = (review['createdAt'] as Timestamp).toDate();
                        date =
                            "${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}";
                        final hour =
                            dt.hour > 12
                                ? dt.hour - 12
                                : (dt.hour == 0 ? 12 : dt.hour);
                        final amPm = dt.hour >= 12 ? 'PM' : 'AM';
                        time =
                            "${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $amPm";
                      } catch (e) {
                        // Ignore parse errors, fallback to N/A
                      }
                    }

                    return DataRow(
                      cells: [
                        DataCell(
                          SizedBox(
                            width: 40,
                            child: Text(
                              index.toString(),
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 150,
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child:
                                      serviceImage != null &&
                                              serviceImage.isNotEmpty
                                          ? Image.network(
                                            serviceImage,
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    _buildImagePlaceholder(),
                                          )
                                          : _buildImagePlaceholder(),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        serviceTitle ?? 'Unknown Service',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF1E293B),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (serviceId != null)
                                        Text(
                                          serviceId,
                                          style: GoogleFonts.inter(
                                            color: Colors.grey.shade500,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 150,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  serviceTitle ?? 'Unknown Service',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1E293B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (category != null && category.isNotEmpty)
                                  Text(
                                    category,
                                    style: GoogleFonts.inter(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 150,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  userName ?? 'Unknown User',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1E293B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (userPhone != null && userPhone.isNotEmpty)
                                  Text(
                                    userPhone,
                                    style: GoogleFonts.inter(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 100,
                            child: Row(
                              children: [
                                Icon(Icons.star, size: 16, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 250,
                            child: Text(
                              reviewText,
                              style: GoogleFonts.inter(
                                color: const Color(0xFF1E293B),
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 110,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _buildStatusBadge(status),
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 120,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  date,
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF1E293B),
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  time,
                                  style: GoogleFonts.inter(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 60,
                            child: Center(
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(
                                    Icons.remove_red_eye,
                                    size: 16,
                                  ),
                                  color: Colors.grey.shade700,
                                  onPressed:
                                      () => _showViewReviewDialog(review),
                                  splashRadius: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 40,
      height: 40,
      color: Colors.grey.shade200,
      child: Icon(Icons.image, color: Colors.grey.shade400, size: 20),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Approved':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        break;
      case 'Pending':
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade800;
        break;
      case 'Rejected':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
    }

    return IntrinsicWidth(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          status,
          style: GoogleFonts.inter(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildPagination(int totalRecords) {
    int totalPages = (totalRecords / _rowsPerPage).ceil();
    if (totalPages < 1) totalPages = 1;

    final startIndex = (_currentPage - 1) * _rowsPerPage + 1;
    final endIndex = startIndex + _rowsPerPage - 1;
    final displayEnd = endIndex > totalRecords ? totalRecords : endIndex;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Showing $startIndex to $displayEnd of $totalRecords reviews",
            style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13),
          ),
          Row(
            children: [
              InkWell(
                onTap:
                    _currentPage > 1
                        ? () => setState(() => _currentPage--)
                        : null,
                child: _buildPageButton(Icons.chevron_left, isIcon: true),
              ),
              const SizedBox(width: 8),
              if (totalPages <= 5)
                ...List.generate(totalPages, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: InkWell(
                      onTap: () => setState(() => _currentPage = index + 1),
                      child: _buildPageButton(
                        "${index + 1}",
                        isSelected: _currentPage == index + 1,
                      ),
                    ),
                  );
                })
              else ...[
                InkWell(
                  onTap: () => setState(() => _currentPage = 1),
                  child: _buildPageButton("1", isSelected: _currentPage == 1),
                ),
                const SizedBox(width: 8),
                Text("...", style: TextStyle(color: Colors.grey.shade500)),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => setState(() => _currentPage = totalPages),
                  child: _buildPageButton(
                    "$totalPages",
                    isSelected: _currentPage == totalPages,
                  ),
                ),
              ],
              InkWell(
                onTap:
                    _currentPage < totalPages
                        ? () => setState(() => _currentPage++)
                        : null,
                child: _buildPageButton(Icons.chevron_right, isIcon: true),
              ),
              const SizedBox(width: 16),
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _rowsPerPage,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                    items:
                        [10, 20, 50].map((int value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text(
                              "$value / page",
                              style: GoogleFonts.inter(fontSize: 13),
                            ),
                          );
                        }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _rowsPerPage = val;
                          _currentPage = 1;
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton(
    dynamic content, {
    bool isSelected = false,
    bool isIcon = false,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF047857) : Colors.white, // green
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected ? const Color(0xFF047857) : Colors.grey.shade300,
        ),
      ),
      child: Center(
        child:
            isIcon
                ? Icon(
                  content as IconData,
                  size: 20,
                  color: Colors.grey.shade600,
                )
                : Text(
                  content.toString(),
                  style: GoogleFonts.inter(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
      ),
    );
  }

  Future<void> _showAddReviewDialog() async {
    final _formKey = GlobalKey<FormState>();
    double _rating = 0;
    String _review = '';
    String _status = 'Pending';

    DocumentSnapshot? _selectedService;
    DocumentSnapshot? _selectedUser;

    bool _isLoading = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                "Add Service Review",
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Service",
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        StreamBuilder<QuerySnapshot>(
                          stream:
                              FirebaseFirestore.instance
                                  .collection('services')
                                  .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData)
                              return const CircularProgressIndicator();
                            final services = snapshot.data!.docs;
                            return Autocomplete<DocumentSnapshot>(
                              displayStringForOption:
                                  (option) =>
                                      (option.data()
                                          as Map<String, dynamic>)['title'] ??
                                      'Unknown Service',
                              optionsBuilder: (
                                TextEditingValue textEditingValue,
                              ) {
                                if (textEditingValue.text.isEmpty) {
                                  return services;
                                }
                                return services.where((service) {
                                  final title =
                                      (service.data()
                                              as Map<String, dynamic>)['title']
                                          ?.toString()
                                          .toLowerCase() ??
                                      '';
                                  return title.contains(
                                    textEditingValue.text.toLowerCase(),
                                  );
                                });
                              },
                              onSelected: (selection) {
                                _selectedService = selection;
                              },
                              fieldViewBuilder: (
                                context,
                                textEditingController,
                                focusNode,
                                onFieldSubmitted,
                              ) {
                                return TextFormField(
                                  controller: textEditingController,
                                  focusNode: focusNode,
                                  decoration: InputDecoration(
                                    hintText: "Search Service",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  validator:
                                      (value) =>
                                          _selectedService == null
                                              ? "Please select a service"
                                              : null,
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        Text(
                          "User",
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        StreamBuilder<QuerySnapshot>(
                          stream:
                              FirebaseFirestore.instance
                                  .collection('users')
                                  .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData)
                              return const CircularProgressIndicator();
                            final users = snapshot.data!.docs;
                            return Autocomplete<DocumentSnapshot>(
                              displayStringForOption: (option) {
                                final data =
                                    option.data() as Map<String, dynamic>;
                                return "${data['name'] ?? 'Unknown'} (${data['phone'] ?? ''})";
                              },
                              optionsBuilder: (
                                TextEditingValue textEditingValue,
                              ) {
                                if (textEditingValue.text.isEmpty) {
                                  return users;
                                }
                                return users.where((user) {
                                  final data =
                                      user.data() as Map<String, dynamic>;
                                  final name =
                                      data['name']?.toString().toLowerCase() ??
                                      '';
                                  final phone =
                                      data['phone']?.toString().toLowerCase() ??
                                      '';
                                  return name.contains(
                                        textEditingValue.text.toLowerCase(),
                                      ) ||
                                      phone.contains(
                                        textEditingValue.text.toLowerCase(),
                                      );
                                });
                              },
                              onSelected: (selection) {
                                _selectedUser = selection;
                              },
                              fieldViewBuilder: (
                                context,
                                textEditingController,
                                focusNode,
                                onFieldSubmitted,
                              ) {
                                return TextFormField(
                                  controller: textEditingController,
                                  focusNode: focusNode,
                                  decoration: InputDecoration(
                                    hintText: "Search User",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  validator:
                                      (value) =>
                                          _selectedUser == null
                                              ? "Please select a user"
                                              : null,
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        Text(
                          "Rating",
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        RatingStars(
                          value: _rating,
                          onValueChanged: (v) {
                            setState(() {
                              _rating = v;
                            });
                          },
                          starCount: 5,
                          starSize: 30,
                          valueLabelColor: const Color(0xff9b9b9b),
                          valueLabelTextStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                            fontSize: 12.0,
                          ),
                          valueLabelRadius: 10,
                          maxValue: 5,
                          starSpacing: 2,
                          maxValueVisibility: true,
                          valueLabelVisibility: true,
                          animationDuration: Duration(milliseconds: 1000),
                          valueLabelPadding: const EdgeInsets.symmetric(
                            vertical: 1,
                            horizontal: 8,
                          ),
                          valueLabelMargin: const EdgeInsets.only(right: 8),
                          starOffColor: const Color(0xffe7e8ea),
                          starColor: Colors.yellow,
                        ),
                        if (_rating == 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              "Please select a rating",
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),

                        Text(
                          "Review",
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: "Enter review...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onChanged: (val) => _review = val,
                          validator:
                              (value) =>
                                  (value == null || value.isEmpty)
                                      ? "Please enter a review"
                                      : null,
                        ),
                        const SizedBox(height: 16),

                        Text(
                          "Status",
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _status,
                          items:
                              ['Pending', 'Approved', 'Rejected']
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (val) {
                            if (val != null) _status = val;
                          },
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed:
                      _isLoading
                          ? null
                          : () async {
                            if (_formKey.currentState!.validate() &&
                                _rating > 0) {
                              setState(() => _isLoading = true);

                              try {
                                final sData =
                                    _selectedService!.data()
                                        as Map<String, dynamic>;
                                final uData =
                                    _selectedUser!.data()
                                        as Map<String, dynamic>;

                                final docRef =
                                    FirebaseFirestore.instance
                                        .collection('service_reviews')
                                        .doc();

                                await docRef.set({
                                  'reviewId': docRef.id,
                                  'serviceId': _selectedService!.id,
                                  'serviceName': sData['title'] ?? 'Unknown',
                                  'serviceCategory':
                                      sData['category'] ?? 'Unknown',
                                  'userId': _selectedUser!.id,
                                  'userName': uData['name'] ?? 'Unknown',
                                  'userPhone': uData['phone'] ?? '',
                                  'rating': _rating,
                                  'review': _review,
                                  'status': _status,
                                  'createdAt': FieldValue.serverTimestamp(),
                                  'updatedAt': FieldValue.serverTimestamp(),
                                });

                                if (mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Review added successfully!",
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setState(() => _isLoading = false);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Error adding review: $e"),
                                    ),
                                  );
                                }
                              }
                            } else if (_rating == 0) {
                              setState(
                                () {},
                              ); // Trigger rebuild to show rating error
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text("Save Review"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showViewReviewDialog(Map<String, dynamic> review) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Review Details",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow("Review ID", review['reviewId'] ?? ''),
                  const Divider(),
                  _buildDetailRow("Service", review['serviceName'] ?? ''),
                  _buildDetailRow("Category", review['serviceCategory'] ?? ''),
                  const Divider(),
                  _buildDetailRow("User", review['userName'] ?? ''),
                  _buildDetailRow("Phone", review['userPhone'] ?? ''),
                  const Divider(),
                  _buildDetailRow("Rating", "${review['rating'] ?? 0} / 5"),
                  _buildDetailRow("Status", review['status'] ?? ''),
                  const Divider(),
                  Text(
                    "Review:",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(review['review'] ?? ''),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportReviews(List<QueryDocumentSnapshot> docs) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Preparing export... Please wait.")),
    );
    try {
      final List<Map<String, dynamic>> reviews =
          docs.map((doc) {
            return doc.data() as Map<String, dynamic>;
          }).toList();
      printServiceReviewsList(reviews);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error exporting: $e")));
      }
    }
  }
}
