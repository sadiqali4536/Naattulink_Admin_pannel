import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:swiftclean_admin/MVVM/utils/rbac_session.dart';
import 'package:swiftclean_admin/MVVM/model/models/admin_model.dart';

class RecentActivityPage extends StatefulWidget {
  final void Function(String)? onNavigate;

  const RecentActivityPage({super.key, this.onNavigate});

  @override
  State<RecentActivityPage> createState() => _RecentActivityPageState();
}

class _RecentActivityPageState extends State<RecentActivityPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _activities = [];

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    try {
      final db = FirebaseFirestore.instance;

      final usersQuery =
          await db
              .collection('users')
              .orderBy('createdAt', descending: true)
              .limit(100)
              .get();
      List<Map<String, dynamic>> allUsers = [];
      for (var doc in usersQuery.docs) {
        final data = doc.data();
        DateTime? uDate;
        if (data['createdAt'] != null) {
          uDate =
              (data['createdAt'] is Timestamp)
                  ? (data['createdAt'] as Timestamp).toDate()
                  : DateTime.tryParse(data['createdAt'].toString());
        }
        allUsers.add({
          'name':
              data['name']?.toString() ??
              data['userName']?.toString() ??
              'A user',
          'date': uDate ?? DateTime.fromMillisecondsSinceEpoch(0),
        });
      }

      final bookingsQuery = await db.collection('service_bookings').get();
      List<Map<String, dynamic>> allBookings = [];
      final dateFormat = DateFormat('MMM d, yyyy');
      final timeFormat = DateFormat('h:mm a');

      for (var doc in bookingsQuery.docs) {
        final data = doc.data();
        DateTime parsedDate = DateTime.now();

        if (data['timestamp'] != null) {
          if (data['timestamp'] is Timestamp) {
            parsedDate = (data['timestamp'] as Timestamp).toDate();
          } else {
            parsedDate =
                DateTime.tryParse(data['timestamp'].toString()) ??
                DateTime.now();
          }
        } else if (data['date'] != null && data['Time'] != null) {
          try {
            final dateParts = data['date'].toString().split('-');
            if (dateParts.length == 3) {
              final year = int.parse(dateParts[2]);
              final month = int.parse(dateParts[1]);
              final day = int.parse(dateParts[0]);
              final timeString = data['Time'].toString().trim().toUpperCase();
              final timeParsed = DateFormat('hh:mm a').parse(timeString);
              parsedDate = DateTime(
                year,
                month,
                day,
                timeParsed.hour,
                timeParsed.minute,
              );
            }
          } catch (e) {
            parsedDate = DateTime.now();
          }
        }

        allBookings.add({
          'id': doc.id.length > 5 ? doc.id.substring(0, 5) : doc.id,
          'parsedDate': parsedDate,
          'status': data['status'],
          'booking_status': data['booking_status'],
        });
      }

      List<Map<String, dynamic>> combined = [];

      for (var u in allUsers) {
        combined.add({
          'title': 'New user registered',
          'subtitle': '${u['name']} joined the platform',
          'time': DateFormat('MMM d, h:mm a').format(u['date'] as DateTime),
          'type': 'user',
          'date': u['date'],
          'icon': Icons.person_add_rounded,
          'iconColor': const Color(0xFF6366F1),
          'bgColor': const Color(0xFFEEF2FF),
        });
      }

      for (var b in allBookings) {
        final isCancelled =
            (b['booking_status'] ?? b['status'] ?? '')
                .toString()
                .trim()
                .toLowerCase() ==
            'cancelled';
        combined.add({
          'title': isCancelled ? 'Booking cancelled' : 'New booking received',
          'subtitle':
              isCancelled
                  ? 'Booking #${b['id']} was cancelled'
                  : 'Booking #${b['id']} received',
          'time': DateFormat(
            'MMM d, h:mm a',
          ).format(b['parsedDate'] as DateTime),
          'type': isCancelled ? 'cancelled' : 'booking',
          'date': b['parsedDate'],
          'icon':
              isCancelled ? Icons.cancel_rounded : Icons.calendar_today_rounded,
          'iconColor':
              isCancelled ? const Color(0xFFEF4444) : const Color(0xFF10B981),
          'bgColor':
              isCancelled ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
        });
      }

      combined.sort(
        (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
      );

      if (combined.length > 150) {
        combined = combined.sublist(0, 150);
      }

      if (mounted) {
        setState(() {
          _activities = combined;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading recent activities: \$e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F5F9),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.onNavigate != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: InkWell(
                    onTap: () => widget.onNavigate!("Dashboard"),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Color(0xFF1E293B),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              Text(
                "Recent Activity",
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "View all the latest actions across the platform.",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _activities.isEmpty
                      ? Center(
                        child: Text(
                          "No recent activities found.",
                          style: GoogleFonts.inter(
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      )
                      : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _activities.length,
                        separatorBuilder:
                            (context, index) => const Divider(
                              color: Color(0xFFF1F5F9),
                              height: 24,
                            ),
                        itemBuilder: (context, index) {
                          final activity = _activities[index];
                          return Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: activity['bgColor'],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  activity['icon'],
                                  color: activity['iconColor'],
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      activity['title'],
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      activity['subtitle'],
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                activity['time'],
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
