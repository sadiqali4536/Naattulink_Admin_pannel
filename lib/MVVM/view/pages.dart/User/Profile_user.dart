import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:swiftclean_admin/MVVM/utils/constants.dart';
import 'package:swiftclean_admin/MVVM/utils/custom_button.dart';


class User {
  final String no;
  final String name;
  final String phone;
  final String email;
  final String address;

  User({
    required this.no,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
  });

  factory User.fromMap(Map<String, dynamic> map, String id) => User(
        no: id,
        name: map['username'] ?? '',
        phone: map['phone'] ?? '',
        email: map['email'] ?? '',
        address: map['address'] ?? '',
      );

  get workType => null;
}

class ProfileUser extends StatefulWidget {
  const ProfileUser({super.key});

  @override
  State<ProfileUser> createState() => _ProfileUserState();
}

class _ProfileUserState extends State<ProfileUser> {
  User? selectedUser;
  final Set<int> _expandedRows = {};

  Widget _actionButton(String label, Color color, VoidCallback onPressed) {
    return CustomButton(
      color: color,
      width: 100,
      height: 40,
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("users")
              .where("role", isEqualTo: 'user')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.gradient1));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No users available"));
            }

            final users = snapshot.data!.docs
                .map((doc) => User.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                .toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const SizedBox(height: 30),
                      selectedUser != null
                          ? _buildUserProfile(selectedUser!)
                          : _buildUserTable(users),
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

  Widget _buildUserTable(List<User> users) {
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
              Expanded(flex: 2, child: Text("Phone", style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text("Email", style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: SizedBox()), // Buttons
            ],
          ),
        ),
        const SizedBox(height: 1),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: users.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final user = users[index];
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
                        Expanded(flex: 1, child: Text("#${index + 1}")),
                        Expanded(flex: 2, child: Text(user.name)),
                        Expanded(flex: 2, child: Text(user.phone)),
                        Expanded(flex: 2, child: Text(user.email)),
                        _actionButton("Block", Colors.black, () {
                          _showConfirmationDialog(
                            title: "Confirm Block",
                            content: "Are you sure you want to block ${user.name}?",
                            confirmText: "Block",
                            onConfirm: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("${user.name} has been blocked.")),
                              );
                            },
                          );
                        }),
                        const SizedBox(width: 8),
                        _actionButton("Delete", Colors.red, () {
                          _showConfirmationDialog(
                            title: "Confirm Delete",
                            content: "Are you sure you want to delete ${user.name}?",
                            confirmText: "Delete",
                            onConfirm: () {
                              FirebaseFirestore.instance.collection("users").doc(user.no).delete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("${user.name} has been deleted.")),
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
                              selectedUser = user;
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
                        Text("Address: ${user.address}"),
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

  Widget _buildUserProfile(User user) {
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
                onPressed: () => setState(() => selectedUser = null),
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
          const Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.black, size: 40),
            ),
          ),
          const SizedBox(height: 5),
          Center(child: Text(user.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("+91 ${user.phone}", style: const TextStyle(fontSize: 16)),
                Text(user.email, style: const TextStyle(fontSize: 16)),
                Text("Address: ${user.address}", style: const TextStyle(fontSize: 16)),
              ]),
            ],
          ),
        ],
      ),
    );
  }
}
