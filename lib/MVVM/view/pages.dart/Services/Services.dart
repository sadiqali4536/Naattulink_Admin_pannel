import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'dart:async';
import 'package:swiftclean_admin/modules/services/service_image_service.dart';

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
  final String? imageFileId;

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
    this.imageFileId,
  });

  factory ServiceModel.fromMap(Map<String, dynamic> map, String docId) {
    return ServiceModel(
      id: docId,
      name: map['service_name'] ?? '',
      category: map['category'] ?? '',
      type: map['service_type'] ?? '',
      originalPrice:
          double.tryParse(map['original_price']?.toString() ?? '0') ?? 0.0,
      discount: double.tryParse(map['discount']?.toString() ?? '0') ?? 0.0,
      finalPrice: double.tryParse(map['price']?.toString() ?? '0') ?? 0.0,
      rating: double.tryParse(map['rating']?.toString() ?? '0') ?? 0.0,
      ratingCount: map['ratingCount'] ?? 0,
      status: map['status'] ?? 'Active',
      imageUrl: map['image'] ?? map['imageUrl'] ?? '',
      imageFileId: map['imageFileId'],
    );
  }
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
  String _selectedStatus = "All Status";
  bool _isLoading = false;

  List<String> _categoryList = <String>["_"];
  StreamSubscription? _categorySubscription;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  void _fetchCategories() {
    _categorySubscription = FirebaseFirestore.instance
        .collection('categories')
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            setState(() {
              final fetchedCategories =
                  snapshot.docs
                      .map<String>(
                        (doc) =>
                            (doc.data()['title'] ?? doc.data()['name'] ?? '')
                                .toString(),
                      )
                      .where((c) => c.isNotEmpty)
                      .toList();

              if (fetchedCategories.isNotEmpty) {
                _categoryList = fetchedCategories;
              }

              if (_selectedCategory != "All Categories" &&
                  !_categoryList.contains(_selectedCategory)) {
                _selectedCategory = "All Categories";
              }
            });
          }
        });
  }

  @override
  void dispose() {
    _categorySubscription?.cancel();
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _openCreateServiceDialog() {
    String? tempCategory;
    final TextEditingController nameController = TextEditingController();
    final TextEditingController originalPriceController =
        TextEditingController();
    final TextEditingController discountController = TextEditingController();
    Uint8List? selectedImage;
    bool isUploading = false;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => Dialog(
                  backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    width: 440,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 28,
                    ),
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
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  size: 22,
                                  color: Color(0xFF64748B),
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Service Name",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: nameController,
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: "Enter service name",
                              hintStyle: GoogleFonts.inter(
                                color: const Color(0xFF94A3B8),
                                fontSize: 14,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFF604987),
                                  width: 0.8,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFF604987),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            style: GoogleFonts.inter(fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Category",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: tempCategory,
                            hint: Text(
                              "Select Category",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: Color(0xFF604987),
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFF604987),
                                  width: 0.8,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFF604987),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            items:
                                _categoryList
                                    .map(
                                      (cat) => DropdownMenuItem(
                                        value: cat,
                                        child: Text(cat),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                (val) =>
                                    setDialogState(() => tempCategory = val),
                          ),

                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Original Price",
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF475569),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: originalPriceController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        isDense: true,
                                        hintText: "₹ Price",
                                        hintStyle: GoogleFonts.inter(
                                          color: const Color(0xFF94A3B8),
                                          fontSize: 14,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF604987),
                                            width: 0.8,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF604987),
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      style: GoogleFonts.inter(fontSize: 14),
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
                                    Text(
                                      "Discount (%)",
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF475569),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: discountController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        isDense: true,
                                        hintText: "% Discount",
                                        hintStyle: GoogleFonts.inter(
                                          color: const Color(0xFF94A3B8),
                                          fontSize: 14,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF604987),
                                            width: 0.8,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF604987),
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      style: GoogleFonts.inter(fontSize: 14),
                                      onChanged: (_) => setDialogState(() {}),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Builder(
                            builder: (_) {
                              final double original =
                                  double.tryParse(
                                    originalPriceController.text,
                                  ) ??
                                  0.0;
                              final double discount =
                                  double.tryParse(discountController.text) ??
                                  0.0;
                              final double finalPrice =
                                  original - (original * discount / 100.0);
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "Calculated Final Price: ₹${finalPrice.toStringAsFixed(0)}",
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Service Image",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    FilePickerResult? result = await FilePicker
                                        .platform
                                        .pickFiles(
                                          type: FileType.image,
                                          withData: true,
                                        );
                                    if (result != null) {
                                      setDialogState(() {
                                        selectedImage =
                                            result.files.first.bytes;
                                      });
                                    }
                                  },
                                  child: Container(
                                    height: 130,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.white,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFECFDF5),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.cloud_upload_outlined,
                                            color: Color(0xFF047857),
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          "Upload image",
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF1E293B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Container(
                                  height: 130,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.white,
                                  ),
                                  child:
                                      selectedImage != null
                                          ? Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                child: Image.memory(
                                                  selectedImage!,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              Positioned(
                                                top: 6,
                                                right: 6,
                                                child: GestureDetector(
                                                  onTap:
                                                      () => setDialogState(
                                                        () =>
                                                            selectedImage =
                                                                null,
                                                      ),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(6),
                                                    decoration:
                                                        const BoxDecoration(
                                                          color: Colors.white,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                    child: const Icon(
                                                      Icons.close,
                                                      color: Colors.red,
                                                      size: 16,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                          : Center(
                                            child: Text(
                                              "No image selected",
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                color: const Color(0xFF94A3B8),
                                              ),
                                            ),
                                          ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFFF4F0F7),
                                  foregroundColor: const Color(0xFF334155),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                ),
                                child: Text(
                                  "Cancel",
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed:
                                    isUploading
                                        ? null
                                        : () async {
                                          if (nameController.text.isEmpty ||
                                              tempCategory == null ||
                                              originalPriceController
                                                  .text
                                                  .isEmpty ||
                                              selectedImage == null) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Please fill in all required fields and select an image.",
                                                ),
                                              ),
                                            );
                                            return;
                                          }

                                          setDialogState(() {
                                            isUploading = true;
                                          });

                                          try {
                                            final String fileName =
                                                'service_${DateTime.now().millisecondsSinceEpoch}.jpg';
                                            final service =
                                                ServiceImageService();
                                            final result = await service
                                                .uploadServiceImage(
                                                  imageBytes: selectedImage!,
                                                  fileName: fileName,
                                                );

                                            final String uploadedImageUrl =
                                                result.imageUrl;
                                            final String uploadedImageFileId =
                                                result.fileId;

                                            final double original =
                                                double.tryParse(
                                                  originalPriceController.text,
                                                ) ??
                                                0.0;
                                            final double discount =
                                                double.tryParse(
                                                  discountController.text,
                                                ) ??
                                                0.0;
                                            final double finalPrice =
                                                original -
                                                (original * discount / 100.0);

                                            final docRef =
                                                FirebaseFirestore.instance
                                                    .collection('services')
                                                    .doc();
                                            await docRef.set({
                                              'service_name':
                                                  nameController.text,
                                              'category': tempCategory,
                                              'discount': discount
                                                  .toStringAsFixed(0),
                                              'price': finalPrice
                                                  .toStringAsFixed(0),
                                              'original_price': original
                                                  .toStringAsFixed(0),
                                              'image': uploadedImageUrl,
                                              'imageFileId':
                                                  uploadedImageFileId,
                                              'serviceId': docRef.id,
                                              'createAt':
                                                  FieldValue.serverTimestamp(),
                                              'rating': 5.0,
                                            });

                                            if (context.mounted) {
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    "New service created successfully!",
                                                  ),
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              setDialogState(() {
                                                isUploading = false;
                                              });
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text("Error: $e"),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF047857),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 14,
                                  ),
                                ),
                                child:
                                    isUploading
                                        ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                        : Text(
                                          "Save Service",
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
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
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('services').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final List<ServiceModel> fetchedServices =
                snapshot.data?.docs.map((doc) {
                  return ServiceModel.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  );
                }).toList() ??
                [];

            return LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;
                final bool isSmall = width < 950;

                final filteredList =
                    fetchedServices.where((srv) {
                      final matchesSearch =
                          srv.name.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ||
                          srv.id.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          );
                      final matchesCategory =
                          _selectedCategory == "All Categories" ||
                          srv.category == _selectedCategory;
                      final matchesStatus =
                          _selectedStatus == "All Status" ||
                          srv.status == _selectedStatus;

                      return matchesSearch && matchesCategory && matchesStatus;
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
                        _buildStatsGrid(isSmall, fetchedServices),
                        const SizedBox(height: 24),
                        _buildFiltersCard(isSmall),
                        const SizedBox(height: 20),
                        _buildTableCard(
                          filteredList,
                          width,
                          fetchedServices.length,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.1),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
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
                  "Services",
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
                  "All Services",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _openCreateServiceDialog,
          icon: const Icon(Icons.add, size: 16),
          label: Text(
            "Add New Service",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF047857),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(bool isSmall, List<ServiceModel> services) {
    int crossAxisCount = 4;
    if (isSmall) {
      crossAxisCount = 2;
    }

    int totalServices = services.length;
    int activeServices = services.where((s) => s.status == "Active").length;
    int inactiveServices = services.where((s) => s.status == "Inactive").length;
    int popularServices = services.where((s) => s.rating >= 4.0).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double itemWidth =
            (constraints.maxWidth - (crossAxisCount - 1) * 16) / crossAxisCount;
        const double itemHeight = 115;
        final double aspectRatio = itemWidth / itemHeight;

        final cards = [
          _buildStatsCard(
            title: "Total Services",
            value: totalServices.toString(),
            subtitle: "All registered services",
            icon: Icons.grid_view_rounded,
            color: const Color(0xFF3B82F6),
            bgColor: const Color(0xFFEFF6FF),
          ),
          _buildStatsCard(
            title: "Active Services",
            value: activeServices.toString(),
            subtitle: "Currently active",
            icon: Icons.local_offer_outlined,
            color: const Color(0xFF10B981),
            bgColor: const Color(0xFFECFDF5),
          ),
          _buildStatsCard(
            title: "Inactive Services",
            value: inactiveServices.toString(),
            subtitle: "Temporarily inactive",
            icon: Icons.pause_circle_outline_rounded,
            color: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFFEF3C7),
          ),
          _buildStatsCard(
            title: "Popular Services",
            value: popularServices.toString(),
            subtitle: "High rated services",
            icon: Icons.star_border_rounded,
            color: const Color(0xFF8B5CF6),
            bgColor: const Color(0xFFF5F3FF),
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
      width: isSmall ? double.infinity : 260,
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
          hintText: "Search by service name or category...",
          hintStyle: GoogleFonts.inter(
            color: const Color(0xFF94A3B8),
            fontSize: 12,
          ),
          suffixIcon: const Icon(
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

    final categoryDropdown = SizedBox(
      width: isSmall ? double.infinity : 150,
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
            <String>["All Categories", ..._categoryList]
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

    final statusDropdown = SizedBox(
      width: isSmall ? double.infinity : 140,
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
            ["All Status", "Active", "Inactive"]
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
          categoryDropdown,
          const SizedBox(height: 12),
          statusDropdown,
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
          categoryDropdown,
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

  Widget _buildTableCard(
    List<ServiceModel> services,
    double screenWidth,
    int totalServices,
  ) {
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
                    2: FlexColumnWidth(1.4), // Original Price
                    3: FlexColumnWidth(1.2), // Discount
                    4: FlexColumnWidth(1.4), // Final Price
                    5: FlexColumnWidth(1.4), // Rating
                    6: FlexColumnWidth(1.4), // Status
                    7: FlexColumnWidth(1.8), // Actions
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
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
                        _buildHeaderCell("Service"),
                        _buildHeaderCell("Category"),
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
                            child: Row(
                              children: [
                                if (srv.imageUrl.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 12.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        srv.imageUrl,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  width: 40,
                                                  height: 40,
                                                  color: Colors.grey[200],
                                                  child: const Icon(
                                                    Icons.image_not_supported,
                                                    size: 20,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                      ),
                                    ),
                                  )
                                else
                                  Padding(
                                    padding: const EdgeInsets.only(right: 12.0),
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.image,
                                        size: 20,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        srv.name,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF0F172A),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        srv.id,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
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
                            child: _buildCategoryBadge(srv.category),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12.0,
                              horizontal: 16.0,
                            ),
                            child: Text(
                              "₹${srv.originalPrice.toStringAsFixed(0)}",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
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
                              srv.discount > 0
                                  ? "${srv.discount.toStringAsFixed(0)}%"
                                  : "0%",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12.0,
                              horizontal: 16.0,
                            ),
                            child: Text(
                              "₹${srv.finalPrice.toStringAsFixed(0)}",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
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
                                Text(
                                  srv.rating.toString(),
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFF59E0B),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "(${srv.ratingCount})",
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF94A3B8),
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
                            child: _buildStatusBadge(srv.status),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12.0,
                              horizontal: 4.0,
                            ),
                            child: Row(
                              children: [
                                _buildActionButton(
                                  Icons.edit_outlined,
                                  Colors.blue,
                                  () {},
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 36,
                                  height: 24,
                                  child: FittedBox(
                                    fit: BoxFit.fill,
                                    child: CupertinoSwitch(
                                      value: srv.status == "Active",
                                      activeColor: const Color(0xFF10B981),
                                      onChanged: (val) async {
                                        final newStatus =
                                            val ? "Active" : "Inactive";
                                        setState(() {
                                          srv.status = newStatus;
                                          _isLoading = true;
                                        });
                                        try {
                                          await FirebaseFirestore.instance
                                              .collection('services')
                                              .doc(srv.id)
                                              .update({'status': newStatus});
                                        } catch (e) {
                                          // Revert on error or show message
                                        } finally {
                                          if (mounted) {
                                            setState(() {
                                              _isLoading = false;
                                            });
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildActionButton(
                                  Icons.delete_outline_rounded,
                                  Colors.red,
                                  () {
                                    _showDeleteConfirmationDialog(srv);
                                  },
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildTableFooter(services.length, totalServices),
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

  Widget _buildCategoryBadge(String cat) {
    Color color;
    Color bgColor;

    switch (cat) {
      case "Vehicle":
        color = const Color(0xFF3B82F6);
        bgColor = const Color(0xFFEFF6FF);
        break;
      case "Home":
        color = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFEF3C7);
        break;
      case "Pet":
      default:
        color = const Color(0xFF8B5CF6);
        bgColor = const Color(0xFFF5F3FF);
        break;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          cat,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
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
      default:
        color = const Color(0xFFEF4444);
        bgColor = const Color(0xFFFEF2F2);
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            Text(
              status,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
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

  Widget _buildTableFooter(int totalFiltered, int totalServices) {
    return Row(
      children: [
        Text(
          "Showing 1 to $totalFiltered of $totalServices services",
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
                    "13",
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

  void _showDeleteConfirmationDialog(ServiceModel srv) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              "Delete Service",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            content: Text(
              "Are you sure you want to delete ${srv.name}? This action cannot be undone.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.inter(color: const Color(0xFF64748B)),
                ),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    // Delete from Firestore
                    await FirebaseFirestore.instance
                        .collection('services')
                        .doc(srv.id)
                        .delete();
                  } catch (e) {
                    // Ignored fallback
                  }
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Service deleted successfully."),
                      ),
                    );
                  }
                },
                child: Text(
                  "Delete",
                  style: GoogleFonts.inter(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
