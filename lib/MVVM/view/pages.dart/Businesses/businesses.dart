import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:swiftclean_admin/MVVM/utils/printer_helper.dart';

class BusinessesPage extends StatefulWidget {
  const BusinessesPage({super.key});

  @override
  State<BusinessesPage> createState() => _BusinessesPageState();
}

class _BusinessesPageState extends State<BusinessesPage> {
  String _selectedStatus = 'All Status';
  String _selectedType = 'All Types';
  String _searchQuery = '';
  Set<String> _selectedBusinessIds = {};
  final ScrollController _verticalScrollController = ScrollController();
  late Stream<QuerySnapshot> _businessesStream;

  @override
  void initState() {
    super.initState();
    _businessesStream =
        FirebaseFirestore.instance.collection('businesses').snapshots();
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        controller: _verticalScrollController,
        padding: const EdgeInsets.all(24.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: _businessesStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Something went wrong'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
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
                _searchQuery.isNotEmpty) {
              filteredDocs =
                  docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final status =
                        data['status']?.toString().toLowerCase() ?? '';
                    final type = data['business_category']?.toString() ?? '';

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

                    bool searchMatches = true;
                    if (_searchQuery.isNotEmpty) {
                      final searchLower = _searchQuery.toLowerCase();
                      final name =
                          data['username']?.toString().toLowerCase() ?? '';
                      final business =
                          data['business_name']?.toString().toLowerCase() ?? '';
                      final phone =
                          data['phone']?.toString().toLowerCase() ?? '';
                      final address =
                          data['address']?.toString().toLowerCase() ?? '';
                      final category =
                          data['business_category']?.toString().toLowerCase() ??
                          '';
                      searchMatches =
                          name.contains(searchLower) ||
                          business.contains(searchLower) ||
                          phone.contains(searchLower) ||
                          address.contains(searchLower) ||
                          category.contains(searchLower);
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
                if (_selectedBusinessIds.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${_selectedBusinessIds.length} businesses selected',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            for (var id in _selectedBusinessIds) {
                              _deleteBusiness(id);
                            }
                            setState(() {
                              _selectedBusinessIds.clear();
                            });
                          },
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text(
                            'Delete Selected',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedBusinessIds.clear();
                            });
                          },
                          icon: const Icon(Icons.close),
                          tooltip: 'Clear Selection',
                        ),
                      ],
                    ),
                  ),
                _buildFilters(docs),
                const SizedBox(height: 24),
                Container(
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
                    children: [_buildDataTable(filteredDocs)],
                  ),
                ),
              ],
            );
          },
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
                  'Shops & Businesses',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Manage registered shops and businesses.',
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
                    printBusinessesList(listToExport);
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
                  onPressed: () => _showBusinessDialog(),
                  icon: const Icon(Icons.add, color: Colors.black87, size: 20),
                  label: const Text(
                    'Add Business',
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
                title: 'Total Businesses',
                value: total.toString(),
                icon: Icons.store_outlined,
                iconBgColor: Colors.purple.shade50,
                iconColor: Colors.purple,
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
    final Set<String> uniqueCategories = {};
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final cat = data['business_category']?.toString();
      if (cat != null && cat.trim().isNotEmpty) {
        uniqueCategories.add(cat.trim());
      }
    }
    final List<String> categoryList = uniqueCategories.toList()..sort();
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
                hintText: 'Search by name, business or phone...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
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
                  ['All Types', ...categoryList].map((String value) {
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
        ],
      ),
    );
  }

  Widget _buildDataTable(List<QueryDocumentSnapshot> docs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(Colors.white),
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
        columns: [
          DataColumn(
            label: Row(
              children: [
                Checkbox(
                  value:
                      docs.isNotEmpty &&
                      _selectedBusinessIds.length == docs.length,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedBusinessIds = docs.map((d) => d.id).toSet();
                      } else {
                        _selectedBusinessIds.clear();
                      }
                    });
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  side: const BorderSide(color: Colors.black26),
                ),
                const SizedBox(width: 8),
                const Text('Owner Details'),
              ],
            ),
          ),
          const DataColumn(label: Text('Phone')),
          const DataColumn(label: Text('Business Name')),
          const DataColumn(label: Text('Category')),
          const DataColumn(label: Text('Address')),
          const DataColumn(label: Text('Joined On')),
          const DataColumn(label: Text('Status')),
          const DataColumn(label: Text('Actions')),
        ],
        rows:
            docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              String name =
                  data['username']?.toString() ??
                  data['name']?.toString() ??
                  'Unknown';
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

              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: _selectedBusinessIds.contains(doc.id),
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedBusinessIds.add(doc.id);
                              } else {
                                _selectedBusinessIds.remove(doc.id);
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
                          backgroundColor: Colors.purple.shade100,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.purple,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 150,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Email: ${data['email']?.toString() ?? 'N/A'}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ID: ${doc.id.length > 6 ? doc.id.substring(0, 6) : doc.id} | ${data['isVerified'] == 1 ? "Verified" : "Unverified"}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
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
                  DataCell(
                    SizedBox(
                      width: 100,
                      child: Text(
                        data['phone']?.toString() ?? 'N/A',
                        style: const TextStyle(fontSize: 13),
                        maxLines: 1,
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
                            data['business_name']?.toString() ?? 'N/A',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Contact: ${data['contact_number']?.toString() ?? 'N/A'}',
                            style: const TextStyle(
                              color: Colors.grey,
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
                      width: 120,
                      child: Text(
                        data['business_category']?.toString() ?? 'N/A',
                        style: const TextStyle(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                      child: Text(
                        dateString,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  DataCell(
                    _buildStatusBadge(data['status']?.toString() ?? 'Pending'),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value:
                                data['status']?.toString().toLowerCase() ==
                                'active',
                            onChanged: (val) {
                              FirebaseFirestore.instance
                                  .collection('businesses')
                                  .doc(doc.id)
                                  .update({
                                    'status': val ? 'active' : 'inactive',
                                  });
                            },
                            activeColor: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Colors.blue,
                            size: 18,
                          ),
                          onPressed: () => _showBusinessDialog(document: doc),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 18,
                          ),
                          onPressed: () => _deleteBusiness(doc.id),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
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

  Future<void> _deleteBusiness(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: const Text(
              'Are you sure you want to delete this business? This action cannot be undone.',
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
            .collection('businesses')
            .doc(docId)
            .delete();
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Deleted successfully')));
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
      }
    }
  }

  void _showBusinessDialog({DocumentSnapshot? document}) {
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

    final businessNameController = TextEditingController(
      text: data?['business_name']?.toString(),
    );
    final categoryController = TextEditingController(
      text: data?['business_category']?.toString(),
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
                            color: Colors.purple,
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
                            document == null ? 'Add Business' : 'Edit Business',
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
                                  'OWNER DETAILS',
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
                                  'BUSINESS DETAILS',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black45,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              buildTextField(
                                businessNameController,
                                'Business Name',
                              ),
                              buildDropdownField(
                                categoryController,
                                'Business Category',
                                [
                                  'Restaurant',
                                  'Grocery',
                                  'Electronics',
                                  'Clothing',
                                  'Pharmacy',
                                  'Hardware',
                                  'Beauty & Salon',
                                  'Bakery',
                                  'Other',
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
                                            'business_name':
                                                businessNameController.text,
                                            'business_category':
                                                categoryController.text,
                                            'address': addressController.text,
                                            'available_time':
                                                availableTimeController.text,
                                            'category': 'Shops & Businesses',
                                            'updated_at':
                                                FieldValue.serverTimestamp(),
                                          };

                                          if (document == null) {
                                            dataToSave['status'] = 'pending';
                                            dataToSave['isVerified'] = 0;
                                            dataToSave['ratings'] = 0;
                                            dataToSave['total_reviews'] = 0;
                                            dataToSave['role'] = 'business';
                                            dataToSave['created_at'] =
                                                FieldValue.serverTimestamp();
                                            dataToSave['profile_img'] = '';
                                            dataToSave['password'] =
                                                'NL' + phoneController.text;
                                            dataToSave['services'] = [];

                                            await FirebaseFirestore.instance
                                                .collection('businesses')
                                                .add(dataToSave);
                                          } else {
                                            await FirebaseFirestore.instance
                                                .collection('businesses')
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
                                                      ? 'Business added successfully'
                                                      : 'Business updated successfully',
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
