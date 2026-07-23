import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swiftclean_admin/MVVM/utils/printer_helper.dart';

class PaymentPage extends StatefulWidget {
  PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  static final String _dateString =
      "${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}";

  List<Map<String, String>> transactions = [];

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  String _filterStatus = 'All';
  String _filterBookingId = '';

  List<Map<String, String>> get filteredTransactions {
    return transactions.where((tx) {
      final matchesStatus =
          _filterStatus == 'All' || tx['status'] == _filterStatus;
      final matchesBookingId =
          _filterBookingId.isEmpty ||
          (tx['bookingId'] != null &&
              tx['bookingId']!.toLowerCase().contains(
                _filterBookingId.toLowerCase(),
              ));
      return matchesStatus && matchesBookingId;
    }).toList();
  }
  late final Stream<QuerySnapshot> _paymentsStream;

  @override
  void initState() {
    super.initState();
    _paymentsStream =
        FirebaseFirestore.instance
            .collection('payments')
            .orderBy('createdAt', descending: true)
            .snapshots();
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _exportToPdf(List<Map<String, String>> currentList) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preparing export... Please wait.")),
      );
      print("Exporting ${currentList.length} items");
      exportPaymentsToPdfWeb(currentList);
    } catch (e) {
      print("Export error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error exporting: $e")));
    }
  }

  void _showCreatePaymentDialog(BuildContext context) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController customBookingIdController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        String? selectedBookingId;
        bool isCustomBooking = false;
        String? selectedPaymentMode;
        String? selectedPaymentStatus;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text(
                'Create Payment',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 400,
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('bookings')
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    var docs = snapshot.data!.docs;

                    return SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Amount',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: amountController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              hintText: 'Enter amount',
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Booking Item',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    'Custom',
                                    style: GoogleFonts.inter(fontSize: 12),
                                  ),
                                  Switch(
                                    value: isCustomBooking,
                                    onChanged: (value) {
                                      setDialogState(() {
                                        isCustomBooking = value;
                                        if (value) {
                                          amountController.clear();
                                          selectedBookingId = null;
                                        } else {
                                          if (docs.isNotEmpty) {
                                            selectedBookingId = docs.first.id;
                                            var selectedData =
                                                docs.first.data()
                                                    as Map<String, dynamic>;
                                            amountController.text =
                                                selectedData['amount']
                                                    ?.toString() ??
                                                '';
                                          }
                                        }
                                      });
                                    },
                                    activeColor: const Color(0xFF10B981),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (!isCustomBooking)
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                isDense: true,
                              ),
                              value: selectedBookingId,
                              hint: const Text('Select Booking Item'),
                              items:
                                  docs.map<DropdownMenuItem<String>>((doc) {
                                    var data =
                                        doc.data() as Map<String, dynamic>;
                                    String id = doc.id;
                                    String serviceName =
                                        data['serviceName']?.toString() ??
                                        'Unknown Service';
                                    return DropdownMenuItem<String>(
                                      value: id,
                                      child: Text("$id - $serviceName"),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedBookingId = value;
                                  var selectedDoc = docs.firstWhere(
                                    (doc) => doc.id == value,
                                  );
                                  var selectedData =
                                      selectedDoc.data()
                                          as Map<String, dynamic>;
                                  amountController.text =
                                      selectedData['amount']?.toString() ?? '';
                                });
                              },
                            )
                          else
                            TextField(
                              controller: customBookingIdController,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                hintText: 'Enter custom booking ID',
                                isDense: true,
                              ),
                            ),
                          const SizedBox(height: 16),
                          Text(
                            'Payment Mode',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              isDense: true,
                            ),
                            value: selectedPaymentMode,
                            hint: const Text('Select Payment Mode'),
                            items:
                                ['UPI', 'Card', 'Cash', 'Bank Transfer']
                                    .map(
                                      (mode) => DropdownMenuItem(
                                        value: mode,
                                        child: Text(mode),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              setDialogState(() {
                                selectedPaymentMode = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Payment Status',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              isDense: true,
                            ),
                            value: selectedPaymentStatus,
                            hint: const Text('Select Payment Status'),
                            items:
                                ['Paid', 'Refund']
                                    .map(
                                      (status) => DropdownMenuItem(
                                        value: status,
                                        child: Text(status),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              setDialogState(() {
                                selectedPaymentStatus = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Date and Time',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: TextEditingController(
                              text: DateTime.now().toString().substring(0, 16),
                            ),
                            readOnly: true,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              isDense: true,
                              suffixIcon: const Icon(Icons.calendar_today),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    FirebaseFirestore.instance.collection('payments').add({
                      'transactionId':
                          '#TXN${_dateString}${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}',
                      'amount':
                          amountController.text.startsWith('₹')
                              ? amountController.text
                              : '₹${amountController.text}',
                      'bookingId':
                          isCustomBooking
                              ? customBookingIdController.text
                              : (selectedBookingId ?? ''),
                      'itemName':
                          isCustomBooking ? 'Custom Service' : 'Service',
                      'paymentMode': selectedPaymentMode ?? '',
                      'status': selectedPaymentStatus ?? '',
                      'dateTime': DateTime.now().toString().substring(0, 16),
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                  ),
                  child: Text(
                    'Create',
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHeaderCell(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF64748B),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _paymentsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          transactions =
              snapshot.data!.docs.map((doc) {
                var data = doc.data() as Map<String, dynamic>;
                return {
                  'transactionId': data['transactionId']?.toString() ?? '',
                  'itemName': data['itemName']?.toString() ?? '',
                  'amount': data['amount']?.toString() ?? '',
                  'bookingId': data['bookingId']?.toString() ?? '',
                  'paymentMode': data['paymentMode']?.toString() ?? '',
                  'status': data['status']?.toString() ?? '',
                  'dateTime': data['dateTime']?.toString() ?? '',
                };
              }).toList();
        }

        return Scrollbar(
          controller: _verticalScrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _verticalScrollController,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter and Create Payment Buttons Top Right
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // LEFT SIDE: Search Field
                      SizedBox(
                        width: 350,
                        height: 38,
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              _filterBookingId = value.trim();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search Booking ID...',
                            prefixIcon: const Icon(Icons.search, size: 18),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 16,
                            ),
                          ),
                        ),
                      ),
                      // RIGHT SIDE: Export, Filter, Create Payment
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _exportToPdf(filteredTransactions),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              setState(() {
                                _filterStatus = value;
                              });
                            },
                            offset: const Offset(0, 40),
                            itemBuilder:
                                (context) => [
                                  const PopupMenuItem(
                                    value: 'All',
                                    child: Text('All'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'Paid',
                                    child: Text('Paid'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'Unpaid',
                                    child: Text('Unpaid'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'Refund',
                                    child: Text('Refund'),
                                  ),
                                ],
                            child: Container(
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.filter_list,
                                    size: 18,
                                    color: Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _filterStatus == 'All'
                                        ? 'Filter'
                                        : _filterStatus,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF475569),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    size: 18,
                                    color: Color(0xFF64748B),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            icon: const Icon(
                              Icons.add,
                              size: 18,
                              color: Colors.white,
                            ),
                            label: Text(
                              'Create Payment',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            onPressed: () => _showCreatePaymentDialog(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Transaction Table
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Scrollbar(
                          controller: _horizontalScrollController,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: _horizontalScrollController,
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width:
                                  1200, // Fixed width to enable horizontal scrolling
                              child: Table(
                                columnWidths: const {
                                  0: FlexColumnWidth(0.7), // No.
                                  1: FlexColumnWidth(1.8), // Transaction ID
                                  2: FlexColumnWidth(1.5), // Item Name
                                  3: FlexColumnWidth(1.0), // Amount
                                  4: FlexColumnWidth(1.2), // Booking ID
                                  5: FlexColumnWidth(1.2), // Payment Mode
                                  6: FlexColumnWidth(1.0), // Status
                                  7: FlexColumnWidth(1.8), // Date & Time
                                },
                                defaultVerticalAlignment:
                                    TableCellVerticalAlignment.middle,
                                children: [
                                  // Header Row
                                  TableRow(
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF8FAFC),
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Color(0xFFE2E8F0),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    children: [
                                      _buildHeaderCell("No."),
                                      _buildHeaderCell("Transaction ID"),
                                      _buildHeaderCell("Item Name"),
                                      _buildHeaderCell("Amount"),
                                      _buildHeaderCell("Booking ID"),
                                      _buildHeaderCell("Payment Mode"),
                                      _buildHeaderCell("Status"),
                                      _buildHeaderCell("Date&Time"),
                                    ],
                                  ),

                                  // Data Rows
                                  ...filteredTransactions.asMap().entries.map((
                                    entry,
                                  ) {
                                    int index = entry.key;
                                    var tx = entry.value;
                                    return TableRow(
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Color(0xFFF1F5F9),
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12.0,
                                            horizontal: 16.0,
                                          ),
                                          child: Text(
                                            (index + 1).toString(),
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: const Color(0xFF475569),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12.0,
                                            horizontal: 16.0,
                                          ),
                                          child: Text(
                                            tx['transactionId']!,
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: const Color(0xFF475569),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12.0,
                                            horizontal: 16.0,
                                          ),
                                          child: Text(
                                            tx['itemName']!,
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: const Color(0xFF475569),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12.0,
                                            horizontal: 16.0,
                                          ),
                                          child: Text(
                                            tx['amount']!,
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: const Color(0xFF475569),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12.0,
                                            horizontal: 16.0,
                                          ),
                                          child: Text(
                                            tx['bookingId']!,
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: const Color(0xFF475569),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12.0,
                                            horizontal: 16.0,
                                          ),
                                          child: Text(
                                            tx['paymentMode']!,
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: const Color(0xFF475569),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12.0,
                                            horizontal: 16.0,
                                          ),
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFF10B981,
                                                ).withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    width: 6,
                                                    height: 6,
                                                    decoration:
                                                        const BoxDecoration(
                                                          color: Color(
                                                            0xFF10B981,
                                                          ),
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    tx['status']!,
                                                    style: GoogleFonts.inter(
                                                      color: const Color(
                                                        0xFF10B981,
                                                      ),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12.0,
                                            horizontal: 16.0,
                                          ),
                                          child: Text(
                                            tx['dateTime']!,
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: const Color(0xFF475569),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Pagination Footer Stub
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Showing 1 to ${filteredTransactions.length} of ${filteredTransactions.length} transactions",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              // Stub pagination controls matching the exact screenshot design
                              Row(
                                children: [
                                  const Icon(
                                    Icons.chevron_left,
                                    color: Color(0xFF94A3B8),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      "1",
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Color(0xFF94A3B8),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          "10 / page",
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: const Color(0xFF475569),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.arrow_drop_down,
                                          color: Color(0xFF475569),
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
