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
              FirebaseFirestore.instance.collection('healthcare').snapshots(),
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
                _selectedType != 'All Types' ||
                _searchQuery.isNotEmpty) {
              filteredDocs =
                  docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final status =
                        data['status']?.toString().toLowerCase() ?? '';
                    final type = data['healthcare_type']?.toString() ?? '';

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
                      final facility =
                          data['facility_name']?.toString().toLowerCase() ?? '';
                      final phone =
                          data['phone']?.toString().toLowerCase() ?? '';
                      searchMatches =
                          name.contains(searchLower) ||
                          facility.contains(searchLower) ||
                          phone.contains(searchLower);
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
                _buildFilters(),
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
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          'Healthcare Directory (${filteredDocs.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: Colors.black12),
                      _buildDataTable(filteredDocs),
                    ],
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

  Widget _buildFilters() {
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
                  [
                    'All Types',
                    'Pharmacy',
                    'Clinic',
                    'Hospital',
                    'Diagnostic Center',
                    'Other',
                  ].map((String value) {
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
      child: SizedBox(
        width: 1500,
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(2.5),
            1: FlexColumnWidth(1.5),
            2: FlexColumnWidth(2.0),
            3: FlexColumnWidth(2.0),
            4: FlexColumnWidth(2.0),
            5: FlexColumnWidth(1.5),
            6: FlexColumnWidth(1.0),
            7: FlexColumnWidth(1.2),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: const Border(
                  bottom: BorderSide(color: Colors.black12, width: 1),
                ),
              ),
              children: [
                _buildHeaderCellWithCheckbox('Provider Details'),
                _buildHeaderCell('Phone'),
                _buildHeaderCell('Facility'),
                _buildHeaderCell('Type & Speciality'),
                _buildHeaderCell('Address'),
                _buildHeaderCell('Joined On'),
                _buildHeaderCell('Status'),
                _buildHeaderCell('Actions'),
              ],
            ),
            ...docs.map((doc) {
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
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
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
                                name,
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
                  _buildDataCell(data['facility_name']?.toString() ?? 'N/A'),
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
                          data['healthcare_type']?.toString() ?? 'N/A',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Spec: ${data['speciality']?.toString() ?? 'N/A'}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildDataCell(data['address']?.toString() ?? 'N/A'),
                  _buildDataCell(dateString),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 16.0,
                    ),
                    child: _buildStatusBadge(
                      data['status']?.toString() ?? 'Pending',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 16.0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value:
                              data['status']?.toString().toLowerCase() ==
                              'active',
                          onChanged: (val) {
                            FirebaseFirestore.instance
                                .collection('healthcare')
                                .doc(doc.id)
                                .update({
                                  'status': val ? 'active' : 'inactive',
                                });
                          },
                          activeColor: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Colors.blue,
                            size: 18,
                          ),
                          onPressed: () => _showHealthcareDialog(document: doc),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 18,
                          ),
                          onPressed: () => _deleteHealthcare(doc.id),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                        ),
                      ],
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
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Colors.black87,
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
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildDataCell(String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Text(
        value,
        style: const TextStyle(fontSize: 13),
        overflow: TextOverflow.ellipsis,
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
