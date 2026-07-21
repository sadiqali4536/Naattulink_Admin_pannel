import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BookingModel {
  final String id;
  final String date;
  final String customerName;
  final String customerPhone;
  final String customerAvatarUrl;
  final String workerName;
  final String workerPhone;
  final String workerAvatarUrl;
  final String serviceName;
  final String serviceDetails;
  final String category;
  final String dateTime;
  final double amount;
  final String paymentStatus;
  final String paymentMethod;
  final String status;

  BookingModel({
    required this.id,
    required this.date,
    required this.customerName,
    required this.customerPhone,
    required this.customerAvatarUrl,
    required this.workerName,
    required this.workerPhone,
    required this.workerAvatarUrl,
    required this.serviceName,
    required this.serviceDetails,
    required this.category,
    required this.dateTime,
    required this.amount,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.status,
  });
}

class Bookings extends StatefulWidget {
  final String initialFilter;
  final ValueChanged<String>? onTabChanged;

  const Bookings({super.key, this.initialFilter = "All", this.onTabChanged});

  @override
  State<Bookings> createState() => _BookingsState();
}

class _BookingsState extends State<Bookings> {
  late int _selectedTabIndex;
  String _searchQuery = "";
  String _selectedCategory = "All Categories";
  String _selectedStatus = "All Status";
  String _selectedPaymentStatus = "All Payment Status";
  String _selectedDate = "Select Date";

  final List<BookingModel> _bookings = [
    BookingModel(
      id: "#BK-5689",
      date: "May 19, 2024",
      customerName: "Ajay Dev",
      customerPhone: "+91 98765 43230",
      customerAvatarUrl: "https://randomuser.me/api/portraits/men/20.jpg",
      workerName: "Arun Kumar",
      workerPhone: "+91 98765 43210",
      workerAvatarUrl: "https://randomuser.me/api/portraits/men/1.jpg",
      serviceName: "Home Cleaning",
      serviceDetails: "Sofa Cleaning",
      category: "Home Cleaning",
      dateTime: "May 19, 2024\n09:00 AM",
      amount: 499.0,
      paymentStatus: "Pending",
      paymentMethod: "UPI",
      status: "Pending",
    ),
    BookingModel(
      id: "#BK-5688",
      date: "May 19, 2024",
      customerName: "Sanya Gupta",
      customerPhone: "+91 98765 43231",
      customerAvatarUrl: "https://randomuser.me/api/portraits/women/20.jpg",
      workerName: "Maya Sen",
      workerPhone: "+91 98765 43233",
      workerAvatarUrl: "https://randomuser.me/api/portraits/women/2.jpg",
      serviceName: "Pet Grooming",
      serviceDetails: "Dog Wash",
      category: "Pet Grooming",
      dateTime: "May 19, 2024\n11:00 AM",
      amount: 699.0,
      paymentStatus: "Pending",
      paymentMethod: "Card",
      status: "Pending",
    ),
    BookingModel(
      id: "#BK-5687",
      date: "May 18, 2024",
      customerName: "Rohit Sharma",
      customerPhone: "+91 98765 43210",
      customerAvatarUrl: "https://randomuser.me/api/portraits/men/32.jpg",
      workerName: "Arun Kumar",
      workerPhone: "+91 98765 43210",
      workerAvatarUrl: "https://randomuser.me/api/portraits/men/1.jpg",
      serviceName: "Home Cleaning",
      serviceDetails: "3 BHK • Deep Cleaning",
      category: "Home Cleaning",
      dateTime: "May 18, 2024\n10:00 AM",
      amount: 1499.0,
      paymentStatus: "Paid",
      paymentMethod: "UPI",
      status: "Confirmed",
    ),
    BookingModel(
      id: "#BK-5686",
      date: "May 18, 2024",
      customerName: "Priya Nair",
      customerPhone: "+91 98765 43211",
      customerAvatarUrl: "https://randomuser.me/api/portraits/women/44.jpg",
      workerName: "Maya Sen",
      workerPhone: "+91 98765 43233",
      workerAvatarUrl: "https://randomuser.me/api/portraits/women/2.jpg",
      serviceName: "Pet Grooming",
      serviceDetails: "Pet Bath • Hair Cut",
      category: "Pet Grooming",
      dateTime: "May 18, 2024\n02:00 PM",
      amount: 899.0,
      paymentStatus: "Paid",
      paymentMethod: "Card",
      status: "Confirmed",
    ),
    BookingModel(
      id: "#BK-5685",
      date: "May 17, 2024",
      customerName: "Suresh Babu",
      customerPhone: "+91 98765 43212",
      customerAvatarUrl: "https://randomuser.me/api/portraits/men/15.jpg",
      workerName: "Vikram Singh",
      workerPhone: "+91 98765 43214",
      workerAvatarUrl: "https://randomuser.me/api/portraits/men/12.jpg",
      serviceName: "Garden Services",
      serviceDetails: "Lawn Mowing • Trimming",
      category: "Garden Services",
      dateTime: "May 17, 2024\n11:30 AM",
      amount: 1199.0,
      paymentStatus: "Paid",
      paymentMethod: "UPI",
      status: "Completed",
    ),
    BookingModel(
      id: "#BK-5684",
      date: "May 17, 2024",
      customerName: "Neha Patel",
      customerPhone: "+91 98765 43213",
      customerAvatarUrl: "https://randomuser.me/api/portraits/women/10.jpg",
      workerName: "Pooja Sharma",
      workerPhone: "+91 98765 43245",
      workerAvatarUrl: "https://randomuser.me/api/portraits/women/15.jpg",
      serviceName: "Room Cleaning",
      serviceDetails: "1 Room • Standard",
      category: "Room Cleaning",
      dateTime: "May 17, 2024\n03:00 PM",
      amount: 699.0,
      paymentStatus: "Failed",
      paymentMethod: "Card",
      status: "Cancelled",
    ),
    BookingModel(
      id: "#BK-5683",
      date: "May 16, 2024",
      customerName: "Amit Verma",
      customerPhone: "+91 98765 43214",
      customerAvatarUrl: "https://randomuser.me/api/portraits/men/33.jpg",
      workerName: "Ramesh K",
      workerPhone: "+91 98765 43215",
      workerAvatarUrl: "https://randomuser.me/api/portraits/men/16.jpg",
      serviceName: "Vehicle Cleaning",
      serviceDetails: "Exterior • Premium",
      category: "Vehicle Cleaning",
      dateTime: "May 16, 2024\n09:00 AM",
      amount: 1299.0,
      paymentStatus: "Paid",
      paymentMethod: "Wallet",
      status: "Completed",
    ),
    BookingModel(
      id: "#BK-5682",
      date: "May 15, 2024",
      customerName: "Kavya Menon",
      customerPhone: "+91 98765 43215",
      customerAvatarUrl: "https://randomuser.me/api/portraits/women/3.jpg",
      workerName: "Arun Kumar",
      workerPhone: "+91 98765 43210",
      workerAvatarUrl: "https://randomuser.me/api/portraits/men/1.jpg",
      serviceName: "Interior Cleaning",
      serviceDetails: "Sofa • Carpet • Floor",
      category: "Interior Cleaning",
      dateTime: "May 15, 2024\n01:00 PM",
      amount: 1799.0,
      paymentStatus: "Paid",
      paymentMethod: "UPI",
      status: "Confirmed",
    ),
    BookingModel(
      id: "#BK-5681",
      date: "May 15, 2024",
      customerName: "Manoj Kumar",
      customerPhone: "+91 98765 43216",
      customerAvatarUrl: "https://randomuser.me/api/portraits/men/4.jpg",
      workerName: "Anjali Sharma",
      workerPhone: "+91 98765 43216",
      workerAvatarUrl: "https://randomuser.me/api/portraits/women/5.jpg",
      serviceName: "Home Cleaning",
      serviceDetails: "2 BHK • Standard",
      category: "Home Cleaning",
      dateTime: "May 15, 2024\n10:00 AM",
      amount: 1199.0,
      paymentStatus: "Paid",
      paymentMethod: "Card",
      status: "Completed",
    ),
    BookingModel(
      id: "#BK-5680",
      date: "May 14, 2024",
      customerName: "Deepak Singh",
      customerPhone: "+91 98765 43217",
      customerAvatarUrl: "https://randomuser.me/api/portraits/men/5.jpg",
      workerName: "Manoj Verma",
      workerPhone: "+91 98765 43217",
      workerAvatarUrl: "https://randomuser.me/api/portraits/men/8.jpg",
      serviceName: "Garden Services",
      serviceDetails: "Plant Care • Watering",
      category: "Garden Services",
      dateTime: "May 14, 2024\n04:00 PM",
      amount: 599.0,
      paymentStatus: "Paid",
      paymentMethod: "Cash",
      status: "Completed",
    ),
    BookingModel(
      id: "#BK-5679",
      date: "May 14, 2024",
      customerName: "Sneha Reddy",
      customerPhone: "+91 98765 43218",
      customerAvatarUrl: "https://randomuser.me/api/portraits/women/6.jpg",
      workerName: "Meena Devi",
      workerPhone: "+91 98765 43213",
      workerAvatarUrl: "https://randomuser.me/api/portraits/women/15.jpg",
      serviceName: "Pet Grooming",
      serviceDetails: "Nail Cut • Spa",
      category: "Pet Grooming",
      dateTime: "May 14, 2024\n12:30 PM",
      amount: 749.0,
      paymentStatus: "Paid",
      paymentMethod: "UPI",
      status: "Confirmed",
    ),
    BookingModel(
      id: "#BK-5678",
      date: "May 13, 2024",
      customerName: "Vivek Joshi",
      customerPhone: "+91 98765 43219",
      customerAvatarUrl: "https://randomuser.me/api/portraits/men/9.jpg",
      workerName: "Vikram Singh",
      workerPhone: "+91 98765 43214",
      workerAvatarUrl: "https://randomuser.me/api/portraits/men/12.jpg",
      serviceName: "Interior Cleaning",
      serviceDetails: "Kitchen • Bathroom",
      category: "Interior Cleaning",
      dateTime: "May 13, 2024\n11:00 AM",
      amount: 1499.0,
      paymentStatus: "Paid",
      paymentMethod: "Wallet",
      status: "Confirmed",
    ),
  ];

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _parseInitialFilter();
  }

  void _parseInitialFilter() {
    switch (widget.initialFilter) {
      case "Pending Bookings":
      case "Pending":
        _selectedTabIndex = 1;
        break;
      case "Confirmed Bookings":
      case "Confirmed":
        _selectedTabIndex = 2;
        break;
      case "Completed Bookings":
      case "Completed":
        _selectedTabIndex = 3;
        break;
      case "Cancelled Bookings":
      case "Cancelled":
        _selectedTabIndex = 4;
        break;
      case "All Bookings":
      case "All":
      default:
        _selectedTabIndex = 0;
        break;
    }
  }

  @override
  void didUpdateWidget(covariant Bookings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFilter != widget.initialFilter) {
      setState(() {
        _parseInitialFilter();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final bool isSmall = width < 950;

        // Filtering
        final filteredList =
            _bookings.where((booking) {
              // Tab selection filter
              if (_selectedTabIndex == 1 && booking.status != "Pending") {
                return false;
              }
              if (_selectedTabIndex == 2 && booking.status != "Confirmed") {
                return false;
              }
              if (_selectedTabIndex == 3 && booking.status != "Completed") {
                return false;
              }
              if (_selectedTabIndex == 4 && booking.status != "Cancelled") {
                return false;
              }

              // Dropdown / Search filters
              final matchesSearch =
                  booking.customerName.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  booking.workerName.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  booking.serviceName.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  booking.id.toLowerCase().contains(_searchQuery.toLowerCase());

              final matchesCategory =
                  _selectedCategory == "All Categories" ||
                  booking.category == _selectedCategory;
              final matchesStatus =
                  _selectedStatus == "All Status" ||
                  booking.status == _selectedStatus;
              final matchesPayment =
                  _selectedPaymentStatus == "All Payment Status" ||
                  booking.paymentStatus == _selectedPaymentStatus;

              return matchesSearch &&
                  matchesCategory &&
                  matchesStatus &&
                  matchesPayment;
            }).toList();

        return Scrollbar(
          controller: _verticalScrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _verticalScrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header & Breadcrumbs
                _buildHeaderAndBreadcrumbs(),
                const SizedBox(height: 24),

                // 5 Statistics Cards
                _buildStatsGrid(isSmall),
                const SizedBox(height: 24),

                // Filter Controls Card
                _buildFiltersCard(isSmall),
                const SizedBox(height: 20),

                // Tabs & Table Card
                _buildTableCard(filteredList, width),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderAndBreadcrumbs() {
    String subPath = "All Bookings";
    if (_selectedTabIndex == 1) subPath = "Pending Bookings";
    if (_selectedTabIndex == 2) subPath = "Confirmed Bookings";
    if (_selectedTabIndex == 3) subPath = "Completed Bookings";
    if (_selectedTabIndex == 4) subPath = "Cancelled Bookings";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Bookings",
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              "Dashboard",
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 14,
              color: Color(0xFF94A3B8),
            ),
            Text(
              "Bookings",
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 14,
              color: Color(0xFF94A3B8),
            ),
            Text(
              subPath,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid(bool isSmall) {
    int crossAxisCount = 5;
    if (isSmall) {
      crossAxisCount = 2;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double itemWidth =
            (constraints.maxWidth - (crossAxisCount - 1) * 16) / crossAxisCount;
        const double itemHeight = 115;
        final double aspectRatio = itemWidth / itemHeight;

        final cards = [
          _buildStatsCard(
            title: "Total Bookings",
            value: "1,568",
            subtitle: "All time bookings",
            icon: Icons.calendar_today_outlined,
            color: const Color(0xFF3B82F6),
            bgColor: const Color(0xFFEFF6FF),
          ),
          _buildStatsCard(
            title: "Pending Bookings",
            value: "18",
            subtitle: "Awaiting confirmation",
            icon: Icons.access_time_rounded,
            color: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFFEF3C7),
          ),
          _buildStatsCard(
            title: "Confirmed Bookings",
            value: "623",
            subtitle: "Upcoming bookings",
            icon: Icons.check_circle_outline_rounded,
            color: const Color(0xFF10B981),
            bgColor: const Color(0xFFECFDF5),
          ),
          _buildStatsCard(
            title: "Completed Bookings",
            value: "812",
            subtitle: "Successfully completed",
            icon: Icons.assignment_outlined,
            color: const Color(0xFF06B6D4),
            bgColor: const Color(0xFFECFEFF),
          ),
          _buildStatsCard(
            title: "Cancelled Bookings",
            value: "115",
            subtitle: "Cancelled by user/admin",
            icon: Icons.cancel_outlined,
            color: const Color(0xFFEF4444),
            bgColor: const Color(0xFFFEF2F2),
          ),
        ];

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: aspectRatio,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: cards,
        );
      },
    );
  }

  Widget _buildStatsCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: const Color(0xFF94A3B8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersCard(bool isSmall) {
    final searchField = SizedBox(
      width: isSmall ? double.infinity : 240,
      height: 38,
      child: TextFormField(
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          fillColor: Colors.white,
          filled: true,
          hintText: "Search by customer, worker, service...",
          hintStyle: GoogleFonts.inter(
            color: const Color(0xFF94A3B8),
            fontSize: 12,
          ),
          prefixIcon: const Icon(
            CupertinoIcons.search,
            color: Color(0xFF94A3B8),
            size: 16,
          ),
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        style: GoogleFonts.inter(color: const Color(0xFF1E293B), fontSize: 12),
      ),
    );

    final dateDropdown = SizedBox(
      width: isSmall ? double.infinity : 130,
      height: 38,
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: _selectedDate,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          fillColor: Colors.white,
          filled: true,
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        style: GoogleFonts.inter(color: const Color(0xFF1E293B), fontSize: 12),
        items: const [
          DropdownMenuItem(
            value: "Select Date",
            child: Text(
              "Select Date",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        onChanged: (val) => setState(() => _selectedDate = val!),
      ),
    );

    final statusDropdown = SizedBox(
      width: isSmall ? double.infinity : 130,
      height: 38,
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: _selectedStatus,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          fillColor: Colors.white,
          filled: true,
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        style: GoogleFonts.inter(color: const Color(0xFF1E293B), fontSize: 12),
        items:
            ["All Status", "Pending", "Confirmed", "Completed", "Cancelled"]
                .map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Text(
                      status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
        onChanged: (val) => setState(() => _selectedStatus = val!),
      ),
    );

    final categoryDropdown = SizedBox(
      width: isSmall ? double.infinity : 160,
      height: 38,
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: _selectedCategory,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          fillColor: Colors.white,
          filled: true,
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        style: GoogleFonts.inter(color: const Color(0xFF1E293B), fontSize: 12),
        items:
            [
                  "All Categories",
                  "Home Cleaning",
                  "Pet Grooming",
                  "Garden Services",
                  "Room Cleaning",
                  "Vehicle Cleaning",
                  "Interior Cleaning",
                ]
                .map(
                  (cat) => DropdownMenuItem(
                    value: cat,
                    child: Text(
                      cat,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
        onChanged: (val) => setState(() => _selectedCategory = val!),
      ),
    );

    final paymentDropdown = SizedBox(
      width: isSmall ? double.infinity : 170,
      height: 38,
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: _selectedPaymentStatus,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          fillColor: Colors.white,
          filled: true,
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        style: GoogleFonts.inter(color: const Color(0xFF1E293B), fontSize: 12),
        items:
            ["All Payment Status", "Paid", "Pending", "Failed"]
                .map(
                  (p) => DropdownMenuItem(
                    value: p,
                    child: Text(
                      p,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
        onChanged: (val) => setState(() => _selectedPaymentStatus = val!),
      ),
    );

    final filterButton = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: IconButton(
        icon: const Icon(
          Icons.filter_list_rounded,
          size: 18,
          color: Color(0xFF64748B),
        ),
        onPressed: () {},
      ),
    );

    final exportButton = ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.download_rounded, size: 14),
      label: Text(
        "Export",
        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF475569),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );

    if (isSmall) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          searchField,
          const SizedBox(height: 12),
          dateDropdown,
          const SizedBox(height: 12),
          statusDropdown,
          const SizedBox(height: 12),
          categoryDropdown,
          const SizedBox(height: 12),
          paymentDropdown,
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [filterButton, const SizedBox(width: 12), exportButton],
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          searchField,
          const SizedBox(width: 12),
          dateDropdown,
          const SizedBox(width: 12),
          statusDropdown,
          const SizedBox(width: 12),
          categoryDropdown,
          const SizedBox(width: 12),
          paymentDropdown,
          const Spacer(),
          filterButton,
          const SizedBox(width: 12),
          exportButton,
        ],
      ),
    );
  }

  Widget _buildTableCard(List<BookingModel> bookings, double screenWidth) {
    final tabs = [
      {"label": "All Bookings", "count": 1568},
      {"label": "Pending Bookings", "count": 18},
      {"label": "Confirmed Bookings", "count": 623},
      {"label": "Completed Bookings", "count": 812},
      {"label": "Cancelled Bookings", "count": 115},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Custom Tab Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(tabs.length, (index) {
                  final tab = tabs[index];
                  final bool isSelected = index == _selectedTabIndex;
                  final String label = tab["label"] as String;
                  final int count = tab["count"] as int;

                  return InkWell(
                    onTap: () {
                      setState(() => _selectedTabIndex = index);
                      if (widget.onTabChanged != null) {
                        String tabName;
                        switch (index) {
                          case 1:
                            tabName = "Pending Bookings";
                            break;
                          case 2:
                            tabName = "Confirmed Bookings";
                            break;
                          case 3:
                            tabName = "Completed Bookings";
                            break;
                          case 4:
                            tabName = "Cancelled Bookings";
                            break;
                          case 0:
                          default:
                            tabName = "All Bookings";
                            break;
                        }
                        widget.onTabChanged!(tabName);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color:
                                isSelected
                                    ? const Color(0xFF10B981)
                                    : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            label,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                              color:
                                  isSelected
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? const Color(0xFFD1FAE5)
                                      : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              count.toString(),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color:
                                    isSelected
                                        ? const Color(0xFF047857)
                                        : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // Scrollable Data Table
          Scrollbar(
            controller: _horizontalScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _horizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1400,
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1.2), // Booking ID
                    1: FlexColumnWidth(2.0), // Customer
                    2: FlexColumnWidth(2.0), // Worker
                    3: FlexColumnWidth(2.2), // Service
                    4: FlexColumnWidth(1.8), // Date & Time
                    5: FlexColumnWidth(1.2), // Amount
                    6: FlexColumnWidth(1.3), // Payment
                    7: FlexColumnWidth(1.3), // Status
                    8: FlexColumnWidth(1.8), // Actions
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    // Table Header
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
                        _buildHeaderCell("Booking ID"),
                        _buildHeaderCell("Customer"),
                        _buildHeaderCell("Worker"),
                        _buildHeaderCell("Service"),
                        _buildHeaderCell("Booking Date & Time"),
                        _buildHeaderCell("Amount"),
                        _buildHeaderCell("Payment"),
                        _buildHeaderCell("Status"),
                        _buildHeaderCell("Actions"),
                      ],
                    ),

                    // Table Rows
                    ...bookings.map((booking) {
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
                          // Booking ID & Date
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12.0,
                              horizontal: 16.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking.id,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  booking.date,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Customer Details
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12.0,
                              horizontal: 16.0,
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    booking.customerAvatarUrl,
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 32,
                                        height: 32,
                                        color: const Color(0xFFE2E8F0),
                                        child: const Icon(
                                          Icons.person,
                                          color: Color(0xFF64748B),
                                          size: 16,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        booking.customerName,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1E293B),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        booking.customerPhone,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: const Color(0xFF64748B),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Worker Details
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12.0,
                              horizontal: 16.0,
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    booking.workerAvatarUrl,
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 32,
                                        height: 32,
                                        color: const Color(0xFFE2E8F0),
                                        child: const Icon(
                                          Icons.person,
                                          color: Color(0xFF64748B),
                                          size: 16,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        booking.workerName,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1E293B),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        booking.workerPhone,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: const Color(0xFF64748B),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Service Details
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12.0,
                              horizontal: 16.0,
                            ),
                            child: _buildServiceCell(
                              booking.category,
                              booking.serviceDetails,
                            ),
                          ),

                          // Booking Date & Time
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12.0,
                              horizontal: 16.0,
                            ),
                            child: Text(
                              booking.dateTime,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF475569),
                                height: 1.3,
                              ),
                            ),
                          ),

                          // Amount Cell
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12.0,
                              horizontal: 16.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "₹${booking.amount.toStringAsFixed(0)}",
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "1 Item",
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Payment Cell
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12.0,
                              horizontal: 16.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildPaymentStatusIndicator(
                                  booking.paymentStatus,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  booking.paymentMethod,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Status Cell
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12.0,
                              horizontal: 16.0,
                            ),
                            child: _buildStatusBadge(booking.status),
                          ),

                          // Actions Cell
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12.0,
                              horizontal: 4.0,
                            ),
                            child: Row(
                              children: [
                                _buildActionButton(
                                  Icons.visibility_outlined,
                                  Colors.blue,
                                  () {},
                                ),
                                const SizedBox(width: 4),
                                _buildActionButton(
                                  Icons.edit_outlined,
                                  Colors.blue,
                                  () {},
                                ),
                                const SizedBox(width: 4),
                                _buildActionButton(
                                  Icons.more_vert_rounded,
                                  Colors.grey,
                                  () {},
                                ),
                              ],
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

          // Pagination Footer
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildTableFooter(bookings.length),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _buildServiceCell(String category, String details) {
    IconData icon;
    Color color;
    Color bgColor;

    switch (category) {
      case "Home Cleaning":
      case "Room Cleaning":
        icon = Icons.home_repair_service_rounded;
        color = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFEF3C7);
        break;
      case "Pet Grooming":
        icon = Icons.pets_rounded;
        color = const Color(0xFF8B5CF6);
        bgColor = const Color(0xFFF5F3FF);
        break;
      case "Garden Services":
        icon = Icons.local_florist_rounded;
        color = const Color(0xFF10B981);
        bgColor = const Color(0xFFECFDF5);
        break;
      case "Vehicle Cleaning":
        icon = Icons.directions_car_rounded;
        color = const Color(0xFF3B82F6);
        bgColor = const Color(0xFFEFF6FF);
        break;
      case "Interior Cleaning":
      default:
        icon = Icons.chair_rounded;
        color = const Color(0xFF06B6D4);
        bgColor = const Color(0xFFECFEFF);
        break;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF1E293B),
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                details,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF64748B),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStatusIndicator(String pStatus) {
    Color color;
    Color bgColor;

    switch (pStatus) {
      case "Paid":
        color = const Color(0xFF10B981);
        bgColor = const Color(0xFFECFDF5);
        break;
      case "Failed":
        color = const Color(0xFFEF4444);
        bgColor = const Color(0xFFFEF2F2);
        break;
      case "Pending":
      default:
        color = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFEF3C7);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        pStatus,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    Color bgColor;

    switch (status) {
      case "Completed":
        color = const Color(0xFF3B82F6);
        bgColor = const Color(0xFFEFF6FF);
        break;
      case "Confirmed":
        color = const Color(0xFF10B981);
        bgColor = const Color(0xFFECFDF5);
        break;
      case "Cancelled":
        color = const Color(0xFFEF4444);
        bgColor = const Color(0xFFFEF2F2);
        break;
      case "Pending":
      default:
        color = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFEF3C7);
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                status,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }

  Widget _buildTableFooter(int totalFiltered) {
    return Row(
      children: [
        Text(
          "Showing 1 to $totalFiltered of 1,568 bookings",
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF64748B),
          ),
        ),
        const Spacer(),
        Row(
          children: [
            const IconButton(
              icon: Icon(Icons.chevron_left_rounded, size: 18),
              onPressed: null,
            ),
            ...[1, 2, 3, 4, 5].map((page) {
              final bool isSelected = page == 1;
              return InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? const Color(0xFF10B981)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      page.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color:
                            isSelected ? Colors.white : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
              );
            }),
            Text(
              "...",
              style: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
            ),
            InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                child: Center(
                  child: Text(
                    "157",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            ),
            const IconButton(
              icon: Icon(Icons.chevron_right_rounded, size: 18),
              onPressed: null,
            ),
          ],
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 115,
          height: 32,
          child: DropdownButtonFormField<int>(
            isExpanded: true,
            initialValue: 10,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(6),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            style: GoogleFonts.inter(
              color: const Color(0xFF1E293B),
              fontSize: 11,
            ),
            items: const [
              DropdownMenuItem(value: 10, child: Text("10 / page")),
            ],
            onChanged: (val) {},
          ),
        ),
      ],
    );
  }
}
