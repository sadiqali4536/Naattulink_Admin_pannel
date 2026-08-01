import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:swiftclean_admin/MVVM/utils/printer_helper.dart';

class TruckAndJcbPage extends StatefulWidget {
  const TruckAndJcbPage({super.key});

  @override
  State<TruckAndJcbPage> createState() => _TruckAndJcbPageState();
}

class _TruckAndJcbPageState extends State<TruckAndJcbPage> {
  String _selectedStatus = 'All Status';
  String _selectedType = 'All Vehicle Types';
  String _selectedCity = 'All Cities';
  String _searchQuery = '';
  final ScrollController _verticalScrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        controller: _verticalScrollController,
        padding: const EdgeInsets.all(24.0),
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('transports')
                  .where('transport_category', isEqualTo: 'Truck / JCB')
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Something went wrong'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: const Color(0xFFFFC107)));
            }

            final docs = snapshot.data?.docs ?? [];
            final activeCount =
                docs.where((d) {
                  final status =
                      (d.data() as Map<String, dynamic>)['status']
                          ?.toString()
                          .toLowerCase();
                  return status == 'active' || status == 'approved';
                }).length;
            final inactiveCount =
                docs.where((d) {
                  final status =
                      (d.data() as Map<String, dynamic>)['status']
                          ?.toString()
                          .toLowerCase();
                  return status == 'inactive' ||
                      status == 'pending' ||
                      status == 'suspended';
                }).length;

            var filteredDocs = docs;
            if (_selectedStatus != 'All Status' ||
                _selectedType != 'All Vehicle Types' ||
                _selectedCity != 'All Cities' ||
                _searchQuery.isNotEmpty) {
              filteredDocs =
                  docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final status =
                        data['status']?.toString().toLowerCase() ?? '';
                    final type = data['vehicle_category']?.toString() ?? '';
                    final city = data['main_stand']?.toString() ?? '';

                    bool statusMatches = true;
                    if (_selectedStatus == 'Active')
                      statusMatches =
                          (status == 'active' || status == 'approved');
                    else if (_selectedStatus == 'Inactive')
                      statusMatches =
                          (status == 'inactive' ||
                              status == 'pending' ||
                              status == 'suspended');

                    bool typeMatches = true;
                    if (_selectedType != 'All Vehicle Types')
                      typeMatches =
                          (type.toLowerCase() == _selectedType.toLowerCase());

                    bool cityMatches = true;
                    if (_selectedCity != 'All Cities')
                      cityMatches =
                          (city.toLowerCase() == _selectedCity.toLowerCase());

                    bool searchMatches = true;
                    if (_searchQuery.isNotEmpty) {
                      final searchLower = _searchQuery.toLowerCase();
                      final name =
                          data['username']?.toString().toLowerCase() ??
                          data['name']?.toString().toLowerCase() ??
                          '';
                      final phone =
                          data['phone']?.toString().toLowerCase() ?? '';
                      final reg =
                          data['reg_number']?.toString().toLowerCase() ?? '';
                      if (!name.contains(searchLower) &&
                          !phone.contains(searchLower) &&
                          !reg.contains(searchLower)) {
                        searchMatches = false;
                      }
                    }

                    return statusMatches &&
                        typeMatches &&
                        cityMatches &&
                        searchMatches;
                  }).toList();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
              'Truck & JCB',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Manage truck and JCB vehicles and account status.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {
                final listToExport =
                    docs.map((d) => d.data() as Map<String, dynamic>).toList();
                printTruckJcbList(listToExport);
              },
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
              onPressed: () => _showTruckJcbDialog(),
              icon: const Icon(Icons.add, color: Colors.black87, size: 20),
              label: const Text(
                'Add Truck/JCB',
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
            title: 'Total Drivers',
            value: total.toString(),
            icon: Icons.people_outline,
            iconBgColor: Colors.blue.shade50,
            iconColor: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Active Drivers',
            value: active.toString(),
            icon: Icons.check_circle_outline,
            iconBgColor: Colors.green.shade50,
            iconColor: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Pending/Inactive',
            value: inactive.toString(),
            icon: Icons.access_time,
            iconBgColor: Colors.orange.shade50,
            iconColor: Colors.orange,
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
                  fontSize: 12,
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
          _buildFilters(docs),
          const Divider(height: 1),
          _buildDataTable(docs),
          const Divider(height: 1),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildFilters(List<QueryDocumentSnapshot> docs) {
    final Set<String> uniqueCities = {};
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final city = data['main_stand']?.toString();
      if (city != null && city.trim().isNotEmpty) {
        uniqueCities.add(city.trim());
      }
    }
    final List<String> cityList = uniqueCities.toList()..sort();

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by name, phone or license number...',
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
                if (val != null) setState(() => _selectedStatus = val);
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
                  ['All Vehicle Types', 'Truck', 'JCB'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedType = val);
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: DropdownButtonFormField<String>(
              value: _selectedCity,
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
                  ['All Cities', ...cityList].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCity = val);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(List<QueryDocumentSnapshot> docs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 1800, // Increased width to fit all data
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(2.5), // Driver Details
            1: FlexColumnWidth(1.5), // Phone
            2: FlexColumnWidth(1.5), // License No.
            3: FlexColumnWidth(2.0), // Vehicle Details
            4: FlexColumnWidth(2.0), // Capacity & Features
            5: FlexColumnWidth(1.5), // Main Stand
            6: FlexColumnWidth(2.0), // Charge & Ratings
            7: FlexColumnWidth(1.5), // Joined On
            8: FlexColumnWidth(1.0), // Status
            9: FlexColumnWidth(1.2), // Actions
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
                _buildHeaderCellWithCheckbox('Driver Details'),
                _buildHeaderCell('Phone'),
                _buildHeaderCell('License No.'),
                _buildHeaderCell('Vehicle Details'),
                _buildHeaderCell('Capacity & Features'),
                _buildHeaderCell('Main Stand'),
                _buildHeaderCell('Charge & Ratings'),
                _buildHeaderCell('Joined On'),
                _buildHeaderCell('Status'),
                _buildHeaderCell('Actions'),
              ],
            ),
            // Data Rows
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              String driverName = [
                    data['username'] ??
                        data['full_name'] ??
                        data['fullName'] ??
                        data['name'],
                    "${data['role'] ?? ''} ${data['role_with_vehicle'] ?? ''}"
                        .trim()
                        .replaceAll(RegExp(r'\s+'), ' '),
                  ]
                  .where((e) => e != null && e.toString().trim().isNotEmpty)
                  .join(' - ');
              if (driverName.isEmpty) driverName = 'Unknown';

              String dateString = 'N/A';
              if (data['created_at'] != null) {
                try {
                  if (data['created_at'] is Timestamp) {
                    dateString = DateFormat(
                      'dd MMM yyyy',
                    ).format((data['created_at'] as Timestamp).toDate());
                  } else if (data['created_at'] is String) {
                    dateString = DateFormat(
                      'dd MMM yyyy',
                    ).format(DateTime.parse(data['created_at']));
                  }
                } catch (_) {}
              }

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
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            driverName.isNotEmpty
                                ? driverName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                driverName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Email: ${data['email']?.toString() ?? 'N/A'}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ID: ${doc.id.length > 6 ? doc.id.substring(0, 6) : doc.id} | ${data['isVerified'] == 1 ? "Verified" : "Unverified"}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildDataCell(data['phone']?.toString() ?? 'N/A'),
                  _buildDataCell(data['reg_number']?.toString() ?? 'N/A'),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 16.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          data['vehicle_model']?.toString() ?? 'N/A',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          data['vehicle_type']?.toString() ?? 'N/A',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Type: ${data['transport_category']?.toString() ?? 'N/A'}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 16.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (data['load_capacity'] != null &&
                            data['load_capacity'].toString().isNotEmpty)
                          Text(
                            'Load: ${data['load_capacity']} Tons',
                            style: const TextStyle(fontSize: 12),
                          )
                        else
                          const Text(
                            'N/A',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                  _buildDataCell(data['main_stand']?.toString() ?? 'N/A'),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 16.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Min Charge: ₹${data['min_charge']?.toString() ?? 'N/A'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Rating: ${data['ratings']?.toString() ?? '0'} (${data['total_reviews']?.toString() ?? '0'} reviews)',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  _buildDataCell(dateString),
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
                                final newStatus = value ? 'active' : 'inactive';
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
                            onPressed: () => _showTruckJcbDialog(document: doc),
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
                            onPressed: () => _deleteTruckJcb(doc.id),
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
    );
  }

  Widget _buildHeaderCellWithCheckbox(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ],
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

    switch (status) {
      case 'Active':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        break;
      case 'Pending':
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        break;
      case 'Suspended':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        break;
      case 'Inactive':
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
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
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
            'Showing 1 to 8 of 126 entries',
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
              _buildPageNumber('16', false),
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

  Future<void> _deleteTruckJcb(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(
              'Delete Record',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'Are you sure you want to delete this record? This action cannot be undone.',
              style: TextStyle(color: Colors.black87),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('transports')
            .doc(id)
            .delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Record deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting record: $e')));
        }
      }
    }
  }

  void _showTruckJcbDialog({DocumentSnapshot? document}) {
    final formKey = GlobalKey<FormState>();
    final data = document?.data() as Map<String, dynamic>?;

    final usernameController = TextEditingController(
      text:
          data?['username']?.toString() ??
          data?['full_name']?.toString() ??
          data?['name']?.toString(),
    );
    final phoneController = TextEditingController(
      text: data?['phone']?.toString(),
    );
    final roleController = TextEditingController(
      text: data?['role_with_vehicle']?.toString(),
    );
    final professionController = TextEditingController(
      text: data?['profession']?.toString(),
    );
    final vehicleCategoryController = TextEditingController(
      text: data?['vehicle_type']?.toString(),
    );

    final minChargeController = TextEditingController(
      text: data?['min_charge']?.toString(),
    );
    final loadCapacityController = TextEditingController(
      text: data?['load_capacity']?.toString(),
    );
    final mainStandController = TextEditingController(
      text: data?['main_stand']?.toString(),
    );

    final vehicleModelController = TextEditingController(
      text: data?['vehicle_model']?.toString(),
    );
    final regNumberController = TextEditingController(
      text: data?['reg_number']?.toString(),
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
              bool isPhone = false,
              bool isUppercase = false,
              bool isNumeric = false,
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
                      maxLength: isPhone ? 10 : null,
                      keyboardType:
                          isPhone || isNumeric ? TextInputType.number : null,
                      textCapitalization:
                          isUppercase
                              ? TextCapitalization.characters
                              : TextCapitalization.none,
                      inputFormatters:
                          isPhone || isNumeric
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
              Function(String?)? onChangedCallback,
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
                          items
                              .map(
                                (String val) => DropdownMenuItem(
                                  value: val,
                                  child: Text(val),
                                ),
                              )
                              .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          controller.text = val;
                        }
                        if (onChangedCallback != null) {
                          onChangedCallback(val);
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
                                ? 'Add Truck/JCB'
                                : 'Edit Truck/JCB',
                            style: const TextStyle(
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
                                      usernameController,
                                      'Full Name',
                                      hint: 'Enter your full name',
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: buildTextField(
                                      phoneController,
                                      'Mobile Number',
                                      hint: 'Enter mobile number',
                                      isPhone: true,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: buildTextField(
                                      roleController,
                                      'Role with the vehicle',
                                      hint: 'Enter your role with the vehicle',
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Vehicle Type',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: () {
                                            vehicleCategoryController.text =
                                                'Truck';
                                            setState(() {});
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  vehicleCategoryController
                                                              .text ==
                                                          'Truck'
                                                      ? const Color(0xFF0F172A)
                                                      : Colors.grey.shade50,
                                              borderRadius:
                                                  const BorderRadius.only(
                                                    topLeft: Radius.circular(8),
                                                    bottomLeft: Radius.circular(
                                                      8,
                                                    ),
                                                  ),
                                              border: Border.all(
                                                color: Colors.black12,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.local_shipping_outlined,
                                                  size: 20,
                                                  color:
                                                      vehicleCategoryController
                                                                  .text ==
                                                              'Truck'
                                                          ? Colors.white
                                                          : Colors.black87,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Truck',
                                                  style: TextStyle(
                                                    color:
                                                        vehicleCategoryController
                                                                    .text ==
                                                                'Truck'
                                                            ? Colors.white
                                                            : Colors.black87,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () {
                                            vehicleCategoryController.text =
                                                'JCB';
                                            setState(() {});
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  vehicleCategoryController
                                                              .text ==
                                                          'JCB'
                                                      ? const Color(0xFF0F172A)
                                                      : Colors.grey.shade50,
                                              borderRadius:
                                                  const BorderRadius.only(
                                                    topRight: Radius.circular(
                                                      8,
                                                    ),
                                                    bottomRight:
                                                        Radius.circular(8),
                                                  ),
                                              border: Border.all(
                                                color: Colors.black12,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.construction,
                                                  size: 20,
                                                  color:
                                                      vehicleCategoryController
                                                                  .text ==
                                                              'JCB'
                                                          ? Colors.white
                                                          : Colors.black87,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'JCB',
                                                  style: TextStyle(
                                                    color:
                                                        vehicleCategoryController
                                                                    .text ==
                                                                'JCB'
                                                            ? Colors.white
                                                            : Colors.black87,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (vehicleCategoryController.text.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Text(
                                        'Required',
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(height: 32, color: Colors.black12),
                              const Center(
                                child: Text(
                                  'VEHICLE DETAILS',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black45,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: buildTextField(
                                      minChargeController,
                                      'Min Charge',
                                      hint: 'e.g. 500',
                                      isNumeric: true,
                                    ),
                                  ),
                                  if (vehicleCategoryController.text !=
                                      'JCB') ...[
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: buildTextField(
                                        loadCapacityController,
                                        'Load Capacity',
                                        hint: 'e.g. 10 Tons',
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              buildTextField(
                                mainStandController,
                                'Main Stand',
                                hint: 'e.g. City Bus Terminal',
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: buildTextField(
                                      vehicleModelController,
                                      vehicleCategoryController.text == 'JCB'
                                          ? 'JCB Type'
                                          : 'Vehicle Model',
                                      hint:
                                          vehicleCategoryController.text ==
                                                  'JCB'
                                              ? 'e.g. 3DX'
                                              : 'e.g. Tata Prima',
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: buildTextField(
                                      regNumberController,
                                      'Reg. Number',
                                      hint: 'KL-XX-0000',
                                      isUppercase: true,
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
                                            'username': usernameController.text,
                                            'name': usernameController.text,
                                            'phone': phoneController.text,
                                            'role_with_vehicle':
                                                roleController.text,
                                            'profession':
                                                professionController.text,
                                            'vehicle_type':
                                                vehicleCategoryController.text,
                                            'min_charge':
                                                minChargeController.text,
                                            'load_capacity':
                                                loadCapacityController.text,
                                            'main_stand':
                                                mainStandController.text,
                                            'vehicle_model':
                                                vehicleModelController.text,
                                            'reg_number':
                                                regNumberController.text,
                                            'transport_category': 'Truck / JCB',
                                            'category': 'Transport (Travels)',
                                            'updated_at':
                                                FieldValue.serverTimestamp(),
                                          };

                                          if (document == null) {
                                            dataToSave['status'] = 'pending';
                                            dataToSave['isVerified'] = 0;
                                            dataToSave['ratings'] = 0;
                                            dataToSave['total_reviews'] = 0;
                                            dataToSave['role'] = 'worker';
                                            dataToSave['created_at'] =
                                                FieldValue.serverTimestamp();
                                            dataToSave['profile_img'] = '';

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
                                                      ? 'Record added successfully'
                                                      : 'Record updated successfully',
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
                                          ? 'Save Record'
                                          : 'Update Record',
                                      style: const TextStyle(
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
