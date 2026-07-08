import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:swiftclean_admin/MVVM/utils/constants.dart';
import 'package:swiftclean_admin/MVVM/utils/custom_button.dart';

class Service {
  final String docId;
  final String no;
  String services;
  final String category;
  final String discount;
  final String price;
  final String imagePath;
  final double rating;

  Service({
    required this.docId,
    required this.rating,
    required this.no,
    required this.services,
    required this.category,
    required this.discount,
    required this.price,
    required this.imagePath,
    required String original_price,
  });

  factory Service.fromFirestore(DocumentSnapshot doc, int index) {
    final data = doc.data() as Map<String, dynamic>;
    double original = double.tryParse(data['original_price']?.toString() ?? '') ?? 0;
    double discount = double.tryParse(data['discount']?.toString().replaceAll('%', '') ?? '') ?? 0;
    double finalPrice = original - (original * discount / 100);

    return Service(
      docId: doc.id,
      no: (index + 1).toString(),
      rating: data['rating']?.toDouble() ?? 1.0,
      services: data['service_name'] ?? '',
      category: data['category'] ?? '',
      discount: '${discount.toStringAsFixed(0)}%',
      price: finalPrice.toStringAsFixed(0),
      imagePath: data['image'] ?? '',
      original_price: original.toStringAsFixed(0),
    );
  }
}

class Services extends StatefulWidget {
  const Services({super.key});

  @override
  State<Services> createState() => _ServicesState();
}

class _ServicesState extends State<Services> {
  String? selectedServiceType;
  int? editingIndex;
  final TextEditingController _editController = TextEditingController();
  List<Service> _servicesList = [];
  List<String> categories = ["Exterior", "Interior", "Vehicle", "Pet", "Home"];

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  Future<void> _openCreateServiceDialog() async {
    String? tempCategory;
    File? selectedImage;
    String serviceType = "";
    final TextEditingController serviceNameController = TextEditingController();
    final TextEditingController serviceDiscountController = TextEditingController();
    final TextEditingController servicePriceController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Create New Service", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildTextField("Service Name", serviceNameController),
                  const SizedBox(height: 20),
                  _buildDropdown("Category", tempCategory, (val) => setState(() => tempCategory = val)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            serviceType = serviceType == "Hour" ? "" : "Hour";
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: serviceType == "Hour" ? AppColors.gradient1 : Colors.grey[300],
                          foregroundColor: serviceType == "Hour" ? Colors.white : Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text("Hour"),
                      ),
                      const SizedBox(width: 10),
                      if (serviceType == "Hour")
                        const Text(
                          "/",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildTextField("Discount (%)", serviceDiscountController, isNumber: true),
                  const SizedBox(height: 20),
                  _buildTextField("Original Price", servicePriceController, isNumber: true),
                  const SizedBox(height: 20),
                  Builder(builder: (_) {
                    final price = double.tryParse(servicePriceController.text) ?? 0;
                    final discount = double.tryParse(serviceDiscountController.text) ?? 0;
                    final calculated = price - ((discount / 100) * price);
                    return Text("Discounted Price: ₹${calculated.toStringAsFixed(0)}",
                        style: const TextStyle(fontWeight: FontWeight.bold));
                  }),
                  const SizedBox(height: 20),
                  _buildImagePicker(selectedImage, () async {
                    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
                    if (result != null) {
                      setState(() => selectedImage = File(result.files.single.path!));
                    }
                  }),
                  const SizedBox(height: 30),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () async {
                        if (serviceNameController.text.isEmpty ||
                            tempCategory == null ||
                            servicePriceController.text.isEmpty ||
                            serviceDiscountController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please fill in all required fields.")));
                          return;
                        }

                        final double price = double.tryParse(servicePriceController.text) ?? 0;
                        final double discount = double.tryParse(serviceDiscountController.text) ?? 0;
                        final discounted = price - (discount / 100 * price);
                        final docRef = FirebaseFirestore.instance.collection('services').doc();

                        // Upload image to Firebase Storage
                        String imageUrl = '';
                        if (selectedImage != null) {
                          String fileName = DateTime.now().millisecondsSinceEpoch.toString();
                          Reference ref = FirebaseStorage.instance.ref().child("services/$fileName");
                          await ref.putFile(selectedImage!);
                          imageUrl = await ref.getDownloadURL();
                        }

                        // Save service to Firestore
                        await docRef.set({
                          'service_name': serviceNameController.text,
                          'category': tempCategory,
                          'discount': discount.toStringAsFixed(0),
                          'price': discounted.toStringAsFixed(0),
                          'original_price': price.toStringAsFixed(0),
                          'service_type': serviceType,
                          'image': imageUrl,
                          'serviceId': docRef.id,
                          'createAt': FieldValue.serverTimestamp(),
                          'rating': 1.0,
                        });

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("New service added successfully!")));
                        }
                      },
                      child: const Text("Save", style: TextStyle(color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String? value, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          hint: Text(label),
          decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          items: categories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildImagePicker(File? selectedImage, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Upload Image"),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(10),
            ),
            child: selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(selectedImage, fit: BoxFit.cover, width: double.infinity),
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upload_file, size: 30),
                        SizedBox(height: 8),
                        Text("Tap to Upload Image"),
                        Text("PNG, JPG, JPEG", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveEdit(int index, String newServiceName) async {
    if (newServiceName.isEmpty) return;
    final service = _servicesList[index];
    await FirebaseFirestore.instance.collection('services').doc(service.docId).update({'service_name': newServiceName});
    if (!mounted) return;
    setState(() {
      _servicesList[index].services = newServiceName;
      editingIndex = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Service updated")));
  }

  Future<void> _deleteService(Service service) async {
    await FirebaseFirestore.instance.collection('services').doc(service.docId).delete();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Service deleted")));
  }

  Future<void> _openFilterDialog() async {
    String? tempSelection = selectedServiceType;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Filter by Category"),
        content: DropdownButton<String>(
          value: tempSelection,
          hint: const Text("Select Category"),
          isExpanded: true,
          items: categories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (value) => setState(() => tempSelection = value),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, tempSelection), child: const Text("Apply")),
        ],
      ),
    );
    if (result != null) setState(() => selectedServiceType = result);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('services').orderBy('createAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        _servicesList = List.generate(snapshot.data!.docs.length, (i) => Service.fromFirestore(snapshot.data!.docs[i], i));
        final filtered = selectedServiceType == null
            ? _servicesList
            : _servicesList.where((s) => s.category == selectedServiceType).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomButton(
                    color: Colors.white,
                    width: 120,
                    height: 40,
                    onPressed: _openFilterDialog,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.filter_alt, color: AppColors.black),
                        SizedBox(width: 6),
                        Text("Filter", style: TextStyle(color: Colors.black)),
                      ],
                    ),
                  ),
                  if (selectedServiceType != null)
                    TextButton(
                      onPressed: () => setState(() => selectedServiceType = null),
                      child: const Text("Clear Filter", style: TextStyle(color: Colors.red)),
                    ),
                  const SizedBox(width: 12),
                  CustomButton(
                    color: AppColors.gradient2,
                    width: 100,
                    height: 40,
                    onPressed: _openCreateServiceDialog,
                    child: const Text("Create", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildServiceTable(filtered),
            ],
          ),
        );
      },
    );
  }

  Widget _buildServiceTable(List<Service> services) {
    return Column(
      children: [
        _buildTableHeader(),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: services.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final s = services[index];
            final isEditing = editingIndex == index;

            return Container(
              color: Colors.white,
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 1, child: Text(s.no)),
                  Expanded(
                    flex: 4,
                    child: Row(
                      children: [
                        if (s.imagePath.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(s.imagePath, width: 30, height: 30, fit: BoxFit.cover),
                          )
                        else
                          const Icon(Icons.image_not_supported, size: 30),
                        const SizedBox(width: 8),
                        if (isEditing)
                          Expanded(
                            child: TextField(
                              controller: _editController,
                              autofocus: true,
                              onSubmitted: (val) => _saveEdit(index, val),
                            ),
                          )
                        else
                          Expanded(child: Text(s.services, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                  Expanded(flex: 3, child: Text(s.category)),
                  Expanded(flex: 2, child: Text(s.discount)),
                  Expanded(flex: 2, child: Text("₹${s.price}")),
                  Expanded(
                    flex: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isEditing)
                          Row(
                            children: [
                              IconButton(icon: const Icon(Icons.check, color: AppColors.gradient1), onPressed: () => _saveEdit(index, _editController.text)),
                              IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => setState(() => editingIndex = null)),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Container(
                                height: 40,
                                width: 60,
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.blue),
                                child: TextButton(
                                  child: const Text("Edit", style: TextStyle(color: Colors.white)),
                                  onPressed: () {
                                    _editController.text = s.services;
                                    setState(() => editingIndex = index);
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                height: 40,
                                width: 70,
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: const Color.fromRGBO(223, 4, 4, 1)),
                                child: TextButton(
                                  child: const Text("Delete", style: TextStyle(color: Colors.white)),
                                  onPressed: () => _deleteService(s),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color.fromARGB(255, 205, 205, 205)),
        color: const Color.fromARGB(255, 255, 253, 253),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 1, child: Text("No", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 4, child: Text("Services", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text("Category", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text("Discount", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text("Price", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}


// import 'dart:io';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:swiftclean_admin/MVVM/utils/constants.dart';
// import 'package:swiftclean_admin/MVVM/utils/custom_button.dart';

// class Service {
//   final String docId;
//   final String no;
//   String services;
//   final String category;
//   final String discount;
//   final String price;
//   final String imagePath;
//   final double rating;

//   Service({
//     required this.docId,
//     required this.rating,
//     required this.no,
//     required this.services,
//     required this.category,
//     required this.discount,
//     required this.price,
//     required this.imagePath,
//     required String original_price,
//   });

//   factory Service.fromFirestore(DocumentSnapshot doc, int index) {
//     final data = doc.data() as Map<String, dynamic>;
//     double original = double.tryParse(data['original_price']?.toString() ?? '') ?? 0;
//     double discount = double.tryParse(data['discount']?.toString()?.replaceAll('%', '') ?? '') ?? 0;

//     double finalPrice = original - (original * discount / 100);
//     return Service(
//       docId: doc.id,
//       no: (index + 1).toString(),
//       rating: data['rating']?.toDouble() ?? 1.0,
//       services: data['service_name'] ?? '',
//       category: data['category'] ?? '',
//       discount: '${discount.toStringAsFixed(0)}%',
//       price: finalPrice.toStringAsFixed(0),
//       imagePath: data['image'] ?? '',
//       original_price: original.toStringAsFixed(0),
//     );
//   }
// }

// class Services extends StatefulWidget {
//   const Services({super.key});

//   @override
//   State<Services> createState() => _ServicesState();
// }

// class _ServicesState extends State<Services> {
//   String? selectedServiceType;
//   int? editingIndex;
//   final TextEditingController _editController = TextEditingController();
//   List<Service> _servicesList = [];
//   List<String> categories = ["Exterior", "Interior", "Vehicle", "Pet", "Home"];

//   @override
//   void dispose() {
//     _editController.dispose();
//     super.dispose();
//   }

//   Future<void> _openCreateServiceDialog() async {
//     String? tempCategory;
//     File? selectedImage;
//     String serviceType = "";
//     final TextEditingController serviceNameController = TextEditingController();
//     final TextEditingController serviceDiscountController = TextEditingController();
//     final TextEditingController servicePriceController = TextEditingController();

//     await showDialog(
//       context: context,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setState) => Dialog(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//           child: Container(
//             width: 400,
//             padding: const EdgeInsets.all(20),
//             child: SingleChildScrollView(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const Text("Create New Service", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//                       IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
//                     ],
//                   ),
//                   const SizedBox(height: 20),
//                   _buildTextField("Service Name", serviceNameController),
//                   const SizedBox(height: 20),
//                   _buildDropdown("Category", tempCategory, (val) => setState(() => tempCategory = val)),
//                   const SizedBox(height: 20),
//                   Row(
//                children: [
//                     ElevatedButton(
//                      onPressed: () {
//                       setState(() {
//                         serviceType = serviceType == "Hour" ? "" : "Hour";
//                   });
//               },
//                 style: ElevatedButton.styleFrom(
//                  backgroundColor: serviceType == "Hour"
//                      ? AppColors.gradient1
//                      : Colors.grey[300],
//                 foregroundColor:
//                     serviceType == "Hour" ? Colors.white : Colors.black,
//                          shape: RoundedRectangleBorder(
//                          borderRadius: BorderRadius.circular(10),
//                  ),
//               ),
//                child: const Text("Hour"),
//             ),

//              const SizedBox(width: 10),

//               if (serviceType == "Hour")
//                const Text(
//                        "/",
//                       style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 25,
//                      ),
//                     ),
//                    ],
//                   ),


//                   const SizedBox(height: 20),
//                   _buildTextField("Discount (%)", serviceDiscountController, isNumber: true),
//                   const SizedBox(height: 20),
//                   _buildTextField("Original Price", servicePriceController, isNumber: true),
//                   const SizedBox(height: 20),
//                   Builder(builder: (_) {
//                     final price = double.tryParse(servicePriceController.text) ?? 0;
//                     final discount = double.tryParse(serviceDiscountController.text) ?? 0;
//                     final calculated = price - ((discount / 100) * price);
//                     return Text("Discounted Price: ₹${calculated.toStringAsFixed(0)}",
//                         style: const TextStyle(fontWeight: FontWeight.bold));
//                   }),
//                   const SizedBox(height: 20),
//                   _buildImagePicker(selectedImage, () async {
//                     FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
//                     if (result != null) {
//                       setState(() => selectedImage = File(result.files.single.path!));
//                     }
//                   }),
//                   const SizedBox(height: 30),
//                   Align(
//                     alignment: Alignment.centerRight,
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green,
//                         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//                       ),
//                       onPressed: () async {
//                         if (serviceNameController.text.isNotEmpty &&
//                             tempCategory != null &&
//                             servicePriceController.text.isNotEmpty &&
//                             serviceDiscountController.text.isNotEmpty) {
//                           final double price = double.tryParse(servicePriceController.text) ?? 0;
//                           final double discount = double.tryParse(serviceDiscountController.text) ?? 0;
//                           final discounted = price - (discount / 100 * price);
//                           final docRef = FirebaseFirestore.instance.collection('services').doc();

//                           await docRef.set({
//                             'service_name': serviceNameController.text,
//                             'category': tempCategory,
//                             'discount': discount.toStringAsFixed(0),
//                             'price': discounted.toStringAsFixed(0),
//                             "original_price": price.toStringAsFixed(0),
//                             "service_type": serviceType,
//                             'image': '', // Handle image upload separately
//                             'serviceId': docRef.id,
//                             'createAt': FieldValue.serverTimestamp(),
//                             'rating': 1.0,
//                           });

//                           Navigator.pop(context);
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(content: Text("New service added successfully!")),
//                           );
//                         } else {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(content: Text("Please fill in all required fields.")),
//                           );
//                         }
//                       },
//                       child: const Text("Save", style: TextStyle(color: Colors.white)),
//                     ),
//                   )
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false}) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(label),
//         const SizedBox(height: 6),
//         TextField(
//           controller: controller,
//           keyboardType: isNumber ? TextInputType.number : TextInputType.text,
//           decoration: InputDecoration(
//             hintText: label,
//             border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildDropdown(String label, String? value, Function(String?) onChanged) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(label),
//         const SizedBox(height: 6),
//         DropdownButtonFormField<String>(
//           value: value,
//           hint: Text(label),
//           decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
//           items: categories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
//           onChanged: onChanged,
//         ),
//       ],
//     );
//   }

//   Widget _buildImagePicker(File? selectedImage, VoidCallback onTap) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text("Upload Image"),
//         const SizedBox(height: 6),
//         GestureDetector(
//           onTap: onTap,
//           child: Container(
//             height: 120,
//             decoration: BoxDecoration(
//               border: Border.all(color: Colors.grey),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: selectedImage != null
//                 ? ClipRRect(
//                     borderRadius: BorderRadius.circular(10),
//                     child: Image.file(selectedImage, fit: BoxFit.cover, width: double.infinity),
//                   )
//                 : const Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.upload_file, size: 30),
//                         SizedBox(height: 8),
//                         Text("Tap to Upload Image"),
//                         Text("PNG, JPG, JPEG", style: TextStyle(fontSize: 12, color: Colors.grey)),
//                       ],
//                     ),
//                   ),
//           ),
//         ),
//       ],
//     );
//   }

//   Future<void> _saveEdit(int index, String newServiceName) async {
//     if (newServiceName.isEmpty) return;
//     final service = _servicesList[index];
//     await FirebaseFirestore.instance.collection('services').doc(service.docId).update({'service_name': newServiceName});
//     setState(() {
//       _servicesList[index].services = newServiceName;
//       editingIndex = null;
//     });
//     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Service updated")));
//   }

//   Future<void> _deleteService(Service service) async {
//     await FirebaseFirestore.instance.collection('services').doc(service.docId).delete();
//     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Service deleted")));
//   }

//   Future<void> _openFilterDialog() async {
//     String? tempSelection = selectedServiceType;
//     final result = await showDialog<String>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("Filter by Category"),
//         content: DropdownButton<String>(
//           value: tempSelection,
//           hint: const Text("Select Category"),
//           isExpanded: true,
//           items: categories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
//           onChanged: (value) => setState(() => selectedServiceType = value),
//         ),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
//           TextButton(onPressed: () => Navigator.pop(context, tempSelection), child: const Text("Apply")),
//         ],
//       ),
//     );
//     if (result != null) setState(() => selectedServiceType = result);
//   }


//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<QuerySnapshot>(
//       stream: FirebaseFirestore.instance.collection('services').orderBy('createAt', descending: true).snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
//         if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

//         _servicesList = List.generate(snapshot.data!.docs.length, (i) => Service.fromFirestore(snapshot.data!.docs[i], i));
//         final filtered = selectedServiceType == null
//             ? _servicesList
//             : _servicesList.where((s) => s.category == selectedServiceType).toList();

//         return SingleChildScrollView(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   CustomButton(
//                     color: Colors.white,
//                     width: 120,
//                     height: 40,
//                     onPressed: _openFilterDialog,
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: const [Icon(Icons.filter_alt,color: AppColors.black,), SizedBox(width: 6), Text("Filter",style: TextStyle(color: Colors.black),)],
//                     ),
//                   ),
//                   if (selectedServiceType != null)
//                     TextButton(
//                       onPressed: () => setState(() => selectedServiceType = null),
//                       child: const Text("Clear Filter", style: TextStyle(color: Colors.red)),
//                     ),
//                   const SizedBox(width: 12),
//                   CustomButton(
//                     color: AppColors.gradient2,
//                     width: 100,
//                     height: 40,
//                     onPressed: _openCreateServiceDialog,
//                     child: const Text("Create", style: TextStyle(color: Colors.white)),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 20),
//               _buildServiceTable(filtered),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildServiceTable(List<Service> services) {
//     return Column(
//       children: [
//         _buildTableHeader(),
//         ListView.separated(
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           itemCount: services.length,
//           separatorBuilder: (_, __) => const Divider(height: 1),
//           itemBuilder: (context, index) {
//             final s = services[index];
//             final isEditing = editingIndex == index;

//             return Container(
//               color: Colors.white,
//               height: 70,
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   Expanded(
//                     flex: 1,
//                     child: Align(
//                       alignment: Alignment.centerLeft,
//                       child: Text(s.no, style: const TextStyle(fontSize: 14)),
//                     ),
//                   ),
//                   Expanded(
//                     flex: 4,
//                     child: Row(
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         if (s.imagePath.isNotEmpty)
//                           ClipRRect(
//                             borderRadius: BorderRadius.circular(4),
//                             child: Image.network(s.imagePath, width: 30, height: 30, fit: BoxFit.cover),
//                           )
//                         else
//                           const Icon(Icons.image_not_supported, size: 30),
//                         const SizedBox(width: 8),
//                         if (isEditing)
//                           Expanded(
//                             child: TextField(
//                               controller: _editController,
//                               autofocus: true,
//                               onSubmitted: (val) => _saveEdit(index, val),
//                               decoration: const InputDecoration(
//                                 isDense: true,
//                                 contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//                                 border: OutlineInputBorder(),
//                               ),
//                             ),
//                           )
//                         else
//                           Expanded(
//                             child: Text(s.services, overflow: TextOverflow.ellipsis),
//                           ),
//                       ],
//                     ),
//                   ),
//                   Expanded(
//                     flex: 3,
//                     child: Align(
//                       alignment: Alignment.centerLeft,
//                       child: Text(s.category),
//                     ),
//                   ),
//                   Expanded(
//                     flex: 2,
//                     child: Align(
//                       alignment: Alignment.centerLeft,
//                       child: Text("${s.discount}"),
//                     ),
//                   ),
//                   Expanded(
//                     flex: 2,
//                     child: Align(
//                       alignment: Alignment.centerLeft,
//                       child: Text("₹${s.price}"),
//                     ),
//                   ),
//                   Expanded(
//                     flex: 2,
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.end,
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         if (isEditing)
//                           Row(
//                             children: [
//                               IconButton(
//                                 icon: const Icon(Icons.check, color: AppColors.gradient1),
//                                 onPressed: () => _saveEdit(index, _editController.text),
//                               ),
//                               IconButton(
//                                 icon: const Icon(Icons.close, color: Colors.red),
//                                 onPressed: () => setState(() => editingIndex = null),
//                               ),
//                             ],
//                           )
//                         else ...[
//                           Container(
//                             height: 40,
//                             width: 60,
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(10),
//                               color: Colors.blue,
//                             ),
//                             child: TextButton(
//                               child: const Text("Edit", style: TextStyle(color: Colors.white)),
//                               onPressed: () {
//                                 _editController.text = s.services;
//                                 setState(() => editingIndex = index);
//                               },
//                             ),
//                           ),
//                           const SizedBox(width: 10),
//                           Container(
//                             height: 40,
//                             width: 70,
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(10),
//                               color: const Color.fromRGBO(223, 4, 4, 1),
//                             ),
//                             child: TextButton(
//                               child: const Text("Delete", style: TextStyle(color: Colors.white)),
//                               onPressed: () => _deleteService(s),
//                             ),
//                           ),
//                         ],
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//         ),
//       ],
//     );
//   }

//   Widget _buildTableHeader() {
//     return Container(
//       height: 55,
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       decoration: BoxDecoration(
//         border: Border.all(color: const Color.fromARGB(255, 205, 205, 205)),
//               color: const Color.fromARGB(255, 255, 253, 253),
//         borderRadius: BorderRadius.only(topLeft: Radius.circular(10),topRight: Radius.circular(10))),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: const [
//           Expanded(flex: 1, child: Text("No", style: TextStyle(fontWeight: FontWeight.bold))),
//           Expanded(flex: 4, child: Text("Services", style: TextStyle(fontWeight: FontWeight.bold))),
//           Expanded(flex: 3, child: Text("Category", style: TextStyle(fontWeight: FontWeight.bold))),
//           Expanded(flex: 2, child: Text("Discount", style: TextStyle(fontWeight: FontWeight.bold))),
//           Expanded(flex: 2, child: Text("Price", style: TextStyle(fontWeight: FontWeight.bold))),
//           Expanded(flex: 2, child: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold))),
//         ],
//       ),
//     );
//   }
// }

