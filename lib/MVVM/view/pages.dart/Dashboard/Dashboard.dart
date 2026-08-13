import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:swiftclean_admin/MVVM/model/models/admin_model.dart';
import 'package:swiftclean_admin/MVVM/utils/rbac_session.dart';

class Dashboard extends StatefulWidget {
  final void Function(String)? onNavigate;

  const Dashboard({super.key, this.onNavigate});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  DateTimeRange? _selectedDateRange;
  final RbacSession _session = RbacSession();

  bool _isLoading = true;
  int _totalUsers = 0;
  int _totalWorkers = 0;
  int _pendingApprovals = 0;
  int _pendingBookings = 0;
  int _completedBookings = 0;
  int _cancelledBookings = 0;
  double _revenue = 0.0;
  int _totalProducts = 0;
  int _totalOrders = 0;
  int _totalAdvertisements = 0;
  int _totalBusRoutes = 0;
  int _totalActiveBuses = 0;
  int _totalBusDistricts = 0;
  int _totalTaxiDrivers = 0;
  List<Map<String, dynamic>> _latestBookings = [];
  Map<String, int> _serviceCategoryCounts = {};
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _recentActivities = [];
  List<Map<String, dynamic>> _bookingTrends = [];

  double _usersTrend = 0.0;
  bool _usersTrendPositive = true;
  double _workersTrend = 0.0;
  bool _workersTrendPositive = true;
  double _pendingTrend = 0.0;
  bool _pendingTrendPositive = true;
  double _pendingBookingsTrend = 0.0;
  bool _pendingBookingsTrendPositive = true;
  double _completedBookingsTrend = 0.0;
  bool _completedBookingsTrendPositive = true;
  double _cancelledBookingsTrend = 0.0;
  bool _cancelledBookingsTrendPositive = true;
  double _revenueTrend = 0.0;
  bool _revenueTrendPositive = true;
  double _productsTrend = 0.0;
  bool _productsTrendPositive = true;
  double _ordersTrend = 0.0;
  bool _ordersTrendPositive = true;
  double _advertisementsTrend = 0.0;
  bool _advertisementsTrendPositive = true;
  double _busRoutesTrend = 0.0;
  bool _busRoutesTrendPositive = true;
  double _taxiDriversTrend = 0.0;
  bool _taxiDriversTrendPositive = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final db = FirebaseFirestore.instance;
      final now = DateTime.now();
      DateTime? startOfThisPeriod;
      DateTime? startOfPreviousPeriod;
      DateTime? endOfThisPeriod;

      if (_selectedDateRange != null) {
        startOfThisPeriod = _selectedDateRange!.start;
        // add 1 day to include the end date fully
        endOfThisPeriod = _selectedDateRange!.end.add(const Duration(days: 1));
        final duration = endOfThisPeriod.difference(startOfThisPeriod);
        startOfPreviousPeriod = startOfThisPeriod.subtract(duration);
      }

      final startOfDay = DateTime(now.year, now.month, now.day);
      final yesterday = startOfDay.subtract(const Duration(days: 1));

      final bool canViewUsers = _session.hasPermission(
        Modules.userManagement,
        Perms.view,
      );
      final bool canViewWorkers = _session.hasPermission(
        Modules.workerManagement,
        Perms.view,
      );
      final bool canViewBookings = _session.hasPermission(
        Modules.bookings,
        Perms.view,
      );
      final bool canViewPayments = _session.hasPermission(
        Modules.payments,
        Perms.view,
      );
      final bool canViewProducts = _session.hasPermission(
        Modules.storeProducts,
        Perms.view,
      );
      final bool canViewOrders = _session.hasPermission(
        Modules.storeOrders,
        Perms.view,
      );
      final bool canViewAds = _session.hasPermission(
        Modules.advertisement,
        Perms.view,
      );
      final bool canViewBus = _session.hasPermission(Modules.bus, Perms.view);
      final bool canViewTaxi = _session.hasPermission(Modules.taxi, Perms.view);

      // Helper to calculate trend safely
      double calcTrend(int current, int previous) {
        if (previous == 0 && current == 0) return 0.0;
        if (previous == 0 && current > 0) return 100.0;
        return ((current - previous) / previous) * 100.0;
      }

      double calcRevenueTrend(double current, double previous) {
        if (previous == 0 && current == 0) return 0.0;
        if (previous == 0 && current > 0) return 100.0;
        return ((current - previous) / previous) * 100.0;
      }

      // 1. Users
      final usersFuture =
          canViewUsers
              ? db.collection('users').count().get()
              : Future.value(null);
      final usersThis =
          (canViewUsers && _selectedDateRange != null)
              ? db
                  .collection('users')
                  .where(
                    'createdAt',
                    isGreaterThanOrEqualTo: startOfThisPeriod!,
                  )
                  .where('createdAt', isLessThan: endOfThisPeriod!)
                  .count()
                  .get()
              : Future.value(null);
      final usersPrev =
          (canViewUsers && _selectedDateRange != null)
              ? db
                  .collection('users')
                  .where(
                    'createdAt',
                    isGreaterThanOrEqualTo: startOfPreviousPeriod!,
                  )
                  .where('createdAt', isLessThan: startOfThisPeriod!)
                  .count()
                  .get()
              : Future.value(null);

      // 2. Workers
      final workersFuture =
          canViewWorkers
              ? db.collection('workers').count().get()
              : Future.value(null);
      final workersThis =
          (canViewWorkers && _selectedDateRange != null)
              ? db
                  .collection('workers')
                  .where(
                    'createdAt',
                    isGreaterThanOrEqualTo: startOfThisPeriod!,
                  )
                  .where('createdAt', isLessThan: endOfThisPeriod!)
                  .count()
                  .get()
              : Future.value(null);
      final workersPrev =
          (canViewWorkers && _selectedDateRange != null)
              ? db
                  .collection('workers')
                  .where(
                    'createdAt',
                    isGreaterThanOrEqualTo: startOfPreviousPeriod!,
                  )
                  .where('createdAt', isLessThan: startOfThisPeriod!)
                  .count()
                  .get()
              : Future.value(null);

      // 3. Pending Approvals (Workers)
      final pendingFuture =
          canViewWorkers
              ? db
                  .collection('workers')
                  .where('isVerified', isEqualTo: 0)
                  .count()
                  .get()
              : Future.value(null);
      final pendingThis =
          (canViewWorkers && _selectedDateRange != null)
              ? db
                  .collection('workers')
                  .where('isVerified', isEqualTo: 0)
                  .where(
                    'createdAt',
                    isGreaterThanOrEqualTo: startOfThisPeriod!,
                  )
                  .where('createdAt', isLessThan: endOfThisPeriod!)
                  .count()
                  .get()
              : Future.value(null);
      final pendingPrev =
          (canViewWorkers && _selectedDateRange != null)
              ? db
                  .collection('workers')
                  .where('isVerified', isEqualTo: 0)
                  .where(
                    'createdAt',
                    isGreaterThanOrEqualTo: startOfPreviousPeriod!,
                  )
                  .where('createdAt', isLessThan: startOfThisPeriod!)
                  .count()
                  .get()
              : Future.value(null);

      // 4. Today's Bookings
      final todayBookingsFuture =
          canViewBookings
              ? db
                  .collection('service_bookings')
                  .where(
                    'timestamp',
                    isGreaterThanOrEqualTo: startOfDay.toIso8601String(),
                  )
                  .count()
                  .get()
              : Future.value(null);
      final yesterdayBookingsFuture =
          canViewBookings
              ? db
                  .collection('service_bookings')
                  .where(
                    'timestamp',
                    isGreaterThanOrEqualTo: yesterday.toIso8601String(),
                  )
                  .where('timestamp', isLessThan: startOfDay.toIso8601String())
                  .count()
                  .get()
              : Future.value(null);

      // 5. Completed Bookings
      final completedFuture =
          canViewBookings
              ? db
                  .collection('service_bookings')
                  .where('status', isEqualTo: 'Completed')
                  .count()
                  .get()
              : Future.value(null);
      final completedThis =
          (canViewBookings && _selectedDateRange != null)
              ? db
                  .collection('service_bookings')
                  .where('status', isEqualTo: 'Completed')
                  .where(
                    'timestamp',
                    isGreaterThanOrEqualTo:
                        startOfThisPeriod!.toIso8601String(),
                  )
                  .where(
                    'timestamp',
                    isLessThan: endOfThisPeriod!.toIso8601String(),
                  )
                  .count()
                  .get()
              : Future.value(null);
      final completedPrev =
          (canViewBookings && _selectedDateRange != null)
              ? db
                  .collection('service_bookings')
                  .where('status', isEqualTo: 'Completed')
                  .where(
                    'timestamp',
                    isGreaterThanOrEqualTo:
                        startOfPreviousPeriod!.toIso8601String(),
                  )
                  .where(
                    'timestamp',
                    isLessThan: startOfThisPeriod!.toIso8601String(),
                  )
                  .count()
                  .get()
              : Future.value(null);

      // 6. Cancelled Bookings
      final cancelledFuture =
          canViewBookings
              ? db
                  .collection('service_bookings')
                  .where('status', isEqualTo: 'Cancelled')
                  .count()
                  .get()
              : Future.value(null);
      final cancelledThis =
          (canViewBookings && _selectedDateRange != null)
              ? db
                  .collection('service_bookings')
                  .where('status', isEqualTo: 'Cancelled')
                  .where(
                    'timestamp',
                    isGreaterThanOrEqualTo:
                        startOfThisPeriod!.toIso8601String(),
                  )
                  .where(
                    'timestamp',
                    isLessThan: endOfThisPeriod!.toIso8601String(),
                  )
                  .count()
                  .get()
              : Future.value(null);
      final cancelledPrev =
          (canViewBookings && _selectedDateRange != null)
              ? db
                  .collection('service_bookings')
                  .where('status', isEqualTo: 'Cancelled')
                  .where(
                    'timestamp',
                    isGreaterThanOrEqualTo:
                        startOfPreviousPeriod!.toIso8601String(),
                  )
                  .where(
                    'timestamp',
                    isLessThan: startOfThisPeriod!.toIso8601String(),
                  )
                  .count()
                  .get()
              : Future.value(null);

      // Paid Payments Calculation
      // We need to fetch all payments and sum the paid amount
      final allPayments = await db.collection('payments').get();
      double currentRevenue = 0.0;
      double previousRevenue = 0.0;
      double totalRev = 0.0;

      for (var doc in allPayments.docs) {
        final data = doc.data();
        final status = data['status']?.toString().toLowerCase() ?? '';

        if (status == 'paid') {
          final amountStr = data['amount']?.toString() ?? '0';
          final amount =
              double.tryParse(amountStr.replaceAll(RegExp(r'[^0-9.]'), '')) ??
              0.0;
          totalRev += amount;

          final tStamp =
              data['date']?.toString() ??
              data['timestamp']?.toString() ??
              data['createdAt']?.toString() ??
              '';
          DateTime? dt;
          if (tStamp.isNotEmpty) {
            dt = DateTime.tryParse(tStamp);
          }

          if (dt != null && _selectedDateRange != null) {
            if (((dt.isAfter(startOfThisPeriod!) ||
                    dt.isAtSameMomentAs(startOfThisPeriod!)) &&
                dt.isBefore(endOfThisPeriod!))) {
              currentRevenue += amount;
            } else if ((dt.isAfter(startOfPreviousPeriod!) ||
                    dt.isAtSameMomentAs(startOfPreviousPeriod!)) &&
                dt.isBefore(startOfThisPeriod!)) {
              previousRevenue += amount;
            }
          }
        }
      }

      // 8. Products
      final productsFuture =
          canViewProducts
              ? db.collection('products').count().get()
              : Future.value(null);
      final productsThis =
          (canViewProducts && _selectedDateRange != null)
              ? db
                  .collection('products')
                  .where(
                    'createdAt',
                    isGreaterThanOrEqualTo: startOfThisPeriod!,
                  )
                  .where('createdAt', isLessThan: endOfThisPeriod!)
                  .count()
                  .get()
              : Future.value(null);
      final productsPrev =
          (canViewProducts && _selectedDateRange != null)
              ? db
                  .collection('products')
                  .where(
                    'createdAt',
                    isGreaterThanOrEqualTo: startOfPreviousPeriod!,
                  )
                  .where('createdAt', isLessThan: startOfThisPeriod!)
                  .count()
                  .get()
              : Future.value(null);

      // 9. Orders
      final ordersFuture =
          canViewOrders
              ? db.collection('orders').count().get()
              : Future.value(null);
      final ordersThis =
          (canViewOrders && _selectedDateRange != null)
              ? db
                  .collection('orders')
                  .where(
                    'createdAt',
                    isGreaterThanOrEqualTo: startOfThisPeriod!,
                  )
                  .where('createdAt', isLessThan: endOfThisPeriod!)
                  .count()
                  .get()
              : Future.value(null);
      final ordersPrev =
          (canViewOrders && _selectedDateRange != null)
              ? db
                  .collection('orders')
                  .where(
                    'createdAt',
                    isGreaterThanOrEqualTo: startOfPreviousPeriod!,
                  )
                  .where('createdAt', isLessThan: startOfThisPeriod!)
                  .count()
                  .get()
              : Future.value(null);

      // 10. Advertisements
      final adsFuture =
          canViewAds
              ? db.collection('advertisements').count().get()
              : Future.value(null);
      final adsThis =
          (canViewAds && _selectedDateRange != null)
              ? db
                  .collection('advertisements')
                  .where(
                    'createdAt',
                    isGreaterThanOrEqualTo: startOfThisPeriod!,
                  )
                  .where('createdAt', isLessThan: endOfThisPeriod!)
                  .count()
                  .get()
              : Future.value(null);
      final adsPrev =
          (canViewAds && _selectedDateRange != null)
              ? db
                  .collection('advertisements')
                  .where(
                    'createdAt',
                    isGreaterThanOrEqualTo: startOfPreviousPeriod!,
                  )
                  .where('createdAt', isLessThan: startOfThisPeriod!)
                  .count()
                  .get()
              : Future.value(null);

      // 11. Taxi Drivers
      final taxiDriversFuture = Future.value(null);
      final taxiThis = Future.value(null);
      final taxiPrev = Future.value(null);

      int activeTaxiCount = 0;
      int taxiThisCount = 0;
      int taxiPrevCount = 0;
      try {
        if (!canViewTaxi) throw Exception("Skip");
        final taxiQuery =
            await db
                .collection('transports')
                .where('transport_category', isEqualTo: 'Taxi')
                .get();
        for (var doc in taxiQuery.docs) {
          final data = doc.data();
          final status = data['status']?.toString().toLowerCase() ?? '';
          if (status == 'active' || status == 'approved') {
            activeTaxiCount++;
            if (_selectedDateRange != null) {
              final tStamp =
                  data['created_at']?.toString() ??
                  data['createdAt']?.toString() ??
                  '';
              DateTime? dt;
              if (tStamp.isNotEmpty) dt = DateTime.tryParse(tStamp);
              if (dt == null && data['created_at'] is Timestamp) {
                dt = (data['created_at'] as Timestamp).toDate();
              }
              if (dt != null) {
                if (startOfThisPeriod != null && endOfThisPeriod != null) {
                  if ((dt.isAfter(startOfThisPeriod) ||
                          dt.isAtSameMomentAs(startOfThisPeriod)) &&
                      dt.isBefore(endOfThisPeriod)) {
                    taxiThisCount++;
                  }
                }
                if (startOfPreviousPeriod != null &&
                    startOfThisPeriod != null) {
                  if ((dt.isAfter(startOfPreviousPeriod) ||
                          dt.isAtSameMomentAs(startOfPreviousPeriod)) &&
                      dt.isBefore(startOfThisPeriod)) {
                    taxiPrevCount++;
                  }
                }
              }
            }
          }
        }
      } catch (_) {}

      // Bus Routes (Transports)
      // Transports query doesn't have an easy aggregate. We will fetch them and filter by date.
      int routes = 0, activeRoutes = 0;
      Set<String> busDistricts = {};
      int busRoutesThis = 0;
      int busRoutesPrev = 0;

      try {
        if (!canViewBus) throw Exception("Skip");
        final transportQuery =
            await db
                .collection('transports')
                .where('transport_category', isEqualTo: 'Bus')
                .get();
        for (var doc in transportQuery.docs) {
          final parentData = doc.data();
          routes++;
          final pStatus = parentData['status']?.toString().toLowerCase();
          if (pStatus == 'active' ||
              pStatus == 'approved' ||
              parentData['status'] == true) {
            activeRoutes++;
          }
          final pDist = parentData['district']?.toString();
          if (pDist != null && pDist.trim().isNotEmpty) {
            busDistricts.add(pDist);
          }

          DateTime? pDate;
          if (parentData['created_at'] != null) {
            pDate =
                (parentData['created_at'] is Timestamp)
                    ? (parentData['created_at']).toDate()
                    : DateTime.tryParse(parentData['created_at'].toString());
          }
          if (pDate != null && _selectedDateRange != null) {
            if (pDate.isAfter(startOfThisPeriod!) &&
                pDate.isBefore(endOfThisPeriod!)) {
              busRoutesThis++;
            } else if (pDate.isAfter(startOfPreviousPeriod!)) {
              busRoutesPrev++;
            }
          }

          try {
            final buses = await doc.reference.collection('buses').get();
            for (var b in buses.docs) {
              routes++;
              final bData = b.data();
              final bStatus = bData['status']?.toString().toLowerCase();
              if (bStatus == 'active' ||
                  bStatus == 'approved' ||
                  bData['status'] == true) {
                activeRoutes++;
              }
              final bDist = bData['district']?.toString() ?? pDist;
              if (bDist != null && bDist.trim().isNotEmpty) {
                busDistricts.add(bDist);
              }

              DateTime? bDate;
              if (bData['created_at'] != null) {
                bDate =
                    (bData['created_at'] is Timestamp)
                        ? (bData['created_at']).toDate()
                        : DateTime.tryParse(bData['created_at'].toString());
              }
              if (bDate != null && _selectedDateRange != null) {
                if (bDate.isAfter(startOfThisPeriod!) &&
                    bDate.isBefore(endOfThisPeriod!)) {
                  busRoutesThis++;
                } else if (bDate.isAfter(startOfPreviousPeriod!)) {
                  busRoutesPrev++;
                }
              }
            }
          } catch (_) {}
        }
      } catch (_) {}

      Map<String, int> fetchedCategoryCounts = {};

      // Fetch all bookings to manually compute pending and completed counts properly
      final allBookingsQuery =
          canViewBookings
              ? await db.collection('service_bookings').get()
              : null;
      List<Map<String, dynamic>> allBookingsList = [];

      int pendingCount = 0;
      int completedCount = 0;
      int completedThisCount = 0;
      int completedPrevCount = 0;

      int cancelledCount = 0;
      int cancelledThisCount = 0;
      int cancelledPrevCount = 0;

      final DateFormat dayFormatter = DateFormat('MMM d');
      final List<DateTime> last7Days = List.generate(
        7,
        (i) => now.subtract(Duration(days: 6 - i)),
      );
      Map<String, int> dailyBookingCounts = {};
      for (var day in last7Days) {
        dailyBookingCounts[dayFormatter.format(day)] = 0;
      }

      if (allBookingsQuery != null) {
        for (var doc in allBookingsQuery.docs) {
          final data = doc.data();

          final String cat =
              (data['category'] ?? data['serviceCategory'])?.toString() ??
              'Others';
          fetchedCategoryCounts[cat] = (fetchedCategoryCounts[cat] ?? 0) + 1;

          DateTime? parsedTimestamp;
          if (data['timestamp'] != null) {
            if (data['timestamp'] is Timestamp) {
              parsedTimestamp = (data['timestamp'] as Timestamp).toDate();
            } else {
              parsedTimestamp = DateTime.tryParse(data['timestamp'].toString());
            }
          }

          String dateStr =
              (data['date'] ?? data['selectedDate'])?.toString() ?? '';
          String timeStr =
              (data['Time'] ?? data['selectedTimeSlot'])?.toString() ?? '';

          if (parsedTimestamp == null &&
              dateStr.isNotEmpty &&
              timeStr.isNotEmpty) {
            try {
              final dateParts = dateStr.split('-');
              if (dateParts.length == 3) {
                final year = int.parse(dateParts[2]);
                final month = int.parse(dateParts[1]);
                final day = int.parse(dateParts[0]);
                final timeParsed = DateFormat(
                  'hh:mm a',
                ).parse(timeStr.trim().toUpperCase());
                parsedTimestamp = DateTime(
                  year,
                  month,
                  day,
                  timeParsed.hour,
                  timeParsed.minute,
                );
              }
            } catch (_) {}
          }

          if (parsedTimestamp != null) {
            final dayStr = dayFormatter.format(parsedTimestamp);
            if (dailyBookingCounts.containsKey(dayStr)) {
              dailyBookingCounts[dayStr] = dailyBookingCounts[dayStr]! + 1;
            }
          }

          String status =
              (data['booking_status'] ?? data['status'])?.toString().trim() ??
              'Pending';
          if (status.isNotEmpty) {
            status =
                status[0].toUpperCase() + status.substring(1).toLowerCase();
          }

          String dateTimeDisplay =
              timeStr.isNotEmpty ? "$dateStr\n$timeStr" : dateStr;
          if (dateTimeDisplay.trim().isEmpty && parsedTimestamp != null) {
            dateTimeDisplay = DateFormat(
              'MMM d, yyyy\nh:mm a',
            ).format(parsedTimestamp);
          }

          allBookingsList.add({
            'id': doc.id.substring(0, 8).toUpperCase(),
            'customer':
                data['customer_name']?.toString() ??
                data['customerName']?.toString() ??
                'Unknown',
            'service':
                data['serviceName']?.toString() ??
                data['serviceTitle']?.toString() ??
                cat,
            'serviceImage':
                data['serviceImage']?.toString() ??
                data['imageUrl']?.toString() ??
                data['image']?.toString() ??
                '',
            'dateTime': dateTimeDisplay,
            'status': status,
            'amount':
                data['amount']?.toString() ??
                data['total_amount']?.toString() ??
                data['price']?.toString() ??
                '₹0',
            'parsedDate': parsedTimestamp ?? DateTime.now(),
          });

          String workStatus =
              data['work_status']?.toString().trim() ?? 'Pending';
          if (workStatus.isNotEmpty) {
            workStatus =
                workStatus[0].toUpperCase() +
                workStatus.substring(1).toLowerCase();
          }

          String completedStatus =
              data['completed_status']?.toString().trim() ?? '';
          if (completedStatus.isNotEmpty) {
            completedStatus =
                completedStatus[0].toUpperCase() +
                completedStatus.substring(1).toLowerCase();
          }

          if (status == 'Confirmed' &&
              workStatus == 'Pending' &&
              completedStatus != 'Ongoing') {
            pendingCount++;
          }

          if (status == 'Completed' || completedStatus == 'Completed') {
            completedCount++;

            if (_selectedDateRange != null) {
              final timestampStr = data['timestamp']?.toString() ?? '';
              if (timestampStr.isNotEmpty) {
                final timestamp = DateTime.tryParse(timestampStr);
                if (timestamp != null) {
                  if (startOfThisPeriod != null && endOfThisPeriod != null) {
                    if ((timestamp.isAfter(startOfThisPeriod) ||
                            timestamp.isAtSameMomentAs(startOfThisPeriod)) &&
                        timestamp.isBefore(endOfThisPeriod)) {
                      completedThisCount++;
                    }
                  }
                  if (startOfPreviousPeriod != null &&
                      startOfThisPeriod != null) {
                    if ((timestamp.isAfter(startOfPreviousPeriod) ||
                            timestamp.isAtSameMomentAs(
                              startOfPreviousPeriod,
                            )) &&
                        timestamp.isBefore(startOfThisPeriod)) {
                      completedPrevCount++;
                    }
                  }
                }
              }
            }
          }

          if (status == 'Cancelled') {
            cancelledCount++;

            if (_selectedDateRange != null) {
              final timestampStr = data['timestamp']?.toString() ?? '';
              if (timestampStr.isNotEmpty) {
                final timestamp = DateTime.tryParse(timestampStr);
                if (timestamp != null) {
                  if (startOfThisPeriod != null && endOfThisPeriod != null) {
                    if ((timestamp.isAfter(startOfThisPeriod) ||
                            timestamp.isAtSameMomentAs(startOfThisPeriod)) &&
                        timestamp.isBefore(endOfThisPeriod)) {
                      cancelledThisCount++;
                    }
                  }
                  if (startOfPreviousPeriod != null &&
                      startOfThisPeriod != null) {
                    if ((timestamp.isAfter(startOfPreviousPeriod) ||
                            timestamp.isAtSameMomentAs(
                              startOfPreviousPeriod,
                            )) &&
                        timestamp.isBefore(startOfThisPeriod)) {
                      cancelledPrevCount++;
                    }
                  }
                }
              }
            }
          }
        }
      } // end if (allBookingsQuery != null)

      // Wait for all aggregation queries
      final results = await Future.wait([
        usersFuture, // 0
        usersThis, // 1
        usersPrev, // 2
        workersFuture, // 3
        workersThis, // 4
        workersPrev, // 5
        pendingFuture, // 6
        pendingThis, // 7
        pendingPrev, // 8
        todayBookingsFuture, // 9
        yesterdayBookingsFuture, // 10
        completedFuture, // 11
        completedThis, // 12
        completedPrev, // 13
        cancelledFuture, // 14
        cancelledThis, // 15
        cancelledPrev, // 16
        productsFuture, // 17
        productsThis, // 18
        productsPrev, // 19
        ordersFuture, // 20
        ordersThis, // 21
        ordersPrev, // 22
        adsFuture, // 23
        adsThis, // 24
        adsPrev, // 25
        taxiDriversFuture, // 26
        taxiThis, // 27
        taxiPrev, // 28
      ]);

      allBookingsList.sort(
        (a, b) => (b['parsedDate'] as DateTime).compareTo(
          a['parsedDate'] as DateTime,
        ),
      );

      List<Map<String, dynamic>> fetchedBookings = [];
      for (int i = 0; i < allBookingsList.length && i < 5; i++) {
        fetchedBookings.add(allBookingsList[i]);
      }

      // Fetch Products (Safely process all)
      List<Map<String, dynamic>> fetchedProducts = [];
      try {
        if (!canViewProducts) throw Exception("Skip");
        final productsQuery = await db.collection('products').get();
        List<Map<String, dynamic>> allProducts = [];
        for (var doc in productsQuery.docs) {
          final data = doc.data();
          int sales =
              int.tryParse(
                data['soldCount']?.toString() ??
                    data['sales']?.toString() ??
                    '0',
              ) ??
              0;
          allProducts.add({
            'name':
                data['product_name']?.toString() ??
                data['name']?.toString() ??
                'Product',
            'sales': sales,
            'revenue': data['price']?.toString() ?? '₹0',
          });
        }
        allProducts.sort(
          (a, b) => (b['sales'] as int).compareTo(a['sales'] as int),
        );
        for (int i = 0; i < allProducts.length && i < 5; i++) {
          fetchedProducts.add(allProducts[i]);
        }
      } catch (e) {}

      // Fetch Recent Activities (Users + Bookings)
      List<Map<String, dynamic>> fetchedActivities = [];
      try {
        if (!canViewUsers) throw Exception("Skip");
        final usersQuery =
            await db
                .collection('users')
                .orderBy('createdAt', descending: true)
                .limit(10)
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
        allUsers.sort(
          (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
        );

        for (int i = 0; i < allUsers.length && i < 3; i++) {
          fetchedActivities.add({
            'title': 'New user registered',
            'subtitle': '${allUsers[i]['name']} joined the platform',
            'time': DateFormat(
              'MMM d, h:mm a',
            ).format(allUsers[i]['date'] as DateTime),
            'type': 'user',
            'date': allUsers[i]['date'],
          });
        }

        for (var b in fetchedBookings.take(3)) {
          final isCancelled =
              (b['booking_status'] ?? b['status'] ?? '')
                  .toString()
                  .trim()
                  .toLowerCase() ==
              'cancelled';
          fetchedActivities.add({
            'title': isCancelled ? 'Booking cancelled' : 'New booking received',
            'subtitle':
                isCancelled
                    ? 'Booking #${b['id']} was cancelled'
                    : 'Booking #${b['id']} received',
            'time': DateFormat(
              'MMM d, h:mm a',
            ).format((b['parsedDate'] ?? DateTime.now()) as DateTime),
            'type': isCancelled ? 'cancelled' : 'booking',
            'date': b['parsedDate'] ?? DateTime.now(),
          });
        }

        fetchedActivities.sort(
          (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
        );
        if (fetchedActivities.length > 5) {
          fetchedActivities = fetchedActivities.sublist(0, 5);
        }
      } catch (e) {}

      List<Map<String, dynamic>> fetchedTrends = [];
      int dayIndex = 0;
      for (var day in last7Days) {
        final dayStr = dayFormatter.format(day);
        fetchedTrends.add({
          'index': dayIndex,
          'day': dayStr,
          'count': dailyBookingCounts[dayStr] ?? 0,
        });
        dayIndex++;
      }

      if (mounted) {
        setState(() {
          _latestBookings = fetchedBookings;
          _serviceCategoryCounts = fetchedCategoryCounts;
          _topProducts = fetchedProducts;
          _recentActivities = fetchedActivities;
          _bookingTrends = fetchedTrends;

          final bool hasDateFilter = _selectedDateRange != null;

          _totalUsers =
              hasDateFilter
                  ? (results[1]?.count ?? 0)
                  : (results[0]?.count ?? 0);
          final ut = results[1]?.count ?? 0;
          final up = results[2]?.count ?? 0;
          _usersTrend = hasDateFilter ? calcTrend(ut, up) : 0.0;
          _usersTrendPositive = _usersTrend >= 0;

          _totalWorkers =
              hasDateFilter
                  ? (results[4]?.count ?? 0)
                  : (results[3]?.count ?? 0);
          final wt = results[4]?.count ?? 0;
          final wp = results[5]?.count ?? 0;
          _workersTrend = hasDateFilter ? calcTrend(wt, wp) : 0.0;
          _workersTrendPositive = _workersTrend >= 0;

          // User requested Pending Approvals to always show the global count from Worker Management
          _pendingApprovals = results[6]?.count ?? 0;
          final pt = results[7]?.count ?? 0;
          final pp = results[8]?.count ?? 0;
          _pendingTrend = hasDateFilter ? calcTrend(pt, pp) : 0.0;
          _pendingTrendPositive = _pendingTrend >= 0;

          _pendingBookings = pendingCount;
          _pendingBookingsTrend = 0.0;
          _pendingBookingsTrendPositive = true;

          _completedBookings =
              hasDateFilter ? completedThisCount : completedCount;
          final ct = completedThisCount;
          final cp = completedPrevCount;
          _completedBookingsTrend = hasDateFilter ? calcTrend(ct, cp) : 0.0;
          _completedBookingsTrendPositive = _completedBookingsTrend >= 0;

          _cancelledBookings =
              hasDateFilter ? cancelledThisCount : cancelledCount;
          final cant = cancelledThisCount;
          final canp = cancelledPrevCount;
          _cancelledBookingsTrend = hasDateFilter ? calcTrend(cant, canp) : 0.0;
          _cancelledBookingsTrendPositive = _cancelledBookingsTrend >= 0;

          _revenue = hasDateFilter ? currentRevenue : totalRev;
          _revenueTrend =
              hasDateFilter
                  ? calcRevenueTrend(currentRevenue, previousRevenue)
                  : 0.0;
          _revenueTrendPositive = _revenueTrend >= 0;

          _totalProducts =
              hasDateFilter
                  ? (results[18]?.count ?? 0)
                  : (results[17]?.count ?? 0);
          final pt_ = results[18]?.count ?? 0;
          final pp_ = results[19]?.count ?? 0;
          _productsTrend = hasDateFilter ? calcTrend(pt_, pp_) : 0.0;
          _productsTrendPositive = _productsTrend >= 0;

          _totalOrders =
              hasDateFilter
                  ? (results[21]?.count ?? 0)
                  : (results[20]?.count ?? 0);
          final ot = results[21]?.count ?? 0;
          final op = results[22]?.count ?? 0;
          _ordersTrend = hasDateFilter ? calcTrend(ot, op) : 0.0;
          _ordersTrendPositive = _ordersTrend >= 0;

          _totalAdvertisements =
              hasDateFilter
                  ? (results[24]?.count ?? 0)
                  : (results[23]?.count ?? 0);
          final adt = results[24]?.count ?? 0;
          final adp = results[25]?.count ?? 0;
          _advertisementsTrend = hasDateFilter ? calcTrend(adt, adp) : 0.0;
          _advertisementsTrendPositive = _advertisementsTrend >= 0;

          _totalTaxiDrivers = hasDateFilter ? taxiThisCount : activeTaxiCount;
          final tdxt = taxiThisCount;
          final tdxp = taxiPrevCount;
          _taxiDriversTrend = hasDateFilter ? calcTrend(tdxt, tdxp) : 0.0;
          _taxiDriversTrendPositive = _taxiDriversTrend >= 0;

          _totalBusRoutes = routes;
          _totalActiveBuses = activeRoutes;
          _totalBusDistricts = busDistricts.length;
          _busRoutesTrend = calcTrend(busRoutesThis, busRoutesPrev);
          _busRoutesTrendPositive = _busRoutesTrend >= 0;
        });
      }
    } catch (e) {
      debugPrint("Error loading dashboard data: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_session.hasPermission(Modules.dashboard, Perms.view)) {
      return const Scaffold(
        body: Center(
          child: Text("You do not have permission to view the dashboard."),
        ),
      );
    }
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: const Color(0xFFFFC107)),
        ),
      );
    }

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final bool isLargeScreen = width > 1100;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(context),
                const SizedBox(height: 24),

                // Stats Cards
                _buildStatsGrid(width),
                const SizedBox(height: 24),

                // Middle Section (Trends Line Chart, Service Donut Chart, Activities)
                _buildMiddleSection(isLargeScreen, width),
                const SizedBox(height: 24),

                // Bottom Section (Latest Bookings Table, Top Selling Products)
                _buildBottomSection(isLargeScreen),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Dashboard",
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Overview of NaattuLink platform",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        InkWell(
          onTap: () async {
            final DateTimeRange? picked =
                await showGeneralDialog<DateTimeRange>(
                  context: context,
                  barrierDismissible: true,
                  barrierLabel: "Dismiss",
                  barrierColor: Colors.black.withValues(alpha: 0.4),
                  transitionDuration: const Duration(milliseconds: 220),
                  pageBuilder: (context, anim1, anim2) {
                    return PremiumDateRangePickerDialog(
                      initialDateRange: _selectedDateRange,
                    );
                  },
                  transitionBuilder: (context, anim1, anim2, child) {
                    return FadeTransition(
                      opacity: anim1,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                          CurvedAnimation(
                            parent: anim1,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                        child: child,
                      ),
                    );
                  },
                );
            if (picked != null) {
              setState(() {
                _selectedDateRange = picked;
              });
              _loadDashboardData();
            }
          },
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 56,
            width: 250,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color:
                    _selectedDateRange != null
                        ? const Color(0xFF10B981)
                        : const Color(0xFFE5E7EB),
                width: 1.5,
              ),
              gradient:
                  _selectedDateRange != null
                      ? const LinearGradient(
                        colors: [Color(0xFFECFDF5), Color(0xFFF0FDF4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                      : null,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFCBD5E1).withValues(alpha: 0.15),
                  blurRadius: 18,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color:
                        _selectedDateRange != null
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_month_rounded,
                    color:
                        _selectedDateRange != null
                            ? Colors.white
                            : const Color(0xFF64748B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Date Range",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedDateRange == null
                            ? "Select Date Range"
                            : "${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][_selectedDateRange!.start.month - 1]} ${_selectedDateRange!.start.day.toString().padLeft(2, '0')} • ${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][_selectedDateRange!.end.month - 1]} ${_selectedDateRange!.end.day.toString().padLeft(2, '0')}",
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight:
                              _selectedDateRange == null
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                          color:
                              _selectedDateRange == null
                                  ? const Color(0xFF475569)
                                  : const Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _selectedDateRange != null
                        ? Icons.check_circle_rounded
                        : Icons.arrow_drop_down_rounded,
                    key: ValueKey(_selectedDateRange != null),
                    color:
                        _selectedDateRange != null
                            ? const Color(0xFF10B981)
                            : const Color(0xFF64748B),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return "${months[date.month - 1]} ${date.day}, ${date.year}";
  }

  Widget _buildStatsGrid(double width) {
    if (!_session.hasPermission(Modules.dashboard, 'view_analytics_cards')) {
      return const SizedBox.shrink();
    }
    List<Widget> cards = [];
    final formatter = NumberFormat('#,##0');

    String formatTrend(double trend) {
      if (trend == 100.0) return "New";
      if (trend == 0.0) return "0.0%";
      return "${trend.abs().toStringAsFixed(1)}%";
    }

    if (_session.hasPermission(Modules.userManagement, Perms.view)) {
      cards.add(
        StatsCard(
          title: "Total Users",
          value: formatter.format(_totalUsers),
          trendPercentage: formatTrend(_usersTrend),
          trendPeriod: "from last week",
          isPositiveTrend: _usersTrendPositive,
          icon: Icons.people_alt_rounded,
          iconColor: const Color(0xFF6366F1),
          iconBgColor: const Color(0xFFEEF2FF),
        ),
      );
    }

    if (_session.hasPermission(Modules.workerManagement, Perms.view)) {
      cards.add(
        StatsCard(
          title: "Total Workers",
          value: formatter.format(_totalWorkers),
          trendPercentage: formatTrend(_workersTrend),
          trendPeriod: "from last week",
          isPositiveTrend: _workersTrendPositive,
          icon: Icons.engineering_rounded,
          iconColor: const Color(0xFF10B981),
          iconBgColor: const Color(0xFFECFDF5),
        ),
      );
      cards.add(
        StatsCard(
          title: "Pending Approvals",
          value: formatter.format(_pendingApprovals),
          trendPercentage: formatTrend(_pendingTrend),
          trendPeriod: "from last week",
          isPositiveTrend: _pendingTrendPositive,
          icon: Icons.pending_actions_rounded,
          iconColor: const Color(0xFFF59E0B),
          iconBgColor: const Color(0xFFFEF3C7),
        ),
      );
    }

    if (_session.hasPermission(Modules.bookings, Perms.view)) {
      cards.add(
        StatsCard(
          title: "Pending Bookings",
          value: formatter.format(_pendingBookings),
          trendPercentage: formatTrend(_pendingBookingsTrend),
          trendPeriod: "currently pending",
          isPositiveTrend: _pendingBookingsTrendPositive,
          icon: Icons.hourglass_empty_rounded,
          iconColor: const Color(0xFF3B82F6),
          iconBgColor: const Color(0xFFEFF6FF),
        ),
      );
      cards.add(
        StatsCard(
          title: "Completed Bookings",
          value: formatter.format(_completedBookings),
          trendPercentage: formatTrend(_completedBookingsTrend),
          trendPeriod: "from last week",
          isPositiveTrend: _completedBookingsTrendPositive,
          icon: Icons.check_circle_outline_rounded,
          iconColor: const Color(0xFF10B981),
          iconBgColor: const Color(0xFFECFDF5),
        ),
      );
      cards.add(
        StatsCard(
          title: "Cancelled Bookings",
          value: formatter.format(_cancelledBookings),
          trendPercentage: formatTrend(_cancelledBookingsTrend),
          trendPeriod: "from last week",
          isPositiveTrend: _cancelledBookingsTrendPositive,
          icon: Icons.cancel_outlined,
          iconColor: const Color(0xFFEF4444),
          iconBgColor: const Color(0xFFFEF2F2),
        ),
      );
    }

    if (_session.hasPermission(Modules.payments, Perms.view)) {
      cards.add(
        StatsCard(
          title: "Paid Total Amount",
          value: "₹${formatter.format(_revenue)}",
          trendPercentage: formatTrend(_revenueTrend),
          trendPeriod: "from last week",
          isPositiveTrend: _revenueTrendPositive,
          icon: Icons.payments_rounded,
          iconColor: const Color(0xFF8B5CF6),
          iconBgColor: const Color(0xFFF5F3FF),
        ),
      );
    }

    if (_session.hasPermission(Modules.storeProducts, Perms.view)) {
      cards.add(
        StatsCard(
          title: "Products",
          value: formatter.format(_totalProducts),
          trendPercentage: formatTrend(_productsTrend),
          trendPeriod: "from last week",
          isPositiveTrend: _productsTrendPositive,
          icon: Icons.shopping_bag_rounded,
          iconColor: const Color(0xFF2563EB),
          iconBgColor: const Color(0xFFEFF6FF),
        ),
      );
    }

    if (_session.hasPermission(Modules.storeOrders, Perms.view)) {
      cards.add(
        StatsCard(
          title: "Orders (This Week)",
          value: formatter.format(_totalOrders),
          trendPercentage: formatTrend(_ordersTrend),
          trendPeriod: "from last week",
          isPositiveTrend: _ordersTrendPositive,
          icon: Icons.shopping_cart_rounded,
          iconColor: const Color(0xFFEA580C),
          iconBgColor: const Color(0xFFFFF7ED),
        ),
      );
    }

    if (_session.hasPermission(Modules.advertisement, Perms.view)) {
      cards.add(
        StatsCard(
          title: "Advertisements",
          value: formatter.format(_totalAdvertisements),
          trendPercentage: formatTrend(_advertisementsTrend),
          trendPeriod: "from last week",
          isPositiveTrend: _advertisementsTrendPositive,
          icon: Icons.campaign_rounded,
          iconColor: const Color(0xFFEC4899),
          iconBgColor: const Color(0xFFFDF2F8),
        ),
      );
    }

    if (_session.hasPermission(Modules.bus, Perms.view)) {
      cards.add(
        StatsCard(
          title: "Bus Routes",
          value: formatter.format(_totalBusRoutes),
          extraInfo:
              "Active: ${formatter.format(_totalActiveBuses)} | Districts: ${formatter.format(_totalBusDistricts)}",
          trendPercentage: formatTrend(_busRoutesTrend),
          trendPeriod: "from last week",
          isPositiveTrend: _busRoutesTrendPositive,
          icon: Icons.directions_bus_rounded,
          iconColor: const Color(0xFF0284C7),
          iconBgColor: const Color(0xFFF0F9FF),
        ),
      );
    }

    if (_session.hasPermission(Modules.taxi, Perms.view)) {
      cards.add(
        StatsCard(
          title: "Active Taxi Drivers",
          value: formatter.format(_totalTaxiDrivers),
          trendPercentage: formatTrend(_taxiDriversTrend),
          trendPeriod: "from last week",
          isPositiveTrend: _taxiDriversTrendPositive,
          icon: Icons.local_taxi_rounded,
          iconColor: const Color(0xFFEAB308),
          iconBgColor: const Color(0xFFFEFCE8),
        ),
      );
    }

    if (cards.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.dashboard_customize_rounded,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                "No dashboard data available",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "You do not have permission to view any dashboard statistics.",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    int crossAxisCount = 6;
    if (width < 650) {
      crossAxisCount = 2;
    } else if (width < 1000) {
      crossAxisCount = 3;
    } else if (width < 1350) {
      crossAxisCount = 4;
    }

    final double itemWidth =
        (width - (crossAxisCount - 1) * 16) / crossAxisCount;
    const double itemHeight = 115;
    final double aspectRatio = itemWidth / itemHeight;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: aspectRatio > 0 ? aspectRatio : 1.5,
      ),
      itemBuilder: (context, index) {
        return cards[index];
      },
    );
  }

  Widget _buildMiddleSection(bool isLargeScreen, double width) {
    bool canViewBookings = _session.hasPermission(
      Modules.dashboard,
      'view_statistics',
    );
    bool canViewActivities = _session.hasPermission(
      Modules.dashboard,
      'view_recent_activity',
    );

    if (!canViewBookings && !canViewActivities) return const SizedBox.shrink();

    if (isLargeScreen) {
      List<Widget> rowChildren = [];
      if (canViewBookings) {
        rowChildren.add(
          Expanded(flex: 4, child: BookingTrendsChart(data: _bookingTrends)),
        );
        rowChildren.add(const SizedBox(width: 24));
        rowChildren.add(
          Expanded(
            flex: 3,
            child: ServiceCategoryChart(categoryCounts: _serviceCategoryCounts),
          ),
        );
      }
      if (canViewActivities) {
        if (rowChildren.isNotEmpty) rowChildren.add(const SizedBox(width: 24));
        rowChildren.add(
          Expanded(
            flex: 3,
            child: RecentActivitiesList(
              activitiesData: _recentActivities,
              onViewAll: () {
                if (widget.onNavigate != null) {
                  widget.onNavigate!("Recent Activity");
                }
              },
            ),
          ),
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rowChildren,
      );
    } else {
      List<Widget> colChildren = [];
      if (canViewBookings) {
        colChildren.add(BookingTrendsChart(data: _bookingTrends));
        colChildren.add(const SizedBox(height: 24));
        if (width > 750) {
          List<Widget> innerRow = [];
          innerRow.add(
            Expanded(
              child: ServiceCategoryChart(
                categoryCounts: _serviceCategoryCounts,
              ),
            ),
          );
          if (canViewActivities) {
            innerRow.add(const SizedBox(width: 24));
            innerRow.add(
              Expanded(
                child: RecentActivitiesList(
                  activitiesData: _recentActivities,
                  onViewAll: () {
                    if (widget.onNavigate != null)
                      widget.onNavigate!("Recent Activity");
                  },
                ),
              ),
            );
          }
          colChildren.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: innerRow,
            ),
          );
        } else {
          colChildren.add(
            ServiceCategoryChart(categoryCounts: _serviceCategoryCounts),
          );
          if (canViewActivities) {
            colChildren.add(const SizedBox(height: 24));
            colChildren.add(
              RecentActivitiesList(
                activitiesData: _recentActivities,
                onViewAll: () {
                  if (widget.onNavigate != null)
                    widget.onNavigate!("Recent Activity");
                },
              ),
            );
          }
        }
      } else if (canViewActivities) {
        colChildren.add(
          RecentActivitiesList(
            activitiesData: _recentActivities,
            onViewAll: () {
              if (widget.onNavigate != null)
                widget.onNavigate!("Recent Activity");
            },
          ),
        );
      }
      return Column(children: colChildren);
    }
  }

  Widget _buildBottomSection(bool isLargeScreen) {
    bool canViewBookings = _session.hasPermission(
      Modules.dashboard,
      'view_statistics',
    );
    bool canViewProducts = _session.hasPermission(
      Modules.dashboard,
      'view_statistics',
    );

    if (!canViewBookings && !canViewProducts) return const SizedBox.shrink();

    if (isLargeScreen) {
      List<Widget> rowChildren = [];
      if (canViewBookings) {
        rowChildren.add(
          Expanded(
            flex: 13,
            child: LatestBookingsTable(
              bookingsData: _latestBookings,
              onViewAll: () {
                if (widget.onNavigate != null)
                  widget.onNavigate!("All Bookings");
              },
            ),
          ),
        );
      }
      if (canViewProducts) {
        if (rowChildren.isNotEmpty) rowChildren.add(const SizedBox(width: 24));
        rowChildren.add(
          Expanded(
            flex: 7,
            child: TopSellingProducts(productsData: _topProducts),
          ),
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rowChildren,
      );
    } else {
      List<Widget> colChildren = [];
      if (canViewBookings) {
        colChildren.add(
          LatestBookingsTable(
            bookingsData: _latestBookings,
            onViewAll: () {
              if (widget.onNavigate != null) widget.onNavigate!("All Bookings");
            },
          ),
        );
      }
      if (canViewProducts) {
        if (colChildren.isNotEmpty) colChildren.add(const SizedBox(height: 24));
        colChildren.add(TopSellingProducts(productsData: _topProducts));
      }
      return Column(children: colChildren);
    }
  }
}

class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String? extraInfo;
  final String trendPercentage;
  final String trendPeriod;
  final bool isPositiveTrend;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    this.extraInfo,
    required this.trendPercentage,
    required this.trendPeriod,
    required this.isPositiveTrend,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    if (extraInfo != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        extraInfo!,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF0284C7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(
                isPositiveTrend ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color:
                    isPositiveTrend
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
              ),
              const SizedBox(width: 4),
              Text(
                trendPercentage,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color:
                      isPositiveTrend
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  trendPeriod,
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

class BookingTrendsChart extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  const BookingTrendsChart({super.key, required this.data});

  @override
  State<BookingTrendsChart> createState() => _BookingTrendsChartState();
}

class _BookingTrendsChartState extends State<BookingTrendsChart> {
  String selectedFilter = 'This Week';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F3F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Booking Trends",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  setState(() {
                    selectedFilter = value;
                  });
                  // Note: Data fetching needs to be wired up here in the future
                },
                offset: const Offset(0, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                color: Colors.white,
                itemBuilder:
                    (context) => [
                      PopupMenuItem(
                        value: 'This Week',
                        child: Text(
                          'This Week',
                          style: GoogleFonts.inter(fontSize: 13),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'This Month',
                        child: Text(
                          'This Month',
                          style: GoogleFonts.inter(fontSize: 13),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'This Year',
                        child: Text(
                          'This Year',
                          style: GoogleFonts.inter(fontSize: 13),
                        ),
                      ),
                    ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        selectedFilter,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 200,
                  getDrawingHorizontalLine: (value) {
                    return const FlLine(
                      color: Color(0xFFF1F5F9),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 200,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            value.toInt().toString(),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < widget.data.length) {
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              widget.data[index]['day'],
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY:
                    (() {
                      if (widget.data.isEmpty) return 10.0;
                      double maxVal = widget.data.fold<double>(
                        0.0,
                        (prev, e) =>
                            (e['count'] as int).toDouble() > prev
                                ? (e['count'] as int).toDouble()
                                : prev,
                      );
                      return maxVal < 10.0 ? 10.0 : maxVal * 1.2;
                    })(),
                lineBarsData: [
                  LineChartBarData(
                    spots:
                        widget.data
                            .map(
                              (e) => FlSpot(
                                (e['index'] as int).toDouble(),
                                (e['count'] as int).toDouble(),
                              ),
                            )
                            .toList(),
                    isCurved: true,
                    color: const Color(0xFF10B981),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF10B981).withValues(alpha: 0.15),
                          const Color(0xFF10B981).withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ServiceCategoryChart extends StatelessWidget {
  final Map<String, int> categoryCounts;
  const ServiceCategoryChart({super.key, required this.categoryCounts});

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = [
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFF06B6D4),
      const Color(0xFFEC4899),
      const Color(0xFF64748B),
    ];

    int total = categoryCounts.values.fold(0, (sum, val) => sum + val);
    List<_ServiceData> data = [];
    if (total == 0) {
      data.add(_ServiceData("No Data", 100, Colors.grey));
    } else {
      int i = 0;
      categoryCounts.forEach((key, value) {
        int percentage = ((value / total) * 100).round();
        data.add(_ServiceData(key, percentage, colors[i % colors.length]));
        i++;
      });
    }

    return Container(
      height: 360,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F3F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Bookings by Service Category",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 45,
                startDegreeOffset: -90,
                sections:
                    data.map((d) {
                      return PieChartSectionData(
                        showTitle: false,
                        color: d.color,
                        value: d.percentage.toDouble(),
                        radius: 25,
                      );
                    }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children:
                data.map((d) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: d.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            d.name,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF475569),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          "${d.percentage}%",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ServiceData {
  final String name;
  final int percentage;
  final Color color;

  _ServiceData(this.name, this.percentage, this.color);
}

class RecentActivitiesList extends StatelessWidget {
  final List<Map<String, dynamic>> activitiesData;
  final VoidCallback? onViewAll;

  const RecentActivitiesList({
    super.key,
    required this.activitiesData,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final activities =
        activitiesData.map((d) {
          bool isUser = d['type'] == 'user';
          bool isCancelled = d['type'] == 'cancelled';
          return _ActivityItem(
            title: d['title'] ?? '',
            subtitle: d['subtitle'] ?? '',
            time: d['time'] ?? 'Recent',
            icon:
                isUser
                    ? Icons.person_add_rounded
                    : isCancelled
                    ? Icons.cancel_rounded
                    : Icons.calendar_today_rounded,
            color:
                isUser
                    ? const Color(0xFF6366F1)
                    : isCancelled
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF10B981),
            bgColor:
                isUser
                    ? const Color(0xFFEEF2FF)
                    : isCancelled
                    ? const Color(0xFFFEF2F2)
                    : const Color(0xFFECFDF5),
          );
        }).toList();
    if (activities.isEmpty) {
      activities.add(
        _ActivityItem(
          title: "No recent activities",
          subtitle: "Waiting for new actions",
          time: "-",
          icon: Icons.hourglass_empty,
          color: Colors.grey,
          bgColor: Colors.grey.shade200,
        ),
      );
    }

    return Container(
      height: 360,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F3F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recent Activities",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  "View All",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final item = activities[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: item.bgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item.icon, color: item.color, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.time,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color color;
  final Color bgColor;

  _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}

class LatestBookingsTable extends StatelessWidget {
  final List<Map<String, dynamic>> bookingsData;
  final VoidCallback? onViewAll;

  const LatestBookingsTable({
    super.key,
    required this.bookingsData,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final bookings =
        bookingsData.map((d) {
          // formatting date safely if it's ISO string
          String dt = d['dateTime'] ?? '';
          if (dt.contains('T'))
            dt = dt.split('T')[0] + ' ' + dt.split('T')[1].substring(0, 5);
          return _BookingRow(
            "#${d['id']}",
            d['customer'] ?? 'Unknown',
            d['service'] ?? 'Service',
            d['serviceImage'] ?? '',
            dt,
            d['status'] ?? 'Pending',
            "${d['amount']}",
          );
        }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F3F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Latest Bookings",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              InkWell(
                onTap: onViewAll,
                child: Text(
                  "View All",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 750,
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.2),
                  1: FlexColumnWidth(1.5),
                  2: FlexColumnWidth(1.8),
                  3: FlexColumnWidth(2.2),
                  4: FlexColumnWidth(1.2),
                  5: FlexColumnWidth(1.0),
                  6: FlexColumnWidth(0.8),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  TableRow(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                      ),
                    ),
                    children: [
                      _buildHeaderCell("Booking ID"),
                      _buildHeaderCell("Customer"),
                      _buildHeaderCell("Service"),
                      _buildHeaderCell("Date & Time"),
                      _buildHeaderCell("Status"),
                      _buildHeaderCell("Amount"),
                      _buildHeaderCell("Actions"),
                    ],
                  ),
                  ...bookings.map((booking) {
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
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              booking.id,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF3B82F6),
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            booking.customer,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  color: const Color(0xFFF1F5F9),
                                  image:
                                      booking.serviceImage.isNotEmpty
                                          ? DecorationImage(
                                            image: NetworkImage(
                                              booking.serviceImage,
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                          : null,
                                ),
                                child:
                                    booking.serviceImage.isEmpty
                                        ? const Icon(
                                          Icons.cleaning_services,
                                          size: 16,
                                          color: Color(0xFF94A3B8),
                                        )
                                        : null,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  booking.service,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFF475569),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            booking.dateTime,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _buildStatusBadge(booking.status),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            booking.amount,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(
                              Icons.visibility_outlined,
                              size: 18,
                              color: Color(0xFF64748B),
                            ),
                            onPressed: () {
                              _showBookingDetailsDialog(context, booking);
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingDetailsDialog(BuildContext context, _BookingRow booking) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            "Booking ${booking.id}",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (booking.serviceImage.isNotEmpty)
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        booking.serviceImage,
                        height: 120,
                        width: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  Center(
                    child: Container(
                      height: 120,
                      width: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.cleaning_services,
                        size: 48,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                _buildDetailRow("Customer", booking.customer),
                _buildDetailRow("Service", booking.service),
                _buildDetailRow(
                  "Date & Time",
                  booking.dateTime.replaceAll('\n', ' '),
                ),
                _buildDetailRow("Amount", booking.amount),
                _buildDetailRow("Status", booking.status),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Close",
                style: GoogleFonts.inter(color: const Color(0xFF3B82F6)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF1E293B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
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

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case "Pending":
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFD97706);
        break;
      case "Confirmed":
        bgColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF059669);
        break;
      case "Assigned":
        bgColor = const Color(0xFFE0F2FE);
        textColor = const Color(0xFF0284C7);
        break;
      case "In Progress":
        bgColor = const Color(0xFFF3E8FF);
        textColor = const Color(0xFF7C3AED);
        break;
      case "Completed":
        bgColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF059669);
        break;
      case "Cancelled":
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFDC2626);
        break;
      default:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF475569);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _BookingRow {
  final String id;
  final String customer;
  final String service;
  final String serviceImage;
  final String dateTime;
  final String status;
  final String amount;

  _BookingRow(
    this.id,
    this.customer,
    this.service,
    this.serviceImage,
    this.dateTime,
    this.status,
    this.amount,
  );
}

class TopSellingProducts extends StatelessWidget {
  final List<Map<String, dynamic>> productsData;
  const TopSellingProducts({super.key, required this.productsData});

  @override
  Widget build(BuildContext context) {
    final List<Color> bgColors = [
      Colors.green[50]!,
      Colors.amber[50]!,
      Colors.orange[50]!,
      Colors.yellow[50]!,
      Colors.teal[50]!,
    ];
    final products = List.generate(productsData.length, (i) {
      final d = productsData[i];
      return _ProductItem(
        d['name'] ?? 'Product',
        int.tryParse(d['sales'].toString()) ?? 0,
        "${d['revenue']}",
        bgColors[i % bgColors.length],
      );
    });
    if (products.isEmpty) {
      products.add(
        _ProductItem("No products found", 0, "₹0", Colors.grey[50]!),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F3F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Top Selling Products",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  "View All",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2.2),
              1: FlexColumnWidth(1.0),
              2: FlexColumnWidth(1.2),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      "Product",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      "Orders",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      "Revenue",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ],
              ),
              ...products.map((product) {
                return TableRow(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: product.imgBgColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.shopping_bag_outlined,
                                size: 16,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              product.name,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E293B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      product.orders.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    Text(
                      product.revenue,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductItem {
  final String name;
  final int orders;
  final String revenue;
  final Color imgBgColor;

  _ProductItem(this.name, this.orders, this.revenue, this.imgBgColor);
}

class PremiumDateRangePickerDialog extends StatefulWidget {
  final DateTimeRange? initialDateRange;

  const PremiumDateRangePickerDialog({super.key, this.initialDateRange});

  @override
  State<PremiumDateRangePickerDialog> createState() =>
      _PremiumDateRangePickerDialogState();
}

class _PremiumDateRangePickerDialogState
    extends State<PremiumDateRangePickerDialog> {
  late DateTime _currentMonth;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialDateRange?.start;
    _endDate = widget.initialDateRange?.end;
    _currentMonth = _startDate ?? DateTime.now();
  }

  String _formatDateString(DateTime? date) {
    if (date == null) return "";
    final months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return "${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}";
  }

  String _formatHeaderDate(DateTimeRange? range) {
    if (range == null) return "No date selected";
    final months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return "${months[range.start.month - 1]} ${range.start.day} – ${months[range.end.month - 1]} ${range.end.day}";
  }

  int _daysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  String _getMonthName(int month) {
    final months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDayInstance = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    );
    final int firstDayOffset = firstDayInstance.weekday % 7;
    final int totalDays = _daysInMonth(_currentMonth);

    final bool hasSelection = _startDate != null && _endDate != null;
    final int daysCount =
        hasSelection ? _endDate!.difference(_startDate!).inDays + 1 : 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 18,
      backgroundColor: const Color(0xFFFCFCFD),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 440,
        decoration: BoxDecoration(
          color: const Color(0xFFFCFCFD),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 40,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header (Gradient) ──────────────────────────────────────────
            Container(
              height: 90,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "SELECT DATE RANGE",
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasSelection
                              ? _formatHeaderDate(
                                DateTimeRange(
                                  start: _startDate!,
                                  end: _endDate!,
                                ),
                              )
                              : "Choose Date Range",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Selected Range Summary or Empty State ────────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child:
                        hasSelection
                            ? Container(
                              key: const ValueKey('summary_selected'),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFA7F3D0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.calendar_today_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Selected Range",
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF065F46),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(
                                              _formatDateString(_startDate),
                                              style: GoogleFonts.inter(
                                                color: const Color(0xFF047857),
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            const Icon(
                                              Icons.arrow_right_alt_rounded,
                                              color: Color(0xFF059669),
                                              size: 16,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              _formatDateString(_endDate),
                                              style: GoogleFonts.inter(
                                                color: const Color(0xFF047857),
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD1FAE5),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      "$daysCount Days",
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF065F46),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : Container(
                              key: const ValueKey('summary_empty'),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE2E8F0),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.calendar_month_rounded,
                                      color: Color(0xFF64748B),
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Choose a date range",
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF1E293B),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          "Filter reports between any two dates.",
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF64748B),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                  ),
                  const SizedBox(height: 20),

                  // ── Month Selector Row ───────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${_getMonthName(_currentMonth.month)} ${_currentMonth.year}",
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Row(
                        children: [
                          _buildNavButton(
                            icon: Icons.chevron_left_rounded,
                            onTap: () {
                              setState(() {
                                _currentMonth = DateTime(
                                  _currentMonth.year,
                                  _currentMonth.month - 1,
                                  1,
                                );
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildNavButton(
                            icon: Icons.chevron_right_rounded,
                            onTap: () {
                              setState(() {
                                _currentMonth = DateTime(
                                  _currentMonth.year,
                                  _currentMonth.month + 1,
                                  1,
                                );
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Calendar Month Card ──────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children:
                              ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"].map((
                                day,
                              ) {
                                return Expanded(
                                  child: Center(
                                    child: Text(
                                      day,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                        const SizedBox(height: 8),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                childAspectRatio: 1.1,
                              ),
                          itemCount: totalDays + firstDayOffset,
                          itemBuilder: (context, index) {
                            if (index < firstDayOffset) {
                              return const SizedBox.shrink();
                            }
                            final int dayNum = index - firstDayOffset + 1;
                            final DateTime cellDate = DateTime(
                              _currentMonth.year,
                              _currentMonth.month,
                              dayNum,
                            );

                            return _buildDayCell(cellDate, dayNum, now);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Action Buttons ───────────────────────────────────────────
                  Row(
                    children: [
                      if (_startDate != null || _endDate != null)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _startDate = null;
                              _endDate = null;
                            });
                          },
                          icon: const Icon(
                            Icons.clear_rounded,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                          label: Text(
                            "Clear",
                            style: GoogleFonts.inter(
                              color: const Color(0xFF64748B),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const Spacer(),
                      SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                          ),
                          child: Text(
                            "Cancel",
                            style: GoogleFonts.inter(
                              color: const Color(0xFF64748B),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed:
                              hasSelection
                                  ? () {
                                    Navigator.pop(
                                      context,
                                      DateTimeRange(
                                        start: _startDate!,
                                        end: _endDate!,
                                      ),
                                    );
                                  }
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                          ),
                          child: Text(
                            "Apply",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF64748B)),
      ),
    );
  }

  Widget _buildDayCell(DateTime date, int dayNum, DateTime today) {
    final bool isStart =
        _startDate != null &&
        date.year == _startDate!.year &&
        date.month == _startDate!.month &&
        date.day == _startDate!.day;
    final bool isEnd =
        _endDate != null &&
        date.year == _endDate!.year &&
        date.month == _endDate!.month &&
        date.day == _endDate!.day;
    final bool isSelected = isStart || isEnd;

    final bool inRange =
        _startDate != null &&
        _endDate != null &&
        date.isAfter(_startDate!) &&
        date.isBefore(_endDate!);

    final bool isToday =
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;

    BoxDecoration? cellDecoration;
    TextStyle textStyle = GoogleFonts.inter(
      fontSize: 12,
      color: const Color(0xFF1E293B),
      fontWeight: FontWeight.w500,
    );

    if (isSelected) {
      cellDecoration = const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF34D399), Color(0xFF10B981)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x4010B981),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      );
      textStyle = GoogleFonts.inter(
        fontSize: 12,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      );
    } else if (inRange) {
      cellDecoration = const BoxDecoration(
        color: Color(0x33DCFCE7),
        shape: BoxShape.circle,
      );
      textStyle = GoogleFonts.inter(
        fontSize: 12,
        color: const Color(0xFF047857),
        fontWeight: FontWeight.w600,
      );
    } else if (isToday) {
      cellDecoration = BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF10B981), width: 2),
      );
      textStyle = GoogleFonts.inter(
        fontSize: 12,
        color: const Color(0xFF10B981),
        fontWeight: FontWeight.bold,
      );
    }

    return InkWell(
      onTap: () {
        setState(() {
          if (_startDate == null || (_startDate != null && _endDate != null)) {
            _startDate = date;
            _endDate = null;
          } else if (date.isBefore(_startDate!)) {
            _startDate = date;
          } else {
            _endDate = date;
          }
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.all(2),
        alignment: Alignment.center,
        decoration: cellDecoration,
        child: Text(dayNum.toString(), style: textStyle),
      ),
    );
  }
}
