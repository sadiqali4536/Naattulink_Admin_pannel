import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  String _searchQuery = '';
  String? _filterStatus;
  String? _filterChannel;
  Set<String> _selectedNotificationIds = {};
  late Stream<QuerySnapshot> _notificationsStream;

  @override
  void initState() {
    super.initState();
    _notificationsStream =
        FirebaseFirestore.instance
            .collection('notifications')
            .orderBy('created_at', descending: true)
            .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: StreamBuilder<QuerySnapshot>(
        stream: _notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: const Color(0xFFFFC107)),
            );
          }

          final allDocs = snapshot.data?.docs ?? [];

          var docs =
              allDocs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                final title = data['title']?.toString().toLowerCase() ?? '';
                final message = data['message']?.toString().toLowerCase() ?? '';
                final status = data['status']?.toString().toLowerCase() ?? '';
                final channel =
                    data['notification_channel']?.toString().toLowerCase() ??
                    '';

                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  if (!title.contains(q) && !message.contains(q)) return false;
                }
                if (_filterStatus != null &&
                    status != _filterStatus!.toLowerCase())
                  return false;
                if (_filterChannel != null &&
                    channel != _filterChannel!.toLowerCase())
                  return false;
                return true;
              }).toList();

          final sentCount =
              allDocs
                  .where(
                    (d) =>
                        (d.data() as Map)['status']?.toString().toLowerCase() ==
                        'sent',
                  )
                  .length;
          final scheduledCount =
              allDocs
                  .where(
                    (d) =>
                        (d.data() as Map)['status']?.toString().toLowerCase() ==
                        'scheduled',
                  )
                  .length;
          final failedCount =
              allDocs
                  .where(
                    (d) =>
                        (d.data() as Map)['status']?.toString().toLowerCase() ==
                        'failed',
                  )
                  .length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildStatsCards(
                  allDocs.length,
                  sentCount,
                  scheduledCount,
                  failedCount,
                ),
                const SizedBox(height: 24),
                _buildTableSection(docs),
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
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Notifications',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Manage and send notifications to users.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => _showNotificationDialog(initialTab: 1),
              icon: const Icon(
                Icons.send_outlined,
                color: Colors.black87,
                size: 20,
              ),
              label: const Text(
                'Send Notification',
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
              onPressed: () => _showNotificationDialog(initialTab: 0),
              icon: const Icon(Icons.add, color: Colors.black87, size: 20),
              label: const Text(
                'Create Notification',
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

  void _showNotificationDialog({
    int initialTab = 0,
    DocumentSnapshot? document,
  }) {
    showDialog(
      context: context,
      builder:
          (context) =>
              _NotificationDialog(initialTab: initialTab, document: document),
    );
  }

  Widget _buildStatsCards(int total, int sent, int scheduled, int failed) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Total Notifications',
            value: total.toString(),
            icon: Icons.notifications,
            iconBgColor: Colors.blue.shade50,
            iconColor: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Sent',
            value: sent.toString(),
            icon: Icons.send,
            iconBgColor: Colors.green.shade50,
            iconColor: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Scheduled',
            value: scheduled.toString(),
            icon: Icons.access_time,
            iconBgColor: Colors.orange.shade50,
            iconColor: Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Failed',
            value: failed.toString(),
            icon: Icons.notifications_off,
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
        border: const Border(
          bottom: BorderSide(color: Colors.black12, width: 0.5),
          top: BorderSide(color: Colors.black12, width: 0.5),
          left: BorderSide(color: Colors.black12, width: 0.5),
          right: BorderSide(color: Colors.black12, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
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
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
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
        ],
      ),
    );
  }

  Widget _buildTableSection(List<QueryDocumentSnapshot> docs) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          bottom: BorderSide(color: Colors.black12, width: 0.5),
          top: BorderSide(color: Colors.black12, width: 0.5),
          left: BorderSide(color: Colors.black12, width: 0.5),
          right: BorderSide(color: Colors.black12, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildFilters(),
          const Divider(height: 1),
          if (_selectedNotificationIds.isNotEmpty) _buildBulkActions(),
          docs.isEmpty ? _buildEmptyState() : _buildDataTable(docs),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 56,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Click \'Create Notification\' to send your first one.',
              style: TextStyle(fontSize: 13, color: Colors.black38),
            ),
          ],
        ),
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
                hintText: 'Search by title or message...',
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
              value: _filterChannel,
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
              hint: const Text('All Channels'),
              items:
                  ['push', 'in_app'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value == 'push' ? 'Push' : 'In-App'),
                    );
                  }).toList(),
              onChanged: (val) => setState(() => _filterChannel = val),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: DropdownButtonFormField<String>(
              value: _filterStatus,
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
              hint: const Text('All Status'),
              items:
                  ['sent', 'scheduled', 'failed'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value[0].toUpperCase() + value.substring(1)),
                    );
                  }).toList(),
              onChanged: (val) => setState(() => _filterStatus = val),
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            onPressed:
                () => setState(() {
                  _searchQuery = '';
                  _filterStatus = null;
                  _filterChannel = null;
                }),
            icon: const Icon(Icons.refresh, color: Colors.black54, size: 20),
            label: const Text('Reset', style: TextStyle(color: Colors.black54)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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

  Widget _buildBulkActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: const Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        children: [
          Text(
            '${_selectedNotificationIds.length} notifications selected',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () {
              for (var id in _selectedNotificationIds) {
                FirebaseFirestore.instance
                    .collection('notifications')
                    .doc(id)
                    .delete();
              }
              setState(() {
                _selectedNotificationIds.clear();
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
                _selectedNotificationIds.clear();
              });
            },
            icon: const Icon(Icons.close),
            tooltip: 'Clear Selection',
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
        dataRowMaxHeight: 90,
        columnSpacing: 24,
        horizontalMargin: 24,
        dividerThickness: 1,
        columns: [
          DataColumn(
            label: SizedBox(
              width: 60,
              child: Checkbox(
                value:
                    docs.isNotEmpty &&
                    _selectedNotificationIds.length == docs.length,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedNotificationIds = docs.map((d) => d.id).toSet();
                    } else {
                      _selectedNotificationIds.clear();
                    }
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: const BorderSide(color: Colors.black26),
              ),
            ),
          ),
          const DataColumn(label: SizedBox(width: 220, child: Text('Title'))),
          const DataColumn(label: SizedBox(width: 340, child: Text('Message'))),
          const DataColumn(label: SizedBox(width: 130, child: Text('Channel'))),
          const DataColumn(
            label: SizedBox(width: 150, child: Text('Audience')),
          ),
          const DataColumn(label: SizedBox(width: 160, child: Text('Sent On'))),
          const DataColumn(label: SizedBox(width: 110, child: Text('Status'))),
          const DataColumn(label: SizedBox(width: 100, child: Text('Actions'))),
        ],
        rows:
            docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              String dateStr = 'N/A';
              if (data['created_at'] != null &&
                  data['created_at'] is Timestamp) {
                dateStr = DateFormat(
                  'dd MMM yyyy\nhh:mm a',
                ).format((data['created_at'] as Timestamp).toDate());
              }
              final channel =
                  data['notification_channel']?.toString() ?? 'push';
              final status = data['status']?.toString() ?? 'sent';

              return DataRow(
                cells: [
                  DataCell(
                    SizedBox(
                      width: 60,
                      child: Checkbox(
                        value: _selectedNotificationIds.contains(doc.id),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedNotificationIds.add(doc.id);
                            } else {
                              _selectedNotificationIds.remove(doc.id);
                            }
                          });
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        side: const BorderSide(color: Colors.black26),
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 220,
                      child: Text(
                        data['title']?.toString() ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 340,
                      child: Text(
                        data['message']?.toString() ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 130,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _buildTypeBadge(
                          channel == 'push' ? 'Push' : 'In-App',
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 150,
                      child: Text(
                        data['audience']?.toString() ?? 'All Users',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 160,
                      child: Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 110,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _buildStatusBadge(
                          status[0].toUpperCase() + status.substring(1),
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 100,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: 20,
                                color: Colors.blueAccent,
                              ),
                              onPressed:
                                  () => _showNotificationDialog(document: doc),
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
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('notifications')
                                    .doc(doc.id)
                                    .delete();
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    Color bgColor;
    Color textColor;

    switch (type) {
      case 'Bus':
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        break;
      case 'Taxi':
        bgColor = Colors.purple.shade50;
        textColor = Colors.purple.shade700;
        break;
      case 'Promotion':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        break;
      case 'System':
        bgColor = Colors.grey.shade200;
        textColor = Colors.black54;
        break;
      case 'Update':
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        break;
      case 'Transaction':
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        break;
      case 'Alert':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        break;
      default:
        bgColor = Colors.grey.shade200;
        textColor = Colors.black54;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Sent':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        break;
      case 'Scheduled':
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        break;
      case 'Failed':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
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
            'Showing 1 to 8 of 256 entries',
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
              _buildPageNumber('32', false),
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
}

// _NotificationDialog - Push & In-App notification sender
class _NotificationDialog extends StatefulWidget {
  final int initialTab;
  final DocumentSnapshot? document;
  const _NotificationDialog({this.initialTab = 0, this.document});

  @override
  State<_NotificationDialog> createState() => _NotificationDialogState();
}

class _NotificationDialogState extends State<_NotificationDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedAudience = 'All Users';
  bool _isSending = false;

  // Push extras
  final _imageUrlController = TextEditingController();
  final _deepLinkController = TextEditingController();
  String _selectedPriority = 'High';

  // In-App extras
  String _selectedType = 'Info';
  String _selectedColor = 'Blue';
  bool _showIcon = true;
  bool _isDismissible = true;

  final List<String> _audiences = [
    'All Users',
    'Taxi Drivers',
    'Truck / JCB Drivers',
    'Bus Users',
    'Healthcare Providers',
    'Business Owners',
    'Workers',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );

    if (widget.document != null) {
      final data = widget.document!.data() as Map<String, dynamic>;
      _titleController.text = data['title']?.toString() ?? '';
      _messageController.text = data['message']?.toString() ?? '';
      _selectedAudience = data['audience']?.toString() ?? 'All Users';
      _imageUrlController.text = data['image_url']?.toString() ?? '';
      _deepLinkController.text = data['deep_link']?.toString() ?? '';
      _selectedPriority = data['priority']?.toString() ?? 'High';
      _selectedType = data['notification_type']?.toString() ?? 'Info';
      _selectedColor = data['accent_color']?.toString() ?? 'Blue';
      _showIcon = data['show_icon'] ?? true;
      _isDismissible = data['is_dismissible'] ?? true;
      if (data['notification_channel'] == 'in_app') {
        _tabController.index = 1;
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    _imageUrlController.dispose();
    _deepLinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 580,
        constraints: const BoxConstraints(maxHeight: 680),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // â”€â”€ Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF334155)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_active_rounded,
                    color: Color(0xFFFFC107),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Send Notification',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            // â”€â”€ Tabs
            Container(
              color: const Color(0xFFF1F5F9),
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF1E293B),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFFFFC107),
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.notifications_rounded, size: 18),
                    text: 'Push Notification',
                  ),
                  Tab(
                    icon: Icon(Icons.campaign_rounded, size: 18),
                    text: 'In-App Notification',
                  ),
                ],
              ),
            ),
            // â”€â”€ Content
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: [_buildPushTab(), _buildInAppTab()],
              ),
            ),
            // â”€â”€ Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FA),
                border: Border(top: BorderSide(color: Colors.black12)),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSending ? null : _send,
                    icon:
                        _isSending
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.black87,
                                ),
                              ),
                            )
                            : const Icon(
                              Icons.send_rounded,
                              size: 18,
                              color: Colors.black87,
                            ),
                    label: Text(
                      _isSending ? 'Sending...' : 'Send Now',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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

  Widget _buildPushTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoBanner(
            icon: Icons.phone_android_rounded,
            color: const Color(0xFF3B82F6),
            text:
                "Push notifications are delivered to users' devices even when the app is closed.",
          ),
          const SizedBox(height: 20),
          _buildSectionLabel('NOTIFICATION CONTENT'),
          _buildField(
            'Title *',
            _titleController,
            hint: 'e.g. New Feature Available!',
          ),
          _buildField(
            'Message *',
            _messageController,
            hint: 'Write your notification message here...',
            maxLines: 3,
          ),
          _buildField(
            'Image URL (optional)',
            _imageUrlController,
            hint: 'https://example.com/image.png',
          ),
          _buildField(
            'Deep Link (optional)',
            _deepLinkController,
            hint: 'e.g. /taxi-drivers',
          ),
          const SizedBox(height: 4),
          _buildSectionLabel('DELIVERY SETTINGS'),
          _buildDropdown(
            'Target Audience',
            _selectedAudience,
            _audiences,
            (val) => setState(() => _selectedAudience = val!),
          ),
          _buildDropdown(
            'Priority',
            _selectedPriority,
            ['High', 'Normal', 'Low'],
            (val) => setState(() => _selectedPriority = val!),
          ),
        ],
      ),
    );
  }

  Widget _buildInAppTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoBanner(
            icon: Icons.mark_chat_unread_rounded,
            color: const Color(0xFF8B5CF6),
            text:
                'In-app notifications appear as banners inside the app while users are active.',
          ),
          const SizedBox(height: 20),
          _buildSectionLabel('NOTIFICATION CONTENT'),
          _buildField(
            'Title *',
            _titleController,
            hint: 'e.g. Important Update',
          ),
          _buildField(
            'Message *',
            _messageController,
            hint: 'Write your notification message here...',
            maxLines: 3,
          ),
          const SizedBox(height: 4),
          _buildSectionLabel('DISPLAY SETTINGS'),
          _buildDropdown(
            'Target Audience',
            _selectedAudience,
            _audiences,
            (val) => setState(() => _selectedAudience = val!),
          ),
          _buildDropdown(
            'Notification Type',
            _selectedType,
            ['Info', 'Success', 'Warning', 'Error'],
            (val) => setState(() => _selectedType = val!),
          ),
          _buildDropdown(
            'Accent Color',
            _selectedColor,
            ['Blue', 'Green', 'Orange', 'Red', 'Purple'],
            (val) => setState(() => _selectedColor = val!),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildToggleRow(
                  label: 'Show Icon',
                  value: _showIcon,
                  onChanged: (val) => setState(() => _showIcon = val),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildToggleRow(
                  label: 'Dismissible',
                  value: _isDismissible,
                  onChanged: (val) => setState(() => _isDismissible = val),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: color, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.black45,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    String? hint,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
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
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFFFFC107),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
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
                items
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e, style: const TextStyle(fontSize: 13)),
                      ),
                    )
                    .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFFFFC107),
            ),
          ),
        ],
      ),
    );
  }

  void _send() async {
    if (_titleController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in the Title and Message fields.'),
        ),
      );
      return;
    }
    setState(() => _isSending = true);

    final bool isPush = _tabController.index == 0;
    final Map<String, dynamic> data = {
      'title': _titleController.text.trim(),
      'message': _messageController.text.trim(),
      'audience': _selectedAudience,
      'notification_channel': isPush ? 'push' : 'in_app',
      'status': 'sent',
      'created_at': FieldValue.serverTimestamp(),
    };

    if (isPush) {
      data['image_url'] = _imageUrlController.text.trim();
      data['deep_link'] = _deepLinkController.text.trim();
      data['priority'] = _selectedPriority;
    } else {
      data['notification_type'] = _selectedType;
      data['accent_color'] = _selectedColor;
      data['show_icon'] = _showIcon;
      data['is_dismissible'] = _isDismissible;
    }

    try {
      if (widget.document != null) {
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(widget.document!.id)
            .update(data);
      } else {
        await FirebaseFirestore.instance.collection('notifications').add(data);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
