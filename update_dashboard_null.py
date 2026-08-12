import os
import re

file_path = r'd:\nattulinkapp\Naattulink_Admin_pannel\lib\MVVM\view\pages.dart\Dashboard\Dashboard.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update the top part
old_top = '''      final now = DateTime.now();
      DateTime startOfThisPeriod;
      DateTime startOfPreviousPeriod;
      DateTime endOfThisPeriod;
      
      if (_selectedDateRange != null) {
        startOfThisPeriod = _selectedDateRange!.start;
        // add 1 day to include the end date fully
        endOfThisPeriod = _selectedDateRange!.end.add(const Duration(days: 1)); 
        final duration = endOfThisPeriod.difference(startOfThisPeriod);
        startOfPreviousPeriod = startOfThisPeriod.subtract(duration);
      } else {
        startOfThisPeriod = DateTime(2000, 1, 1);
        startOfPreviousPeriod = DateTime(2000, 1, 1);
        endOfThisPeriod = now.add(const Duration(days: 1));
      }'''

new_top = '''      final now = DateTime.now();
      DateTime? startOfThisPeriod;
      DateTime? startOfPreviousPeriod;
      DateTime? endOfThisPeriod;
      
      if (_selectedDateRange != null) {
        startOfThisPeriod = _selectedDateRange!.start;
        // add 1 day to include the end date fully
        endOfThisPeriod = _selectedDateRange!.end.add(const Duration(days: 1)); 
        final duration = endOfThisPeriod.difference(startOfThisPeriod);
        startOfPreviousPeriod = startOfThisPeriod.subtract(duration);
      }'''

content = content.replace(old_top, new_top)

# We will use regex to conditionally execute the queries if _selectedDateRange != null

queries_to_replace = [
    # USERS
    (r"final usersThis =[\s\n]*db[\s\n]*\.collection\('users'\)[\s\n]*\.where\('createdAt', isGreaterThanOrEqualTo: startOfThisPeriod\)[\s\n]*\.where\('createdAt', isLessThan: endOfThisPeriod\)[\s\n]*\.count\(\)[\s\n]*\.get\(\);",
     r"final usersThis = _selectedDateRange != null ? db.collection('users').where('createdAt', isGreaterThanOrEqualTo: startOfThisPeriod!).where('createdAt', isLessThan: endOfThisPeriod!).count().get() : Future.value(null);"),
    
    (r"final usersPrev =[\s\n]*db[\s\n]*\.collection\('users'\)[\s\n]*\.where\('createdAt', isGreaterThanOrEqualTo: startOfPreviousPeriod\)[\s\n]*\.where\('createdAt', isLessThan: startOfThisPeriod\)[\s\n]*\.count\(\)[\s\n]*\.get\(\);",
     r"final usersPrev = _selectedDateRange != null ? db.collection('users').where('createdAt', isGreaterThanOrEqualTo: startOfPreviousPeriod!).where('createdAt', isLessThan: startOfThisPeriod!).count().get() : Future.value(null);"),

    # WORKERS
    (r"final workersThis =[\s\n]*db[\s\n]*\.collection\('workers'\)[\s\n]*\.where\('createdAt', isGreaterThanOrEqualTo: startOfThisPeriod\)[\s\n]*\.where\('createdAt', isLessThan: endOfThisPeriod\)[\s\n]*\.count\(\)[\s\n]*\.get\(\);",
     r"final workersThis = _selectedDateRange != null ? db.collection('workers').where('createdAt', isGreaterThanOrEqualTo: startOfThisPeriod!).where('createdAt', isLessThan: endOfThisPeriod!).count().get() : Future.value(null);"),
     
    (r"final workersPrev =[\s\n]*db[\s\n]*\.collection\('workers'\)[\s\n]*\.where\('createdAt', isGreaterThanOrEqualTo: startOfPreviousPeriod\)[\s\n]*\.where\('createdAt', isLessThan: startOfThisPeriod\)[\s\n]*\.count\(\)[\s\n]*\.get\(\);",
     r"final workersPrev = _selectedDateRange != null ? db.collection('workers').where('createdAt', isGreaterThanOrEqualTo: startOfPreviousPeriod!).where('createdAt', isLessThan: startOfThisPeriod!).count().get() : Future.value(null);"),

    # PENDING
    (r"final pendingThis =[\s\n]*db[\s\n]*\.collection\('workers'\)[\s\n]*\.where\('isVerified', isEqualTo: 0\)[\s\n]*\.where\('createdAt', isGreaterThanOrEqualTo: startOfThisPeriod\)[\s\n]*\.where\('createdAt', isLessThan: endOfThisPeriod\)[\s\n]*\.count\(\)[\s\n]*\.get\(\);",
     r"final pendingThis = _selectedDateRange != null ? db.collection('workers').where('isVerified', isEqualTo: 0).where('createdAt', isGreaterThanOrEqualTo: startOfThisPeriod!).where('createdAt', isLessThan: endOfThisPeriod!).count().get() : Future.value(null);"),

    (r"final pendingPrev =[\s\n]*db[\s\n]*\.collection\('workers'\)[\s\n]*\.where\('isVerified', isEqualTo: 0\)[\s\n]*\.where\('createdAt', isGreaterThanOrEqualTo: startOfPreviousPeriod\)[\s\n]*\.where\('createdAt', isLessThan: startOfThisPeriod\)[\s\n]*\.count\(\)[\s\n]*\.get\(\);",
     r"final pendingPrev = _selectedDateRange != null ? db.collection('workers').where('isVerified', isEqualTo: 0).where('createdAt', isGreaterThanOrEqualTo: startOfPreviousPeriod!).where('createdAt', isLessThan: startOfThisPeriod!).count().get() : Future.value(null);"),

    # COMPLETED BOOKINGS
    (r"final completedThis =[\s\n]*db[\s\n]*\.collection\('service_bookings'\)[\s\n]*\.where\('status', isEqualTo: 'Completed'\)[\s\n]*\.where\('timestamp', isGreaterThanOrEqualTo: startOfThisPeriod\.toIso8601String\(\)\)[\s\n]*\.where\('timestamp', isLessThan: endOfThisPeriod\.toIso8601String\(\)\)[\s\n]*\.count\(\)[\s\n]*\.get\(\);",
     r"final completedThis = _selectedDateRange != null ? db.collection('service_bookings').where('status', isEqualTo: 'Completed').where('timestamp', isGreaterThanOrEqualTo: startOfThisPeriod!.toIso8601String()).where('timestamp', isLessThan: endOfThisPeriod!.toIso8601String()).count().get() : Future.value(null);"),

    (r"final completedPrev =[\s\n]*db[\s\n]*\.collection\('service_bookings'\)[\s\n]*\.where\('status', isEqualTo: 'Completed'\)[\s\n]*\.where\([\s\n]*'timestamp',[\s\n]*isGreaterThanOrEqualTo: startOfPreviousPeriod\.toIso8601String\(\),[\s\n]*\)[\s\n]*\.where\([\s\n]*'timestamp',[\s\n]*isLessThan: startOfThisPeriod\.toIso8601String\(\),[\s\n]*\)[\s\n]*\.count\(\)[\s\n]*\.get\(\);",
     r"final completedPrev = _selectedDateRange != null ? db.collection('service_bookings').where('status', isEqualTo: 'Completed').where('timestamp', isGreaterThanOrEqualTo: startOfPreviousPeriod!.toIso8601String()).where('timestamp', isLessThan: startOfThisPeriod!.toIso8601String()).count().get() : Future.value(null);"),

    # CANCELLED BOOKINGS
    (r"final cancelledThis =[\s\n]*db[\s\n]*\.collection\('service_bookings'\)[\s\n]*\.where\('status', isEqualTo: 'Cancelled'\)[\s\n]*\.where\('timestamp', isGreaterThanOrEqualTo: startOfThisPeriod\.toIso8601String\(\)\)[\s\n]*\.where\('timestamp', isLessThan: endOfThisPeriod\.toIso8601String\(\)\)[\s\n]*\.count\(\)[\s\n]*\.get\(\);",
     r"final cancelledThis = _selectedDateRange != null ? db.collection('service_bookings').where('status', isEqualTo: 'Cancelled').where('timestamp', isGreaterThanOrEqualTo: startOfThisPeriod!.toIso8601String()).where('timestamp', isLessThan: endOfThisPeriod!.toIso8601String()).count().get() : Future.value(null);"),

    (r"final cancelledPrev =[\s\n]*db[\s\n]*\.collection\('service_bookings'\)[\s\n]*\.where\('status', isEqualTo: 'Cancelled'\)[\s\n]*\.where\([\s\n]*'timestamp',[\s\n]*isGreaterThanOrEqualTo: startOfPreviousPeriod\.toIso8601String\(\),[\s\n]*\)[\s\n]*\.where\([\s\n]*'timestamp',[\s\n]*isLessThan: startOfThisPeriod\.toIso8601String\(\),[\s\n]*\)[\s\n]*\.count\(\)[\s\n]*\.get\(\);",
     r"final cancelledPrev = _selectedDateRange != null ? db.collection('service_bookings').where('status', isEqualTo: 'Cancelled').where('timestamp', isGreaterThanOrEqualTo: startOfPreviousPeriod!.toIso8601String()).where('timestamp', isLessThan: startOfThisPeriod!.toIso8601String()).count().get() : Future.value(null);"),

    # PRODUCTS
    (r"final productsThis =[\s\n]*db[\s\n]*\.collection\('products'\)[\s\n]*\.where\('createdAt', isGreaterThanOrEqualTo: startOfThisPeriod\)[\s\n]*\.where\('createdAt', isLessThan: endOfThisPeriod\)[\s\n]*\.count\(\)[\s\n]*\.get\(\);",
     r"final productsThis = _selectedDateRange != null ? db.collection('products').where('createdAt', isGreaterThanOrEqualTo: startOfThisPeriod!).where('createdAt', isLessThan: endOfThisPeriod!).count().get() : Future.value(null);"),

    (r"final productsPrev =[\s\n]*db[\s\n]*\.collection\('products'\)[\s\n]*\.where\('createdAt', isGreaterThanOrEqualTo: startOfPreviousPeriod\)[\s\n]*\.where\('createdAt', isLessThan: startOfThisPeriod\)[\s\n]*\.count\(\)[\s\n]*\.get\(\);",
     r"final productsPrev = _selectedDateRange != null ? db.collection('products').where('createdAt', isGreaterThanOrEqualTo: startOfPreviousPeriod!).where('createdAt', isLessThan: startOfThisPeriod!).count().get() : Future.value(null);"),

    # ORDERS
    (r"final ordersThis =[\s\n]*db[\s\n]*\.collection\('orders'\)[\s\n]*\.where\('createdAt', isGreaterThanOrEqualTo: startOfThisPeriod\)[\s\n]*\.where\('createdAt', isLessThan: endOfThisPeriod\)[\s\n]*\.count\(\)[\s\n]*\.get\(\);",
     r"final ordersThis = _selectedDateRange != null ? db.collection('orders').where('createdAt', isGreaterThanOrEqualTo: startOfThisPeriod!).where('createdAt', isLessThan: endOfThisPeriod!).count().get() : Future.value(null);"),

    (r"final ordersPrev =[\s\n]*db[\s\n]*\.collection\('orders'\)[\s\n]*\.where\('createdAt', isGreaterThanOrEqualTo: startOfPreviousPeriod\)[\s\n]*\.where\('createdAt', isLessThan: startOfThisPeriod\)[\s\n]*\.count\(\)[\s\n]*\.get\(\);",
     r"final ordersPrev = _selectedDateRange != null ? db.collection('orders').where('createdAt', isGreaterThanOrEqualTo: startOfPreviousPeriod!).where('createdAt', isLessThan: startOfThisPeriod!).count().get() : Future.value(null);"),

    # ADS
    (r"final adsThis =[\s\n]*db[\s\n]*\.collection\('advertisements'\)[\s\n]*\.where\('createdAt', isGreaterThanOrEqualTo: startOfThisPeriod\)[\s\n]*\.where\('createdAt', isLessThan: endOfThisPeriod\)[\s\n]*\.count\(\)[\s\n]*\.get\(\);",
     r"final adsThis = _selectedDateRange != null ? db.collection('advertisements').where('createdAt', isGreaterThanOrEqualTo: startOfThisPeriod!).where('createdAt', isLessThan: endOfThisPeriod!).count().get() : Future.value(null);"),

    (r"final adsPrev =[\s\n]*db[\s\n]*\.collection\('advertisements'\)[\s\n]*\.where\('createdAt', isGreaterThanOrEqualTo: startOfPreviousPeriod\)[\s\n]*\.where\('createdAt', isLessThan: startOfThisPeriod\)[\s\n]*\.count\(\)[\s\n]*\.get\(\);",
     r"final adsPrev = _selectedDateRange != null ? db.collection('advertisements').where('createdAt', isGreaterThanOrEqualTo: startOfPreviousPeriod!).where('createdAt', isLessThan: startOfThisPeriod!).count().get() : Future.value(null);"),

    # TAXI DRIVERS
    (r"final taxiThis =[\s\n]*db[\s\n]*\.collection\('taxi_drivers'\)[\s\n]*\.where\('created_at', isGreaterThanOrEqualTo: startOfThisPeriod\)[\s\n]*\.where\('created_at', isLessThan: endOfThisPeriod\)[\s\n]*\.count\(\)[\s\n]*\.get\(\);",
     r"final taxiThis = _selectedDateRange != null ? db.collection('taxi_drivers').where('created_at', isGreaterThanOrEqualTo: startOfThisPeriod!).where('created_at', isLessThan: endOfThisPeriod!).count().get() : Future.value(null);"),

    (r"final taxiPrev =[\s\n]*db[\s\n]*\.collection\('taxi_drivers'\)[\s\n]*\.where\([\s\n]*'created_at',[\s\n]*isGreaterThanOrEqualTo: startOfPreviousPeriod,[\s\n]*\)[\s\n]*\.where\('created_at', isLessThan: startOfThisPeriod\)[\s\n]*\.count\(\)[\s\n]*\.get\(\);",
     r"final taxiPrev = _selectedDateRange != null ? db.collection('taxi_drivers').where('created_at', isGreaterThanOrEqualTo: startOfPreviousPeriod!).where('created_at', isLessThan: startOfThisPeriod!).count().get() : Future.value(null);")
]

for old, new in queries_to_replace:
    content = re.sub(old, new, content)


# Revenue Calculation updates
content = content.replace("if (dt != null) {", "if (dt != null && _selectedDateRange != null) {")
content = content.replace("(dt.isAfter(startOfThisPeriod) || dt.isAtSameMomentAs(startOfThisPeriod)) && dt.isBefore(endOfThisPeriod)", "(dt.isAfter(startOfThisPeriod!) || dt.isAtSameMomentAs(startOfThisPeriod!)) && dt.isBefore(endOfThisPeriod!)")
content = content.replace("dt.isAfter(startOfPreviousPeriod) &&\n              dt.isBefore(startOfThisPeriod)", "dt.isAfter(startOfPreviousPeriod!) && dt.isBefore(startOfThisPeriod!)")
content = content.replace("dt.isAfter(startOfPreviousPeriod) && dt.isBefore(startOfThisPeriod)", "dt.isAfter(startOfPreviousPeriod!) && dt.isBefore(startOfThisPeriod!)")

# Transports updates
content = content.replace("if (pDate != null) {", "if (pDate != null && _selectedDateRange != null) {")
content = content.replace("pDate.isAfter(startOfThisPeriod) && pDate.isBefore(endOfThisPeriod)", "pDate.isAfter(startOfThisPeriod!) && pDate.isBefore(endOfThisPeriod!)")
content = content.replace("pDate.isAfter(startOfPreviousPeriod)", "pDate.isAfter(startOfPreviousPeriod!)")

content = content.replace("if (bDate != null) {", "if (bDate != null && _selectedDateRange != null) {")
content = content.replace("bDate.isAfter(startOfThisPeriod) && bDate.isBefore(endOfThisPeriod)", "bDate.isAfter(startOfThisPeriod!) && bDate.isBefore(endOfThisPeriod!)")
content = content.replace("bDate.isAfter(startOfPreviousPeriod)", "bDate.isAfter(startOfPreviousPeriod!)")

# SetState block updates
setState_old = '''          _totalUsers = results[0].count ?? 0;
          final ut = results[1].count ?? 0;
          final up = results[2].count ?? 0;
          _usersTrend = calcTrend(ut, up);
          _usersTrendPositive = _usersTrend >= 0;

          _totalWorkers = results[3].count ?? 0;
          final wt = results[4].count ?? 0;
          final wp = results[5].count ?? 0;
          _workersTrend = calcTrend(wt, wp);
          _workersTrendPositive = _workersTrend >= 0;

          _pendingApprovals = results[6].count ?? 0;
          final pt = results[7].count ?? 0;
          final pp = results[8].count ?? 0;
          _pendingTrend = calcTrend(pt, pp);
          _pendingTrendPositive = _pendingTrend >= 0;

          _todaysBookings = results[9].count ?? 0;
          final tbt = _todaysBookings;
          final tbp = results[10].count ?? 0;
          _todaysBookingsTrend = calcTrend(tbt, tbp);
          _todaysBookingsTrendPositive = _todaysBookingsTrend >= 0;

          _completedBookings = results[11].count ?? 0;
          final ct = results[12].count ?? 0;
          final cp = results[13].count ?? 0;
          _completedBookingsTrend = calcTrend(ct, cp);
          _completedBookingsTrendPositive = _completedBookingsTrend >= 0;

          _cancelledBookings = results[14].count ?? 0;
          final cbt = results[15].count ?? 0;
          final cbp = results[16].count ?? 0;
          _cancelledBookingsTrend = calcTrend(cbt, cbp);
          _cancelledBookingsTrendPositive = _cancelledBookingsTrend >= 0;

          _revenue = totalRev;
          _revenueTrend = calcRevenueTrend(currentRevenue, previousRevenue);
          _revenueTrendPositive = _revenueTrend >= 0;

          _totalProducts = results[17].count ?? 0;
          final pt_ = results[18].count ?? 0;
          final pp_ = results[19].count ?? 0;
          _productsTrend = calcTrend(pt_, pp_);
          _productsTrendPositive = _productsTrend >= 0;

          _totalOrders = results[20].count ?? 0;
          final ot = results[21].count ?? 0;
          final op = results[22].count ?? 0;
          _ordersTrend = calcTrend(ot, op);
          _ordersTrendPositive = _ordersTrend >= 0;

          _totalAdvertisements = results[23].count ?? 0;
          final adt = results[24].count ?? 0;
          final adp = results[25].count ?? 0;
          _advertisementsTrend = calcTrend(adt, adp);
          _advertisementsTrendPositive = _advertisementsTrend >= 0;

          _totalTaxiDrivers = results[26].count ?? 0;
          final tdxt = results[27].count ?? 0;
          final tdxp = results[28].count ?? 0;
          _taxiDriversTrend = calcTrend(tdxt, tdxp);
          _taxiDriversTrendPositive = _taxiDriversTrend >= 0;'''

setState_new = '''          final bool hasDateFilter = _selectedDateRange != null;
          
          _totalUsers = hasDateFilter ? (results[1]?.count ?? 0) : (results[0]?.count ?? 0);
          final ut = results[1]?.count ?? 0;
          final up = results[2]?.count ?? 0;
          _usersTrend = hasDateFilter ? calcTrend(ut, up) : 0.0;
          _usersTrendPositive = _usersTrend >= 0;

          _totalWorkers = hasDateFilter ? (results[4]?.count ?? 0) : (results[3]?.count ?? 0);
          final wt = results[4]?.count ?? 0;
          final wp = results[5]?.count ?? 0;
          _workersTrend = hasDateFilter ? calcTrend(wt, wp) : 0.0;
          _workersTrendPositive = _workersTrend >= 0;

          _pendingApprovals = hasDateFilter ? (results[7]?.count ?? 0) : (results[6]?.count ?? 0);
          final pt = results[7]?.count ?? 0;
          final pp = results[8]?.count ?? 0;
          _pendingTrend = hasDateFilter ? calcTrend(pt, pp) : 0.0;
          _pendingTrendPositive = _pendingTrend >= 0;

          // Today's bookings usually shouldn't be affected by a generic date filter, but if selected, we could show the range bookings.
          // The user requested "Date range selected -> Apply selected start/end dates -> Show filtered counts + revenue"
          // We will use results[9] (today) if no filter, or maybe calculate bookings in range. But wait, results[9] is strictly today.
          // If hasDateFilter, we don't have a "this period" bookings count (we only have completed and cancelled).
          // Actually, we can just keep _todaysBookings as today, since the label says "Today's Bookings". 
          _todaysBookings = results[9]?.count ?? 0; 
          final tbt = _todaysBookings;
          final tbp = results[10]?.count ?? 0;
          _todaysBookingsTrend = hasDateFilter ? 0.0 : calcTrend(tbt, tbp); // Or just keep trend for today
          _todaysBookingsTrendPositive = _todaysBookingsTrend >= 0;

          _completedBookings = hasDateFilter ? (results[12]?.count ?? 0) : (results[11]?.count ?? 0);
          final ct = results[12]?.count ?? 0;
          final cp = results[13]?.count ?? 0;
          _completedBookingsTrend = hasDateFilter ? calcTrend(ct, cp) : 0.0;
          _completedBookingsTrendPositive = _completedBookingsTrend >= 0;

          _cancelledBookings = hasDateFilter ? (results[15]?.count ?? 0) : (results[14]?.count ?? 0);
          final cbt = results[15]?.count ?? 0;
          final cbp = results[16]?.count ?? 0;
          _cancelledBookingsTrend = hasDateFilter ? calcTrend(cbt, cbp) : 0.0;
          _cancelledBookingsTrendPositive = _cancelledBookingsTrend >= 0;

          _revenue = hasDateFilter ? currentRevenue : totalRev;
          _revenueTrend = hasDateFilter ? calcRevenueTrend(currentRevenue, previousRevenue) : 0.0;
          _revenueTrendPositive = _revenueTrend >= 0;

          _totalProducts = hasDateFilter ? (results[18]?.count ?? 0) : (results[17]?.count ?? 0);
          final pt_ = results[18]?.count ?? 0;
          final pp_ = results[19]?.count ?? 0;
          _productsTrend = hasDateFilter ? calcTrend(pt_, pp_) : 0.0;
          _productsTrendPositive = _productsTrend >= 0;

          _totalOrders = hasDateFilter ? (results[21]?.count ?? 0) : (results[20]?.count ?? 0);
          final ot = results[21]?.count ?? 0;
          final op = results[22]?.count ?? 0;
          _ordersTrend = hasDateFilter ? calcTrend(ot, op) : 0.0;
          _ordersTrendPositive = _ordersTrend >= 0;

          _totalAdvertisements = hasDateFilter ? (results[24]?.count ?? 0) : (results[23]?.count ?? 0);
          final adt = results[24]?.count ?? 0;
          final adp = results[25]?.count ?? 0;
          _advertisementsTrend = hasDateFilter ? calcTrend(adt, adp) : 0.0;
          _advertisementsTrendPositive = _advertisementsTrend >= 0;

          _totalTaxiDrivers = hasDateFilter ? (results[27]?.count ?? 0) : (results[26]?.count ?? 0);
          final tdxt = results[27]?.count ?? 0;
          final tdxp = results[28]?.count ?? 0;
          _taxiDriversTrend = hasDateFilter ? calcTrend(tdxt, tdxp) : 0.0;
          _taxiDriversTrendPositive = _taxiDriversTrend >= 0;'''

content = content.replace(setState_old, setState_new)


with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated Dashboard.dart")
