import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swiftclean_admin/MVVM/model/models/admin_model.dart';
import 'package:swiftclean_admin/MVVM/utils/rbac_session.dart';

class StoreOrderModel {
  final String id;
  final String orderNumber;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final List<Map<String, dynamic>> items;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String orderStatus;
  final String deliveryAddress;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StoreOrderModel({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.items,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    required this.deliveryAddress,
    this.createdAt,
    this.updatedAt,
  });

  factory StoreOrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StoreOrderModel(
      id: doc.id,
      orderNumber: data['orderNumber'] ?? doc.id.substring(0, 8).toUpperCase(),
      customerName: data['customerName'] ?? data['userName'] ?? 'Unknown',
      customerPhone: data['customerPhone'] ?? data['phone'] ?? '',
      customerEmail: data['customerEmail'] ?? data['email'] ?? '',
      items: List<Map<String, dynamic>>.from(data['items'] ?? []),
      totalAmount: (data['totalAmount'] ?? data['total'] ?? 0.0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? 'Unknown',
      paymentStatus: data['paymentStatus'] ?? 'Pending',
      orderStatus: data['orderStatus'] ?? data['status'] ?? 'Pending',
      deliveryAddress: data['deliveryAddress'] ?? data['address'] ?? '',
      createdAt:
          data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : null,
      updatedAt:
          data['updatedAt'] != null
              ? (data['updatedAt'] as Timestamp).toDate()
              : null,
    );
  }

  int get itemCount => items.fold(0, (sum, item) {
    return sum + ((item['quantity'] as num?)?.toInt() ?? 1);
  });
}

class StoreOrdersPage extends StatefulWidget {
  const StoreOrdersPage({super.key});

  @override
  State<StoreOrdersPage> createState() => _StoreOrdersPageState();
}

class _StoreOrdersPageState extends State<StoreOrdersPage> {
  final _session = RbacSession();
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<StoreOrderModel> _orders = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatus = 'All Status';
  String _selectedPayment = 'All Payments';
  Timer? _searchDebounce;

  int _statTotal = 0;
  int _statPending = 0;
  int _statProcessing = 0;
  int _statDelivered = 0;
  double _statRevenue = 0;

  static const _orderStatuses = [
    'All Status',
    'Pending',
    'Confirmed',
    'Processing',
    'Shipped',
    'Delivered',
    'Cancelled',
    'Refunded',
  ];

  static const _paymentStatuses = [
    'All Payments',
    'Pending',
    'Paid',
    'Failed',
    'Refunded',
  ];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool _can(String action) =>
      _session.hasPermission(Modules.storeOrders, action);

  void _onSearchChanged(String val) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => _searchQuery = val);
      _fetchOrders();
    });
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      final db = FirebaseFirestore.instance;
      Query query = db
          .collection('store_orders')
          .orderBy('createdAt', descending: true);

      if (_selectedStatus != 'All Status') {
        query = query.where('orderStatus', isEqualTo: _selectedStatus);
      }
      if (_selectedPayment != 'All Payments') {
        query = query.where('paymentStatus', isEqualTo: _selectedPayment);
      }

      final snapshot = await query.get();
      List<StoreOrderModel> loaded =
          snapshot.docs.map((d) => StoreOrderModel.fromFirestore(d)).toList();

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        loaded =
            loaded.where((o) {
              return o.orderNumber.toLowerCase().contains(q) ||
                  o.customerName.toLowerCase().contains(q) ||
                  o.customerPhone.contains(q) ||
                  o.customerEmail.toLowerCase().contains(q);
            }).toList();
      }

      _calculateStats(
        snapshot.docs.map((d) => StoreOrderModel.fromFirestore(d)).toList(),
      );

      if (mounted) {
        setState(() {
          _orders = loaded;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _calculateStats(List<StoreOrderModel> all) {
    int pending = 0, processing = 0, delivered = 0;
    double revenue = 0;
    for (final o in all) {
      if (o.orderStatus == 'Pending') pending++;
      if (o.orderStatus == 'Processing' || o.orderStatus == 'Confirmed')
        processing++;
      if (o.orderStatus == 'Delivered') delivered++;
      if (o.paymentStatus == 'Paid') revenue += o.totalAmount;
    }
    setState(() {
      _statTotal = all.length;
      _statPending = pending;
      _statProcessing = processing;
      _statDelivered = delivered;
      _statRevenue = revenue;
    });
  }

  Future<void> _updateOrderStatus(
    StoreOrderModel order,
    String newStatus,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('store_orders')
          .doc(order.id)
          .update({
            'orderStatus': newStatus,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order #${order.orderNumber} updated to $newStatus.'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        _fetchOrders();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showOrderDetails(StoreOrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => _OrderDetailsDialog(order: order),
    );
  }

  void _showStatusUpdateDialog(StoreOrderModel order) {
    String selected = order.orderStatus;
    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (context, setStateDialog) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width: 380,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Update Order Status',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Order #${order.orderNumber}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ...[
                          'Pending',
                          'Confirmed',
                          'Processing',
                          'Shipped',
                          'Delivered',
                          'Cancelled',
                          'Refunded',
                        ].map(
                          (s) => RadioListTile<String>(
                            title: Text(s, style: GoogleFonts.inter()),
                            value: s,
                            groupValue: selected,
                            activeColor: const Color(0xFFFFC107),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            onChanged:
                                (v) => setStateDialog(() => selected = v!),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _updateOrderStatus(order, selected);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFC107),
                                foregroundColor: const Color(0xFF1E293B),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                              ),
                              child: Text(
                                'Update',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              controller: _verticalScrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsRow(),
                  const SizedBox(height: 24),
                  _buildToolbar(),
                  const SizedBox(height: 16),
                  _buildOrdersTable(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Dashboard',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  Text(
                    'Online Store',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  Text(
                    'Store Orders',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Store Orders',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage and track all customer orders from the online store.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: _fetchOrders,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF475569),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final revenue =
        _statRevenue >= 1000
            ? '${(_statRevenue / 1000).toStringAsFixed(1)}K'
            : _statRevenue.toStringAsFixed(0);
    return Row(
      children: [
        _statCard(
          'Total Orders',
          _statTotal.toString(),
          Icons.receipt_long_outlined,
          const Color(0xFF3B82F6),
        ),
        const SizedBox(width: 16),
        _statCard(
          'Pending',
          _statPending.toString(),
          Icons.hourglass_empty_rounded,
          const Color(0xFFF59E0B),
        ),
        const SizedBox(width: 16),
        _statCard(
          'Processing',
          _statProcessing.toString(),
          Icons.autorenew_rounded,
          const Color(0xFF8B5CF6),
        ),
        const SizedBox(width: 16),
        _statCard(
          'Delivered',
          _statDelivered.toString(),
          Icons.check_circle_outline_rounded,
          const Color(0xFF10B981),
        ),
        const SizedBox(width: 16),
        _statCard(
          'Revenue',
          '₹$revenue',
          Icons.currency_rupee_rounded,
          const Color(0xFF0EA5E9),
        ),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x05000000),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
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

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 42,
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by order #, name, phone or email…',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: Color(0xFF94A3B8),
                  ),
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: Color(0xFF94A3B8),
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                              _fetchOrders();
                            },
                          )
                          : null,
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 0,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
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
            ),
          ),
          const SizedBox(width: 12),
          _dropdown(
            value: _selectedStatus,
            items: _orderStatuses,
            icon: Icons.local_shipping_outlined,
            onChanged: (v) {
              setState(() => _selectedStatus = v!);
              _fetchOrders();
            },
          ),
          const SizedBox(width: 12),
          _dropdown(
            value: _selectedPayment,
            items: _paymentStatuses,
            icon: Icons.payment_rounded,
            onChanged: (v) {
              setState(() => _selectedPayment = v!);
              _fetchOrders();
            },
          ),
        ],
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(
            Icons.expand_more_rounded,
            size: 18,
            color: Color(0xFF64748B),
          ),
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1E293B),
          ),
          items:
              items
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 15, color: const Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Text(s),
                        ],
                      ),
                    ),
                  )
                  .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildOrdersTable() {
    if (_isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 80),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFFFFC107)),
        ),
      );
    }
    if (_orders.isEmpty) return _buildEmptyState();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  Text(
                    '${_orders.length} order${_orders.length == 1 ? '' : 's'} found',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
            Scrollbar(
              controller: _horizontalScrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _horizontalScrollController,
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 48,
                  dataRowMinHeight: 64,
                  dataRowMaxHeight: 80,
                  horizontalMargin: 20,
                  columnSpacing: 24,
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFFF8FAFC),
                  ),
                  dividerThickness: 1,
                  columns: [
                    DataColumn(label: _th('Order')),
                    DataColumn(label: _th('Customer')),
                    DataColumn(label: _th('Items')),
                    DataColumn(label: _th('Amount'), numeric: true),
                    DataColumn(label: _th('Payment')),
                    DataColumn(label: _th('Status')),
                    DataColumn(label: _th('Date')),
                    if (_can(Perms.edit)) DataColumn(label: _th('Actions')),
                  ],
                  rows:
                      _orders
                          .map(
                            (order) => DataRow(
                              cells: [
                                DataCell(_orderCell(order)),
                                DataCell(_customerCell(order)),
                                DataCell(_itemsCell(order)),
                                DataCell(
                                  Text(
                                    '₹${order.totalAmount.toStringAsFixed(2)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  _badge(
                                    order.paymentStatus,
                                    _paymentColor(order.paymentStatus),
                                    _paymentBg(order.paymentStatus),
                                  ),
                                ),
                                DataCell(
                                  _badge(
                                    order.orderStatus,
                                    _statusColor(order.orderStatus),
                                    _statusBg(order.orderStatus),
                                  ),
                                ),
                                DataCell(_dateCell(order.createdAt)),
                                if (_can(Perms.edit))
                                  DataCell(_actionsCell(order)),
                              ],
                            ),
                          )
                          .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _th(String text) => Text(
    text.toUpperCase(),
    style: GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF64748B),
      letterSpacing: 0.5,
    ),
  );

  Widget _orderCell(StoreOrderModel o) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '#${o.orderNumber}',
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF3B82F6),
        ),
      ),
      Text(
        o.id.length > 10 ? '${o.id.substring(0, 10)}...' : o.id,
        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
      ),
    ],
  );

  Widget _customerCell(StoreOrderModel o) => SizedBox(
    width: 160,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          o.customerName,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        if (o.customerPhone.isNotEmpty)
          Text(
            o.customerPhone,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF64748B),
            ),
          ),
      ],
    ),
  );

  Widget _itemsCell(StoreOrderModel o) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '${o.items.length} item${o.items.length == 1 ? '' : 's'}',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF475569),
          ),
        ),
      ),
      if (o.itemCount > 0) ...[
        const SizedBox(width: 4),
        Text(
          'x${o.itemCount}',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ],
    ],
  );

  Widget _badge(String text, Color color, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    ),
  );

  Widget _dateCell(DateTime? date) {
    if (date == null)
      return Text(
        '—',
        style: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
      );
    final diff = DateTime.now().difference(date);
    final rel =
        diff.inMinutes < 60
            ? '${diff.inMinutes}m ago'
            : diff.inHours < 24
            ? '${diff.inHours}h ago'
            : '${diff.inDays}d ago';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${date.day}/${date.month}/${date.year}',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1E293B),
          ),
        ),
        Text(
          rel,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _actionsCell(StoreOrderModel order) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        icon: const Icon(Icons.visibility_outlined, size: 18),
        color: const Color(0xFF3B82F6),
        tooltip: 'View Details',
        splashRadius: 20,
        onPressed: () => _showOrderDetails(order),
      ),
      IconButton(
        icon: const Icon(Icons.edit_note_rounded, size: 20),
        color: const Color(0xFF8B5CF6),
        tooltip: 'Update Status',
        splashRadius: 20,
        onPressed: () => _showStatusUpdateDialog(order),
      ),
    ],
  );

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Orders Found',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty ||
                    _selectedStatus != 'All Status' ||
                    _selectedPayment != 'All Payments'
                ? 'Try adjusting your filters or search query.'
                : 'Orders from your online store will appear here.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Pending':
        return const Color(0xFFF59E0B);
      case 'Confirmed':
        return const Color(0xFF3B82F6);
      case 'Processing':
        return const Color(0xFF8B5CF6);
      case 'Shipped':
        return const Color(0xFF0EA5E9);
      case 'Delivered':
        return const Color(0xFF10B981);
      case 'Cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _statusBg(String s) {
    switch (s) {
      case 'Pending':
        return const Color(0xFFFFFBEB);
      case 'Confirmed':
        return const Color(0xFFEFF6FF);
      case 'Processing':
        return const Color(0xFFF5F3FF);
      case 'Shipped':
        return const Color(0xFFE0F2FE);
      case 'Delivered':
        return const Color(0xFFECFDF5);
      case 'Cancelled':
        return const Color(0xFFFEF2F2);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Color _paymentColor(String s) {
    switch (s) {
      case 'Paid':
        return const Color(0xFF10B981);
      case 'Pending':
        return const Color(0xFFF59E0B);
      case 'Failed':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _paymentBg(String s) {
    switch (s) {
      case 'Paid':
        return const Color(0xFFECFDF5);
      case 'Pending':
        return const Color(0xFFFFFBEB);
      case 'Failed':
        return const Color(0xFFFEF2F2);
      default:
        return const Color(0xFFF1F5F9);
    }
  }
}

class _OrderDetailsDialog extends StatelessWidget {
  final StoreOrderModel order;
  const _OrderDetailsDialog({required this.order});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: 560,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Details',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '#${order.orderNumber}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF3B82F6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF64748B),
                    ),
                    splashRadius: 24,
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _chip(order.orderStatus, _oColor(order.orderStatus)),
                        const SizedBox(width: 8),
                        _chip(
                          order.paymentStatus,
                          _pColor(order.paymentStatus),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _section('Customer Information'),
                    const SizedBox(height: 12),
                    _row(
                      Icons.person_outline_rounded,
                      'Name',
                      order.customerName,
                    ),
                    if (order.customerPhone.isNotEmpty)
                      _row(Icons.phone_outlined, 'Phone', order.customerPhone),
                    if (order.customerEmail.isNotEmpty)
                      _row(Icons.email_outlined, 'Email', order.customerEmail),
                    if (order.deliveryAddress.isNotEmpty)
                      _row(
                        Icons.location_on_outlined,
                        'Address',
                        order.deliveryAddress,
                      ),
                    const SizedBox(height: 20),
                    _section('Order Information'),
                    const SizedBox(height: 12),
                    _row(Icons.payment_rounded, 'Payment', order.paymentMethod),
                    _row(
                      Icons.calendar_today_outlined,
                      'Ordered On',
                      order.createdAt != null
                          ? '${order.createdAt!.day}/${order.createdAt!.month}/${order.createdAt!.year}  ${order.createdAt!.hour}:${order.createdAt!.minute.toString().padLeft(2, '0')}'
                          : '—',
                    ),
                    if (order.items.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _section('Items (${order.items.length})'),
                      const SizedBox(height: 12),
                      ...order.items.map((item) => _itemRow(item)),
                    ],
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          Text(
                            '₹${order.totalAmount.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      foregroundColor: const Color(0xFF1E293B),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
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

  Widget _section(String text) => Text(
    text,
    style: GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF475569),
      letterSpacing: 0.3,
    ),
  );

  Widget _row(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 10),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _itemRow(Map<String, dynamic> item) {
    final name = item['productName'] ?? item['name'] ?? 'Product';
    final qty = item['quantity'] ?? 1;
    final price = (item['price'] ?? 0.0).toDouble();
    final imageUrl = item['imageUrl'] as String?;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child:
                  imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => const Icon(
                              Icons.inventory_2_outlined,
                              size: 20,
                              color: Color(0xFF94A3B8),
                            ),
                      )
                      : const Icon(
                        Icons.inventory_2_outlined,
                        size: 20,
                        color: Color(0xFF94A3B8),
                      ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  'Qty: $qty',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${(price * qty).toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    ),
  );

  Color _oColor(String s) {
    switch (s) {
      case 'Pending':
        return const Color(0xFFF59E0B);
      case 'Confirmed':
        return const Color(0xFF3B82F6);
      case 'Processing':
        return const Color(0xFF8B5CF6);
      case 'Shipped':
        return const Color(0xFF0EA5E9);
      case 'Delivered':
        return const Color(0xFF10B981);
      case 'Cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _pColor(String s) {
    switch (s) {
      case 'Paid':
        return const Color(0xFF10B981);
      case 'Pending':
        return const Color(0xFFF59E0B);
      case 'Failed':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }
}
