import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ServiceModel {
  final String id;
  final String name;
  final String category;
  final String type;
  final double originalPrice;
  final double discount;
  final double finalPrice;
  final double rating;
  final int ratingCount;
  String status;
  final String imageUrl;

  ServiceModel({
    required this.id,
    required this.name,
    required this.category,
    required this.type,
    required this.originalPrice,
    required this.discount,
    required this.finalPrice,
    required this.rating,
    required this.ratingCount,
    required this.status,
    required this.imageUrl,
  });
}

class Services extends StatefulWidget {
  const Services({super.key});

  @override
  State<Services> createState() => _ServicesState();
}

class _ServicesState extends State<Services> {
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  String _searchQuery = "";
  String _selectedCategory = "All Categories";
  String _selectedType = "All Types";
  String _selectedStatus = "All Status";

  final List<ServiceModel> _servicesList = [
    ServiceModel(
      id: "#SRV-001",
      name: "Exterior Car Cleaning",
      category: "Vehicle",
      type: "Hourly",
      originalPrice: 1000.0,
      discount: 20.0,
      finalPrice: 800.0,
      rating: 4.7,
      ratingCount: 128,
      status: "Active",
      imageUrl: "https://images.unsplash.com/photo-1607860108855-64acf2078ed9?w=150&auto=format&fit=crop",
    ),
    ServiceModel(
      id: "#SRV-002",
      name: "Interior Car Cleaning",
      category: "Vehicle",
      type: "Non-Hourly",
      originalPrice: 1500.0,
      discount: 15.0,
      finalPrice: 1275.0,
      rating: 4.6,
      ratingCount: 96,
      status: "Active",
      imageUrl: "https://images.unsplash.com/photo-1563720223185-11003d516935?w=150&auto=format&fit=crop",
    ),
    ServiceModel(
      id: "#SRV-003",
      name: "Home Deep Cleaning",
      category: "Home",
      type: "Non-Hourly",
      originalPrice: 2000.0,
      discount: 10.0,
      finalPrice: 1800.0,
      rating: 4.8,
      ratingCount: 210,
      status: "Active",
      imageUrl: "https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=150&auto=format&fit=crop",
    ),
    ServiceModel(
      id: "#SRV-004",
      name: "Sofa Cleaning",
      category: "Home",
      type: "Non-Hourly",
      originalPrice: 1200.0,
      discount: 5.0,
      finalPrice: 1140.0,
      rating: 4.5,
      ratingCount: 78,
      status: "Active",
      imageUrl: "https://images.unsplash.com/photo-1556911220-e15b29be8c8f?w=150&auto=format&fit=crop",
    ),
    ServiceModel(
      id: "#SRV-005",
      name: "Pet Grooming",
      category: "Pet",
      type: "Non-Hourly",
      originalPrice: 1500.0,
      discount: 20.0,
      finalPrice: 1200.0,
      rating: 4.7,
      ratingCount: 154,
      status: "Active",
      imageUrl: "https://images.unsplash.com/photo-1516734212186-a967f81ad0d7?w=150&auto=format&fit=crop",
    ),
    ServiceModel(
      id: "#SRV-006",
      name: "Garden Services",
      category: "Home",
      type: "Hourly",
      originalPrice: 800.0,
      discount: 0.0,
      finalPrice: 800.0,
      rating: 4.4,
      ratingCount: 62,
      status: "Active",
      imageUrl: "https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=150&auto=format&fit=crop",
    ),
    ServiceModel(
      id: "#SRV-007",
      name: "Bathroom Cleaning",
      category: "Home",
      type: "Non-Hourly",
      originalPrice: 900.0,
      discount: 10.0,
      finalPrice: 810.0,
      rating: 4.3,
      ratingCount: 45,
      status: "Inactive",
      imageUrl: "https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=150&auto=format&fit=crop",
    ),
    ServiceModel(
      id: "#SRV-008",
      name: "Office Cleaning",
      category: "Home",
      type: "Non-Hourly",
      originalPrice: 2500.0,
      discount: 15.0,
      finalPrice: 2125.0,
      rating: 4.6,
      ratingCount: 88,
      status: "Active",
      imageUrl: "https://images.unsplash.com/photo-1497366216548-37526070297c?w=150&auto=format&fit=crop",
    ),
    ServiceModel(
      id: "#SRV-009",
      name: "Water Tank Cleaning",
      category: "Home",
      type: "Non-Hourly",
      originalPrice: 1000.0,
      discount: 5.0,
      finalPrice: 950.0,
      rating: 4.2,
      ratingCount: 36,
      status: "Out of Stock",
      imageUrl: "https://images.unsplash.com/photo-1508962914676-134849a727f0?w=150&auto=format&fit=crop",
    ),
    ServiceModel(
      id: "#SRV-010",
      name: "AC Duct Cleaning",
      category: "Home",
      type: "Hourly",
      originalPrice: 1200.0,
      discount: 10.0,
      finalPrice: 1080.0,
      rating: 4.5,
      ratingCount: 74,
      status: "Active",
      imageUrl: "https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=150&auto=format&fit=crop",
    ),
  ];

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _openCreateServiceDialog() {
    String? tempCategory;
    String? tempType;
    final TextEditingController nameController = TextEditingController();
    final TextEditingController originalPriceController = TextEditingController();
    final TextEditingController discountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Create New Service",
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFFE2E8F0), height: 24),
                  const SizedBox(height: 8),
                  Text("Service Name", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: "Enter service name",
                      hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Text("Category", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: tempCategory,
                    hint: Text("Select Category", style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8))),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: const [
                      DropdownMenuItem(value: "Vehicle", child: Text("Vehicle")),
                      DropdownMenuItem(value: "Home", child: Text("Home")),
                      DropdownMenuItem(value: "Pet", child: Text("Pet")),
                    ],
                    onChanged: (val) => setDialogState(() => tempCategory = val),
                  ),
                  const SizedBox(height: 16),
                  Text("Service Type", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: tempType,
                    hint: Text("Select Type", style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8))),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: const [
                      DropdownMenuItem(value: "Hourly", child: Text("Hourly")),
                      DropdownMenuItem(value: "Non-Hourly", child: Text("Non-Hourly")),
                    ],
                    onChanged: (val) => setDialogState(() => tempType = val),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Original Price", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: originalPriceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: "₹ Price",
                                hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              style: GoogleFonts.inter(fontSize: 13),
                              onChanged: (_) => setDialogState(() {}),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Discount (%)", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: discountController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: "% Discount",
                                hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              style: GoogleFonts.inter(fontSize: 13),
                              onChanged: (_) => setDialogState(() {}),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Builder(builder: (_) {
                    final double original = double.tryParse(originalPriceController.text) ?? 0.0;
                    final double discount = double.tryParse(discountController.text) ?? 0.0;
                    final double finalPrice = original - (original * discount / 100.0);
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        "Calculated Final Price: ₹${finalPrice.toStringAsFixed(0)}",
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF475569),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text("Cancel", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          if (nameController.text.isEmpty || tempCategory == null || tempType == null || originalPriceController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill in all required fields.")));
                            return;
                          }

                          final double original = double.tryParse(originalPriceController.text) ?? 0.0;
                          final double discount = double.tryParse(discountController.text) ?? 0.0;
                          final double finalPrice = original - (original * discount / 100.0);
                          final String newId = "#SRV-0${_servicesList.length + 1}";

                          final newService = ServiceModel(
                            id: newId,
                            name: nameController.text,
                            category: tempCategory!,
                            type: tempType!,
                            originalPrice: original,
                            discount: discount,
                            finalPrice: finalPrice,
                            rating: 5.0,
                            ratingCount: 1,
                            status: "Active",
                            imageUrl: "https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=150&auto=format&fit=crop",
                          );

                          setState(() {
                            _servicesList.insert(0, newService);
                          });

                          try {
                            final docRef = FirebaseFirestore.instance.collection('services').doc();
                            await docRef.set({
                              'service_name': nameController.text,
                              'category': tempCategory,
                              'discount': discount.toStringAsFixed(0),
                              'price': finalPrice.toStringAsFixed(0),
                              'original_price': original.toStringAsFixed(0),
                              'service_type': tempType,
                              'image': '',
                              'serviceId': docRef.id,
                              'createAt': FieldValue.serverTimestamp(),
                              'rating': 5.0,
                            });
                          } catch (e) {
                            // Ignored - offline mode fallback matches list updates
                          }

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("New service created successfully!")));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF047857),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        child: Text("Save Service", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final bool isSmall = width < 950;

        final filteredList = _servicesList.where((srv) {
          final matchesSearch = srv.name.toLowerCase().contains(_searchQuery.toLowerCase()) || srv.id.toLowerCase().contains(_searchQuery.toLowerCase());
          final matchesCategory = _selectedCategory == "All Categories" || srv.category == _selectedCategory;
          final matchesType = _selectedType == "All Types" || srv.type == _selectedType;
          final matchesStatus = _selectedStatus == "All Status" || srv.status == _selectedStatus;

          return matchesSearch && matchesCategory && matchesType && matchesStatus;
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
                _buildHeaderAndBreadcrumbs(),
                const SizedBox(height: 24),
                _buildStatsGrid(isSmall),
                const SizedBox(height: 24),
                _buildFiltersCard(isSmall),
                const SizedBox(height: 20),
                _buildTableCard(filteredList, width),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderAndBreadcrumbs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Services",
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text("Dashboard", style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
                const Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF94A3B8)),
                Text("Services", style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
                const Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF94A3B8)),
                Text("All Services", style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF0F172A), fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _openCreateServiceDialog,
          icon: const Icon(Icons.add, size: 16),
          label: Text("Add New Service", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF047857),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
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
        final double itemWidth = (constraints.maxWidth - (crossAxisCount - 1) * 16) / crossAxisCount;
        const double itemHeight = 115;
        final double aspectRatio = itemWidth / itemHeight;

        final cards = [
          _buildStatsCard(
            title: "Total Services",
            value: "128",
            subtitle: "All registered services",
            icon: Icons.grid_view_rounded,
            color: const Color(0xFF3B82F6),
            bgColor: const Color(0xFFEFF6FF),
          ),
          _buildStatsCard(
            title: "Active Services",
            value: "98",
            subtitle: "Currently active",
            icon: Icons.local_offer_outlined,
            color: const Color(0xFF10B981),
            bgColor: const Color(0xFFECFDF5),
          ),
          _buildStatsCard(
            title: "Inactive Services",
            value: "20",
            subtitle: "Temporarily inactive",
            icon: Icons.pause_circle_outline_rounded,
            color: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFFEF3C7),
          ),
          _buildStatsCard(
            title: "Popular Services",
            value: "35",
            subtitle: "High rated services",
            icon: Icons.star_border_rounded,
            color: const Color(0xFF8B5CF6),
            bgColor: const Color(0xFFF5F3FF),
          ),
          _buildStatsCard(
            title: "Out of Stock",
            value: "10",
            subtitle: "Currently unavailable",
            icon: Icons.archive_outlined,
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
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
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
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8)),
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
      width: isSmall ? double.infinity : 260,
      height: 38,
      child: TextFormField(
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          fillColor: Colors.white,
          filled: true,
          hintText: "Search by service name or category...",
          hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12),
          suffixIcon: const Icon(CupertinoIcons.search, color: Color(0xFF94A3B8), size: 16),
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

    final categoryDropdown = SizedBox(
      width: isSmall ? double.infinity : 150,
      height: 38,
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: _selectedCategory,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        items: ["All Categories", "Vehicle", "Home", "Pet"]
            .map((cat) => DropdownMenuItem(value: cat, child: Text(cat, maxLines: 1, overflow: TextOverflow.ellipsis)))
            .toList(),
        onChanged: (val) => setState(() => _selectedCategory = val!),
      ),
    );

    final typeDropdown = SizedBox(
      width: isSmall ? double.infinity : 140,
      height: 38,
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: _selectedType,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        items: ["All Types", "Hourly", "Non-Hourly"]
            .map((t) => DropdownMenuItem(value: t, child: Text(t, maxLines: 1, overflow: TextOverflow.ellipsis)))
            .toList(),
        onChanged: (val) => setState(() => _selectedType = val!),
      ),
    );

    final statusDropdown = SizedBox(
      width: isSmall ? double.infinity : 140,
      height: 38,
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: _selectedStatus,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        items: ["All Status", "Active", "Inactive", "Out of Stock"]
            .map((status) => DropdownMenuItem(value: status, child: Text(status, maxLines: 1, overflow: TextOverflow.ellipsis)))
            .toList(),
        onChanged: (val) => setState(() => _selectedStatus = val!),
      ),
    );

    final filterButton = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: IconButton(
        icon: const Icon(Icons.filter_list_rounded, size: 18, color: Color(0xFF64748B)),
        onPressed: () {},
      ),
    );

    final exportButton = ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.download_rounded, size: 14),
      label: Text("Export", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
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
          categoryDropdown,
          const SizedBox(height: 12),
          typeDropdown,
          const SizedBox(height: 12),
          statusDropdown,
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              filterButton,
              const SizedBox(width: 12),
              exportButton,
            ],
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
          categoryDropdown,
          const SizedBox(width: 12),
          typeDropdown,
          const SizedBox(width: 12),
          statusDropdown,
          const Spacer(),
          filterButton,
          const SizedBox(width: 12),
          exportButton,
        ],
      ),
    );
  }

  Widget _buildTableCard(List<ServiceModel> services, double screenWidth) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Scrollbar(
            controller: _horizontalScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _horizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1300,
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2.6), // Service Image & Title
                    1: FlexColumnWidth(1.6), // Category Badge
                    2: FlexColumnWidth(1.4), // Service Type Tag
                    3: FlexColumnWidth(1.4), // Original Price
                    4: FlexColumnWidth(1.2), // Discount
                    5: FlexColumnWidth(1.4), // Final Price
                    6: FlexColumnWidth(1.4), // Rating
                    7: FlexColumnWidth(1.4), // Status
                    8: FlexColumnWidth(1.8), // Actions
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
                      ),
                      children: [
                        _buildHeaderCell("Service"),
                        _buildHeaderCell("Category"),
                        _buildHeaderCell("Type"),
                        _buildHeaderCell("Original Price"),
                        _buildHeaderCell("Discount"),
                        _buildHeaderCell("Final Price"),
                        _buildHeaderCell("Rating"),
                        _buildHeaderCell("Status"),
                        _buildHeaderCell("Actions"),
                      ],
                    ),
                    ...services.map((srv) {
                      return TableRow(
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    srv.imageUrl,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 44,
                                        height: 44,
                                        color: const Color(0xFFE2E8F0),
                                        child: const Icon(Icons.home_repair_service, color: Color(0xFF64748B), size: 20),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        srv.name,
                                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        srv.id,
                                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                            child: _buildCategoryBadge(srv.category),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                            child: _buildTypeTag(srv.type),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                            child: Text(
                              "₹${srv.originalPrice.toStringAsFixed(0)}",
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                            child: Text(
                              srv.discount > 0 ? "${srv.discount.toStringAsFixed(0)}%" : "0%",
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                            child: Text(
                              "₹${srv.finalPrice.toStringAsFixed(0)}",
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                            child: Row(
                              children: [
                                Text(
                                  srv.rating.toString(),
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  "(${srv.ratingCount})",
                                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                            child: _buildStatusBadge(srv.status),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
                            child: Row(
                              children: [
                                _buildActionButton(Icons.edit_outlined, Colors.blue, () {}),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 36,
                                  height: 24,
                                  child: FittedBox(
                                    fit: BoxFit.fill,
                                    child: CupertinoSwitch(
                                      value: srv.status == "Active",
                                      activeColor: const Color(0xFF10B981),
                                      onChanged: (val) {
                                        setState(() {
                                          srv.status = val ? "Active" : "Inactive";
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildActionButton(Icons.delete_outline_rounded, Colors.red, () {
                                  _showDeleteConfirmationDialog(srv);
                                }),
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildTableFooter(services.length),
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
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
      ),
    );
  }

  Widget _buildCategoryBadge(String cat) {
    IconData icon;
    Color color;
    Color bgColor;

    switch (cat) {
      case "Vehicle":
        icon = Icons.directions_car_rounded;
        color = const Color(0xFF3B82F6);
        bgColor = const Color(0xFFEFF6FF);
        break;
      case "Home":
        icon = Icons.home_rounded;
        color = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFEF3C7);
        break;
      case "Pet":
      default:
        icon = Icons.pets_rounded;
        color = const Color(0xFF8B5CF6);
        bgColor = const Color(0xFFF5F3FF);
        break;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 6),
            Text(
              cat,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeTag(String type) {
    final bool isHourly = type == "Hourly";
    final Color color = isHourly ? const Color(0xFF047857) : const Color(0xFF0284C7);
    final Color bgColor = isHourly ? const Color(0xFFD1FAE5) : const Color(0xFFE0F2FE);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4)),
        child: Text(
          type,
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    Color bgColor;

    switch (status) {
      case "Active":
        color = const Color(0xFF10B981);
        bgColor = const Color(0xFFECFDF5);
        break;
      case "Inactive":
        color = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFEF3C7);
        break;
      case "Out of Stock":
      default:
        color = const Color(0xFFEF4444);
        bgColor = const Color(0xFFFEF2F2);
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              status,
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: color),
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
          "Showing 1 to $totalFiltered of 128 services",
          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
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
                    color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      page.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
              );
            }),
            Text("...", style: GoogleFonts.inter(color: const Color(0xFF94A3B8))),
            InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                child: Center(
                  child: Text(
                    "13",
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF475569)),
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            style: GoogleFonts.inter(color: const Color(0xFF1E293B), fontSize: 11),
            items: const [
              DropdownMenuItem(value: 10, child: Text("10 / page")),
            ],
            onChanged: (val) {},
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmationDialog(ServiceModel srv) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Service", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to delete ${srv.name}? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          TextButton(
            onPressed: () async {
              setState(() {
                _servicesList.remove(srv);
              });
              try {
                // Delete from Firestore
                await FirebaseFirestore.instance.collection('services').doc(srv.id).delete();
              } catch (e) {
                // Ignored fallback
              }
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Service deleted successfully.")));
              }
            },
            child: Text("Delete", style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
