import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:swiftclean_admin/MVVM/utils/constants.dart';
import 'package:swiftclean_admin/MVVM/utils/custom_button.dart';

class Worker {
  final String id;
  final String name;
  final String work;
  final String phone;
  final String email;
  final String address;

  Worker({
    required this.id,
    required this.name,
    required this.work,
    required this.phone,
    required this.email,
    required this.address,
  });

  factory Worker.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Worker(
      id: doc.id,
      name: data['username'] ?? '',
      work: data['category'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      address: data['address'] ?? '',
    );
  }
}

class VerificationWorker extends StatefulWidget {
  const VerificationWorker({super.key});

  @override
  State<VerificationWorker> createState() => _VerificationWorkerState();
}

class _VerificationWorkerState extends State<VerificationWorker> {
  String? selectedWorktype;
  Worker? selectedWorker;

  void _openFilterDialog(List<Worker> allWorkers) async {
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
                items: allWorkers.map((e) => e.work).toSet().map((work) => DropdownMenuItem(value: work, child: Text(work))).toList(),
                onChanged: (value) => setDialogState(() => tempSelection = value),
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
      setState(() => selectedWorktype = result);
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

  void _verifyWorker(String workerId, bool isAccepted) async {
    await FirebaseFirestore.instance.collection("workers").doc(workerId).update({
      "isVerified": isAccepted ? 1 : -1,
    });
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection("workers").where("isVerified", isEqualTo: 0).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.gradient1));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No workers available to accept"));
        }

        final allWorkers = snapshot.data!.docs.map((doc) => Worker.fromFirestore(doc)).toList();
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
                  if (selectedWorker == null) ...[
                    Row(
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
                              onPressed: () => _openFilterDialog(allWorkers),
                              icon: Image.asset("assets/icon/funnel.png", width: 18),
                              label: const Text("Filter", style: TextStyle(color: AppColors.black)),
                            ),
                          ),
                        ),
                        if (selectedWorktype != null)
                          TextButton(
                            onPressed: () => setState(() => selectedWorktype = null),
                            child: const Text("Clear Filter", style: TextStyle(color: Colors.red)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Column(
                      children: filteredWorkers.map((worker) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(worker.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text(worker.work),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _actionButton("Accept", AppColors.gradient1, () {
                                    _showConfirmationDialog(
                                      title: "Accept Worker",
                                      content: "Are you sure you want to accept ${worker.name}?",
                                      confirmText: "Accept",
                                      onConfirm: () => _verifyWorker(worker.id, true),
                                    );
                                  }),
                                  const SizedBox(width: 10),
                                  _actionButton("Reject", Colors.red, () {
                                    _showConfirmationDialog(
                                      title: "Reject Worker",
                                      content: "Are you sure you want to reject ${worker.name}?",
                                      confirmText: "Reject",
                                      onConfirm: () => _verifyWorker(worker.id, false),
                                    );
                                  }),
                                ],
                              )
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ] else
                    _buildWorkerProfile(selectedWorker!),
                ],
              ),
            ),
          ),
        );
      },
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
          const SizedBox(height: 10),
          Center(child: Text(worker.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
          const SizedBox(height: 20),
          Text("Work: ${worker.work}"),
          Text("Phone: ${worker.phone}"),
          Text("Email: ${worker.email}"),
          Text("Address: ${worker.address}"),
        ],
      ),
    );
  }
}