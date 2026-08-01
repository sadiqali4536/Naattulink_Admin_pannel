import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swiftclean_admin/MVVM/utils/rbac_session.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  bool isLoading = true;
  String name = '';
  String status = '';
  String occupation = '';
  String assignedCategory = '';
  String email = '';
  String joinedOn = '';
  String phone = '';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final session = RbacSession();
    name = session.fullName ?? 'Admin';
    status = session.status.isNotEmpty ? session.status : 'Active';
    occupation = session.roleDisplayName ?? 'System Administrator';
    assignedCategory = session.roleDisplayName ?? 'Super Admin';
    email = session.email ?? '';
    phone = '+91 98765 43210'; // Fallback
    joinedOn = '01 January 2024, 10:00 AM'; // Fallback

    if (session.uid != null) {
      try {
        final doc =
            await FirebaseFirestore.instance
                .collection('admin_users')
                .doc(session.uid)
                .get();
        if (doc.exists) {
          final data = doc.data()!;
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
          if (createdAt != null) {
            joinedOn = _formatDate(createdAt);
          }
          if (data['phone'] != null || data['phoneNumber'] != null) {
            phone = data['phone'] ?? data['phoneNumber'];
          }
        }
      } catch (e) {
        debugPrint('Error fetching admin details: $e');
      }
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year;

    int hour = dt.hour;
    final amPm = hour >= 12 ? 'PM' : 'AM';
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;
    final minute = dt.minute.toString().padLeft(2, '0');

    return '$day $month $year, $hour:$minute $amPm';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(child: CircularProgressIndicator(color: const Color(0xFFFFC107))),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildProfileCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'View and manage your profile information.',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile Overview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'S',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFC107),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        color: Color(0xFF1E293B),
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 48),
          _buildInfoRow(
            icon: Icons.work_outline,
            label: 'Occupation',
            value: occupation,
          ),
          _buildDivider(),
          if (!RbacSession().isSuperAdmin) ...[
            _buildInfoRow(
              icon: Icons.phone_outlined,
              label: 'Phone Number',
              value: phone,
            ),
            _buildDivider(),
          ],
          _buildInfoRow(
            icon: Icons.local_offer_outlined,
            label: 'Assigned Category',
            value: assignedCategory,
            isBadge: true,
            badgeColor: Colors.green.shade50,
            badgeTextColor: Colors.green.shade700,
          ),
          _buildDivider(),
          _buildInfoRow(
            icon: Icons.email_outlined,
            label: 'Email Address',
            value: email,
          ),
          _buildDivider(),
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Joined On',
            value: joinedOn,
          ),
          _buildDivider(),
          _buildInfoRow(
            icon: Icons.verified_user_outlined,
            label: 'Status',
            value: status,
            isBadge: true,
            badgeColor: Colors.green.shade50,
            badgeTextColor: Colors.green.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isBadge = false,
    Color? badgeColor,
    Color? badgeTextColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(icon, color: Colors.grey, size: 20),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child:
                isBadge
                    ? Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          value,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: badgeTextColor,
                          ),
                        ),
                      ),
                    )
                    : Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(color: Colors.black12, height: 1);
  }
}
