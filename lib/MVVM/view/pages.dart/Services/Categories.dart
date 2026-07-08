import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoryModel {
  final String name;
  final String description;
  final int totalServices;
  String status;
  final String createdOn;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  CategoryModel({
    required this.name,
    required this.description,
    required this.totalServices,
    required this.status,
    required this.createdOn,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
  });
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

  final List<CategoryModel> _categoriesList = [
    CategoryModel(
      name: "Vehicle Cleaning",
      description: "Services related to cleaning all types of vehicles",
      totalServices: 25,
      status: "Active",
      createdOn: "May 10, 2024",
      icon: Icons.directions_car_rounded,
      iconColor: const Color(0xFF3B82F6),
      iconBgColor: const Color(0xFFEFF6FF),
    ),
    CategoryModel(
      name: "Home Cleaning",
      description: "Home, room, sofa, kitchen and other cleaning services",
      totalServices: 32,
      status: "Active",
      createdOn: "May 10, 2024",
      icon: Icons.home_rounded,
      iconColor: const Color(0xFFF59E0B),
      iconBgColor: const Color(0xFFFEF3C7),
    ),
    CategoryModel(
      name: "Pet Grooming",
      description: "Pet grooming, bathing and related services",
      totalServices: 18,
      status: "Active",
      createdOn: "May 11, 2024",
      icon: Icons.pets_rounded,
      iconColor: const Color(0xFF8B5CF6),
      iconBgColor: const Color(0xFFF5F3FF),
    ),
    CategoryModel(
      name: "Garden Services",
      description: "Lawn mowing, trimming, planting and garden care",
      totalServices: 12,
      status: "Active",
      createdOn: "May 11, 2024",
      icon: Icons.local_florist_rounded,
      iconColor: const Color(0xFF10B981),
      iconBgColor: const Color(0xFFECFDF5),
    ),
    CategoryModel(
      name: "Office Cleaning",
      description: "Office, commercial and workspace cleaning services",
      totalServices: 15,
      status: "Active",
      createdOn: "May 12, 2024",
      icon: Icons.business_rounded,
      iconColor: const Color(0xFF3B82F6),
      iconBgColor: const Color(0xFFEFF6FF),
    ),
    CategoryModel(
      name: "Interior Cleaning",
      description: "Interior deep cleaning for homes and offices",
      totalServices: 10,
      status: "Active",
      createdOn: "May 12, 2024",
      icon: Icons.chair_rounded,
      iconColor: const Color(0xFF06B6D4),
      iconBgColor: const Color(0xFFECFEFF),
    ),
    CategoryModel(
      name: "Bathroom Cleaning",
      description: "Bathroom, toilet and wash area cleaning",
      totalServices: 6,
      status: "Active",
      createdOn: "May 13, 2024",
      icon: Icons.bathtub_rounded,
      iconColor: const Color(0xFFF59E0B),
      iconBgColor: const Color(0xFFFEF3C7),
    ),
    CategoryModel(
      name: "Water Tank Cleaning",
      description: "Water tank cleaning and maintenance services",
      totalServices: 5,
      status: "Active",
      createdOn: "May 13, 2024",
      icon: Icons.opacity_rounded,
      iconColor: const Color(0xFF3B82F6),
      iconBgColor: const Color(0xFFEFF6FF),
    ),
    CategoryModel(
      name: "AC Duct Cleaning",
      description: "AC duct, vent and air system cleaning services",
      totalServices: 5,
      status: "Inactive",
      createdOn: "May 14, 2024",
      icon: Icons.toys_rounded,
      iconColor: const Color(0xFFEF4444),
      iconBgColor: const Color(0xFFFEF2F2),
    ),
  ];

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _openCreateCategoryDialog() {
    String? tempIconType;
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => Dialog(
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
                          const Divider(color: Color(0xFFE2E8F0), height: 24),
                          const SizedBox(height: 8),
                          Text(
                            "Category Name",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: nameController,
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: "Enter category name",
                              hintStyle: GoogleFonts.inter(
                                color: const Color(0xFF94A3B8),
                                fontSize: 13,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            style: GoogleFonts.inter(fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Description",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: descController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: "Enter category description",
                              hintStyle: GoogleFonts.inter(
                                color: const Color(0xFF94A3B8),
                                fontSize: 13,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            style: GoogleFonts.inter(fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Category Icon Type",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: tempIconType,
                            hint: Text(
                              "Select Icon style",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: "Vehicle",
                                child: Text("Vehicle"),
                              ),
                              DropdownMenuItem(
                                value: "Home",
                                child: Text("Home"),
                              ),
                              DropdownMenuItem(
                                value: "Pet",
                                child: Text("Pet"),
                              ),
                            ],
                            onChanged:
                                (val) =>
                                    setDialogState(() => tempIconType = val),
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
                                onPressed: () {
                                  if (nameController.text.isEmpty ||
                                      descController.text.isEmpty ||
                                      tempIconType == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Please fill in all required fields.",
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  IconData newIcon = Icons.home_rounded;
                                  Color newColor = const Color(0xFFF59E0B);
                                  Color newBgColor = const Color(0xFFFEF3C7);

                                  if (tempIconType == "Vehicle") {
                                    newIcon = Icons.directions_car_rounded;
                                    newColor = const Color(0xFF3B82F6);
                                    newBgColor = const Color(0xFFEFF6FF);
                                  } else if (tempIconType == "Pet") {
                                    newIcon = Icons.pets_rounded;
                                    newColor = const Color(0xFF8B5CF6);
                                    newBgColor = const Color(0xFFF5F3FF);
                                  }

                                  final newCategory = CategoryModel(
                                    name: nameController.text,
                                    description: descController.text,
                                    totalServices: 0,
                                    status: "Active",
                                    createdOn: "May 18, 2024",
                                    icon: newIcon,
                                    iconColor: newColor,
                                    iconBgColor: newBgColor,
                                  );

                                  setState(() {
                                    _categoriesList.insert(0, newCategory);
                                  });

                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "New category added successfully!",
                                      ),
                                    ),
                                  );
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

        final filteredList =
            _categoriesList.where((cat) {
              return cat.name.toLowerCase().contains(
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
            title: "Total Categories",
            value: "9",
            subtitle: "All service categories",
            icon: Icons.grid_view_rounded,
            color: const Color(0xFF3B82F6),
            bgColor: const Color(0xFFEFF6FF),
          ),
          _buildStatsCard(
            title: "Active Categories",
            value: "8",
            subtitle: "Currently active",
            icon: Icons.check_circle_outline_rounded,
            color: const Color(0xFF10B981),
            bgColor: const Color(0xFFECFDF5),
          ),
          _buildStatsCard(
            title: "Inactive Categories",
            value: "1",
            subtitle: "Currently inactive",
            icon: Icons.pause_circle_outline_rounded,
            color: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFFEF3C7),
          ),
          _buildStatsCard(
            title: "Most Used",
            value: "Home Services",
            subtitle: "Top performing category",
            icon: Icons.star_border_rounded,
            color: const Color(0xFF8B5CF6),
            bgColor: const Color(0xFFF5F3FF),
          ),
          _buildStatsCard(
            title: "Total Services",
            value: "128",
            subtitle: "Under all categories",
            icon: Icons.local_offer_outlined,
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

  Widget _buildFiltersCard(bool isSmall) {
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
          const Spacer(),
          filterButton,
          const SizedBox(width: 12),
          exportButton,
        ],
      ),
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
          Scrollbar(
            controller: _horizontalScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _horizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1200,
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2.2), // Category
                    1: FlexColumnWidth(3.0), // Description
                    2: FlexColumnWidth(1.4), // Total Services
                    3: FlexColumnWidth(1.4), // Status
                    4: FlexColumnWidth(1.6), // Created On
                    5: FlexColumnWidth(1.4), // Actions
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
                        _buildHeaderCell("Category"),
                        _buildHeaderCell("Description"),
                        _buildHeaderCell("Total Services"),
                        _buildHeaderCell("Status"),
                        _buildHeaderCell("Created On"),
                        _buildHeaderCell("Actions"),
                      ],
                    ),
                    ...categories.map((cat) {
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
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: cat.iconBgColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    cat.icon,
                                    color: cat.iconColor,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    cat.name,
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
                              cat.description,
                              style: GoogleFonts.inter(
                                fontSize: 12,
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
                              cat.totalServices.toString(),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12.0,
                              horizontal: 16.0,
                            ),
                            child: _buildStatusBadge(cat.status),
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
              "Are you sure you want to delete ${cat.name}? This action cannot be undone.",
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
                onPressed: () {
                  setState(() {
                    _categoriesList.remove(cat);
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Category deleted successfully."),
                    ),
                  );
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
