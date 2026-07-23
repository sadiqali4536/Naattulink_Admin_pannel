import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swiftclean_admin/MVVM/utils/printer_helper.dart';

import 'package:intl/intl.dart';

class CategoryModel {
  final String id;
  final String title;
  final String description;
  final int totalServices;
  String status;
  final String createdOn;
  final String iconType;
  final double price;
  final String imageUrl;

  CategoryModel({
    required this.id,
    required this.title,
    required this.description,
    required this.totalServices,
    required this.status,
    required this.createdOn,
    required this.iconType,
    required this.price,
    required this.imageUrl,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map, String id) {
    return CategoryModel(
      id: id,
      title: map['title'] ?? map['name'] ?? '',
      description: map['description'] ?? '',
      totalServices: map['totalServices'] ?? 0,
      status: map['status'] ?? 'Active',
      createdOn: map['createdOn'] ?? '',
      iconType: map['iconType'] ?? 'Home',
      price: (map['price'] ?? 0.0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'totalServices': totalServices,
      'status': status,
      'createdOn': createdOn,
      'iconType': iconType,
      'price': price,
      'imageUrl': imageUrl,
    };
  }
}

class ServiceCategoriesPage extends StatefulWidget {
  const ServiceCategoriesPage({super.key});

  @override
  State<ServiceCategoriesPage> createState() => _ServiceCategoriesPageState();
}

class _ServiceCategoriesPageState extends State<ServiceCategoriesPage> {
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  String _searchQuery = "";

  // The hardcoded _categoriesList has been removed. We now stream from Firestore.

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _openCreateCategoryDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => Dialog(
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
                                "Create New Category",
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  size: 20,
                                  color: Color(0xFF64748B),
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Add a new category to organize your services.",
                            style: GoogleFonts.inter(
                              color: const Color(0xFF64748B),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFE2E8F0), height: 1),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Text(
                                "Title ",
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                "*",
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: titleController,
                            maxLength: 80,
                            decoration: InputDecoration(
                              isDense: true,
                              prefixIcon: const Icon(
                                Icons.local_offer_outlined,
                                color: Color(0xFF047857),
                                size: 20,
                              ),
                              hintText: "Enter category title",
                              hintStyle: GoogleFonts.inter(
                                color: const Color(0xFF94A3B8),
                                fontSize: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF047857),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF047857),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            style: GoogleFonts.inter(fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Description",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: descController,
                            maxLines: 4,
                            maxLength: 200,
                            decoration: InputDecoration(
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(bottom: 60),
                                child: Icon(
                                  Icons.description_outlined,
                                  color: Color(0xFF047857),
                                  size: 20,
                                ),
                              ),
                              hintText:
                                  "Enter a short description of this category",
                              hintStyle: GoogleFonts.inter(
                                color: const Color(0xFF94A3B8),
                                fontSize: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                            ),
                            style: GoogleFonts.inter(fontSize: 14),
                          ),

                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF475569),
                                  side: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  "Cancel",
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () async {
                                  if (titleController.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Please fill in all required fields.",
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  try {
                                    final newCategory = CategoryModel(
                                      id: '', // Will be assigned by Firestore
                                      title: titleController.text,
                                      description: descController.text,
                                      totalServices: 0,
                                      status: "Active",
                                      createdOn: DateFormat(
                                        'MMM dd, yyyy',
                                      ).format(DateTime.now()),
                                      iconType: "Home",
                                      price: 0.0,
                                      imageUrl: '',
                                    );

                                    await FirebaseFirestore.instance
                                        .collection('categories')
                                        .add(newCategory.toMap());

                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "New category added successfully!",
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (error) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Failed to add category: $error",
                                          ),
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
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                child: Text(
                                  "Save Category",
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final bool isSmall = width < 950;

        return StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance.collection('categories').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final List<CategoryModel> categoriesList = [];
            if (snapshot.hasData) {
              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                categoriesList.add(CategoryModel.fromMap(data, doc.id));
              }
            }

            final filteredList =
                categoriesList.where((cat) {
                  return cat.title.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      cat.description.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      );
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
                    _buildStatsGrid(isSmall, categoriesList),
                    const SizedBox(height: 24),
                    _buildFiltersCard(isSmall, filteredList),
                    const SizedBox(height: 20),
                    _buildTableCard(filteredList, width),
                  ],
                ),
              ),
            );
          },
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
              "Categories",
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
                  "Categories",
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
          onPressed: _openCreateCategoryDialog,
          icon: const Icon(Icons.add, size: 16),
          label: Text(
            "Add New Category",
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

  Widget _buildStatsGrid(bool isSmall, List<CategoryModel> categoriesList) {
    int crossAxisCount = 5;
    if (isSmall) {
      crossAxisCount = 2;
    }

    final totalCategories = categoriesList.length;
    final activeCategories =
        categoriesList.where((c) => c.status == 'Active').length;
    final inactiveCategories =
        categoriesList.where((c) => c.status != 'Active').length;
    int totalServices = categoriesList.fold(
      0,
      (sum, item) => sum + item.totalServices,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final double itemWidth =
            (constraints.maxWidth - (crossAxisCount - 1) * 16) / crossAxisCount;
        const double itemHeight = 115;
        final double aspectRatio = itemWidth / itemHeight;

        final cards = [
          _buildStatsCard(
            title: "Total Categories",
            value: "$totalCategories",
            subtitle: "All service categories",
            icon: Icons.grid_view_rounded,
            color: const Color(0xFF3B82F6),
            bgColor: const Color(0xFFEFF6FF),
          ),
          _buildStatsCard(
            title: "Active Categories",
            value: "$activeCategories",
            subtitle: "Currently active",
            icon: Icons.check_circle_outline_rounded,
            color: const Color(0xFF10B981),
            bgColor: const Color(0xFFECFDF5),
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
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

  Widget _buildFiltersCard(bool isSmall, List<CategoryModel> filteredList) {
    final searchField = SizedBox(
      width: isSmall ? double.infinity : 280,
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
          hintText: "Search by category name...",
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

    final exportButton = ElevatedButton.icon(
      onPressed: () => _exportToPdf(filteredList),
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [exportButton],
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
      child: Row(children: [searchField, const Spacer(), exportButton]),
    );
  }

  Widget _buildTableCard(List<CategoryModel> categories, double screenWidth) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return Scrollbar(
                controller: _horizontalScrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth:
                          constraints.maxWidth > 800
                              ? constraints.maxWidth
                              : 800,
                    ),
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(1.0), // No.
                        1: FlexColumnWidth(5.0), // Title
                        2: FlexColumnWidth(3.0), // Created On
                        3: FlexColumnWidth(2.0), // Actions
                      },
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
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
                            _buildHeaderCell("No."),
                            _buildHeaderCell("Category"),
                            _buildHeaderCell("Created On"),
                            _buildHeaderCell("Actions"),
                          ],
                        ),
                        ...categories.asMap().entries.map((entry) {
                          final index = entry.key;
                          final cat = entry.value;
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
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
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
                                    Expanded(
                                      child: Text(
                                        cat.title,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF0F172A),
                                        ),
                                        overflow: TextOverflow.ellipsis,
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
                                  cat.createdOn,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF64748B),
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
                                    _buildActionButton(
                                      Icons.edit_outlined,
                                      Colors.blue,
                                      () {},
                                    ),
                                    const SizedBox(width: 8),
                                    _buildActionButton(
                                      Icons.delete_outline_rounded,
                                      Colors.red,
                                      () {
                                        _showDeleteConfirmationDialog(cat);
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
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildTableFooter(categories.length),
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

  Widget _buildStatusBadge(String status) {
    final bool isActive = status == "Active";
    final Color color =
        isActive ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final Color bgColor =
        isActive ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7);

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
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _buildTableFooter(int totalFiltered) {
    return Row(
      children: [
        Text(
          "Showing 1 to $totalFiltered of 9 categories",
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
            InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    "1",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  void _showDeleteConfirmationDialog(CategoryModel cat) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              "Delete Category",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            content: Text(
              "Are you sure you want to delete ${cat.title}? This action cannot be undone.",
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
                  // Close the dialog first
                  Navigator.pop(context);

                  try {
                    // Delete the document from Firestore
                    await FirebaseFirestore.instance
                        .collection('categories')
                        .doc(cat.id)
                        .delete();

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Category deleted successfully."),
                        ),
                      );
                    }
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Failed to delete category: $error"),
                        ),
                      );
                    }
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

  Future<void> _exportToPdf(List<CategoryModel> filteredList) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Preparing export... Please wait.")),
    );
    try {
      printCategoriesList(filteredList);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error exporting: $e")));
      }
    }
  }
}
