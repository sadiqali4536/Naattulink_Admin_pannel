import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WorkerModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String category;
  final String experience;
  final double rating;
  final int ratingsCount;
  final int jobsCompleted;
  final String status;
  final String verification;
  final String joinedOn;
  final String avatarUrl;
  final String address;
  final DateTime? createdAt;

  WorkerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.category,
    required this.experience,
    required this.rating,
    required this.ratingsCount,
    required this.jobsCompleted,
    required this.status,
    required this.verification,
    required this.joinedOn,
    required this.avatarUrl,
    required this.address,
    this.createdAt,
  });
}

class AllWorkersPage extends StatefulWidget {
  final String initialFilter;
  final ValueChanged<String>? onTabChanged;

  const AllWorkersPage({
    super.key,
    this.initialFilter = "All",
    this.onTabChanged,
  });

  @override
  State<AllWorkersPage> createState() => _AllWorkersPageState();
}

class _AllWorkersPageState extends State<AllWorkersPage> {
  late int _selectedTabIndex;
  String _searchQuery = "";
  String _selectedCategory = "All Categories";
  String _selectedStatus = "All Status";
  String _selectedVerification = "All Verification";
  String _selectedRating = "All Ratings";

  bool _seeding = false;
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  final List<WorkerModel> _dummyWorkersToSeed = [
    WorkerModel(
      id: '',
      name: "Arun Kumar",
      phone: "+91 98765 43210",
      email: "arun.kumar@email.com",
      category: "Home Cleaning",
      experience: "3 Years",
      rating: 4.8,
      ratingsCount: 128,
      jobsCompleted: 156,
      status: "Approved",
      verification: "Verified",
      joinedOn: "May 18, 2024",
      avatarUrl: "https://randomuser.me/api/portraits/men/1.jpg",
      address: "Chennai, India",
    ),
    WorkerModel(
      id: '',
      name: "Priya Nair",
      phone: "+91 98765 43211",
      email: "priya.nair@email.com",
      category: "Pet Grooming",
      experience: "2 Years",
      rating: 4.6,
      ratingsCount: 96,
      jobsCompleted: 112,
      status: "Pending",
      verification: "Pending",
      joinedOn: "May 17, 2024",
      avatarUrl: "https://randomuser.me/api/portraits/women/2.jpg",
      address: "Bangalore, India",
    ),
    WorkerModel(
      id: '',
      name: "Suresh Babu",
      phone: "+91 98765 43212",
      email: "suresh.babu@email.com",
      category: "Garden Services",
      experience: "5 Years",
      rating: 4.7,
      ratingsCount: 203,
      jobsCompleted: 198,
      status: "Approved",
      verification: "Verified",
      joinedOn: "May 16, 2024",
      avatarUrl: "https://randomuser.me/api/portraits/men/3.jpg",
      address: "Hyderabad, India",
    ),
    WorkerModel(
      id: '',
      name: "Meena Devi",
      phone: "+91 98765 43213",
      email: "meena.devi@email.com",
      category: "Room Cleaning",
      experience: "1 Year",
      rating: 4.5,
      ratingsCount: 72,
      jobsCompleted: 68,
      status: "Rejected",
      verification: "Not Verified",
      joinedOn: "May 15, 2024",
      avatarUrl: "https://randomuser.me/api/portraits/women/4.jpg",
      address: "Mumbai, India",
    ),
    WorkerModel(
      id: '',
      name: "Vikram Singh",
      phone: "+91 98765 43214",
      email: "vikram.singh@email.com",
      category: "Vehicle Cleaning",
      experience: "4 Years",
      rating: 4.9,
      ratingsCount: 176,
      jobsCompleted: 221,
      status: "Approved",
      verification: "Verified",
      joinedOn: "May 14, 2024",
      avatarUrl: "https://randomuser.me/api/portraits/men/5.jpg",
      address: "Delhi, India",
    ),
    WorkerModel(
      id: '',
      name: "Ramesh K",
      phone: "+91 98765 43215",
      email: "ramesh.k@email.com",
      category: "Interior Cleaning",
      experience: "3 Years",
      rating: 4.4,
      ratingsCount: 88,
      jobsCompleted: 95,
      status: "Suspended",
      verification: "Verified",
      joinedOn: "May 13, 2024",
      avatarUrl: "https://randomuser.me/api/portraits/men/6.jpg",
      address: "Kolkata, India",
    ),
    WorkerModel(
      id: '',
      name: "Anjali Sharma",
      phone: "+91 98765 43216",
      email: "anjali.sharma@email.com",
      category: "Home Cleaning",
      experience: "2 Years",
      rating: 4.6,
      ratingsCount: 117,
      jobsCompleted: 134,
      status: "Approved",
      verification: "Verified",
      joinedOn: "May 12, 2024",
      avatarUrl: "https://randomuser.me/api/portraits/women/7.jpg",
      address: "Pune, India",
    ),
    WorkerModel(
      id: '',
      name: "Manoj Varma",
      phone: "+91 98765 43217",
      email: "manoj.varma@email.com",
      category: "Garden Services",
      experience: "6 Years",
      rating: 4.8,
      ratingsCount: 210,
      jobsCompleted: 245,
      status: "Approved",
      verification: "Verified",
      joinedOn: "May 11, 2024",
      avatarUrl: "https://randomuser.me/api/portraits/men/8.jpg",
      address: "Chennai, India",
    ),
  ];

  DateTime? _parseJoinedOn(String joinedOn) {
    try {
      final parts = joinedOn.replaceAll(',', '').split(' ');
      if (parts.length == 3) {
        final monthStr = parts[0].substring(0, 3).toLowerCase();
        final day = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        final months = {
          'jan': 1,
          'feb': 2,
          'mar': 3,
          'apr': 4,
          'may': 5,
          'jun': 6,
          'jul': 7,
          'aug': 8,
          'sep': 9,
          'oct': 10,
          'nov': 11,
          'dec': 12,
        };
        final month = months[monthStr] ?? 1;
        return DateTime(year, month, day);
      }
    } catch (_) {}
    return null;
  }

  String _formatCurrentDate() {
    final now = DateTime.now();
    final months = [
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
    return "${months[now.month - 1]} ${now.day}, ${now.year}";
  }

  void _checkAndSeed(List<WorkerModel> workers) {
    if (workers.isEmpty && !_seeding) {
      _seeding = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final collection = FirebaseFirestore.instance.collection("workers");
          final snapshot = await collection.limit(1).get();
          if (snapshot.docs.isEmpty) {
            final batch = FirebaseFirestore.instance.batch();
            for (var dummy in _dummyWorkersToSeed) {
              final docRef = collection.doc();
              final seedDate = _parseJoinedOn(dummy.joinedOn) ?? DateTime.now();
              batch.set(docRef, {
                'username': dummy.name,
                'phone': dummy.phone,
                'email': dummy.email,
                'category': dummy.category,
                'experience': dummy.experience,
                'rating': dummy.rating,
                'ratingsCount': dummy.ratingsCount,
                'jobsCompleted': dummy.jobsCompleted,
                'status': dummy.status,
                'verification': dummy.verification,
                'isVerified':
                    dummy.status == "Approved"
                        ? 1
                        : dummy.status == "Pending"
                        ? 0
                        : dummy.status == "Rejected"
                        ? -1
                        : -2,
                'role': 'worker',
                'joinedOn': dummy.joinedOn,
                'avatarUrl': dummy.avatarUrl,
                'address': dummy.address,
                'createdAt': Timestamp.fromDate(seedDate),
              });
            }
            await batch.commit();
          }
        } catch (e) {
          debugPrint("Error seeding dummy data: $e");
        } finally {
          _seeding = false;
        }
      });
    }
  }

  void _changeWorkerStatus(WorkerModel worker, String newStatus) async {
    String newVerification = worker.verification;
    int isVerifiedVal = 0;

    if (newStatus == "Approved") {
      newVerification = "Verified";
      isVerifiedVal = 1;
    } else if (newStatus == "Suspended") {
      newVerification = "Not Verified";
      isVerifiedVal = -2;
    } else if (newStatus == "Rejected") {
      newVerification = "Not Verified";
      isVerifiedVal = -1;
    } else if (newStatus == "Pending") {
      newVerification = "Pending";
      isVerifiedVal = 0;
    }

    try {
      await FirebaseFirestore.instance
          .collection("workers")
          .doc(worker.id)
          .update({
            "status": newStatus,
            "verification": newVerification,
            "isVerified": isVerifiedVal,
          });
      if (mounted) {
        String msg = "";
        if (newStatus == "Approved") {
          msg = "${worker.name} approved successfully.";
        } else if (newStatus == "Rejected") {
          msg = "${worker.name} rejected successfully.";
        } else if (newStatus == "Suspended") {
          msg = "${worker.name} suspended successfully.";
        } else {
          msg = "${worker.name} status updated to $newStatus.";
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error updating status: $e")));
      }
    }
  }

  void _showWorkerDetailsDialog(WorkerModel worker) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              width: 480,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000), // 8% opacity
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Worker Profile Details",
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF64748B),
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        splashRadius: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(height: 1, color: const Color(0xFFE2E8F0)),
                  const SizedBox(height: 24),

                  // Wrap details body in Flexible + SingleChildScrollView to prevent overflow
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile Header Card (Avatar + Name + Status Badges)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                    width: 3,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(40),
                                  child: Image.network(
                                    worker.avatarUrl,
                                    width: 72,
                                    height: 72,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 72,
                                        height: 72,
                                        color: const Color(0xFFE2E8F0),
                                        child: const Icon(
                                          Icons.person,
                                          color: Color(0xFF64748B),
                                          size: 32,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      worker.name,
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      worker.category,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF10B981),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        _buildStatusBadge(worker.status),
                                        const SizedBox(width: 8),
                                        _buildVerificationBadge(
                                          worker.verification,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Details Grid / List
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFF1F5F9),
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildDetailRow(
                                  Icons.phone_outlined,
                                  "Phone Number",
                                  worker.phone,
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Divider(color: Color(0xFFE2E8F0)),
                                ),
                                _buildDetailRow(
                                  Icons.mail_outline_rounded,
                                  "Email Address",
                                  worker.email,
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Divider(color: Color(0xFFE2E8F0)),
                                ),
                                _buildDetailRow(
                                  Icons.location_on_outlined,
                                  "Location",
                                  worker.address,
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Divider(color: Color(0xFFE2E8F0)),
                                ),
                                _buildDetailRow(
                                  Icons.work_outline_rounded,
                                  "Experience",
                                  worker.experience,
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Divider(color: Color(0xFFE2E8F0)),
                                ),
                                _buildDetailRow(
                                  Icons.task_alt_rounded,
                                  "Jobs Completed",
                                  "${worker.jobsCompleted} Completed Jobs",
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Divider(color: Color(0xFFE2E8F0)),
                                ),
                                _buildDetailRow(
                                  Icons.star_outline_rounded,
                                  "Rating & Reviews",
                                  "${worker.rating} / 5.0 (${worker.ratingsCount} reviews)",
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Divider(color: Color(0xFFE2E8F0)),
                                ),
                                _buildDetailRow(
                                  Icons.calendar_today_outlined,
                                  "Joined On",
                                  worker.joinedOn,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          "Close",
                          style: GoogleFonts.inter(
                            color: const Color(0xFF475569),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
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
  }

  void _showEditWorkerDialog(WorkerModel worker) {
    final formKey = GlobalKey<FormState>();
    String name = worker.name;
    String email = worker.email;
    String phone = worker.phone;
    String address = worker.address;
    String category = worker.category;
    String experience = worker.experience;

    final validCategories = [
      "Home Cleaning",
      "Pet Grooming",
      "Garden Services",
      "Room Cleaning",
      "Vehicle Cleaning",
      "Interior Cleaning",
    ];
    if (!validCategories.contains(category)) {
      category = validCategories.first;
    }

    final validExperiences = [
      "Less than 6 months",
      "6 months",
      "More than 6 months",
      "1 Year",
      "2 Years",
      "3 Years",
      "4 Years",
      "5 Years",
      "6+ Years",
    ];
    if (!validExperiences.contains(experience)) {
      experience = validExperiences.first;
    }

    showDialog(
      context: context,
      builder:
          (dialogContext) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              width: 460,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000), // black with 8% opacity
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Edit Worker Details",
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFF64748B),
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            splashRadius: 18,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(height: 1, color: const Color(0xFFE2E8F0)),
                      const SizedBox(height: 20),

                      // Full Name Field
                      Text(
                        "Full Name",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        initialValue: name,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          hintText: "Enter full name",
                          hintStyle: GoogleFonts.inter(
                            color: const Color(0xFF94A3B8),
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(
                            Icons.person_outline_rounded,
                            color: Color(0xFF94A3B8),
                            size: 18,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF10B981),
                              width: 1.5,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 1.5,
                            ),
                          ),
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF1E293B),
                        ),
                        validator:
                            (v) =>
                                v == null || v.isEmpty
                                    ? "Name is required"
                                    : null,
                        onSaved: (v) => name = v!,
                      ),
                      const SizedBox(height: 16),

                      // Email Field
                      Text(
                        "Email Address",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        initialValue: email,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          hintText: "Enter email address",
                          hintStyle: GoogleFonts.inter(
                            color: const Color(0xFF94A3B8),
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(
                            Icons.mail_outline_rounded,
                            color: Color(0xFF94A3B8),
                            size: 18,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF10B981),
                              width: 1.5,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 1.5,
                            ),
                          ),
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF1E293B),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return "Email is required";
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(v)) {
                            return "Enter a valid email address";
                          }
                          return null;
                        },
                        onSaved: (v) => email = v!,
                      ),
                      const SizedBox(height: 16),

                      // Phone Number Field
                      Text(
                        "Phone Number",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        initialValue: phone,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          hintText: "+91 XXXXX XXXXX",
                          hintStyle: GoogleFonts.inter(
                            color: const Color(0xFF94A3B8),
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(
                            Icons.phone_outlined,
                            color: Color(0xFF94A3B8),
                            size: 18,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF10B981),
                              width: 1.5,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 1.5,
                            ),
                          ),
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF1E293B),
                        ),
                        validator:
                            (v) =>
                                v == null || v.isEmpty
                                    ? "Phone number is required"
                                    : null,
                        onSaved: (v) => phone = v!,
                      ),
                      const SizedBox(height: 16),

                      // Location Field
                      Text(
                        "Worker Location",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        initialValue: address,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          hintText: "e.g. Chennai, India",
                          hintStyle: GoogleFonts.inter(
                            color: const Color(0xFF94A3B8),
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(
                            Icons.location_on_outlined,
                            color: Color(0xFF94A3B8),
                            size: 18,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF10B981),
                              width: 1.5,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 1.5,
                            ),
                          ),
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF1E293B),
                        ),
                        validator:
                            (v) =>
                                v == null || v.isEmpty
                                    ? "Location is required"
                                    : null,
                        onSaved: (v) => address = v!,
                      ),
                      const SizedBox(height: 16),

                      // Category Field
                      Text(
                        "Service Category",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          prefixIcon: const Icon(
                            Icons.category_outlined,
                            color: Color(0xFF94A3B8),
                            size: 18,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF10B981),
                              width: 1.5,
                            ),
                          ),
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF1E293B),
                        ),
                        items:
                            validCategories
                                .map(
                                  (cat) => DropdownMenuItem(
                                    value: cat,
                                    child: Text(cat),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => category = v!,
                      ),
                      const SizedBox(height: 16),

                      // Experience Field
                      Text(
                        "Experience Level",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: experience,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          prefixIcon: const Icon(
                            Icons.work_outline_rounded,
                            color: Color(0xFF94A3B8),
                            size: 18,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF10B981),
                              width: 1.5,
                            ),
                          ),
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF1E293B),
                        ),
                        items:
                            validExperiences
                                .map(
                                  (exp) => DropdownMenuItem(
                                    value: exp,
                                    child: Text(exp),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => experience = v!,
                      ),
                      const SizedBox(height: 24),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
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
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                formKey.currentState!.save();
                                Navigator.pop(dialogContext);
                                try {
                                  await FirebaseFirestore.instance
                                      .collection("workers")
                                      .doc(worker.id)
                                      .update({
                                        'username': name,
                                        'phone': phone,
                                        'email': email,
                                        'category': category,
                                        'experience': experience,
                                        'address': address,
                                      });
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Worker updated successfully.",
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Error updating worker: $e",
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              "Save Changes",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF64748B), size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddWorkerDialog() {
    final formKey = GlobalKey<FormState>();
    String name = "";
    String email = "";
    String phone = "";
    String address = "";
    String category = "Home Cleaning";
    String experience = "1 Year";

    showDialog(
      context: context,
      builder:
          (dialogContext) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              width: 460,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000), // black with 8% opacity
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Add New Worker",
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFF64748B),
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            splashRadius: 18,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(height: 1, color: const Color(0xFFE2E8F0)),
                      const SizedBox(height: 20),

                      // Full Name Field
                      Text(
                        "Full Name",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          hintText: "Enter full name",
                          hintStyle: GoogleFonts.inter(
                            color: const Color(0xFF94A3B8),
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(
                            Icons.person_outline_rounded,
                            color: Color(0xFF94A3B8),
                            size: 18,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF10B981),
                              width: 1.5,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 1.5,
                            ),
                          ),
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF1E293B),
                        ),
                        validator:
                            (v) =>
                                v == null || v.isEmpty
                                    ? "Name is required"
                                    : null,
                        onSaved: (v) => name = v!,
                      ),
                      const SizedBox(height: 16),

                      // Email Field
                      Text(
                        "Email Address",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          hintText: "Enter email address",
                          hintStyle: GoogleFonts.inter(
                            color: const Color(0xFF94A3B8),
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(
                            Icons.mail_outline_rounded,
                            color: Color(0xFF94A3B8),
                            size: 18,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF10B981),
                              width: 1.5,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 1.5,
                            ),
                          ),
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF1E293B),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return "Email is required";
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(v)) {
                            return "Enter a valid email address";
                          }
                          return null;
                        },
                        onSaved: (v) => email = v!,
                      ),
                      const SizedBox(height: 16),

                      // Phone Field
                      Text(
                        "Phone Number",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          hintText: "+91 XXXXX XXXXX",
                          hintStyle: GoogleFonts.inter(
                            color: const Color(0xFF94A3B8),
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(
                            Icons.phone_outlined,
                            color: Color(0xFF94A3B8),
                            size: 18,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF10B981),
                              width: 1.5,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 1.5,
                            ),
                          ),
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF1E293B),
                        ),
                        validator:
                            (v) =>
                                v == null || v.isEmpty
                                    ? "Phone number is required"
                                    : null,
                        onSaved: (v) => phone = v!,
                      ),
                      const SizedBox(height: 16),

                      // Location Field
                      Text(
                        "Worker Location",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          hintText: "e.g. Chennai, India",
                          hintStyle: GoogleFonts.inter(
                            color: const Color(0xFF94A3B8),
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(
                            Icons.location_on_outlined,
                            color: Color(0xFF94A3B8),
                            size: 18,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF10B981),
                              width: 1.5,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 1.5,
                            ),
                          ),
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF1E293B),
                        ),
                        validator:
                            (v) =>
                                v == null || v.isEmpty
                                    ? "Location is required"
                                    : null,
                        onSaved: (v) => address = v!,
                      ),
                      const SizedBox(height: 16),

                      // Category Field
                      Text(
                        "Service Category",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          prefixIcon: const Icon(
                            Icons.category_outlined,
                            color: Color(0xFF94A3B8),
                            size: 18,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF10B981),
                              width: 1.5,
                            ),
                          ),
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF1E293B),
                        ),
                        items:
                            [
                                  "Home Cleaning",
                                  "Pet Grooming",
                                  "Garden Services",
                                  "Room Cleaning",
                                  "Vehicle Cleaning",
                                  "Interior Cleaning",
                                ]
                                .map(
                                  (cat) => DropdownMenuItem(
                                    value: cat,
                                    child: Text(cat),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => category = v!,
                      ),
                      const SizedBox(height: 16),

                      // Experience Field
                      Text(
                        "Experience Level",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: experience,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          prefixIcon: const Icon(
                            Icons.work_outline_rounded,
                            color: Color(0xFF94A3B8),
                            size: 18,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF10B981),
                              width: 1.5,
                            ),
                          ),
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF1E293B),
                        ),
                        items:
                            [
                                  "Less than 6 months",
                                  "6 months",
                                  "More than 6 months",
                                  "1 Year",
                                  "2 Years",
                                  "3 Years",
                                  "4 Years",
                                  "5 Years",
                                  "6+ Years",
                                ]
                                .map(
                                  (exp) => DropdownMenuItem(
                                    value: exp,
                                    child: Text(exp),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => experience = v!,
                      ),
                      const SizedBox(height: 24),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
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
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                formKey.currentState!.save();
                                Navigator.pop(dialogContext);
                                try {
                                  final newWorkerData = {
                                    'username': name,
                                    'phone': phone,
                                    'email': email,
                                    'category': category,
                                    'experience': experience,
                                    'rating': 0.0,
                                    'ratingsCount': 0,
                                    'jobsCompleted': 0,
                                    'status': "Pending",
                                    'verification': "Pending",
                                    'isVerified': 0,
                                    'role': 'worker',
                                    'joinedOn': _formatCurrentDate(),
                                    'avatarUrl':
                                        "https://randomuser.me/api/portraits/men/9.jpg",
                                    'address': address,
                                    'createdAt': FieldValue.serverTimestamp(),
                                  };
                                  await FirebaseFirestore.instance
                                      .collection("workers")
                                      .add(newWorkerData);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Worker added successfully.",
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Error adding worker: $e"),
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              "Add Worker",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
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
  void initState() {
    super.initState();
    // Set active tab based on router request
    switch (widget.initialFilter) {
      case "Pending":
        _selectedTabIndex = 1;
        break;
      case "Approved":
        _selectedTabIndex = 2;
        break;
      case "Rejected":
        _selectedTabIndex = 3;
        break;
      case "Suspended":
        _selectedTabIndex = 4;
        break;
      case "All":
      default:
        _selectedTabIndex = 0;
        break;
    }
  }

  @override
  void didUpdateWidget(covariant AllWorkersPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFilter != widget.initialFilter) {
      setState(() {
        switch (widget.initialFilter) {
          case "Pending":
            _selectedTabIndex = 1;
            break;
          case "Approved":
            _selectedTabIndex = 2;
            break;
          case "Rejected":
            _selectedTabIndex = 3;
            break;
          case "Suspended":
            _selectedTabIndex = 4;
            break;
          case "All":
          default:
            _selectedTabIndex = 0;
            break;
        }
      });
    }
  }

  Widget _buildBreadcrumbs() {
    String subPath = "All Workers";
    if (_selectedTabIndex == 1) subPath = "Pending Approvals";
    if (_selectedTabIndex == 2) subPath = "Approved Workers";
    if (_selectedTabIndex == 3) subPath = "Rejected Workers";
    if (_selectedTabIndex == 4) subPath = "Suspended Workers";

    return Row(
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
          "Worker Management",
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
          subPath,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  WorkerModel _parseWorker(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Normalize status and verification casing from database (e.g. 'pending' -> 'Pending')
    String rawStatus = data['status']?.toString() ?? 'Pending';
    String status = 'Pending';
    if (rawStatus.toLowerCase() == 'approved') {
      status = 'Approved';
    } else if (rawStatus.toLowerCase() == 'pending') {
      status = 'Pending';
    } else if (rawStatus.toLowerCase() == 'rejected') {
      status = 'Rejected';
    } else if (rawStatus.toLowerCase() == 'suspended') {
      status = 'Suspended';
    }

    String rawVerification = data['verification']?.toString() ?? 'Pending';
    String verification = 'Pending';
    if (rawVerification.toLowerCase() == 'verified') {
      verification = 'Verified';
    } else if (rawVerification.toLowerCase() == 'pending') {
      verification = 'Pending';
    } else if (rawVerification.toLowerCase() == 'not verified') {
      verification = 'Not Verified';
    }

    // Override based on isVerified value and type (int, double, bool, String)
    if (data['isVerified'] != null) {
      final isVerified = data['isVerified'];
      int? normalizedIsVerified;
      if (isVerified is bool) {
        normalizedIsVerified = isVerified ? 1 : 0;
      } else if (isVerified is num) {
        normalizedIsVerified = isVerified.toInt();
      } else if (isVerified is String) {
        normalizedIsVerified = int.tryParse(isVerified);
        if (normalizedIsVerified == null) {
          if (isVerified.toLowerCase() == 'true') normalizedIsVerified = 1;
          if (isVerified.toLowerCase() == 'false') normalizedIsVerified = 0;
        }
      }

      if (normalizedIsVerified != null) {
        if (normalizedIsVerified == 1) {
          status = 'Approved';
          verification = 'Verified';
        } else if (normalizedIsVerified == 0) {
          status = 'Pending';
          verification = 'Pending';
        } else if (normalizedIsVerified == -1) {
          status = 'Rejected';
          verification = 'Not Verified';
        } else if (normalizedIsVerified == -2) {
          status = 'Suspended';
          verification = 'Verified';
        }
      }
    }

    double toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return 0.0;
    }

    int toInt(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toInt();
      return 0;
    }

    DateTime? createdAt;
    if (data['createdAt'] != null) {
      if (data['createdAt'] is Timestamp) {
        createdAt = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is String) {
        createdAt = DateTime.tryParse(data['createdAt']);
      }
    }

    return WorkerModel(
      id: doc.id,
      name: data['username'] ?? data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      category: data['category'] ?? '',
      experience: data['experience'] ?? '1 Year',
      rating: toDouble(data['rating']),
      ratingsCount: toInt(data['ratingsCount']),
      jobsCompleted: toInt(data['jobsCompleted']),
      status: status,
      verification: verification,
      joinedOn: data['joinedOn'] ?? 'May 18, 2024',
      avatarUrl:
          data['avatarUrl'] ?? 'https://randomuser.me/api/portraits/men/1.jpg',
      address: data['address'] ?? 'Chennai, India',
      createdAt: createdAt,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("workers").snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF10B981)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text("Error fetching workers: ${snapshot.error}"),
          );
        }

        final List<WorkerModel> allWorkers =
            snapshot.data!.docs.map((doc) => _parseWorker(doc)).toList();

        // Sort in memory: newly added data at top
        final now = DateTime.now();
        allWorkers.sort((a, b) {
          final timeA =
              a.createdAt ??
              (a.joinedOn.contains("2024")
                  ? _parseJoinedOn(a.joinedOn)
                  : null) ??
              now;
          final timeB =
              b.createdAt ??
              (b.joinedOn.contains("2024")
                  ? _parseJoinedOn(b.joinedOn)
                  : null) ??
              now;
          return timeB.compareTo(timeA);
        });

        // Seed initial dummy data if empty
        _checkAndSeed(allWorkers);

        return LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;

            // Filtering logic
            final filteredWorkers =
                allWorkers.where((worker) {
                  // Tab selection filter
                  if (_selectedTabIndex == 1 && worker.status != "Pending") {
                    return false;
                  }
                  if (_selectedTabIndex == 2 && worker.status != "Approved") {
                    return false;
                  }
                  if (_selectedTabIndex == 3 && worker.status != "Rejected") {
                    return false;
                  }
                  if (_selectedTabIndex == 4 && worker.status != "Suspended") {
                    return false;
                  }

                  // Dropdown filters
                  final matchesSearch =
                      worker.name.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      worker.email.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      worker.phone.contains(_searchQuery) ||
                      worker.category.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      );

                  final matchesCategory =
                      _selectedCategory == "All Categories" ||
                      worker.category == _selectedCategory;
                  final matchesStatus =
                      _selectedStatus == "All Status" ||
                      worker.status == _selectedStatus;
                  final matchesVerification =
                      _selectedVerification == "All Verification" ||
                      worker.verification == _selectedVerification;
                  final matchesRating =
                      _selectedRating == "All Ratings" ||
                      (_selectedRating == "4.5+ Ratings" &&
                          worker.rating >= 4.5) ||
                      (_selectedRating == "4.8+ Ratings" &&
                          worker.rating >= 4.8);

                  return matchesSearch &&
                      matchesCategory &&
                      matchesStatus &&
                      matchesVerification &&
                      matchesRating;
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
                    // Breadcrumbs
                    _buildBreadcrumbs(),
                    const SizedBox(height: 8),

                    // Title Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Worker Management",
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showAddWorkerDialog(),
                          icon: const Icon(Icons.add, size: 14),
                          label: Text(
                            "Add New Worker",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 5 Statistics Cards
                    _buildStatsGrid(width, allWorkers),
                    const SizedBox(height: 24),

                    // Filter controls Row
                    _buildFilterRow(context, width),
                    const SizedBox(height: 24),

                    // Tab bar selectors
                    _buildCustomTabBar(allWorkers),
                    const SizedBox(height: 16),

                    // Worker list data table
                    _buildWorkersTable(filteredWorkers),
                    const SizedBox(height: 16),

                    // Bottom Pagination footer
                    _buildTableFooter(
                      filteredWorkers.length,
                      allWorkers.length,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatsGrid(double width, List<WorkerModel> allWorkers) {
    int crossAxisCount = 5;
    if (width < 600) {
      crossAxisCount = 1;
    } else if (width < 900) {
      crossAxisCount = 2;
    } else if (width < 1200) {
      crossAxisCount = 3;
    }

    final double itemWidth =
        (width - (crossAxisCount - 1) * 16) / crossAxisCount;
    const double itemHeight = 115;
    final double aspectRatio = itemWidth / itemHeight;

    final int total = allWorkers.length;
    final int pending = allWorkers.where((w) => w.status == "Pending").length;
    final int approved = allWorkers.where((w) => w.status == "Approved").length;
    final int rejected = allWorkers.where((w) => w.status == "Rejected").length;
    final int suspended =
        allWorkers.where((w) => w.status == "Suspended").length;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: aspectRatio > 0 ? aspectRatio : 2.0,
      children: [
        StatsCard(
          title: "Total Workers",
          value: total.toString(),
          desc: "All registered workers",
          icon: Icons.people_alt_rounded,
          iconColor: const Color(0xFF3B82F6),
          iconBgColor: const Color(0xFFEFF6FF),
        ),
        StatsCard(
          title: "Pending Approvals",
          value: pending.toString(),
          desc: "Awaiting admin approval",
          icon: Icons.access_time_filled_rounded,
          iconColor: const Color(0xFFF59E0B),
          iconBgColor: const Color(0xFFFEF3C7),
        ),
        StatsCard(
          title: "Approved Workers",
          value: approved.toString(),
          desc: "Active and approved",
          icon: Icons.check_circle_outline_rounded,
          iconColor: const Color(0xFF10B981),
          iconBgColor: const Color(0xFFECFDF5),
        ),
        StatsCard(
          title: "Rejected Workers",
          value: rejected.toString(),
          desc: "Registration rejected",
          icon: Icons.cancel_outlined,
          iconColor: const Color(0xFFEF4444),
          iconBgColor: const Color(0xFFFEF2F2),
        ),
        StatsCard(
          title: "Suspended Workers",
          value: suspended.toString(),
          desc: "Temporarily suspended",
          icon: Icons.pause_circle_outline_rounded,
          iconColor: const Color(0xFF6366F1),
          iconBgColor: const Color(0xFFEEF2FF),
        ),
      ],
    );
  }

  Widget _buildFilterRow(BuildContext context, double width) {
    final bool isSmall = width < 900;

    final searchField = SizedBox(
      width: isSmall ? double.infinity : 240,
      height: 38,
      child: TextFormField(
        onChanged:
            (val) => setState(() {
              _searchQuery = val;
            }),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          fillColor: Colors.white,
          filled: true,
          hintText: "Search by name, email or category...",
          hintStyle: GoogleFonts.inter(
            color: const Color(0xFF94A3B8),
            fontSize: 12,
          ),
          prefixIcon: const Icon(
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
      width: isSmall ? double.infinity : 160,
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
            [
                  "All Categories",
                  "Home Cleaning",
                  "Pet Grooming",
                  "Garden Services",
                  "Room Cleaning",
                  "Vehicle Cleaning",
                  "Interior Cleaning",
                ]
                .map(
                  (cat) => DropdownMenuItem(
                    value: cat,
                    child: Text(
                      cat,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                )
                .toList(),
        onChanged:
            (val) => setState(() {
              _selectedCategory = val!;
            }),
      ),
    );

    final statusDropdown = SizedBox(
      width: isSmall ? double.infinity : 130,
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
            ["All Status", "Approved", "Pending", "Rejected", "Suspended"]
                .map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Text(
                      status,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                )
                .toList(),
        onChanged:
            (val) => setState(() {
              _selectedStatus = val!;
            }),
      ),
    );

    final verificationDropdown = SizedBox(
      width: isSmall ? double.infinity : 160,
      height: 38,
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: _selectedVerification,
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
            ["All Verification", "Verified", "Pending", "Not Verified"]
                .map(
                  (ver) => DropdownMenuItem(
                    value: ver,
                    child: Text(
                      ver,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                )
                .toList(),
        onChanged:
            (val) => setState(() {
              _selectedVerification = val!;
            }),
      ),
    );

    final ratingDropdown = SizedBox(
      width: isSmall ? double.infinity : 130,
      height: 38,
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: _selectedRating,
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
            ["All Ratings", "4.5+ Ratings", "4.8+ Ratings"]
                .map(
                  (rating) => DropdownMenuItem(
                    value: rating,
                    child: Text(
                      rating,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                )
                .toList(),
        onChanged:
            (val) => setState(() {
              _selectedRating = val!;
            }),
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
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    if (isSmall) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          searchField,
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: categoryDropdown),
              const SizedBox(width: 12),
              Expanded(child: statusDropdown),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: verificationDropdown),
              const SizedBox(width: 12),
              Expanded(child: ratingDropdown),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [filterButton, const SizedBox(width: 12), exportButton],
          ),
        ],
      );
    } else {
      return Row(
        children: [
          searchField,
          const SizedBox(width: 12),
          categoryDropdown,
          const SizedBox(width: 12),
          statusDropdown,
          const SizedBox(width: 12),
          verificationDropdown,
          const SizedBox(width: 12),
          ratingDropdown,
          const Spacer(),
          filterButton,
          const SizedBox(width: 12),
          exportButton,
        ],
      );
    }
  }

  Widget _buildCustomTabBar(List<WorkerModel> allWorkers) {
    final int total = allWorkers.length;
    final int pending = allWorkers.where((w) => w.status == "Pending").length;
    final int approved = allWorkers.where((w) => w.status == "Approved").length;
    final int rejected = allWorkers.where((w) => w.status == "Rejected").length;
    final int suspended =
        allWorkers.where((w) => w.status == "Suspended").length;

    final List<Map<String, dynamic>> tabs = [
      {"label": "All Workers", "count": total},
      {"label": "Pending Approvals", "count": pending},
      {"label": "Approved Workers", "count": approved},
      {"label": "Rejected Workers", "count": rejected},
      {"label": "Suspended Workers", "count": suspended},
    ];

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(tabs.length, (index) {
            final tab = tabs[index];
            final bool isSelected = index == _selectedTabIndex;
            final String label = tab["label"];
            final int count = tab["count"];

            return InkWell(
              onTap: () {
                setState(() => _selectedTabIndex = index);
                if (widget.onTabChanged != null) {
                  String tabName;
                  switch (index) {
                    case 1:
                      tabName = "Pending Approvals";
                      break;
                    case 2:
                      tabName = "Approved Workers";
                      break;
                    case 3:
                      tabName = "Rejected Workers";
                      break;
                    case 4:
                      tabName = "Suspended Workers";
                      break;
                    case 0:
                    default:
                      tabName = "All Workers";
                      break;
                  }
                  widget.onTabChanged!(tabName);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color:
                          isSelected
                              ? const Color(0xFF10B981)
                              : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color:
                            isSelected
                                ? const Color(0xFF10B981)
                                : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? const Color(0xFFD1FAE5)
                                : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count.toString(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color:
                              isSelected
                                  ? const Color(0xFF047857)
                                  : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildWorkersTable(List<WorkerModel> workers) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F3F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Scrollbar(
            controller: _horizontalScrollController,
            thumbVisibility: true,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            child: SingleChildScrollView(
              controller: _horizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1550,
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(3.0), // Worker
                    1: FlexColumnWidth(2.0), // Category
                    2: FlexColumnWidth(1.2), // Experience
                    3: FlexColumnWidth(1.2), // Rating
                    4: FlexColumnWidth(1.2), // Jobs Completed
                    5: FlexColumnWidth(1.2), // Status
                    6: FlexColumnWidth(1.5), // Verification
                    7: FlexColumnWidth(1.5), // Joined On
                    8: FlexColumnWidth(4.5), // Actions (wider for text buttons)
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    // Table Header
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
                        _buildHeaderCell("Worker"),
                        _buildHeaderCell("Category"),
                        _buildHeaderCell("Experience"),
                        _buildHeaderCell("Rating"),
                        _buildHeaderCell("Jobs Completed"),
                        _buildHeaderCell("Status"),
                        _buildHeaderCell("Verification"),
                        _buildHeaderCell("Joined On"),
                        _buildHeaderCell("Actions"),
                      ],
                    ),

                    // Table Rows
                    ...workers.map((worker) {
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
                          // Worker Circular Avatar + Name/Phone details
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10.0,
                              horizontal: 16.0,
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    worker.avatarUrl,
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 32,
                                        height: 32,
                                        color: const Color(0xFFE2E8F0),
                                        child: const Icon(
                                          Icons.person,
                                          color: Color(0xFF64748B),
                                          size: 16,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        worker.name,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF1E293B),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        worker.phone,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                      Text(
                                        worker.email,
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: const Color(0xFF94A3B8),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.location_on_outlined,
                                            color: Color(0xFF64748B),
                                            size: 11,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              worker.address,
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                color: const Color(0xFF64748B),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Category with specific icon & color
                          _buildCategoryCell(worker.category),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: Text(
                              worker.experience,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ),
                          // Rating star details
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      worker.rating.toString(),
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.star,
                                      color: Color(0xFFF59E0B),
                                      size: 12,
                                    ),
                                  ],
                                ),
                                Text(
                                  "(${worker.ratingsCount})",
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: Text(
                              worker.jobsCompleted.toString(),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF1E293B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          _buildStatusBadge(worker.status),
                          _buildVerificationBadge(worker.verification),
                          Text(
                            worker.joinedOn,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          // Actions row
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _buildActionButton(
                                "View",
                                Icons.visibility_outlined,
                                Colors.blue,
                                () {
                                  _showWorkerDetailsDialog(worker);
                                },
                              ),
                              _buildActionButton(
                                "Edit",
                                Icons.edit_outlined,
                                Colors.blue,
                                () {
                                  _showEditWorkerDialog(worker);
                                },
                              ),
                              if (worker.status == "Pending") ...[
                                _buildActionButton(
                                  "Approve",
                                  Icons.check_circle_outline_rounded,
                                  Colors.green,
                                  () => _changeWorkerStatus(worker, "Approved"),
                                ),
                                _buildActionButton(
                                  "Reject",
                                  Icons.cancel_outlined,
                                  Colors.red,
                                  () => _changeWorkerStatus(worker, "Rejected"),
                                ),
                              ] else if (worker.status == "Approved") ...[
                                _buildActionButton(
                                  "Suspend",
                                  Icons.pause_circle_outline_rounded,
                                  Colors.orange,
                                  () =>
                                      _changeWorkerStatus(worker, "Suspended"),
                                ),
                              ] else ...[
                                _buildActionButton(
                                  "Approve",
                                  Icons.check_circle_outline_rounded,
                                  Colors.green,
                                  () => _changeWorkerStatus(worker, "Approved"),
                                ),
                              ],
                              _buildActionButton(
                                "Delete",
                                Icons.delete_outline_rounded,
                                Colors.red,
                                () {
                                  _showDeleteConfirmation(worker);
                                },
                              ),
                            ],
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
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
          color: const Color(0xFF94A3B8),
        ),
      ),
    );
  }

  Widget _buildCategoryCell(String category) {
    IconData icon;
    Color color;

    switch (category) {
      case "Home Cleaning":
        icon = Icons.home_work_rounded;
        color = const Color(0xFFF59E0B);
        break;
      case "Pet Grooming":
        icon = Icons.pets_rounded;
        color = const Color(0xFF8B5CF6);
        break;
      case "Garden Services":
        icon = Icons.local_florist_rounded;
        color = const Color(0xFF10B981);
        break;
      case "Room Cleaning":
        icon = Icons.cleaning_services_rounded;
        color = const Color(0xFFEC4899);
        break;
      case "Vehicle Cleaning":
        icon = Icons.directions_car_rounded;
        color = const Color(0xFF3B82F6);
        break;
      case "Interior Cleaning":
      default:
        icon = Icons.chair_alt_rounded;
        color = const Color(0xFF0D9488);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              category,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF1E293B),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    Color bgColor;

    switch (status) {
      case "Approved":
        color = const Color(0xFF10B981);
        bgColor = const Color(0xFFECFDF5);
        break;
      case "Pending":
        color = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFEF3C7);
        break;
      case "Rejected":
        color = const Color(0xFFEF4444);
        bgColor = const Color(0xFFFEF2F2);
        break;
      case "Suspended":
      default:
        color = const Color(0xFF6366F1);
        bgColor = const Color(0xFFEEF2FF);
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
            Flexible(
              child: Text(
                status,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationBadge(String verification) {
    Color color;
    Color bgColor;
    IconData icon;

    switch (verification) {
      case "Verified":
        color = const Color(0xFF10B981);
        bgColor = const Color(0xFFECFDF5);
        icon = Icons.check_circle_outline_rounded;
        break;
      case "Pending":
        color = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFEF3C7);
        icon = Icons.access_time_rounded;
        break;
      case "Not Verified":
      default:
        color = const Color(0xFFEF4444);
        bgColor = const Color(0xFFFEF2F2);
        icon = Icons.cancel_outlined;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                verification,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableFooter(int totalFiltered, int totalAll) {
    return Row(
      children: [
        Text(
          "Showing 1 to $totalFiltered of $totalAll workers",
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
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, size: 18),
              onPressed: () {},
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

  void _showDeleteConfirmation(WorkerModel worker) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(
              "Delete Worker",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            content: Text(
              "Are you sure you want to delete the registration of '${worker.name}'? This action cannot be undone.",
              style: GoogleFonts.inter(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.inter(color: const Color(0xFF64748B)),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  try {
                    await FirebaseFirestore.instance
                        .collection("workers")
                        .doc(worker.id)
                        .delete();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Worker '${worker.name}' deleted successfully.",
                        ),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error deleting worker: $e")),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                ),
                child: Text("Delete", style: GoogleFonts.inter()),
              ),
            ],
          ),
    );
  }
}

class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String desc;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.desc,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F3F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF94A3B8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
