import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:swiftclean_admin/MVVM/model/models/admin_model.dart';
import 'package:swiftclean_admin/MVVM/utils/rbac_session.dart';
import 'package:swiftclean_admin/modules/products/product_image_service.dart';

class StoreProductModel {
  final String id;
  final String productName;
  final String category;
  final String description;
  final double price;
  final double discountPrice;
  final int stockQuantity;
  final String sku;
  final String unit;
  final String imageUrl;
  final String? imageFileId;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StoreProductModel({
    required this.id,
    required this.productName,
    required this.category,
    required this.description,
    required this.price,
    required this.discountPrice,
    required this.stockQuantity,
    required this.sku,
    required this.unit,
    required this.imageUrl,
    this.imageFileId,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory StoreProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StoreProductModel(
      id: doc.id,
      productName: data['productName'] ?? '',
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      discountPrice: (data['discountPrice'] ?? 0.0).toDouble(),
      stockQuantity: data['stockQuantity'] ?? 0,
      sku: data['sku'] ?? '',
      unit: data['unit'] ?? 'Piece',
      imageUrl: data['imageUrl'] ?? '',
      imageFileId: data['imageFileId'] as String?,
      status: data['status'] ?? 'Active',
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

  Map<String, dynamic> toFirestore() {
    return {
      'productName': productName,
      'category': category,
      'description': description,
      'price': price,
      'discountPrice': discountPrice,
      'stockQuantity': stockQuantity,
      'sku': sku,
      'unit': unit,
      'imageUrl': imageUrl,
      if (imageFileId != null && imageFileId!.isNotEmpty)
        'imageFileId': imageFileId,
      'status': status,
      'createdAt':
          createdAt != null
              ? Timestamp.fromDate(createdAt!)
              : FieldValue.serverTimestamp(),
      'updatedAt':
          updatedAt != null
              ? Timestamp.fromDate(updatedAt!)
              : FieldValue.serverTimestamp(),
    };
  }
}

class StoreProductsPage extends StatefulWidget {
  const StoreProductsPage({super.key});

  @override
  State<StoreProductsPage> createState() => _StoreProductsPageState();
}

class _StoreProductsPageState extends State<StoreProductsPage> {
  String _searchQuery = "";
  String _selectedCategory = "All Categories";
  String _selectedStatus = "All Status";

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();
  final _productImageService = ProductImageService();

  List<StoreProductModel> _products = [];
  List<String> _categories = [];
  bool _isLoading = true;

  int _statTotalProducts = 0;
  int _statActiveProducts = 0;
  int _statOutOfStock = 0;
  int _statLowStock = 0;

  Timer? _searchDebounce;
  final TextEditingController _searchController = TextEditingController();
  final _session = RbacSession();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchProducts();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = val;
      });
      _fetchProducts();
    });
  }

  void _onFilterChanged() {
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = FirebaseFirestore.instance;
      Query query = db.collection("store_products");

      if (_selectedStatus != "All Status") {
        query = query.where("status", isEqualTo: _selectedStatus);
      }
      if (_selectedCategory != "All Categories") {
        query = query.where("category", isEqualTo: _selectedCategory);
      }

      final snapshot = await query.get();
      List<StoreProductModel> loadedProducts =
          snapshot.docs
              .map((doc) => StoreProductModel.fromFirestore(doc))
              .toList();

      if (_searchQuery.isNotEmpty) {
        final queryLower = _searchQuery.toLowerCase();
        loadedProducts =
            loadedProducts.where((p) {
              return p.productName.toLowerCase().contains(queryLower) ||
                  p.sku.toLowerCase().contains(queryLower);
            }).toList();
      }

      loadedProducts.sort(
        (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
          a.createdAt ?? DateTime.now(),
        ),
      );

      if (mounted) {
        setState(() {
          _products = loadedProducts;
          _isLoading = false;
        });
        _calculateStats(
          snapshot.docs
              .map((doc) => StoreProductModel.fromFirestore(doc))
              .toList(),
        );
      }
    } catch (e) {
      print("Error fetching products: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _calculateStats(List<StoreProductModel> allUnfilteredProducts) {
    int total = allUnfilteredProducts.length;
    int active = 0;
    int outOfStock = 0;
    int lowStock = 0;

    for (var p in allUnfilteredProducts) {
      if (p.status == 'Active') active++;
      if (p.stockQuantity <= 0) {
        outOfStock++;
      } else if (p.stockQuantity <= 5) {
        lowStock++;
      }
    }

    setState(() {
      _statTotalProducts = total;
      _statActiveProducts = active;
      _statOutOfStock = outOfStock;
      _statLowStock = lowStock;
    });
  }

  bool _can(String action) {
    return _session.hasPermission(Modules.storeProducts, action);
  }

  Future<void> _fetchCategories() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection("store_product_categories")
              .orderBy("name")
              .get();
      if (mounted) {
        setState(() {
          _categories =
              snapshot.docs.map((doc) => doc['name'] as String).toList();
          if (_selectedCategory != "All Categories" &&
              !_categories.contains(_selectedCategory)) {
            _selectedCategory = "All Categories";
            _fetchProducts();
          }
        });
      }
    } catch (e) {
      print("Error fetching categories: $e");
    }
  }

  void _showCreateCategoryDialog() {
    final formKey = GlobalKey<FormState>();
    String categoryName = "";
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => StatefulBuilder(
            builder: (context, setStateDialog) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width: 400,
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Create Product Category",
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Category Name *",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          decoration: InputDecoration(
                            hintText: "Enter category name",
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFF3B82F6),
                                width: 1.5,
                              ),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty)
                              return "Required";
                            return null;
                          },
                          onSaved: (val) => categoryName = val!.trim(),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed:
                                  isSaving
                                      ? null
                                      : () => Navigator.pop(dialogContext),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
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
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed:
                                  isSaving
                                      ? null
                                      : () async {
                                        if (!formKey.currentState!.validate())
                                          return;
                                        formKey.currentState!.save();

                                        setStateDialog(() => isSaving = true);

                                        try {
                                          final db = FirebaseFirestore.instance;
                                          final duplicateCheck =
                                              await db
                                                  .collection(
                                                    "store_product_categories",
                                                  )
                                                  .get();
                                          bool exists = duplicateCheck.docs.any(
                                            (doc) =>
                                                doc['name']
                                                    .toString()
                                                    .toLowerCase() ==
                                                categoryName.toLowerCase(),
                                          );

                                          if (exists) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "This category already exists.",
                                                ),
                                              ),
                                            );
                                            setStateDialog(
                                              () => isSaving = false,
                                            );
                                            return;
                                          }

                                          await db
                                              .collection(
                                                "store_product_categories",
                                              )
                                              .add({
                                                'name': categoryName,
                                                'createdAt':
                                                    FieldValue.serverTimestamp(),
                                                'updatedAt':
                                                    FieldValue.serverTimestamp(),
                                              });

                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Category created successfully!",
                                                ),
                                              ),
                                            );
                                            _fetchCategories();
                                            Navigator.pop(dialogContext);
                                          }
                                        } catch (e) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text("Error: $e"),
                                            ),
                                          );
                                          setStateDialog(
                                            () => isSaving = false,
                                          );
                                        }
                                      },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFC107),
                                foregroundColor: const Color(0xFF1E293B),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child:
                                  isSaving
                                      ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF1E293B),
                                        ),
                                      )
                                      : Text(
                                        "Save",
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
              );
            },
          ),
    );
  }

  void _showCreateProductDialog({StoreProductModel? productToEdit}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _ProductFormDialog(
            productToEdit: productToEdit,
            categories: _categories,
            onSaved: () {
              _fetchProducts();
            },
          ),
    );
  }

  Future<void> _deleteProduct(StoreProductModel product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              "Delete Product",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            content: Text(
              "Are you sure you want to delete '${product.productName}'?\nThis action cannot be undone.",
              style: GoogleFonts.inter(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.inter(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text(
                  "Delete",
                  style: GoogleFonts.inter(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection("store_products")
            .doc(product.id)
            .delete();
        if (product.imageFileId != null && product.imageFileId!.isNotEmpty) {
          try {
            await _productImageService.deleteProductImage(product.imageFileId!);
          } catch (e) {
            print("Error deleting image from ImageKit: $e");
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Product deleted successfully.")),
          );
          _fetchProducts();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error deleting product: $e")));
        }
      }
    }
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
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsRow(),
                  const SizedBox(height: 24),
                  _buildToolbar(),
                  const SizedBox(height: 16),
                  _buildProductsTable(),
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
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
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
                    "Dashboard",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  Text(
                    "Online Store",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  Text(
                    "Store Products",
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
                "Store Products",
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Manage products available in your online store.",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          if (_can(Perms.create))
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _showCreateCategoryDialog,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text(
                    "Create Category",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E293B),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _showCreateProductDialog,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text(
                    "Create Product",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    foregroundColor: const Color(0xFF1E293B),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard(
          "Total Products",
          _statTotalProducts.toString(),
          Icons.inventory_2_outlined,
          const Color(0xFF3B82F6),
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          "Active Products",
          _statActiveProducts.toString(),
          Icons.check_circle_outline_rounded,
          const Color(0xFF10B981),
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          "Out of Stock",
          _statOutOfStock.toString(),
          Icons.remove_shopping_cart_outlined,
          const Color(0xFFEF4444),
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          "Low Stock",
          _statLowStock.toString(),
          Icons.warning_amber_rounded,
          const Color(0xFFF59E0B),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
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
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 24,
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
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: "Search products by name or SKU...",
              hintStyle: GoogleFonts.inter(
                color: const Color(0xFF94A3B8),
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF94A3B8),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFF3B82F6),
                  width: 1.5,
                ),
              ),
            ),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF1E293B),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 200,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF64748B),
              ),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF1E293B),
              ),
              items:
                  ["All Categories", ..._categories]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedCategory = val);
                  _onFilterChanged();
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 160,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedStatus,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF64748B),
              ),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF1E293B),
              ),
              items:
                  ["All Status", "Active", "Inactive"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedStatus = val);
                  _onFilterChanged();
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductsTable() {
    if (_isLoading) {
      return Container(
        height: 300,
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

    if (_products.isEmpty) {
      return _buildEmptyState();
    }

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
        child: Scrollbar(
          controller: _horizontalScrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width - 350,
              ),
              child: DataTable(
                headingRowHeight: 56,
                dataRowMinHeight: 72,
                dataRowMaxHeight: 72,
                horizontalMargin: 24,
                columnSpacing: 24,
                headingRowColor: MaterialStateProperty.all(
                  const Color(0xFFF8FAFC),
                ),
                border: const TableBorder(
                  horizontalInside: BorderSide(color: Color(0xFFF1F5F9)),
                ),
                columns: [
                  DataColumn(label: _tableHeader("Product")),
                  DataColumn(label: _tableHeader("Category")),
                  DataColumn(label: _tableHeader("Price")),
                  DataColumn(label: _tableHeader("Stock")),
                  DataColumn(label: _tableHeader("SKU")),
                  DataColumn(label: _tableHeader("Status")),
                  if (_can(Perms.edit) || _can(Perms.delete))
                    DataColumn(label: _tableHeader("Actions")),
                ],
                rows:
                    _products.map((product) {
                      return DataRow(
                        cells: [
                          DataCell(_buildProductCell(product)),
                          DataCell(
                            Text(product.category, style: _rowTextStyle()),
                          ),
                          DataCell(_buildPriceCell(product)),
                          DataCell(_buildStockCell(product.stockQuantity)),
                          DataCell(
                            Text(
                              product.sku.isEmpty ? "-" : product.sku,
                              style: _rowTextStyle(),
                            ),
                          ),
                          DataCell(_buildStatusBadge(product.status)),
                          if (_can(Perms.edit) || _can(Perms.delete))
                            DataCell(_buildActionsCell(product)),
                        ],
                      );
                    }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tableHeader(String text) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF64748B),
        letterSpacing: 0.5,
      ),
    );
  }

  TextStyle _rowTextStyle() {
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF1E293B),
    );
  }

  Widget _buildProductCell(StoreProductModel product) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child:
                product.imageUrl.isNotEmpty
                    ? Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => const Icon(
                            Icons.image_not_supported_rounded,
                            color: Color(0xFF94A3B8),
                          ),
                    )
                    : const Icon(
                      Icons.inventory_2_rounded,
                      color: Color(0xFF94A3B8),
                    ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.productName,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            if (product.description.isNotEmpty)
              Text(
                product.description.length > 30
                    ? '${product.description.substring(0, 30)}...'
                    : product.description,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceCell(StoreProductModel product) {
    if (product.discountPrice > 0 && product.discountPrice < product.price) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "₹${product.discountPrice.toStringAsFixed(2)}",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF10B981),
            ),
          ),
          Text(
            "₹${product.price.toStringAsFixed(2)}",
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      );
    }
    return Text("₹${product.price.toStringAsFixed(2)}", style: _rowTextStyle());
  }

  Widget _buildStockCell(int stock) {
    Color color;
    if (stock <= 0) {
      color = const Color(0xFFEF4444);
    } else if (stock <= 5) {
      color = const Color(0xFFF59E0B);
    } else {
      color = const Color(0xFF1E293B);
    }

    return Text(
      stock.toString(),
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isActive = status == 'Active';
    final color = isActive ? const Color(0xFF10B981) : const Color(0xFF64748B);
    final bgColor =
        isActive ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildActionsCell(StoreProductModel product) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_can(Perms.edit))
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            color: const Color(0xFF3B82F6),
            tooltip: "Edit Product",
            onPressed: () => _showCreateProductDialog(productToEdit: product),
            splashRadius: 20,
          ),
        if (_can(Perms.delete))
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            color: const Color(0xFFEF4444),
            tooltip: "Delete Product",
            onPressed: () => _deleteProduct(product),
            splashRadius: 20,
          ),
      ],
    );
  }

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
              Icons.inventory_2_outlined,
              size: 64,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No Products Yet",
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Create your first product to start selling through the online store.",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
          if (_can(Perms.create))
            ElevatedButton.icon(
              onPressed: _showCreateProductDialog,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                "Create Product",
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107),
                foregroundColor: const Color(0xFF1E293B),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductFormDialog extends StatefulWidget {
  final StoreProductModel? productToEdit;
  final VoidCallback onSaved;
  final List<String> categories;

  const _ProductFormDialog({
    this.productToEdit,
    required this.onSaved,
    required this.categories,
  });

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _productImageService = ProductImageService();

  bool _isLoading = false;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  String _imageUrl = "";
  String _imageFileId = "";

  String _productName = "";
  String _category = "";
  String _description = "";
  double _price = 0.0;
  double _discountPrice = 0.0;
  int _stockQuantity = 0;
  String _sku = "";
  String _unit = "Piece";
  String _status = "Active";

  @override
  void initState() {
    super.initState();
    if (widget.categories.isNotEmpty) {
      _category = widget.categories.first;
    }
    if (widget.productToEdit != null) {
      final p = widget.productToEdit!;
      _productName = p.productName;
      _category =
          widget.categories.contains(p.category)
              ? p.category
              : (widget.categories.isNotEmpty
                  ? widget.categories.first
                  : p.category);
      if (_category.isEmpty) _category = p.category;
      _description = p.description;
      _price = p.price;
      _discountPrice = p.discountPrice;
      _stockQuantity = p.stockQuantity;
      _sku = p.sku;
      _unit = p.unit;
      _status = p.status;
      _imageUrl = p.imageUrl;
      _imageFileId = p.imageFileId ?? '';
    }
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _selectedImageBytes = result.files.single.bytes;
          _selectedImageName = result.files.single.name;
        });
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImageBytes == null) return;

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_$_selectedImageName';

    // Delete old image from ImageKit if replacing
    if (_imageFileId.isNotEmpty) {
      try {
        await _productImageService.deleteProductImage(_imageFileId);
      } catch (e) {
        print('Error deleting old product image: $e');
      }
    }

    final result = await _productImageService.uploadProductImage(
      imageBytes: _selectedImageBytes!,
      fileName: fileName,
    );

    _imageUrl = result.imageUrl;
    _imageFileId = result.imageFileId;
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      await _uploadImage();

      final data = {
        'productName': _productName,
        'category': _category,
        'description': _description,
        'price': _price,
        'discountPrice': _discountPrice,
        'stockQuantity': _stockQuantity,
        'sku': _sku,
        'unit': _unit,
        'imageUrl': _imageUrl,
        'imageFileId': _imageFileId,
        'status': _status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.productToEdit == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection("store_products").add(data);
      } else {
        await FirebaseFirestore.instance
            .collection("store_products")
            .doc(widget.productToEdit!.id)
            .update(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.productToEdit == null
                  ? "Product created successfully!"
                  : "Product updated successfully!",
            ),
          ),
        );
        widget.onSaved();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error saving product: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.productToEdit != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
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
                        isEditing ? "Edit Product" : "Create Product",
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isEditing
                            ? "Update product details."
                            : "Add a new product to your online store.",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
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
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Upload Section
                      Text(
                        "Product Image",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child:
                                  _selectedImageBytes != null
                                      ? Image.memory(
                                        _selectedImageBytes!,
                                        fit: BoxFit.cover,
                                      )
                                      : _imageUrl.isNotEmpty
                                      ? Image.network(
                                        _imageUrl,
                                        fit: BoxFit.cover,
                                      )
                                      : const Center(
                                        child: Icon(
                                          Icons.add_photo_alternate_outlined,
                                          color: Color(0xFF94A3B8),
                                          size: 32,
                                        ),
                                      ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _pickImage,
                            icon: const Icon(Icons.upload_rounded, size: 18),
                            label: Text(
                              _selectedImageBytes != null ||
                                      _imageUrl.isNotEmpty
                                  ? "Replace Image"
                                  : "Upload Image",
                              style: GoogleFonts.inter(),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1E293B),
                              elevation: 0,
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Name and Category
                      Row(
                        children: [
                          Expanded(
                            child: _buildFormField(
                              label: "Product Name *",
                              hint: "Enter product name",
                              initialValue: _productName,
                              validator: (v) => v!.isEmpty ? "Required" : null,
                              onSaved: (v) => _productName = v!,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdownField(
                              label: "Category *",
                              value: _category,
                              items:
                                  widget.categories.isNotEmpty
                                      ? widget.categories
                                      : [
                                        _category.isNotEmpty
                                            ? _category
                                            : "No Category",
                                      ],
                              onChanged: (v) => setState(() => _category = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Description
                      _buildFormField(
                        label: "Description",
                        hint: "Enter product description",
                        initialValue: _description,
                        maxLines: 3,
                        onSaved: (v) => _description = v ?? "",
                      ),
                      const SizedBox(height: 20),

                      // Price and Discount
                      Row(
                        children: [
                          Expanded(
                            child: _buildFormField(
                              label: "Price (₹) *",
                              hint: "0.00",
                              initialValue: _price > 0 ? _price.toString() : "",
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (v) {
                                if (v!.isEmpty) return "Required";
                                if (double.tryParse(v) == null)
                                  return "Invalid number";
                                return null;
                              },
                              onSaved: (v) => _price = double.parse(v!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildFormField(
                              label: "Discount Price (₹)",
                              hint: "0.00",
                              initialValue:
                                  _discountPrice > 0
                                      ? _discountPrice.toString()
                                      : "",
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (v) {
                                if (v!.isNotEmpty && double.tryParse(v) == null)
                                  return "Invalid number";
                                return null;
                              },
                              onSaved:
                                  (v) =>
                                      _discountPrice =
                                          v!.isEmpty ? 0.0 : double.parse(v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Stock, SKU, Unit
                      Row(
                        children: [
                          Expanded(
                            child: _buildFormField(
                              label: "Stock Quantity *",
                              hint: "0",
                              initialValue: _stockQuantity.toString(),
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v!.isEmpty) return "Required";
                                if (int.tryParse(v) == null)
                                  return "Invalid integer";
                                return null;
                              },
                              onSaved: (v) => _stockQuantity = int.parse(v!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildFormField(
                              label: "SKU",
                              hint: "Optional",
                              initialValue: _sku,
                              onSaved: (v) => _sku = v ?? "",
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdownField(
                              label: "Unit *",
                              value: _unit,
                              items: ["Piece", "Kg", "Pack", "Box", "Litre"],
                              onChanged: (v) => setState(() => _unit = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Status
                      _buildDropdownField(
                        label: "Product Status *",
                        value: _status,
                        items: ["Active", "Inactive"],
                        onChanged: (v) => setState(() => _status = v!),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer / Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: GoogleFonts.inter(
                        color: const Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      foregroundColor: const Color(0xFF1E293B),
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
                        _isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF1E293B),
                              ),
                            )
                            : Text(
                              isEditing ? "Save Changes" : "Create Product",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
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

  Widget _buildFormField({
    required String label,
    required String hint,
    required String initialValue,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: initialValue,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          onSaved: onSaved,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontSize: 14,
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF3B82F6),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF64748B),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF3B82F6),
                width: 1.5,
              ),
            ),
          ),
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF1E293B),
          ),
          items:
              items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
        ),
      ],
    );
  }
}
