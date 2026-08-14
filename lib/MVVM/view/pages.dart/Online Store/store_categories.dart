import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:swiftclean_admin/MVVM/model/models/admin_model.dart';
import 'package:swiftclean_admin/MVVM/utils/rbac_session.dart';

class StoreCategoriesPage extends StatefulWidget {
  const StoreCategoriesPage({super.key});

  @override
  State<StoreCategoriesPage> createState() => _StoreCategoriesPageState();
}

class _StoreCategoriesPageState extends State<StoreCategoriesPage> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  final _session = RbacSession();

  int _pageSize = 10;
  int _currentPage = 1;
  List<DocumentSnapshot> _pageCursors = [];
  DocumentSnapshot? _lastDocument;
  bool _hasNextPage = true;
  bool _isLoading = true;
  List<DocumentSnapshot> _categories = [];
  int _totalCategories = 0;

  bool _can(String action) {
    return _session.hasPermission(Modules.storeProducts, action);
  }

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories({
    bool isNext = false,
    bool isPrev = false,
  }) async {
    setState(() => _isLoading = true);
    try {
      final totalQuery = await FirebaseFirestore.instance.collection("store_product_categories").count().get();
      int totalCount = totalQuery.count ?? 0;

      Query query = FirebaseFirestore.instance
          .collection("store_product_categories")
          .orderBy("createdAt", descending: true);

      if (isNext && _lastDocument != null) {
        _pageCursors.add(_lastDocument!);
        _currentPage++;
        query = query.startAfterDocument(_lastDocument!);
      } else if (isPrev && _currentPage > 1) {
        _currentPage--;
        _pageCursors.removeLast();
        if (isPrev && _pageCursors.isNotEmpty) {
          query = query.startAfterDocument(_pageCursors.last);
        }
      } else if (!isNext && !isPrev) {
        _currentPage = 1;
        _pageCursors.clear();
      }

      query = query.limit(_pageSize);
      final snapshot = await query.get();

      _hasNextPage = snapshot.docs.length == _pageSize;
      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }

      if (mounted) {
        setState(() {
          _categories = snapshot.docs;
          _totalCategories = totalCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching categories: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
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
                                            Navigator.pop(dialogContext);
                                            _fetchCategories();
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

  void _showEditCategoryDialog(DocumentSnapshot categoryDoc) {
    final formKey = GlobalKey<FormState>();
    final oldName = categoryDoc['name'] as String;
    String categoryName = oldName;
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
                          "Edit Product Category",
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
                          initialValue: categoryName,
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

                                        if (categoryName.toLowerCase() ==
                                            oldName.toLowerCase()) {
                                          Navigator.pop(dialogContext);
                                          return;
                                        }

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
                                                doc.id != categoryDoc.id &&
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
                                              .doc(categoryDoc.id)
                                              .update({
                                                'name': categoryName,
                                                'updatedAt':
                                                    FieldValue.serverTimestamp(),
                                              });

                                          // Cascade update to all products
                                          final productsCheck =
                                              await db
                                                  .collection("store_products")
                                                  .where(
                                                    "category",
                                                    isEqualTo: oldName,
                                                  )
                                                  .get();
                                          if (productsCheck.docs.isNotEmpty) {
                                            WriteBatch batch = db.batch();
                                            for (var pDoc
                                                in productsCheck.docs) {
                                              batch.update(pDoc.reference, {
                                                'category': categoryName,
                                              });
                                            }
                                            await batch.commit();
                                          }

                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Category updated successfully!",
                                                ),
                                              ),
                                            );
                                            Navigator.pop(dialogContext);
                                            _fetchCategories();
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

  Future<void> _deleteCategory(DocumentSnapshot categoryDoc) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              "Delete Category",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            content: Text(
              "Are you sure you want to delete '${categoryDoc['name']}'? This action cannot be undone.\nNote: Existing products in this category will not be deleted, but they will retain the deleted category name.",
              style: GoogleFonts.inter(color: Colors.grey.shade700),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.inter(color: Colors.grey.shade600),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                child: Text(
                  "Delete",
                  style: GoogleFonts.inter(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection("store_product_categories")
          .doc(categoryDoc.id)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Category deleted successfully.")),
        );
        _fetchCategories();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete category: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_can(Perms.view)) {
      return const Center(child: Text("Access Denied"));
    }
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          // Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Manage Category",
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Online Store / Manage Category",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (_can(Perms.create))
                  ElevatedButton.icon(
                    onPressed: _showCreateCategoryDialog,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: Text(
                      "Create Category",
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
          ),
          // Body
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsRow(),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isLoading)
                            const Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFFFC107),
                                ),
                              ),
                            )
                      else if (_categories.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Center(
                            child: Text(
                              "No categories found.",
                              style: GoogleFonts.inter(
                                color: const Color(0xFF64748B),
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      else
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
                                    minWidth: constraints.maxWidth,
                                  ),
                                  child: DataTable(
                                    headingRowColor: MaterialStateProperty.all(
                                      const Color(0xFFF8FAFC),
                                    ),
                                    columns: [
                                      DataColumn(
                                        label: Text(
                                          "Name",
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF475569),
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          "Created At",
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF475569),
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          "Actions",
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF475569),
                                          ),
                                        ),
                                      ),
                                    ],
                                    rows:
                                        _categories.map((doc) {
                                          final data =
                                              doc.data()
                                                  as Map<String, dynamic>;
                                          String dateStr = "-";
                                          if (data['createdAt'] != null) {
                                            dateStr = DateFormat(
                                              'dd MMM yyyy, hh:mm a',
                                            ).format(
                                              (data['createdAt'] as Timestamp)
                                                  .toDate(),
                                            );
                                          }
                                          return DataRow(
                                            cells: [
                                              DataCell(
                                                Text(
                                                  data['name'] ?? '',
                                                  style: GoogleFonts.inter(
                                                    color: const Color(
                                                      0xFF1E293B,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  dateStr,
                                                  style: GoogleFonts.inter(
                                                    color: const Color(
                                                      0xFF64748B,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    if (_can(Perms.edit))
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.edit_outlined,
                                                          size: 20,
                                                          color: Colors.blue,
                                                        ),
                                                        onPressed:
                                                            () =>
                                                                _showEditCategoryDialog(
                                                                  doc,
                                                                ),
                                                        tooltip: "Edit",
                                                      ),
                                                    if (_can(Perms.delete))
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.delete_outline,
                                                          size: 20,
                                                          color: Colors.red,
                                                        ),
                                                        onPressed:
                                                            () =>
                                                                _deleteCategory(
                                                                  doc,
                                                                ),
                                                        tooltip: "Delete",
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      _buildPaginationFooter(),
                    ],
                  ),
                ),
                ],
              ),
            ),
          ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: _buildStatCard(
            "Total Categories",
            _totalCategories.toString(),
            Icons.category_outlined,
            const Color(0xFF3B82F6),
          ),
        ),
        const Expanded(flex: 3, child: SizedBox()),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
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
    );
  }

  Widget _buildPaginationFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                "Rows per page: ",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  isDense: true,
                  value: _pageSize,
                  items:
                      [10, 20, 50].map((size) {
                        return DropdownMenuItem<int>(
                          value: size,
                          child: Text(
                            size.toString(),
                            style: GoogleFonts.inter(fontSize: 14),
                          ),
                        );
                      }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _pageSize = val;
                        _currentPage = 1;
                        _pageCursors.clear();
                      });
                      _fetchCategories();
                    }
                  },
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                "Page $_currentPage",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed:
                    _currentPage > 1 && !_isLoading
                        ? () => _fetchCategories(isPrev: true)
                        : null,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed:
                    _hasNextPage && !_isLoading
                        ? () => _fetchCategories(isNext: true)
                        : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
