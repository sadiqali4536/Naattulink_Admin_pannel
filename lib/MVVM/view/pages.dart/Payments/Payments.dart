import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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
  DateTime? _filterDate;

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
      final matchesDate =
          _filterDate == null ||
          tx['date'] ==
              DateFormat('dd/MM/yyyy').format(_filterDate!).toLowerCase();

      return matchesStatus && matchesBookingId && matchesDate;
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

    InputDecoration buildInputDecoration(String hint, {Widget? suffixIcon}) {
      return InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          color: const Color(0xFF94A3B8),
          fontSize: 13,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
        ),
        suffixIcon: suffixIcon,
      );
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        String? selectedBookingId;
        bool isCustomBooking = false;
        String? selectedPaymentMode;
        String? selectedPaymentStatus;
        DateTime selectedDateTime = DateTime.now();
        String selectedBookingImage = '';
        String selectedServiceName = 'Service';

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              titlePadding: EdgeInsets.zero,
              title: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.payment_rounded,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Create Payment',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              contentPadding: const EdgeInsets.all(24),
              content: SizedBox(
                width: 450,
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('service_bookings')
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                            color: Color(0xFF10B981),
                          ),
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
                              color: const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: amountController,
                            decoration: buildInputDecoration(
                              'Enter amount',
                              suffixIcon: const Icon(
                                Icons.currency_rupee,
                                color: Color(0xFF94A3B8),
                                size: 18,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.inter(fontSize: 14),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Booking Item',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    'Custom',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Switch(
                                    value: isCustomBooking,
                                    onChanged: (value) {
                                      setDialogState(() {
                                        isCustomBooking = value;
                                        if (value) {
                                          selectedBookingId = null;
                                          selectedBookingImage = '';
                                        } else {
                                          if (docs.isNotEmpty) {
                                            selectedBookingId = docs.first.id;
                                            var selectedData =
                                                docs.first.data()
                                                    as Map<String, dynamic>;
                                            String newAmount =
                                                selectedData['amount']
                                                    ?.toString() ??
                                                '';
                                            if (newAmount.isNotEmpty) {
                                              amountController.text = newAmount;
                                            }
                                            selectedBookingImage =
                                                selectedData['serviceImage']
                                                    ?.toString() ??
                                                selectedData['imageUrl']
                                                    ?.toString() ??
                                                selectedData['image']
                                                    ?.toString() ??
                                                '';
                                            selectedServiceName =
                                                selectedData['serviceName']
                                                    ?.toString() ??
                                                'Service';
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
                          const SizedBox(height: 8),
                          if (!isCustomBooking)
                            DropdownButtonFormField<String>(
                              decoration: buildInputDecoration(
                                'Select Booking Item',
                              ),
                              value: selectedBookingId,
                              dropdownColor: Colors.white,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Color(0xFF94A3B8),
                              ),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: const Color(0xFF0F172A),
                              ),
                              items:
                                  docs.map<DropdownMenuItem<String>>((doc) {
                                    var data =
                                        doc.data() as Map<String, dynamic>;
                                    String id = doc.id;
                                    String serviceName =
                                        data['serviceName']?.toString() ??
                                        'Unknown Service';
                                    String imageUrl =
                                        data['serviceImage']?.toString() ??
                                        data['imageUrl']?.toString() ??
                                        data['image']?.toString() ??
                                        '';
                                    return DropdownMenuItem<String>(
                                      value: id,
                                      child: Row(
                                        children: [
                                          if (imageUrl.isNotEmpty) ...[
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              child: Image.network(
                                                imageUrl,
                                                width: 24,
                                                height: 24,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (c, e, s) => const Icon(
                                                      Icons.image_not_supported,
                                                      size: 24,
                                                      color: Colors.grey,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          Text("$id - $serviceName"),
                                        ],
                                      ),
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
                                  String newAmount =
                                      selectedData['amount']?.toString() ?? '';
                                  if (newAmount.isNotEmpty) {
                                    amountController.text = newAmount;
                                  }
                                  selectedBookingImage =
                                      selectedData['serviceImage']
                                          ?.toString() ??
                                      selectedData['imageUrl']?.toString() ??
                                      selectedData['image']?.toString() ??
                                      '';
                                  selectedServiceName =
                                      selectedData['serviceName']?.toString() ??
                                      'Service';
                                });
                              },
                            )
                          else
                            TextField(
                              controller: customBookingIdController,
                              decoration: buildInputDecoration(
                                'Enter custom booking ID',
                              ),
                              style: GoogleFonts.inter(fontSize: 14),
                            ),
                          const SizedBox(height: 20),
                          Text(
                            'Payment Mode',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            decoration: buildInputDecoration(
                              'Select Payment Mode',
                            ),
                            value: selectedPaymentMode,
                            dropdownColor: Colors.white,
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF94A3B8),
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF0F172A),
                            ),
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
                          const SizedBox(height: 20),
                          Text(
                            'Payment Status',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            decoration: buildInputDecoration(
                              'Select Payment Status',
                            ),
                            value: selectedPaymentStatus,
                            dropdownColor: Colors.white,
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF94A3B8),
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF0F172A),
                            ),
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
                          const SizedBox(height: 20),
                          Text(
                            'Date and Time',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedDateTime,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: Color(0xFF10B981),
                                        onPrimary: Colors.white,
                                        onSurface: Colors.black,
                                        surface: Colors.white,
                                      ),
                                      dialogBackgroundColor: Colors.white,
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (date != null) {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.fromDateTime(
                                    selectedDateTime,
                                  ),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.light(
                                          primary: Color(0xFF10B981),
                                          onPrimary: Colors.white,
                                          onSurface: Colors.black,
                                          surface: Colors.white,
                                        ),
                                        dialogBackgroundColor: Colors.white,
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (time != null) {
                                  setDialogState(() {
                                    selectedDateTime = DateTime(
                                      date.year,
                                      date.month,
                                      date.day,
                                      time.hour,
                                      time.minute,
                                    );
                                  });
                                }
                              }
                            },
                            child: IgnorePointer(
                              child: TextField(
                                controller: TextEditingController(
                                  text: DateFormat(
                                    'dd MMM yyyy, hh:mm a',
                                  ).format(selectedDateTime),
                                ),
                                readOnly: true,
                                decoration: buildInputDecoration(
                                  '',
                                  suffixIcon: const Icon(
                                    Icons.calendar_today_rounded,
                                    color: Color(0xFF10B981),
                                    size: 18,
                                  ),
                                ),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
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
                          isCustomBooking
                              ? 'Custom Service'
                              : selectedServiceName,
                      'imageUrl': isCustomBooking ? '' : selectedBookingImage,
                      'paymentMode': selectedPaymentMode ?? '',
                      'status': selectedPaymentStatus ?? '',
                      'dateTime': selectedDateTime.toString().substring(0, 16),
                      'createdAt': Timestamp.fromDate(selectedDateTime),
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Create Payment',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
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
          return const Center(
            child: CircularProgressIndicator(color: const Color(0xFFFFC107)),
          );
        }
        double totalAmount = 0.0;
        double paidAmount = 0.0;
        double refundedAmount = 0.0;
        int totalCount = 0;
        int paidCount = 0;
        int refundedCount = 0;

        if (snapshot.hasData) {
          transactions =
              snapshot.data!.docs.map((doc) {
                var data = doc.data() as Map<String, dynamic>;
                final String amtStr = data['amount']?.toString() ?? '0';
                final double amt =
                    double.tryParse(
                      amtStr.replaceAll(RegExp(r'[^0-9.]'), ''),
                    ) ??
                    0.0;
                final String status =
                    data['status']?.toString().toLowerCase() ?? '';

                totalAmount += amt;
                totalCount++;

                if (status == 'paid') {
                  paidAmount += amt;
                  paidCount++;
                } else if (status == 'refund') {
                  refundedAmount += amt;
                  refundedCount++;
                }
                String formattedDate = '';
                String formattedTime = '';
                if (data['createdAt'] is Timestamp) {
                  final dt = (data['createdAt'] as Timestamp).toDate();
                  formattedDate =
                      DateFormat('dd/MM/yyyy').format(dt).toLowerCase();
                  formattedTime =
                      DateFormat('hh:mma\nEEEE').format(dt).toLowerCase();
                } else if (data['dateTime'] != null) {
                  formattedDate = data['dateTime'].toString();
                }

                return {
                  'transactionId': data['transactionId']?.toString() ?? '',
                  'itemName': data['itemName']?.toString() ?? '',
                  'amount': data['amount']?.toString() ?? '',
                  'bookingId': data['bookingId']?.toString() ?? '',
                  'paymentMode': data['paymentMode']?.toString() ?? '',
                  'status': data['status']?.toString() ?? '',
                  'date': formattedDate,
                  'time': formattedTime,
                  'imageUrl': data['imageUrl']?.toString() ?? '',
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
                  // Page Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Payments Management',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
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
                  const SizedBox(height: 24),

                  // Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Payments',
                          totalCount.toString(),
                          Icons.receipt_long,
                          const Color(0xFF3B82F6),
                          amount: "₹${totalAmount.toStringAsFixed(0)}",
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Paid',
                          paidCount.toString(),
                          Icons.check_circle_outline,
                          const Color(0xFF10B981),
                          amount: "₹${paidAmount.toStringAsFixed(0)}",
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Refunded',
                          refundedCount.toString(),
                          Icons.refresh,
                          const Color(0xFFF59E0B),
                          amount: "₹${refundedAmount.toStringAsFixed(0)}",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Filter and Create Payment Buttons Top Right
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
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
                            InkWell(
                              onTap: () async {
                                final selected = await showDatePicker(
                                  context: context,
                                  initialDate: _filterDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.light(
                                          primary: Color(0xFFFFC107),
                                          onPrimary: Colors.white,
                                          onSurface: Colors.black,
                                          surface: Colors.white,
                                        ),
                                        dialogBackgroundColor: Colors.white,
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (selected != null) {
                                  setState(() => _filterDate = selected);
                                }
                              },
                              child: Container(
                                height: 38,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color:
                                          _filterDate != null
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _filterDate != null
                                          ? DateFormat(
                                            'dd/MM/yyyy',
                                          ).format(_filterDate!)
                                          : 'Select Date',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: const Color(0xFF475569),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (_filterDate != null) ...[
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() => _filterDate = null);
                                        },
                                        child: const Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),
                            PopupMenuButton<String>(
                              color: Colors.white,
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
                              onPressed:
                                  () => _exportToPdf(filteredTransactions),
                              icon: const Icon(
                                Icons.download_rounded,
                                size: 14,
                              ),
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
                                side: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

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
                                  1400, // Fixed width to enable horizontal scrolling
                              child: Table(
                                columnWidths: const {
                                  0: FlexColumnWidth(0.7), // No.
                                  1: FlexColumnWidth(1.8), // Transaction ID
                                  2: FlexColumnWidth(1.5), // Item Name
                                  3: FlexColumnWidth(1.0), // Amount
                                  4: FlexColumnWidth(1.2), // Booking ID
                                  5: FlexColumnWidth(1.2), // Payment Mode
                                  6: FlexColumnWidth(1.0), // Status
                                  7: FlexColumnWidth(1.2), // Date
                                  8: FlexColumnWidth(1.2), // Time
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
                                      _buildHeaderCell("Date"),
                                      _buildHeaderCell("Time"),
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
                                          child: Row(
                                            children: [
                                              if (tx['imageUrl'] != null &&
                                                  tx['imageUrl']!
                                                      .isNotEmpty) ...[
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  child: Image.network(
                                                    tx['imageUrl']!,
                                                    width: 24,
                                                    height: 24,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (c, e, s) => const Icon(
                                                          Icons
                                                              .image_not_supported,
                                                          size: 24,
                                                          color: Colors.grey,
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                              ],
                                              Expanded(
                                                child: Text(
                                                  tx['itemName']!,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 13,
                                                    color: const Color(
                                                      0xFF475569,
                                                    ),
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                                            child: Builder(
                                              builder: (context) {
                                                final st = tx['status']!;
                                                final stColor =
                                                    st.toLowerCase() == 'refund'
                                                        ? const Color(
                                                          0xFFF59E0B,
                                                        ) // Orange
                                                        : st.toLowerCase() ==
                                                            'unpaid'
                                                        ? const Color(
                                                          0xFFEF4444,
                                                        ) // Red
                                                        : const Color(
                                                          0xFF10B981,
                                                        ); // Green

                                                return Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: stColor.withValues(
                                                      alpha: 0.1,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        width: 6,
                                                        height: 6,
                                                        decoration:
                                                            BoxDecoration(
                                                              color: stColor,
                                                              shape:
                                                                  BoxShape
                                                                      .circle,
                                                            ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        st,
                                                        style:
                                                            GoogleFonts.inter(
                                                              color: stColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 12,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12.0,
                                            horizontal: 16.0,
                                          ),
                                          child: Text(
                                            tx['date']!,
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
                                            tx['time']!,
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

  Widget _buildStatCard(
    String title,
    String count,
    IconData icon,
    Color color, {
    String? amount,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
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
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                count,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              if (amount != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    amount,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
