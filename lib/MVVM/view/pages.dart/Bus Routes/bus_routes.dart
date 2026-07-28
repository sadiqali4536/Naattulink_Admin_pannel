import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swiftclean_admin/MVVM/utils/printer_helper.dart';

class BusRoutesPage extends StatefulWidget {
  const BusRoutesPage({super.key});

  @override
  State<BusRoutesPage> createState() => _BusRoutesPageState();
}

class _BusRoutesPageState extends State<BusRoutesPage> {
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();
  String _selectedStatus = 'All Status';
  String _selectedType = 'All Types';

  Future<void> _exportToPdf(List<QueryDocumentSnapshot> docs) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Preparing export... Please wait.")),
    );
    try {
      final routesList =
          docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      printBusRoutesList(routesList);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error exporting: \$e")));
      }
    }
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Scrollbar(
        controller: _verticalScrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _verticalScrollController,
          padding: const EdgeInsets.all(24.0),
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('transports')
                    .where('transport_category', isEqualTo: 'Bus')
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Something went wrong'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];
              final activeCount =
                  docs
                      .where(
                        (d) =>
                            (d.data() as Map<String, dynamic>)['status']
                                    ?.toString()
                                    .toLowerCase() ==
                                'active' ||
                            (d.data() as Map<String, dynamic>)['status']
                                    ?.toString()
                                    .toLowerCase() ==
                                'approved',
                      )
                      .length;
              final inactiveCount =
                  docs.where((d) {
                    final status =
                        (d.data() as Map<String, dynamic>)['status']
                            ?.toString()
                            .toLowerCase();
                    return status == 'inactive' || status == 'pending';
                  }).length;

              var filteredDocs = docs;
              if (_selectedStatus != 'All Status' ||
                  _selectedType != 'All Types') {
                filteredDocs =
                    docs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      final status =
                          data['status']?.toString().toLowerCase() ?? '';
                      final busType = data['bus_type']?.toString() ?? '';

                      bool statusMatches = true;
                      if (_selectedStatus == 'Active')
                        statusMatches = (status == 'active');
                      else if (_selectedStatus == 'Inactive')
                        statusMatches =
                            (status == 'inactive' || status == 'pending');

                      bool typeMatches = true;
                      if (_selectedType != 'All Types')
                        typeMatches = (busType == _selectedType);

                      return statusMatches && typeMatches;
                    }).toList();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBreadcrumb(),
                  const SizedBox(height: 24),
                  _buildHeader(filteredDocs),
                  const SizedBox(height: 24),
                  _buildStatsCards(
                    total: docs.length,
                    active: activeCount,
                    inactive: inactiveCount,
                  ),
                  const SizedBox(height: 24),
                  _buildTableSection(filteredDocs),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBreadcrumb() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text(
              'Dashboard',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
            const SizedBox(width: 8),
            const Text(
              'Bus Routes',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
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
              'Bus Routes',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Manage bus routes, stops, timings and status.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => _exportToPdf(docs),
              icon: const Icon(
                Icons.download_rounded,
                color: Colors.black87,
                size: 20,
              ),
              label: const Text(
                'Export',
                style: TextStyle(color: Colors.black87),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                side: const BorderSide(color: Colors.black12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () => _showBusDialog(),
              icon: const Icon(Icons.add, color: Colors.black87, size: 20),
              label: const Text(
                'Add Bus Route',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                elevation: 0,
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

  Widget _buildStatsCards({
    required int total,
    required int active,
    required int inactive,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Total Buses',
            value: total.toString(),
            icon: Icons.directions_bus_filled,
            iconBgColor: Colors.blue.shade50,
            iconColor: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Active Buses',
            value: active.toString(),
            icon: Icons.check_circle_outline,
            iconBgColor: Colors.green.shade50,
            iconColor: Colors.green,
          ),
        ),

        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Inactive Buses',
            value: inactive.toString(),
            icon: Icons.cancel_outlined,
            iconBgColor: Colors.red.shade50,
            iconColor: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableSection(List<QueryDocumentSnapshot> docs) {
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
              decoration: InputDecoration(
                hintText: 'Search by route name or number...',
                hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.black38),
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
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: DropdownButtonFormField<String>(
              value: _selectedStatus,
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
              items:
                  ['All Status', 'Active', 'Inactive'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedStatus = val;
                  });
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: DropdownButtonFormField<String>(
              value: _selectedType,
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
              items:
                  ['All Types', 'Private Bus', 'KSRTC'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedType = val;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(List<QueryDocumentSnapshot> docs) {
    return Scrollbar(
      controller: _horizontalScrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _horizontalScrollController,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 1800, // Fixed width to enable horizontal scrolling
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(1.2), // Reg Number
              1: FlexColumnWidth(1.5), // Bus Name
              2: FlexColumnWidth(1.5), // Main Stand
              3: FlexColumnWidth(1.2), // Type
              4: FlexColumnWidth(1.0), // From
              5: FlexColumnWidth(1.0), // To
              6: FlexColumnWidth(1.0), // Departure
              7: FlexColumnWidth(1.0), // Arrival
              8: FlexColumnWidth(1.2), // Phone
              9: FlexColumnWidth(1.2), // Role/Vehicle
              10: FlexColumnWidth(1.0), // Status
              11: FlexColumnWidth(1.2), // Actions
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              // Header Row
              TableRow(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: const Border(
                    bottom: BorderSide(color: Colors.black12, width: 1),
                  ),
                ),
                children: [
                  _buildHeaderCell('Reg Number'),
                  _buildHeaderCell('Bus Name'),
                  _buildHeaderCell('Main Stand'),
                  _buildHeaderCell('Type'),
                  _buildHeaderCell('From'),
                  _buildHeaderCell('To'),
                  _buildHeaderCell('Departure'),
                  _buildHeaderCell('Arrival'),
                  _buildHeaderCell('Phone'),
                  _buildHeaderCell('Added By'),
                  _buildHeaderCell('Status'),
                  _buildHeaderCell('Actions'),
                ],
              ),
              // Data Rows
              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return TableRow(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.black12, width: 1),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12.0,
                        horizontal: 16.0,
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: false,
                            onChanged: (val) {},
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            side: const BorderSide(color: Colors.black26),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              data['reg_number']?.toString() ?? 'N/A',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildDataCell(data['bus_name']?.toString() ?? 'N/A'),
                    _buildDataCell(data['main_stand']?.toString() ?? 'N/A'),
                    _buildDataCell(data['bus_type']?.toString() ?? 'N/A'),
                    _buildDataCell(data['first_stop']?.toString() ?? 'N/A'),
                    _buildDataCell(data['destination']?.toString() ?? 'N/A'),
                    _buildDataCell(
                      _formatTime(data['departure_time']?.toString()),
                    ),
                    _buildDataCell(
                      _formatTime(data['arrival_time']?.toString()),
                    ),
                    _buildDataCell(data['phone']?.toString() ?? 'N/A'),
                    _buildDataCell(
                      (data['role'] != null ||
                              data['role_with_vehicle'] != null ||
                              data['vehicle'] != null ||
                              data['username'] != null ||
                              data['full_name'] != null ||
                              data['fullName'] != null ||
                              data['name'] != null)
                          ? [
                                data['username'] ??
                                    data['full_name'] ??
                                    data['fullName'] ??
                                    data['name'],
                                "${data['role'] ?? ''} ${data['role_with_vehicle'] ?? ''} ${data['vehicle'] != null ? '(${data['vehicle']})' : ''}"
                                    .trim()
                                    .replaceAll(RegExp(r'\s+'), ' '),
                              ]
                              .where(
                                (e) =>
                                    e != null && e.toString().trim().isNotEmpty,
                              )
                              .join(' - ')
                          : 'Admin',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12.0,
                        horizontal: 16.0,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _buildStatusBadge(
                          data['status']?.toString() ?? 'unknown',
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12.0,
                        horizontal: 16.0,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Transform.scale(
                              scale: 0.8,
                              child: Switch(
                                value: data['status'] == 'active',
                                onChanged: (bool value) async {
                                  final newStatus =
                                      value ? 'active' : 'inactive';
                                  await FirebaseFirestore.instance
                                      .collection('transports')
                                      .doc(doc.id)
                                      .update({'status': newStatus});
                                },
                                activeColor: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: 20,
                                color: Colors.black54,
                              ),
                              onPressed: () => _showBusDialog(document: doc),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: Colors.redAccent,
                              ),
                              onPressed: () {},
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildDataCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Text(text, style: const TextStyle(fontSize: 13)),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'active':
      case 'approved':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        break;
      case 'inactive':
      case 'pending':
        status = 'inactive';
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        break;
      case 'removed':
        bgColor = Colors.grey.shade200;
        textColor = Colors.black54;
        break;
      default:
        bgColor = Colors.grey.shade200;
        textColor = Colors.black54;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
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
            'Showing 1 to 8 of 48 entries',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          Row(
            children: [
              _buildPageButton(Icons.chevron_left, false),
              const SizedBox(width: 8),
              _buildPageNumber('1', true),
              const SizedBox(width: 8),
              _buildPageNumber('2', false),
              const SizedBox(width: 8),
              _buildPageNumber('3', false),
              const SizedBox(width: 8),
              const Text('...', style: TextStyle(color: Colors.grey)),
              const SizedBox(width: 8),
              _buildPageNumber('6', false),
              const SizedBox(width: 8),
              _buildPageButton(Icons.chevron_right, false),
              const SizedBox(width: 16),
              Container(
                height: 36,
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
        color: isActive ? const Color(0xFFFFC107) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        number,
        style: TextStyle(
          color: isActive ? Colors.black87 : Colors.black54,
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

  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return 'N/A';
    try {
      final parts = time.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);
        String period = hour >= 12 ? 'PM' : 'AM';
        hour = hour % 12;
        if (hour == 0) hour = 12;
        return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
      }
    } catch (e) {
      // Ignore parsing errors and return the original string
    }
    return time;
  }

  void _showBusDialog({QueryDocumentSnapshot? document}) {
    final formKey = GlobalKey<FormState>();
    final data = document?.data() as Map<String, dynamic>?;

    final regNumberController = TextEditingController(
      text: data?['reg_number']?.toString(),
    );
    final busNameController = TextEditingController(
      text: data?['bus_name']?.toString(),
    );
    final busTypeController = TextEditingController(
      text: data?['bus_type']?.toString(),
    );
    final busSubTypeController = TextEditingController(
      text: data?['bus_sub_type']?.toString() ?? data?['category']?.toString(),
    );
    final firstStopController = TextEditingController(
      text: data?['first_stop']?.toString(),
    );
    final destinationController = TextEditingController(
      text: data?['destination']?.toString(),
    );
    final departureTimeController = TextEditingController(
      text: data?['departure_time']?.toString(),
    );
    final arrivalTimeController = TextEditingController(
      text: data?['arrival_time']?.toString(),
    );
    final phoneController = TextEditingController(
      text: data?['phone']?.toString(),
    );
    final mainStandController = TextEditingController(
      text: data?['main_stand']?.toString(),
    );

    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Widget buildTextField(
              TextEditingController controller,
              String label, {
              String? hint,
              int maxLines = 1,
              bool isTime = false,
              bool isPhone = false,
              bool isUppercase = false,
              VoidCallback? onTap,
            }) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: controller,
                      maxLines: maxLines,
                      readOnly: onTap != null,
                      onTap: onTap,
                      maxLength: isPhone ? 10 : null,
                      keyboardType: isPhone ? TextInputType.phone : null,
                      textCapitalization:
                          isUppercase
                              ? TextCapitalization.characters
                              : TextCapitalization.none,
                      inputFormatters:
                          isPhone
                              ? [FilteringTextInputFormatter.digitsOnly]
                              : isUppercase
                              ? [
                                TextInputFormatter.withFunction(
                                  (oldValue, newValue) => newValue.copyWith(
                                    text: newValue.text.toUpperCase(),
                                  ),
                                ),
                              ]
                              : null,
                      decoration: InputDecoration(
                        counterText: isPhone ? '' : null,
                        hintText: hint ?? 'Enter $label',
                        hintStyle: const TextStyle(
                          color: Colors.black38,
                          fontSize: 13,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        suffixIcon:
                            isTime
                                ? const Icon(
                                  Icons.access_time,
                                  color: Colors.black38,
                                  size: 20,
                                )
                                : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.redAccent),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator:
                          (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Required'
                                  : null,
                    ),
                  ],
                ),
              );
            }

            Widget buildDropdownField(
              TextEditingController controller,
              String label,
              List<String> items, {
              String? hint,
              void Function(String?)? onChanged,
            }) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      key: ValueKey(items.join(',')),

                      value:
                          controller.text.isEmpty
                              ? null
                              : (items.contains(controller.text)
                                  ? controller.text
                                  : null),
                      decoration: InputDecoration(
                        hintText: hint ?? 'Select $label',
                        hintStyle: const TextStyle(
                          color: Colors.black38,
                          fontSize: 13,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.redAccent),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      items:
                          items.map((String val) {
                            return DropdownMenuItem(
                              value: val,
                              child: Text(val),
                            );
                          }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          controller.text = val;
                          if (onChanged != null) {
                            onChanged(val);
                          }
                        }
                      },
                      validator:
                          (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Required'
                                  : null,
                    ),
                  ],
                ),
              );
            }

            return Dialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                width: 600,
                constraints: const BoxConstraints(maxHeight: 800),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.black12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            document == null
                                ? 'Add New Bus Route'
                                : 'Edit Bus Route',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.black54,
                            ),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    // Form Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: buildTextField(
                                      regNumberController,
                                      'Registration Number',
                                      hint: 'e.g., KL 11 AB 1234',
                                      isUppercase: true,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 2,
                                    child: buildTextField(
                                      busNameController,
                                      'Bus Name',
                                      hint: 'e.g., Star Travels',
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: buildDropdownField(
                                      busTypeController,
                                      'Bus Type',
                                      ['Private Bus', 'KSRTC'],
                                      hint: 'Select Bus Type',
                                      onChanged: (val) {
                                        busSubTypeController.text = '';
                                        setState(() {});
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child:
                                        busTypeController.text == 'Private Bus'
                                            ? buildDropdownField(
                                              busSubTypeController,
                                              'Bus Category',
                                              ['limited stop', 'ordinary'],
                                              hint: 'Select Category',
                                            )
                                            : busTypeController.text == 'KSRTC'
                                            ? buildDropdownField(
                                              busSubTypeController,
                                              'Bus Category',
                                              [
                                                'ordinary',
                                                'super fast',
                                                'fast passenger',
                                              ],
                                              hint: 'Select Category',
                                            )
                                            : const SizedBox(),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: buildTextField(
                                      phoneController,
                                      'Phone Number',
                                      hint: 'Enter contact number',
                                      isPhone: true,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: buildTextField(
                                      mainStandController,
                                      'Main Stand',
                                      hint: 'e.g., Central Bus Stand',
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 32, color: Colors.black12),
                              const Text(
                                'Route Details',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: buildTextField(
                                      firstStopController,
                                      'From (First Stop)',
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: buildTextField(
                                      destinationController,
                                      'To (Destination)',
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: buildTextField(
                                      departureTimeController,
                                      'Departure Time',
                                      hint: 'Select time',
                                      isTime: true,
                                      onTap: () async {
                                        final TimeOfDay? time =
                                            await showTimePicker(
                                              context: context,
                                              initialTime: TimeOfDay.now(),
                                            );
                                        if (time != null) {
                                          departureTimeController.text =
                                              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: buildTextField(
                                      arrivalTimeController,
                                      'Arrival Time',
                                      hint: 'Select time',
                                      isTime: true,
                                      onTap: () async {
                                        final TimeOfDay? time =
                                            await showTimePicker(
                                              context: context,
                                              initialTime: TimeOfDay.now(),
                                            );
                                        if (time != null) {
                                          arrivalTimeController.text =
                                              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Footer
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.black12)),
                        color: Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed:
                                isLoading
                                    ? null
                                    : () async {
                                      if (formKey.currentState!.validate()) {
                                        setState(() => isLoading = true);
                                        try {
                                          final dataToSave = {
                                            'reg_number':
                                                regNumberController.text,
                                            'bus_name': busNameController.text,
                                            'bus_type': busTypeController.text,
                                            'bus_sub_type':
                                                busSubTypeController.text,
                                            'first_stop':
                                                firstStopController.text,
                                            'destination':
                                                destinationController.text,
                                            'departure_time':
                                                departureTimeController.text,
                                            'arrival_time':
                                                arrivalTimeController.text,
                                            'phone': phoneController.text,
                                            'main_stand':
                                                mainStandController.text,
                                            'transport_category': 'Bus',
                                            'category': 'Transport (Travels)',
                                            'updated_at':
                                                FieldValue.serverTimestamp(),
                                          };

                                          if (document == null) {
                                            dataToSave['status'] = 'inactive';
                                            dataToSave['isVerified'] = 0;
                                            dataToSave['ratings'] = 0;
                                            dataToSave['total_reviews'] = 0;
                                            dataToSave['services'] = [];
                                            dataToSave['created_at'] =
                                                FieldValue.serverTimestamp();

                                            await FirebaseFirestore.instance
                                                .collection('transports')
                                                .add(dataToSave);
                                          } else {
                                            await FirebaseFirestore.instance
                                                .collection('transports')
                                                .doc(document.id)
                                                .update(dataToSave);
                                          }

                                          if (context.mounted) {
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  document == null
                                                      ? 'Bus route added successfully'
                                                      : 'Bus route updated successfully',
                                                ),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          setState(() => isLoading = false);
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text('Error: $e'),
                                            ),
                                          );
                                        }
                                      }
                                    },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFC107),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child:
                                isLoading
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.black87,
                                      ),
                                    )
                                    : Text(
                                      document == null
                                          ? 'Save Bus Route'
                                          : 'Update Bus Route',
                                      style: TextStyle(
                                        color: Colors.black87,
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
            );
          },
        );
      },
    );
  }
}
