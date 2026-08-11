import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class ReportsOverviewPage extends StatefulWidget {
  const ReportsOverviewPage({super.key});

  @override
  State<ReportsOverviewPage> createState() => _ReportsOverviewPageState();
}

class _ReportsOverviewPageState extends State<ReportsOverviewPage> {
  Stream<QuerySnapshot>? _reportsStream;
  String _searchQuery = '';
  String _trendDateRange = 'Last 7 Days';
  String? _filterType;
  String? _filterStatus;
  String? _filterModule;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _reportsStream =
        FirebaseFirestore.instance
            .collection('reports')
            .orderBy('created_at', descending: true)
            .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isDesktop = constraints.maxWidth > 1000;
          return StreamBuilder<QuerySnapshot>(
            stream: _reportsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Something went wrong'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFFC107)),
                );
              }

              final allDocs = snapshot.data?.docs ?? [];
              var docs =
                  allDocs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final reason =
                        data['reason']?.toString().toLowerCase() ?? '';
                    final reporterName =
                        data['reporterName']?.toString().toLowerCase() ?? '';
                    final target =
                        data['target']?.toString().toLowerCase() ?? '';
                    final module =
                        data['module']?.toString().toLowerCase() ?? '';
                    final status =
                        data['status']?.toString().toLowerCase() ?? '';

                    if (_searchQuery.isNotEmpty) {
                      final q = _searchQuery.toLowerCase();
                      if (!reason.contains(q) &&
                          !reporterName.contains(q) &&
                          !target.contains(q))
                        return false;
                    }
                    if (_filterType != null &&
                        _filterType != 'All Report Types' &&
                        reason != _filterType!.toLowerCase())
                      return false;
                    if (_filterStatus != null &&
                        _filterStatus != 'All Status' &&
                        status != _filterStatus!.toLowerCase())
                      return false;
                    if (_filterModule != null &&
                        _filterModule != 'All Modules' &&
                        module != _filterModule!.toLowerCase())
                      return false;
                    if (_selectedDateRange != null) {
                      if (data['created_at'] != null &&
                          data['created_at'] is Timestamp) {
                        final dt = (data['created_at'] as Timestamp).toDate();
                        if (dt.isBefore(_selectedDateRange!.start) ||
                            dt.isAfter(
                              _selectedDateRange!.end.add(
                                const Duration(days: 1),
                              ),
                            )) {
                          return false;
                        }
                      } else {
                        return false;
                      }
                    }
                    return true;
                  }).toList();

              final totalCount = allDocs.length;
              final underReviewCount =
                  allDocs
                      .where(
                        (d) =>
                            (d.data() as Map<String, dynamic>)['status']
                                ?.toString()
                                .toLowerCase() ==
                            'under review',
                      )
                      .length;
              final resolvedCount =
                  allDocs
                      .where(
                        (d) =>
                            (d.data() as Map<String, dynamic>)['status']
                                ?.toString()
                                .toLowerCase() ==
                            'resolved',
                      )
                      .length;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(docs),
                    const SizedBox(height: 24),
                    _buildStatsCards(
                      isDesktop,
                      totalCount,
                      underReviewCount,
                      resolvedCount,
                    ),
                    const SizedBox(height: 24),
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _buildLeftPanel(docs)),
                          const SizedBox(width: 24),
                          Expanded(flex: 1, child: _buildRightPanel(docs)),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildLeftPanel(docs),
                          const SizedBox(height: 24),
                          _buildRightPanel(docs),
                        ],
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(List<QueryDocumentSnapshot> docs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Reports Overview',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Monitor and analyze all reports across the platform.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        Row(
          children: [
            InkWell(
              onTap: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  initialDateRange: _selectedDateRange,
                  initialEntryMode: DatePickerEntryMode.calendarOnly,
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: Color(0xFF1E293B),
                          onPrimary: Colors.white,
                          surface: Colors.white,
                          onSurface: Colors.black87,
                        ),
                        dialogTheme: const DialogThemeData(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                          ),
                        ),
                        textButtonTheme: TextButtonThemeData(
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 400,
                            maxHeight: 600,
                          ),
                          child: child!,
                        ),
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
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedDateRange != null
                          ? '${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.end)}'
                          : 'All Time',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                      ),
                    ),
                    if (_selectedDateRange != null) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _selectedDateRange = null;
                          });
                        },
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.black54,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: Colors.black54,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              onPressed: () {
                _exportToCsv(docs);
              },
              icon: const Icon(
                Icons.download_rounded,
                color: Colors.green,
                size: 20,
              ),
              label: const Text(
                'Export Report',
                style: TextStyle(color: Colors.green),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                side: const BorderSide(color: Colors.green),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsCards(
    bool isDesktop,
    int total,
    int underReview,
    int resolved,
  ) {
    List<Widget> cards = [
      _buildStatCard(
        title: 'Total Reports',
        value: total.toString(),
        trendText: 'All time',
        isPositive: true,
        icon: Icons.shield_outlined,
        iconBgColor: Colors.green.shade50,
        iconColor: Colors.green,
      ),
      _buildStatCard(
        title: 'Under Review',
        value: underReview.toString(),
        trendText: 'Needs attention',
        isPositive: true,
        icon: Icons.remove_red_eye_outlined,
        iconBgColor: Colors.orange.shade50,
        iconColor: Colors.orange,
      ),
      _buildStatCard(
        title: 'Resolved',
        value: resolved.toString(),
        trendText: 'Completed',
        isPositive: true,
        icon: Icons.check,
        iconBgColor: Colors.blue.shade50,
        iconColor: Colors.blue,
      ),
    ];

    if (isDesktop) {
      return Row(
        children:
            cards
                .map(
                  (c) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 24),
                      child: c,
                    ),
                  ),
                )
                .toList(),
      );
    }
    return Column(
      children:
          cards
              .map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: c,
                ),
              )
              .toList(),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String trendText,
    required bool isPositive,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            trendText,
            style: TextStyle(
              color: isPositive ? Colors.green : Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel(List<QueryDocumentSnapshot> docs) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilters(),
          const Divider(height: 1),
          _buildDataTable(docs),
          const Divider(height: 1),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search by reason, reporter or target...',
                hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.black38,
                  size: 20,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
              ),
              hint: const Text(
                'All Report Types',
                style: TextStyle(fontSize: 13),
              ),
              value: _filterType,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, size: 18),
              items:
                  [
                    'All Report Types',
                    'Inappropriate Content',
                    'Fake Information',
                    'Spam',
                    'Harassment',
                    'Other',
                  ].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value == 'All Report Types' ? null : value,
                      child: Text(value, style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
              onChanged: (val) => setState(() => _filterType = val),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
              ),
              hint: const Text('All Status', style: TextStyle(fontSize: 13)),
              value: _filterStatus,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, size: 18),
              items:
                  ['All Status', 'Under Review', 'Resolved', 'Rejected'].map((
                    String value,
                  ) {
                    return DropdownMenuItem<String>(
                      value: value == 'All Status' ? null : value,
                      child: Text(value, style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
              onChanged: (val) => setState(() => _filterStatus = val),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
              ),
              hint: const Text('All Modules', style: TextStyle(fontSize: 13)),
              value: _filterModule,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, size: 18),
              items:
                  [
                    'All Modules',
                    'Local Ads',
                    'Taxi Drivers',
                    'Services',
                    'Bus Routes',
                    'Payments',
                  ].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value == 'All Modules' ? null : value,
                      child: Text(value, style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
              onChanged: (val) => setState(() => _filterModule = val),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _filterType = null;
                _filterStatus = null;
                _filterModule = null;
              });
            },
            icon: const Icon(Icons.refresh, color: Colors.black54, size: 18),
            label: const Text(
              'Reset',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              side: const BorderSide(color: Colors.black12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String hint, List<String> items) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black12),
        ),
      ),
      hint: Text(hint, style: const TextStyle(fontSize: 13)),
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down, size: 18),
      items:
          items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: const TextStyle(fontSize: 13)),
            );
          }).toList(),
      onChanged: (_) {},
    );
  }

  Widget _buildDataTable(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: Center(
          child: Text(
            'No reports found.',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.white),
        headingRowHeight: 54,
        headingTextStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: const Color(0xFF64748B),
          fontSize: 15,
        ),
        dataRowMinHeight: 70,
        dataRowMaxHeight: 75,
        columnSpacing: 24,
        horizontalMargin: 24,
        dividerThickness: 1,
        columns: const [
          DataColumn(label: Text('#')),
          DataColumn(label: Text('Report ID')),
          DataColumn(label: Text('Reason')),
          DataColumn(label: Text('Reported By')),
          DataColumn(label: Text('Module')),
          DataColumn(label: Text('Target Details')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Reported On')),
          DataColumn(label: Text('Actions')),
        ],
        rows: List.generate(docs.length, (index) {
          final doc = docs[index];
          final data = doc.data() as Map<String, dynamic>;

          final reason = data['reason']?.toString() ?? 'Unknown';
          final reporterName = data['reporterName']?.toString() ?? 'Unknown';
          final reporterPhone = data['reporterPhone']?.toString() ?? 'N/A';
          final module = data['module']?.toString() ?? 'Unknown';
          final target = data['target']?.toString() ?? 'Unknown';
          final status = data['status']?.toString() ?? 'pending';

          String dateStr = 'Unknown';
          if (data['created_at'] != null && data['created_at'] is Timestamp) {
            dateStr = DateFormat(
              'dd MMM yyyy\\nhh:mm a',
            ).format((data['created_at'] as Timestamp).toDate());
          }

          return DataRow(
            cells: [
              DataCell(
                SizedBox(
                  width: 30,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 80,
                  child: Text(
                    doc.id.substring(0, 8).toUpperCase(),
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 150,
                  child: Text(
                    reason,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
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
                        reporterName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reporterPhone,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 100,
                  child: Text(
                    module,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 150,
                  child: Text(
                    target,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 110,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color:
                            status.toLowerCase() == 'resolved'
                                ? Colors.green
                                : status.toLowerCase() == 'rejected'
                                ? Colors.red
                                : Colors.orange,
                      ),
                    ),
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 100,
                  child: Text(
                    dateStr,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 100,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.remove_red_eye_outlined,
                          size: 18,
                          color: Colors.blue,
                        ),
                        onPressed: () {},
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Colors.red,
                        ),
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('reports')
                              .doc(doc.id)
                              .delete();
                        },
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Showing 1 to 8 of 1,248 entries',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          Row(
            children: [
              _buildPageButton(Icons.chevron_left, true),
              const SizedBox(width: 8),
              _buildPageNumber('1', true),
              const SizedBox(width: 8),
              _buildPageNumber('2', false),
              const SizedBox(width: 8),
              _buildPageNumber('3', false),
              const SizedBox(width: 8),
              const Text('...', style: TextStyle(color: Colors.grey)),
              const SizedBox(width: 8),
              _buildPageNumber('156', false),
              const SizedBox(width: 8),
              _buildPageButton(Icons.chevron_right, false),
              const SizedBox(width: 16),
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: const [
                    Text(
                      '10 / page',
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageNumber(String number, bool isActive) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive ? Colors.green : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        number,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.black87,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildPageButton(IconData icon, bool isDisabled) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        icon,
        size: 16,
        color: isDisabled ? Colors.black26 : Colors.black54,
      ),
    );
  }

  Map<String, int> _calculateStatusCounts(List<QueryDocumentSnapshot> docs) {
    final Map<String, int> counts = {};
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status']?.toString();
      if (status != null && status.trim().isNotEmpty) {
        counts[status] = (counts[status] ?? 0) + 1;
      }
    }
    final sorted =
        counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }

  Map<String, int> _calculateModuleCounts(List<QueryDocumentSnapshot> docs) {
    final Map<String, int> counts = {};
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final module = data['module']?.toString();
      if (module != null && module.trim().isNotEmpty) {
        counts[module] = (counts[module] ?? 0) + 1;
      }
    }
    final sorted =
        counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }

  Map<DateTime, int> _calculateTrendCounts(List<QueryDocumentSnapshot> docs) {
    final Map<DateTime, int> counts = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int days = 7;
    if (_trendDateRange == 'Last 30 Days') days = 30;
    if (_trendDateRange == 'Last 90 Days') days = 90;
    if (_trendDateRange == 'This Month') days = now.day;
    if (_trendDateRange == 'Last Month') {
      final lastMonth = DateTime(now.year, now.month - 1, 1);
      days = DateTime(now.year, now.month, 0).day;
    }

    // pre-fill zeros
    for (int i = 0; i < days; i++) {
      counts[today.subtract(Duration(days: i))] = 0;
    }

    final cutoff = today.subtract(Duration(days: days - 1));

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['created_at'] != null && data['created_at'] is Timestamp) {
        final dt = (data['created_at'] as Timestamp).toDate();
        final dateKey = DateTime(dt.year, dt.month, dt.day);

        if (dateKey.isAfter(cutoff.subtract(const Duration(days: 1))) &&
            dateKey.isBefore(today.add(const Duration(days: 1)))) {
          if (counts.containsKey(dateKey)) {
            counts[dateKey] = counts[dateKey]! + 1;
          }
        }
      }
    }

    final sortedKeys = counts.keys.toList()..sort();
    final Map<DateTime, int> sortedCounts = {};
    for (var k in sortedKeys) {
      sortedCounts[k] = counts[k]!;
    }

    return sortedCounts;
  }

  void _exportToCsv(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) return;

    List<String> rows = [];
    // Header
    rows.add("Report ID,Reason,Reported By,Module,Target,Status,Reported On");

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final reason = (data['reason']?.toString() ?? 'Unknown').replaceAll(
        ',',
        ' ',
      );
      final reporterName = (data['reporterName']?.toString() ?? 'Unknown')
          .replaceAll(',', ' ');
      final module = (data['module']?.toString() ?? 'Unknown').replaceAll(
        ',',
        ' ',
      );
      final target = (data['target']?.toString() ?? 'Unknown').replaceAll(
        ',',
        ' ',
      );
      final status = (data['status']?.toString() ?? 'pending').replaceAll(
        ',',
        ' ',
      );

      String dateStr = 'Unknown';
      if (data['created_at'] != null && data['created_at'] is Timestamp) {
        dateStr = DateFormat(
          'yyyy-MM-dd HH:mm',
        ).format((data['created_at'] as Timestamp).toDate());
      }

      rows.add(
        "${doc.id},$reason,$reporterName,$module,$target,$status,$dateStr",
      );
    }

    String csvContent = rows.join('\n');

    final encoded = Uri.encodeComponent(csvContent);
    final dataUri = 'data:text/csv;charset=utf-8,$encoded';

    final anchor =
        html.AnchorElement(href: dataUri)
          ..setAttribute(
            "download",
            "reports_export_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv",
          )
          ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
  }

  Widget _buildRightPanel(List<QueryDocumentSnapshot> docs) {
    final statusCounts = _calculateStatusCounts(docs);
    final moduleCounts = _calculateModuleCounts(docs);
    final trendCounts = _calculateTrendCounts(docs);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRightPanelCard(
            'Reports by Status',
            _buildDonutChartWidget(statusCounts, docs.length),
          ),
          const Divider(height: 1),
          _buildRightPanelCard(
            'Reports by Module',
            _buildProgressBarsWidget(moduleCounts, docs.length),
          ),
          const Divider(height: 1),
          _buildRightPanelCard(
            'Reports Trend',
            _buildLineChartWidget(trendCounts),
            showDateRange: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanelCard(
    String title,
    Widget child, {
    bool showDateRange = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              if (showDateRange)
                DropdownButton<String>(
                  value: _trendDateRange,
                  icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                  underline: const SizedBox(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _trendDateRange = newValue;
                      });
                    }
                  },
                  items:
                      <String>[
                        'Last 7 Days',
                        'Last 30 Days',
                        'Last 90 Days',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildDonutChartWidget(Map<String, int> statusCounts, int total) {
    if (total == 0 || statusCounts.isEmpty) {
      return const Center(
        child: Text('No reports found', style: TextStyle(color: Colors.grey)),
      );
    }

    final colors = [
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.blue,
      Colors.purple,
    ];

    int colorIndex = 0;
    List<PieChartSectionData> sections = [];
    List<Widget> legends = [];

    statusCounts.forEach((status, count) {
      final color = colors[colorIndex % colors.length];
      final percentage = (count / total) * 100;

      sections.add(
        PieChartSectionData(
          value: count.toDouble(),
          color: color,
          radius: 20,
          showTitle: false,
        ),
      );

      legends.add(
        _buildChartLegend(
          status,
          '$count (${percentage.toStringAsFixed(1)}%)',
          color,
        ),
      );
      legends.add(const SizedBox(height: 12));
      colorIndex++;
    });

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: sections,
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      total.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const Text(
                      'Total',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: legends),
      ],
    );
  }

  Widget _buildChartLegend(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(value, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildProgressBarsWidget(Map<String, int> moduleCounts, int total) {
    if (total == 0 || moduleCounts.isEmpty) {
      return const Center(
        child: Text(
          'No module data available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      children:
          moduleCounts.entries.map((entry) {
            final percentage = (entry.value / total);
            final percentText = (percentage * 100).round();
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _buildProgressBar(
                entry.key,
                '${entry.value} ($percentText%)',
                percentage,
              ),
            );
          }).toList(),
    );
  }

  Widget _buildProgressBar(String label, String value, double percent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: percent.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLineChartWidget(Map<DateTime, int> trendCounts) {
    if (trendCounts.isEmpty) {
      return const Center(
        child: Text(
          'No report activity for this period',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final spots =
        trendCounts.entries.toList().asMap().entries.map((entry) {
          return FlSpot(entry.key.toDouble(), entry.value.value.toDouble());
        }).toList();

    double maxY = 0;
    for (var count in trendCounts.values) {
      if (count > maxY) maxY = count.toDouble();
    }
    maxY = maxY == 0 ? 1 : maxY * 1.2;

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4 > 0 ? maxY / 4 : 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < trendCounts.length) {
                    final date = trendCounts.keys.elementAt(index);
                    // Show fewer labels if too many days
                    if (trendCounts.length > 15 &&
                        index % 5 != 0 &&
                        index != trendCounts.length - 1) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat('MMM dd').format(date),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: maxY / 4 > 0 ? maxY / 4 : 1,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (trendCounts.length - 1).toDouble(),
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.green,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter:
                    (spot, percent, barData, index) => FlDotCirclePainter(
                      radius: 4,
                      color: Colors.green,
                      strokeWidth: 0,
                    ),
              ),
              belowBarData: BarAreaData(show: false),
            ),
          ],
          lineTouchData: LineTouchData(
            getTouchLineEnd: (barData, spotIndex) => 0,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor:
                  (LineBarSpot touchedSpot) => Colors.blueGrey.shade800,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((LineBarSpot touchedSpot) {
                  final index = touchedSpot.x.toInt();
                  final date = trendCounts.keys.elementAt(index);
                  return LineTooltipItem(
                    '${DateFormat('MMM dd, yyyy').format(date)}\nReports: ${touchedSpot.y.toInt()}',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}
