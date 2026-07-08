import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:swiftclean_admin/MVVM/utils/constants.dart';
import 'package:swiftclean_admin/MVVM/utils/custom_button.dart';

// Worker Model
class Worker {
  final String no;
  final String name;
  final String work;
  final String phone;
  final String email;
  final String address;

  Worker({
    required this.no,
    required this.name,
    required this.work,
    required this.phone,
    required this.email,
    required this.address,
  });

  factory Worker.fromMap(Map<String, dynamic> map, String id) => Worker(
        no: id,
        name: map['username'] ?? '',
        work: map['category'] ?? '',
        phone: map['phone'] ?? '',
        email: map['email'] ?? '',
        address: map['address'] ?? '',
      );
}

class ProfileWorker extends StatefulWidget {
  const ProfileWorker({super.key});

  @override
  State<ProfileWorker> createState() => _ProfileWorkerState();
}

class _ProfileWorkerState extends State<ProfileWorker> {
  final Set<int> _expandedRows = {};
  String? selectedWorktype;
  Worker? selectedWorker;

  void _openFilterDialog() async {
    String? tempSelection = selectedWorktype;

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Filter by Work Type"),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return DropdownButton<String>(
                isExpanded: true,
                value: tempSelection,
                hint: const Text("Select Work Type"),
                items: ['Grass Cutting', 'Home Cleaning', 'Car Washing', 'Pet Cleaning']
                    .map((work) => DropdownMenuItem(value: work, child: Text(work)))
                    .toList(),
                onChanged: (value) {
                  setDialogState(() => tempSelection = value);
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, tempSelection),
              child: const Text("Apply", style: TextStyle(color: AppColors.black)),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        selectedWorktype = result;
      });
    }
  }

  Widget _actionButton(String label, Color color, VoidCallback onPressed) {
    return CustomButton(
      color: color,
      width: 100,
      height: 40,
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection("workers").where("role", isEqualTo: 'worker').where('isVerified',isEqualTo: 1).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.gradient1));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No workers available"));
            }

            final allWorkers = snapshot.data!.docs
                .map((doc) => Worker.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                .toList();

            final filteredWorkers = selectedWorktype == null
                ? allWorkers
                : allWorkers.where((w) => w.work == selectedWorktype).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (selectedWorker == null) _buildFilterControls(filteredWorkers),
                      const SizedBox(height: 30),
                      selectedWorker != null
                          ? _buildWorkerProfile(selectedWorker!)
                          : _buildWorkerTable(filteredWorkers),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterControls(List<Worker> currentList) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Material(
          elevation: 5,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 45,
            width: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: TextButton.icon(
              onPressed: _openFilterDialog,
              icon: Image.asset("assets/icon/funnel.png", width: 18),
              label: const Text("Filter", style: TextStyle(color: AppColors.black)),
            ),
          ),
        ),
        if (selectedWorktype != null)
          TextButton(
            onPressed: () {
              setState(() {
                selectedWorktype = null;
              });
            },
            child: const Text("Clear Filter", style: TextStyle(color: Colors.red)),
          ),
      ],
    );
  }

  Widget _buildWorkerTable(List<Worker> filteredWorkers) {
    return Column(
      children: [
        Container(
          height: 55,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            border: Border.all(color: const Color.fromARGB(255, 214, 214, 214)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: const Row(
            children: [
              Expanded(flex: 1, child: Text("No.", style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text("Name", style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text("Work", style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text("Phone", style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text("Email", style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 3, child: SizedBox()), // Buttons
            ],
          ),
        ),
        const SizedBox(height: 1),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredWorkers.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final worker = filteredWorkers[index];
            final isExpanded = _expandedRows.contains(index);

            return Column(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isExpanded ? _expandedRows.remove(index) : _expandedRows.add(index);
                    });
                  },
                  child: Container(
                    height: 55,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Row(
                      children: [
                        Expanded(flex: 1, child: Text("#${index+1}")),
                        Expanded(flex: 2, child: Text(worker.name)),
                        Expanded(flex: 2, child: Text(worker.work)),
                        Expanded(flex: 2, child: Text(worker.phone)),
                        Expanded(flex: 2, child: Text(worker.email)),
                        _actionButton("Block", Colors.black, () {
                          _showConfirmationDialog(
                            title: "Confirm Block",
                            content: "Are you sure you want to block ${worker.name}?",
                            confirmText: "Block",
                            onConfirm: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("${worker.name} has been blocked.")),
                              );
                            },
                          );
                        }),
                        const SizedBox(width: 8),
                        _actionButton("Delete", Colors.red, () {
                          _showConfirmationDialog(
                            title: "Confirm Delete",
                            content: "Are you sure you want to delete ${worker.name}?",
                            confirmText: "Delete",
                            onConfirm: () {
                              FirebaseFirestore.instance.collection("users").doc(worker.no).delete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("${worker.name} has been deleted.")),
                              );
                            },
                          );
                        }),
                        const SizedBox(width: 8),
                        CustomButton(
                          color: AppColors.gradient1,
                          width: 100,
                          height: 40,
                          onPressed: () {
                            setState(() {
                              selectedWorker = worker;
                            });
                          },
                          child: const Icon(Icons.arrow_forward, size: 25, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isExpanded)
                  Container(
                    width: double.infinity,
                    color: Colors.grey[100],
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    child: Row(
                      children: [
                        const Text("More Details: "),
                        const SizedBox(width: 10),
                        Text("Address ${worker.address}"),
                        const Spacer(),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildWorkerProfile(Worker worker) {
    return Container(
      width: 600,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomButton(
                onPressed: () => setState(() => selectedWorker = null),
                color: Colors.grey,
                width: 130,
                height: 40,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_back, color: Colors.white),
                    SizedBox(width: 5),
                    Text("Back", style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Center(child: CircleAvatar(radius: 40, backgroundColor: Colors.white, child: Icon(Icons.person, color: Colors.black, size: 40))),
          const SizedBox(height: 5),
          Center(child: Text(worker.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(worker.work, style: const TextStyle(fontSize: 16)),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("+91 ${worker.phone}", style: const TextStyle(fontSize: 16)),
                Text(worker.email, style: const TextStyle(fontSize: 16)),
                Text("Address ${worker.address}", style: const TextStyle(fontSize: 16)),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog({
    required String title,
    required String content,
    required String confirmText,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: Text(confirmText, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
