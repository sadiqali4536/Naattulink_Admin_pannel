import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:swiftclean_admin/MVVM/utils/printer_helper.dart';

class HealthcarePage extends StatefulWidget {
  const HealthcarePage({super.key});

  @override
  State<HealthcarePage> createState() => _HealthcarePageState();
}

class _HealthcarePageState extends State<HealthcarePage> {
  String _selectedStatus = 'All Status';
  String _selectedType = 'All Types';
  String _selectedCity = 'All Cities';
  String _searchQuery = '';
  Set<String> _selectedHealthcareIds = {};
  Set<String> _expandedProviderIds = {};
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();
  late Stream<QuerySnapshot> _healthcareStream;
  late Stream<QuerySnapshot> _healthcareFieldsStream;

  @override
  void initState() {
    super.initState();
    _healthcareStream =
        FirebaseFirestore.instance.collection('healthcare').snapshots();
    _healthcareFieldsStream =
        FirebaseFirestore.instance.collection('healthcare_fields').snapshots();
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _showBulkConfirmDialog(
    String action,
    List<QueryDocumentSnapshot> filteredDocs,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: Text('Confirm Bulk $action'),
          content: Text(
            'Are you sure you want to $action ${_selectedHealthcareIds.length} selected facility(s)?',
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
    List<QueryDocumentSnapshot> filteredDocs,
  ) async {
    final ids = _selectedHealthcareIds.toList();
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
      _selectedHealthcareIds.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully processed $successCount facility(s)'),
        ),
      );
    }
  }

  Widget _buildBulkActionToolbar(List<QueryDocumentSnapshot> filteredDocs) {
    if (_selectedHealthcareIds.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Text(
            '${_selectedHealthcareIds.length} selected',
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
                _selectedHealthcareIds.clear();
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
            stream: _healthcareStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Something went wrong'));
              }
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: const Color(0xFFFFC107),
                  ),
                );
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
                  _selectedType != 'All Types' ||
                  _selectedCity != 'All Cities' ||
                  _searchQuery.isNotEmpty) {
                filteredDocs =
                    docs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      final status =
                          data['status']?.toString().toLowerCase() ?? '';
                      final type = data['healthcare_type']?.toString() ?? '';
                      final city =
                          data['city']?.toString() ??
                          data['address']?.toString() ??
                          '';

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
                      if (_selectedType != 'All Types')
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
                            data['username']?.toString().toLowerCase() ?? '';
                        final facility =
                            data['facility_name']?.toString().toLowerCase() ??
                            '';
                        final phone =
                            data['phone']?.toString().toLowerCase() ?? '';
                        final hType =
                            data['healthcare_type']?.toString().toLowerCase() ??
                            '';
                        final spec =
                            data['speciality']?.toString().toLowerCase() ?? '';
                        searchMatches =
                            name.contains(searchLower) ||
                            facility.contains(searchLower) ||
                            phone.contains(searchLower) ||
                            hType.contains(searchLower) ||
                            spec.contains(searchLower);
                      }

                      return statusMatches && typeMatches && searchMatches;
                    }).toList();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(
                    filteredDocs,
                    activeCount,
                    inactiveCount,
                    docs.length,
                  ),
                  const SizedBox(height: 24),
                  _buildFilters(docs),
                  const SizedBox(height: 24),
                  _buildBulkActionToolbar(filteredDocs),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.black12.withOpacity(0.05),
                      ),
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
                        StreamBuilder<QuerySnapshot>(
                          stream: _healthcareFieldsStream,
                          builder: (context, fieldsSnapshot) {
                            if (fieldsSnapshot.connectionState ==
                                    ConnectionState.waiting &&
                                !fieldsSnapshot.hasData) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24.0),
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFFFC107),
                                  ),
                                ),
                              );
                            }
                            final fieldsDocs = fieldsSnapshot.data?.docs ?? [];
                            final Map<String, List<QueryDocumentSnapshot>>
                            providerFields = {};
                            for (var doc in fieldsDocs) {
                              final data = doc.data() as Map<String, dynamic>;
                              final providerId = data['providerId']?.toString();
                              if (providerId != null) {
                                providerFields
                                    .putIfAbsent(providerId, () => [])
                                    .add(doc);
                              }
                            }
                            return _buildDataTable(
                              filteredDocs,
                              providerFields,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    List<QueryDocumentSnapshot> docs,
    int active,
    int inactive,
    int total,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Healthcare Management',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Manage healthcare facilities and providers.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    final listToExport =
                        docs
                            .map((d) => d.data() as Map<String, dynamic>)
                            .toList();
                    printHealthcareList(listToExport);
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
                  onPressed: () => _showHealthcareDialog(),
                  icon: const Icon(Icons.add, color: Colors.black87, size: 20),
                  label: const Text(
                    'Add Healthcare',
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
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total Healthcare',
                value: total.toString(),
                icon: Icons.local_hospital_outlined,
                iconBgColor: Colors.blue.shade50,
                iconColor: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Active',
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

  Widget _buildFilters(List<QueryDocumentSnapshot> docs) {
    final Set<String> uniqueCities = {};
    final Set<String> uniqueTypes = {};
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      final city = data['city']?.toString() ?? data['address']?.toString();
      if (city != null && city.trim().isNotEmpty) {
        uniqueCities.add(city.trim());
      }

      final hType = data['healthcare_type']?.toString();
      if (hType != null && hType.trim().isNotEmpty) {
        uniqueTypes.add(hType.trim());
      }
    }
    final List<String> cityList = uniqueCities.toList()..sort();
    final List<String> typeList = uniqueTypes.toList()..sort();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search by name, facility or phone...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.grey,
                  size: 20,
                ),
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
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: InputDecoration(
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
              ),
              items:
                  ['All Types', ...typeList].map((String value) {
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

  Widget _buildDataTable(
    List<QueryDocumentSnapshot> docs,
    Map<String, List<QueryDocumentSnapshot>> providerFields,
  ) {
    List<DataRow> allRows = [];

    for (int docIndex = 0; docIndex < docs.length; docIndex++) {
      final doc = docs[docIndex];
      final data = doc.data() as Map<String, dynamic>;
      String name =
          data['username']?.toString() ?? data['name']?.toString() ?? 'Unknown';
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

      final isExpanded = _expandedProviderIds.contains(doc.id);
      final hasFields =
          providerFields.containsKey(doc.id) &&
          providerFields[doc.id]!.isNotEmpty;
      final showExpandIcon = true; // Always show to allow adding new fields

      allRows.add(
        DataRow(
          cells: [
            DataCell(Text('${docIndex + 1}')),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showExpandIcon)
                    IconButton(
                      icon: Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_right,
                      ),
                      onPressed: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedProviderIds.remove(doc.id);
                          } else {
                            _expandedProviderIds.add(doc.id);
                          }
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                      splashRadius: 16,
                    )
                  else
                    const SizedBox(width: 24),
                  Checkbox(
                    value: _selectedHealthcareIds.contains(doc.id),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedHealthcareIds.add(doc.id);
                        } else {
                          _selectedHealthcareIds.remove(doc.id);
                        }
                      });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    side: const BorderSide(color: Colors.black26),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.blue.shade50,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        data['email']?.toString() ?? 'N/A',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            DataCell(Text(data['phone']?.toString() ?? 'N/A')),
            DataCell(
              SizedBox(
                width: 150,
                child: Text(
                  data['facility_name']?.toString() ?? 'N/A',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
                      data['healthcare_type']?.toString() ?? 'N/A',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Spec: ${data["speciality"]?.toString() ?? "N/A"}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
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
                child: Text(
                  data['address']?.toString() ?? 'N/A',
                  style: const TextStyle(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataCell(
              SizedBox(
                width: 100,
                child: Text(dateString, style: const TextStyle(fontSize: 13)),
              ),
            ),
            DataCell(_buildStatusBadge(data['status']?.toString() ?? '')),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value:
                          data['status']?.toString().toLowerCase() == 'active',
                      onChanged: (val) {
                        FirebaseFirestore.instance
                            .collection('healthcare')
                            .doc(doc.id)
                            .update({'status': val ? 'active' : 'inactive'});
                      },
                      activeColor: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => _showHealthcareDialog(document: doc),
                    color: Colors.grey.shade600,
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => _deleteHealthcare(doc.id),
                    color: Colors.red.shade400,
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      if (isExpanded) {
        final providerDocFields = providerFields[doc.id] ?? [];

        void buildTreeRows(
          String? parentId,
          int depth,
          List<bool> isLastChildList,
        ) {
          final children =
              providerDocFields
                  .where(
                    (f) =>
                        (f.data() as Map<String, dynamic>)['parentId'] ==
                        parentId,
                  )
                  .toList();
          // Sort by creation time to maintain order, or just use as-is
          for (int i = 0; i < children.length; i++) {
            final childDoc = children[i];
            final childData = childDoc.data() as Map<String, dynamic>;
            final isLast = i == children.length - 1;

            final List<bool> currentList = List.from(isLastChildList)
              ..add(isLast);

            Widget treeConnector = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int j = 0; j < depth; j++)
                  SizedBox(
                    width: 20,
                    child: Center(
                      child: Text(
                        isLastChildList[j] ? ' ' : '│',
                        style: const TextStyle(
                          color: Colors.black38,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                SizedBox(
                  width: 20,
                  child: Center(
                    child: Text(
                      isLast ? '└──' : '├──',
                      style: const TextStyle(
                        color: Colors.black38,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            );

            allRows.add(
              DataRow(
                cells: [
                  const DataCell(SizedBox.shrink()),
                  DataCell(
                    Row(
                      children: [
                        const SizedBox(width: 48), // Align with Provider text
                        treeConnector,
                        Text(
                          childData['name']?.toString() ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _showAddFieldDialog(doc.id, childDoc.id),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.blue.shade200),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.add,
                              size: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Text(
                      childData['value']?.toString() ?? '',
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                  const DataCell(SizedBox.shrink()),
                  const DataCell(SizedBox.shrink()),
                  const DataCell(SizedBox.shrink()),
                  const DataCell(SizedBox.shrink()),
                  const DataCell(SizedBox.shrink()),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          onPressed:
                              () => _showAddFieldDialog(
                                doc.id,
                                parentId,
                                existingDoc: childDoc,
                              ),
                          color: Colors.grey.shade600,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          padding: EdgeInsets.zero,
                          tooltip: 'Edit Field',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 16),
                          onPressed: () => _deleteField(childDoc),
                          color: Colors.red.shade400,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          padding: EdgeInsets.zero,
                          tooltip: 'Delete Field',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );

            buildTreeRows(childDoc.id, depth + 1, currentList);
          }
        }

        buildTreeRows(null, 0, []);

        allRows.add(
          DataRow(
            cells: [
              const DataCell(SizedBox.shrink()),
              DataCell(
                Padding(
                  padding: const EdgeInsets.only(left: 48.0),
                  child: TextButton.icon(
                    onPressed: () => _showAddFieldDialog(doc.id, null),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add New Field'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue.shade700,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
              const DataCell(SizedBox.shrink()),
              const DataCell(SizedBox.shrink()),
              const DataCell(SizedBox.shrink()),
              const DataCell(SizedBox.shrink()),
              const DataCell(SizedBox.shrink()),
              const DataCell(SizedBox.shrink()),
              const DataCell(SizedBox.shrink()),
            ],
          ),
        );
      }
    }

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
          dataRowMinHeight: 40,
          dataRowMaxHeight: 64,
          columnSpacing: 24,
          horizontalMargin: 24,
          dividerThickness: 1,
          columns: [
            const DataColumn(label: Text('#')),
            DataColumn(
              label: Row(
                children: [
                  Checkbox(
                    value:
                        docs.isNotEmpty &&
                        _selectedHealthcareIds.length == docs.length,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedHealthcareIds.addAll(docs.map((d) => d.id));
                        } else {
                          _selectedHealthcareIds.clear();
                        }
                      });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    side: const BorderSide(color: Colors.black26),
                  ),
                  const SizedBox(width: 8),
                  const Text('Provider Details'),
                ],
              ),
            ),
            const DataColumn(label: Text('Phone')),
            const DataColumn(label: Text('Facility')),
            const DataColumn(label: Text('Type & Speciality')),
            const DataColumn(label: Text('Address')),
            const DataColumn(label: Text('Joined On')),
            const DataColumn(label: Text('Status')),
            const DataColumn(label: Text('Actions')),
          ],
          rows: allRows,
        ),
      ),
    );
  }

  void _deleteField(QueryDocumentSnapshot fieldDoc) async {
    final bool confirm =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Delete Field'),
                content: const Text(
                  'Are you sure you want to delete this field? All nested child fields will also be deleted.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirm) {
      await fieldDoc.reference.delete();
      final children =
          await FirebaseFirestore.instance
              .collection('healthcare_fields')
              .where('parentId', isEqualTo: fieldDoc.id)
              .get();
      for (var child in children.docs) {
        await child.reference.delete();
      }
    }
  }

  void _showAddFieldDialog(
    String providerId,
    String? parentId, {
    QueryDocumentSnapshot? existingDoc,
  }) {
    final nameController = TextEditingController(
      text: existingDoc != null ? (existingDoc.data() as Map)['name'] : '',
    );
    final valueController = TextEditingController(
      text: existingDoc != null ? (existingDoc.data() as Map)['value'] : '',
    );
    bool isLoading = false;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  title: Text(
                    existingDoc == null
                        ? 'Add New Healthcare Field'
                        : 'Edit Healthcare Field',
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Field Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: valueController,
                        decoration: InputDecoration(
                          labelText: 'Field Value',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed:
                          isLoading
                              ? null
                              : () async {
                                if (nameController.text.trim().isEmpty) return;
                                setDialogState(() => isLoading = true);

                                try {
                                  if (existingDoc != null) {
                                    await existingDoc.reference.update({
                                      'name': nameController.text.trim(),
                                      'value': valueController.text.trim(),
                                    });
                                  } else {
                                    await FirebaseFirestore.instance
                                        .collection('healthcare_fields')
                                        .add({
                                          'providerId': providerId,
                                          'parentId': parentId,
                                          'name': nameController.text.trim(),
                                          'value': valueController.text.trim(),
                                          'createdAt':
                                              FieldValue.serverTimestamp(),
                                        });
                                  }
                                  if (mounted) Navigator.pop(context);
                                } catch (e) {
                                  setDialogState(() => isLoading = false);
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                      ),
                      child:
                          isLoading
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : Text(
                                existingDoc == null ? 'Add Field' : 'Save',
                              ),
                    ),
                  ],
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
      case 'pending':
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        break;
      case 'suspended':
      case 'banned':
      case 'rejected':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Future<void> _deleteHealthcare(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: const Text(
              'Are you sure you want to delete this healthcare provider? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
            .collection('healthcare')
            .doc(docId)
            .delete();

        final fields =
            await FirebaseFirestore.instance
                .collection('healthcare_fields')
                .where('providerId', isEqualTo: docId)
                .get();
        for (var field in fields.docs) {
          await field.reference.delete();
        }

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Deleted successfully')));
        }
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
      }
    }
  }

  void _showHealthcareDialog({DocumentSnapshot? document}) {
    final data = document?.data() as Map<String, dynamic>?;

    final formKey = GlobalKey<FormState>();

    final usernameController = TextEditingController(
      text: data?['username']?.toString(),
    );
    final emailController = TextEditingController(
      text: data?['email']?.toString(),
    );
    final phoneController = TextEditingController(
      text: data?['phone']?.toString(),
    );
    final contactController = TextEditingController(
      text: data?['contact_number']?.toString(),
    );

    final facilityController = TextEditingController(
      text: data?['facility_name']?.toString(),
    );
    final typeController = TextEditingController(
      text: data?['healthcare_type']?.toString(),
    );
    final specialityController = TextEditingController(
      text: data?['speciality']?.toString(),
    );

    final addressController = TextEditingController(
      text: data?['address']?.toString(),
    );
    final availableTimeController = TextEditingController(
      text: data?['available_time']?.toString(),
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
                      keyboardType: isPhone ? TextInputType.number : null,
                      inputFormatters:
                          isPhone
                              ? [FilteringTextInputFormatter.digitsOnly]
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
                      ),
                      validator:
                          (value) =>
                              value!.isEmpty ? 'Please enter $label' : null,
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
                      value:
                          items.contains(controller.text)
                              ? controller.text
                              : null,
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
                      ),
                      items:
                          items.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                      onChanged: (val) {
                        if (val != null) controller.text = val;
                      },
                      validator:
                          (value) =>
                              controller.text.isEmpty
                                  ? 'Please select $label'
                                  : null,
                    ),
                  ],
                ),
              );
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                width: 600,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
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
                                ? 'Add Healthcare'
                                : 'Edit Healthcare',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(bottom: 16),
                                child: Text(
                                  'BASIC DETAILS',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black45,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: buildTextField(
                                      usernameController,
                                      'Full Name',
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: buildTextField(
                                      emailController,
                                      'Email Address',
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: buildTextField(
                                      phoneController,
                                      'Mobile Number',
                                      isPhone: true,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: buildTextField(
                                      contactController,
                                      'Alt Contact Number',
                                      isPhone: true,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 32, color: Colors.black12),
                              const Padding(
                                padding: EdgeInsets.only(bottom: 16),
                                child: Text(
                                  'FACILITY DETAILS',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black45,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              buildTextField(
                                facilityController,
                                'Facility Name',
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: buildDropdownField(
                                      typeController,
                                      'Healthcare Type',
                                      [
                                        'Pharmacy',
                                        'Clinic',
                                        'Hospital',
                                        'Diagnostic Center',
                                        'Other',
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: buildTextField(
                                      specialityController,
                                      'Speciality',
                                      hint: 'e.g. General, Dental',
                                    ),
                                  ),
                                ],
                              ),
                              buildTextField(
                                addressController,
                                'Address',
                                maxLines: 2,
                              ),
                              buildTextField(
                                availableTimeController,
                                'Available Time',
                                hint: 'e.g. 9 AM - 8 PM',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
                                            'email': emailController.text,
                                            'phone': phoneController.text,
                                            'contact_number':
                                                contactController.text,
                                            'facility_name':
                                                facilityController.text,
                                            'healthcare_type':
                                                typeController.text,
                                            'speciality':
                                                specialityController.text,
                                            'address': addressController.text,
                                            'available_time':
                                                availableTimeController.text,
                                            'category': 'Healthcare',
                                            'updated_at':
                                                FieldValue.serverTimestamp(),
                                          };

                                          if (document == null) {
                                            dataToSave['status'] = 'pending';
                                            dataToSave['isVerified'] = 0;
                                            dataToSave['ratings'] = 0;
                                            dataToSave['total_reviews'] = 0;
                                            dataToSave['role'] = 'healthcare';
                                            dataToSave['created_at'] =
                                                FieldValue.serverTimestamp();
                                            dataToSave['profile_img'] = '';
                                            dataToSave['password'] =
                                                'NL' + phoneController.text;
                                            dataToSave['services'] = [];

                                            await FirebaseFirestore.instance
                                                .collection('healthcare')
                                                .add(dataToSave);
                                          } else {
                                            await FirebaseFirestore.instance
                                                .collection('healthcare')
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
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                    : const Text(
                                      'Save Details',
                                      style: TextStyle(
                                        color: Colors.black87,
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
          },
        );
      },
    );
  }
}
