import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swiftclean_admin/MVVM/utils/printer_helper.dart';
import 'package:swiftclean_admin/MVVM/view/widgets/custom_dropdown.dart';

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
  String _selectedDistrict = 'All Districts';
  String _searchQuery = '';
  Set<String> _selectedBusIds = {};

  Future<void> _exportToPdf(List<BusItem> docs) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Preparing export... Please wait.")),
    );
    try {
      final routesList = docs.map((doc) => doc.data).toList();
      printBusRoutesList(routesList);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error exporting: \$e")));
      }
    }
  }

  void _showBulkConfirmDialog(String action, List<BusItem> filteredDocs) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: Text('Confirm Bulk $action'),
          content: Text(
            'Are you sure you want to $action ${_selectedBusIds.length} selected bus route(s)?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black54),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _executeBulkAction(action, filteredDocs);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    action == 'Delete'
                        ? Colors.redAccent
                        : (action == 'Mark Active'
                            ? Colors.green
                            : Colors.orange),
                foregroundColor:
                    action == 'Delete' ||
                            action == 'Mark Active' ||
                            action == 'Mark Inactive'
                        ? Colors.white
                        : Colors.black87,
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _executeBulkAction(
    String action,
    List<BusItem> filteredDocs,
  ) async {
    final ids = _selectedBusIds.toList();
    int successCount = 0;

    for (String id in ids) {
      try {
        final docIndex = filteredDocs.indexWhere((d) => d.id == id);
        if (docIndex != -1) {
          final doc = filteredDocs[docIndex];
          if (action == 'Delete') {
            await doc.reference.delete();
          } else if (action == 'Mark Active') {
            await doc.reference.update({'status': 'active'});
          } else if (action == 'Mark Inactive') {
            await doc.reference.update({'status': 'inactive'});
          }
          successCount++;
        }
      } catch (e) {
        // Log or handle error for specific document
      }
    }

    setState(() {
      _selectedBusIds.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully processed $successCount bus route(s)'),
        ),
      );
    }
  }

  Widget _buildBulkActionToolbar(List<BusItem> filteredDocs) {
    if (_selectedBusIds.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Text(
            '${_selectedBusIds.length} selected',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed:
                () => _showBulkConfirmDialog('Mark Active', filteredDocs),
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Mark Active'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed:
                () => _showBulkConfirmDialog('Mark Inactive', filteredDocs),
            icon: const Icon(Icons.pause_circle_outline, size: 18),
            label: const Text('Mark Inactive'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _showBulkConfirmDialog('Delete', filteredDocs),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
          const SizedBox(width: 24),
          IconButton(
            onPressed: () {
              setState(() {
                _selectedBusIds.clear();
              });
            },
            icon: const Icon(Icons.close),
            tooltip: 'Clear Selection',
          ),
        ],
      ),
    );
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
          child: StreamBuilder<List<BusItem>>(
            stream: FirebaseFirestore.instance
                .collection('transports')
                .where('transport_category', isEqualTo: 'Bus')
                .snapshots()
                .asyncMap((transportSnapshot) async {
                  List<BusItem> allDocs = [];
                  for (var doc in transportSnapshot.docs) {
                    final parentData = doc.data() as Map<String, dynamic>;
                    allDocs.add(
                      BusItem(
                        data: parentData,
                        reference: doc.reference,
                        id: doc.id,
                      ),
                    );
                    try {
                      var busesSnapshot =
                          await doc.reference.collection('buses').get();
                      for (var childDoc in busesSnapshot.docs) {
                        final childData =
                            childDoc.data() as Map<String, dynamic>;
                        childData['username'] ??= parentData['username'];
                        childData['full_name'] ??= parentData['full_name'];
                        childData['fullName'] ??= parentData['fullName'];
                        childData['name'] ??= parentData['name'];
                        childData['role'] ??= parentData['role'];
                        childData['role_with_vehicle'] ??=
                            parentData['role_with_vehicle'];
                        childData['vehicle'] ??= parentData['vehicle'];
                        childData['phone'] ??= parentData['phone'];
                        allDocs.add(
                          BusItem(
                            data: childData,
                            reference: childDoc.reference,
                            id: childDoc.id,
                          ),
                        );
                      }
                    } catch (e) {
                      // print error
                    }
                  }
                  return allDocs;
                }),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Something went wrong'));
              }
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFFC107)),
                  ),
                );
              }

              final docs = snapshot.data ?? [];
              final activeCount =
                  docs.where((d) {
                    final status = (d.data)['status'];
                    if (status is bool) return status;
                    final statusStr = status?.toString().toLowerCase();
                    return statusStr == 'active' || statusStr == 'approved';
                  }).length;
              final inactiveCount =
                  docs.where((d) {
                    final status = (d.data)['status'];
                    if (status is bool) return !status;
                    final statusStr = status?.toString().toLowerCase();
                    return statusStr == 'inactive' || statusStr == 'pending';
                  }).length;

              var filteredDocs = docs;
              if (_selectedStatus != 'All Status' ||
                  _selectedType != 'All Types' ||
                  _selectedDistrict != 'All Districts' ||
                  _searchQuery.isNotEmpty) {
                filteredDocs =
                    docs.where((d) {
                      final data = d.data;
                      final status = data['status'];
                      final statusStr = status?.toString().toLowerCase() ?? '';
                      final busType = data['bus_type']?.toString() ?? '';
                      final district = data['district']?.toString() ?? '';

                      bool statusMatches = true;
                      if (_selectedStatus == 'Active') {
                        statusMatches =
                            (statusStr == 'active' || status == true);
                      } else if (_selectedStatus == 'Inactive') {
                        statusMatches =
                            (statusStr == 'inactive' ||
                                statusStr == 'pending' ||
                                status == false);
                      }

                      bool typeMatches = true;
                      if (_selectedType != 'All Types') {
                        typeMatches = (busType == _selectedType);
                      }

                      bool districtMatches = true;
                      if (_selectedDistrict != 'All Districts') {
                        districtMatches = (district == _selectedDistrict);
                      }

                      bool searchMatches = true;
                      if (_searchQuery.isNotEmpty) {
                        final query = _searchQuery.toLowerCase();
                        final queryNoSpaces = query.replaceAll(' ', '');
                        final busName =
                            (data['bus_name'] ?? data['name'])
                                ?.toString()
                                .toLowerCase() ??
                            '';
                        final regNum =
                            (data['registration_number'] ?? data['bus_no'])
                                ?.toString()
                                .toLowerCase()
                                .replaceAll(' ', '') ??
                            '';
                        final fromPlace =
                            (data['first_stop'] ?? data['start_place'])
                                ?.toString()
                                .toLowerCase() ??
                            '';
                        final toPlace =
                            data['destination']?.toString().toLowerCase() ?? '';

                        searchMatches =
                            busName.contains(query) ||
                            regNum.contains(queryNoSpaces) ||
                            fromPlace.contains(query) ||
                            toPlace.contains(query);
                      }

                      return statusMatches &&
                          typeMatches &&
                          districtMatches &&
                          searchMatches;
                    }).toList();
              }

              final districtsCount =
                  docs
                      .map((d) => d.data['district']?.toString())
                      .where((d) => d != null && d.trim().isNotEmpty)
                      .toSet()
                      .length;

              final activeDistrictsList =
                  docs
                      .where((d) {
                        final status = d.data['status'];
                        if (status is bool) return status;
                        final statusStr = status?.toString().toLowerCase();
                        return statusStr == 'active' || statusStr == 'approved';
                      })
                      .map((d) => d.data['district']?.toString() ?? '')
                      .where((d) => d.trim().isNotEmpty)
                      .toSet()
                      .toList();
              activeDistrictsList.sort();

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
                    districtsCount: districtsCount,
                    activeDistricts: activeDistrictsList,
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

  Widget _buildHeader(List<BusItem> docs) {
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
    required int districtsCount,
    List<String> activeDistricts = const [],
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
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Total Districts',
            value: districtsCount.toString(),
            icon: Icons.map_outlined,
            iconBgColor: Colors.purple.shade50,
            iconColor: Colors.purple,
            dropdownItems: activeDistricts,
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
    List<String>? dropdownItems,
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
          Expanded(
            child: Column(
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
          ),
          if (dropdownItems != null && dropdownItems.isNotEmpty)
            PopupMenuButton<String>(
              color: Colors.white,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
              tooltip: 'Active Districts',
              itemBuilder: (context) {
                return dropdownItems.map((item) {
                  return PopupMenuItem(value: item, child: Text(item));
                }).toList();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTableSection(List<BusItem> docs) {
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
          _buildBulkActionToolbar(docs),
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
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim();
                });
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Search by bus name, reg no, or places...',
                hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.black38),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
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
                    color: Color(0xFFFFC107),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: CustomDropdown<String>(
              value: _selectedStatus,
              items: const ['All Status', 'Active', 'Inactive'],
              itemLabelBuilder: (val) => val,
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
            child: CustomDropdown<String>(
              value: _selectedType,
              items: const ['All Types', 'Private Bus', 'KSRTC'],
              itemLabelBuilder: (val) => val,
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedType = val;
                  });
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: CustomDropdown<String>(
              value: _selectedDistrict,
              items: const [
                'All Districts',
                'Alappuzha',
                'Ernakulam',
                'Idukki',
                'Kannur',
                'Kasaragod',
                'Kollam',
                'Kottayam',
                'Kozhikode',
                'Malappuram',
                'Palakkad',
                'Pathanamthitta',
                'Thiruvananthapuram',
                'Thrissur',
                'Wayanad',
              ],
              itemLabelBuilder: (val) => val,
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedDistrict = val;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(List<BusItem> docs) {
    return Scrollbar(
      controller: _horizontalScrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _horizontalScrollController,
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.white),
          headingRowHeight: 48,
          headingTextStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
            fontSize: 14,
          ),
          dataRowMinHeight: 56,
          dataRowMaxHeight: 64,
          columnSpacing: 24,
          horizontalMargin: 24,
          dividerThickness: 1,
          columns: [
            const DataColumn(label: Text('No.')),
            DataColumn(
              label: Row(
                children: [
                  Checkbox(
                    value:
                        docs.isNotEmpty &&
                        _selectedBusIds.length == docs.length,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedBusIds.addAll(docs.map((d) => d.id));
                        } else {
                          _selectedBusIds.clear();
                        }
                      });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    side: const BorderSide(color: Colors.black26),
                  ),
                  const SizedBox(width: 8),
                  const Text('Reg Number'),
                ],
              ),
            ),
            const DataColumn(label: Text('Bus Name')),
            const DataColumn(label: Text('Main Stand')),
            const DataColumn(label: Text('District')),
            const DataColumn(label: Text('Type')),
            const DataColumn(label: Text('From')),
            const DataColumn(label: Text('To')),
            const DataColumn(label: Text('Departure')),
            const DataColumn(label: Text('Arrival')),
            const DataColumn(label: Text('Phone')),
            const DataColumn(label: Text('Added By')),
            const DataColumn(label: Text('Status')),
            const DataColumn(label: Text('Actions')),
          ],
          rows:
              docs.asMap().entries.map((entry) {
                final index = entry.key;
                final doc = entry.value;
                final data = doc.data;

                return DataRow(
                  cells: [
                    DataCell(Text('${index + 1}')),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: _selectedBusIds.contains(doc.id),
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedBusIds.add(doc.id);
                                } else {
                                  _selectedBusIds.remove(doc.id);
                                }
                              });
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            side: const BorderSide(color: Colors.black26),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 100,
                            child: Text(
                              (data['reg_number'] ??
                                          data['registration_number'])
                                      ?.toString() ??
                                  'N/A',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 100,
                        child: Text(
                          data['bus_name']?.toString() ?? 'N/A',
                          style: const TextStyle(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 100,
                        child: Text(
                          data['main_stand']?.toString() ?? 'N/A',
                          style: const TextStyle(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 100,
                        child: Text(
                          data['district']?.toString() ?? 'N/A',
                          style: const TextStyle(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 100,
                        child: Text(
                          data['bus_type']?.toString() ?? 'N/A',
                          style: const TextStyle(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 100,
                        child: Text(
                          (data['first_stop'] ?? data['start_place'])
                                  ?.toString() ??
                              'N/A',
                          style: const TextStyle(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 100,
                        child: Text(
                          data['destination']?.toString() ?? 'N/A',
                          style: const TextStyle(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        _formatTime(data['departure_time']?.toString()),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    DataCell(
                      Text(
                        _formatTime(data['arrival_time']?.toString()),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    DataCell(
                      Text(
                        data['phone']?.toString() ?? 'N/A',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 120,
                        child: Text(
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
                                        e != null &&
                                        e.toString().trim().isNotEmpty,
                                  )
                                  .join(' - ')
                              : 'Admin',
                          style: const TextStyle(fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      _buildStatusBadge(
                        (data['status'] is bool)
                            ? (data['status'] ? 'active' : 'inactive')
                            : (data['status']?.toString() ?? 'unknown'),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.scale(
                            scale: 0.8,
                            child: Switch(
                              value:
                                  data['status'] == 'active' ||
                                  data['status'] == true,
                              onChanged: (bool value) async {
                                final isBoolStatus = data['status'] is bool;
                                final dynamic newStatus =
                                    isBoolStatus
                                        ? value
                                        : (value ? 'active' : 'inactive');
                                await doc.reference.update({
                                  'status': newStatus,
                                });
                              },
                              activeColor: Colors.green,
                              inactiveThumbColor: Colors.red,
                              inactiveTrackColor: Colors.red.shade200,
                            ),
                          ),
                          const SizedBox(width: 8),
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
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => _showDeleteDialog(doc),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
        ),
      ),
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

  void _showBusDialog({BusItem? document}) {
    final formKey = GlobalKey<FormState>();
    final data = document?.data;

    final regNumberController = TextEditingController(
      text:
          data?['reg_number']?.toString() ??
          data?['registration_number']?.toString(),
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
      text: data?['first_stop']?.toString() ?? data?['start_place']?.toString(),
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
    final districtController = TextEditingController(
      text: data?['district']?.toString(),
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
                        fillColor: Colors.white,
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
                        fillColor: Colors.white,
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
                              Row(
                                children: [
                                  Expanded(
                                    child: buildDropdownField(
                                      districtController,
                                      'District',
                                      [
                                        'Alappuzha',
                                        'Ernakulam',
                                        'Idukki',
                                        'Kannur',
                                        'Kasaragod',
                                        'Kollam',
                                        'Kottayam',
                                        'Kozhikode',
                                        'Malappuram',
                                        'Palakkad',
                                        'Pathanamthitta',
                                        'Thiruvananthapuram',
                                        'Thrissur',
                                        'Wayanad',
                                      ],
                                      hint: 'Select District',
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(child: const SizedBox()),
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
                                          int hour12 = time.hour % 12;
                                          if (hour12 == 0) hour12 = 12;
                                          String period =
                                              time.hour >= 12 ? 'PM' : 'AM';
                                          departureTimeController.text =
                                              '${hour12.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
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
                                          int hour12 = time.hour % 12;
                                          if (hour12 == 0) hour12 = 12;
                                          String period =
                                              time.hour >= 12 ? 'PM' : 'AM';
                                          arrivalTimeController.text =
                                              '${hour12.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
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
                                            'district': districtController.text,
                                            'transport_category': 'Bus',
                                            'category': 'Transport (Travels)',
                                            'updated_at':
                                                FieldValue.serverTimestamp(),
                                          };

                                          if (document == null) {
                                            dataToSave['status'] = 'active';
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

  void _showDeleteDialog(BusItem doc) {
    final data = doc.data;
    final busName = data['bus_name']?.toString() ?? 'N/A';
    final regNo =
        (data['reg_number'] ?? data['registration_number'])?.toString() ??
        'N/A';

    final addedBy =
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
            ].where((e) => e != null && e.toString().trim().isNotEmpty).join(' - ')
            : 'Admin';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: const Text('Delete Bus Route'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Are you sure you want to delete this bus route?'),
              const SizedBox(height: 16),
              Text(
                'Bus Name: $busName',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                'Reg No: $regNo',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                'Added By: $addedBy',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black54),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('transports')
                      .doc(doc.id)
                      .delete();
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bus route deleted successfully'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting bus route: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}

class BusItem {
  final Map<String, dynamic> data;
  final dynamic
  reference; // dynamic to avoid needing to import specific firestore types if they clash, though DocumentReference works
  final String id;
  BusItem({required this.data, required this.reference, required this.id});
}
