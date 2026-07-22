import 'dart:html' as html;
import 'package:swiftclean_admin/MVVM/view/pages.dart/User/Profile_user.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/User/User_roles.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/User/Banned_users.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/worker/All_workers.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Bookings/Bookings.dart';

void printUsersList(List<UserModel> users) {
  final htmlBuffer = StringBuffer();
  htmlBuffer.write('''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>User List Export</title>
      <style>
        body {
          font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
          margin: 40px;
          color: #1E293B;
          background-color: #FFFFFF;
        }
        h1 {
          font-size: 22px;
          margin: 0;
          color: #0F172A;
          font-weight: 700;
        }
        .header-container {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 24px;
          border-bottom: 2px solid #E2E8F0;
          padding-bottom: 16px;
        }
        table {
          width: 100%;
          border-collapse: collapse;
          margin-top: 10px;
        }
        th, td {
          border: 1px solid #E2E8F0;
          padding: 10px 12px;
          text-align: left;
          font-size: 12px;
          vertical-align: middle;
        }
        th {
          background-color: #F8FAFC;
          font-weight: 600;
          color: #475569;
          text-transform: uppercase;
          font-size: 11px;
          letter-spacing: 0.5px;
        }
        tr:nth-child(even) {
          background-color: #F8FAFC;
        }
        .status {
          font-weight: 600;
          font-size: 11px;
          padding: 3px 8px;
          border-radius: 4px;
          display: inline-block;
        }
        .status-active {
          background-color: #D1FAE5;
          color: #065F46;
        }
        .status-suspended {
          background-color: #FEE2E2;
          color: #991B1B;
        }
        .status-inactive {
          background-color: #F1F5F9;
          color: #475569;
        }
        .badge {
          font-size: 11px;
          padding: 2px 6px;
          border-radius: 4px;
          font-weight: 500;
          background-color: #DBEAFE;
          color: #1E40AF;
        }
        .badge-admin {
          background-color: #F3E8FF;
          color: #6B21A8;
        }
        @media print {
          body {
            margin: 20px 10px;
          }
          button {
            display: none;
          }
          .header-container {
            border-bottom: 1px solid #CBD5E1;
          }
        }
      </style>
    </head>
    <body>
      <div class="header-container">
        <div>
          <h1>Registered Users Directory</h1>
          <p style="margin: 4px 0 0 0; font-size: 12px; color: #64748B;">Total Users: ${users.length} | Generated on ${DateTime.now().toString().split('.')[0]}</p>
        </div>
        <button onclick="window.print()" style="padding: 10px 20px; background-color: #10B981; color: white; border: none; border-radius: 6px; font-weight: bold; cursor: pointer; font-family: inherit; font-size: 13px; box-shadow: 0 1px 3px rgba(0,0,0,0.1);">Print / Save PDF</button>
      </div>
      <table>
        <thead>
          <tr>
            <th>Name & ID</th>
            <th>Email</th>
            <th>Phone</th>
            <th>User Type</th>
            <th>Status</th>
            <th>Joined Date</th>
            <th>Points</th>
            <th>Address</th>
          </tr>
        </thead>
        <tbody>
  ''');

  for (final user in users) {
    final statusClass =
        user.status.toLowerCase() == 'active'
            ? 'status-active'
            : (user.status.toLowerCase() == 'suspended'
                ? 'status-suspended'
                : 'status-inactive');

    final typeClass =
        user.userType.toLowerCase() == 'admin' ? 'badge-admin' : '';

    htmlBuffer.write('''
          <tr>
            <td>
              <div style="font-weight: 600; color: #0F172A;">${_escapeHtml(user.name)}</div>
              <div style="color: #64748B; font-size: 11px; margin-top: 2px;">${_escapeHtml(user.userId)}</div>
            </td>
            <td>${_escapeHtml(user.email)}</td>
            <td>${_escapeHtml(user.phone)}</td>
            <td><span class="badge $typeClass">${_escapeHtml(user.userType)}</span></td>
            <td><span class="status $statusClass">${_escapeHtml(user.status)}</span></td>
            <td>${_escapeHtml(user.joinedDate)}</td>
            <td><strong style="color: #F59E0B;">&#9733;</strong> ${user.points}</td>
            <td>${_escapeHtml(user.address)}</td>
          </tr>
    ''');
  }

  htmlBuffer.write('''
        </tbody>
      </table>
      <script>
        window.addEventListener('load', () => {
          setTimeout(() => {
            window.print();
          }, 500);
        });
      </script>
    </body>
    </html>
  ''');

  final blob = html.Blob([htmlBuffer.toString()], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
}

String _escapeHtml(String text) {
  return text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#x27;');
}

void printRolesList(List<RoleModel> roles) {
  final htmlBuffer = StringBuffer();
  htmlBuffer.write('''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>User Roles Directory</title>
      <style>
        body {
          font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
          margin: 40px;
          color: #1E293B;
          background-color: #FFFFFF;
        }
        h1 {
          font-size: 22px;
          margin: 0;
          color: #0F172A;
          font-weight: 700;
        }
        .header-container {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 24px;
          border-bottom: 2px solid #E2E8F0;
          padding-bottom: 16px;
        }
        table {
          width: 100%;
          border-collapse: collapse;
          margin-top: 10px;
        }
        th, td {
          border: 1px solid #E2E8F0;
          padding: 10px 12px;
          text-align: left;
          font-size: 12px;
          vertical-align: middle;
        }
        th {
          background-color: #F8FAFC;
          font-weight: 600;
          color: #475569;
          text-transform: uppercase;
          font-size: 11px;
          letter-spacing: 0.5px;
        }
        tr:nth-child(even) {
          background-color: #F8FAFC;
        }
        .status {
          font-weight: 600;
          font-size: 11px;
          padding: 3px 8px;
          border-radius: 4px;
          display: inline-block;
        }
        .status-active {
          background-color: #D1FAE5;
          color: #065F46;
        }
        .status-inactive {
          background-color: #F1F5F9;
          color: #475569;
        }
        @media print {
          body {
            margin: 20px 10px;
          }
          button {
            display: none;
          }
          .header-container {
            border-bottom: 1px solid #CBD5E1;
          }
        }
      </style>
    </head>
    <body>
      <div class="header-container">
        <div>
          <h1>User Roles Directory</h1>
          <p style="margin: 4px 0 0 0; font-size: 12px; color: #64748B;">Total Roles: ${roles.length} | Generated on ${DateTime.now().toString().split('.')[0]}</p>
        </div>
        <button onclick="window.print()" style="padding: 10px 20px; background-color: #10B981; color: white; border: none; border-radius: 6px; font-weight: bold; cursor: pointer; font-family: inherit; font-size: 13px; box-shadow: 0 1px 3px rgba(0,0,0,0.1);">Print / Save PDF</button>
      </div>
      <table>
        <thead>
          <tr>
            <th>Role Name & ID</th>
            <th>Description</th>
            <th>Active Users Count</th>
            <th>Status</th>
            <th>Created At</th>
          </tr>
        </thead>
        <tbody>
  ''');

  for (final role in roles) {
    final statusClass =
        role.status.toLowerCase() == 'active' ? 'status-active' : 'status-inactive';

    final colorHex = '#${role.badgeColor.toARGB32().toRadixString(16).substring(2).padLeft(6, '0').toUpperCase()}';

    htmlBuffer.write('''
          <tr>
            <td>
              <div style="display: flex; align-items: center; gap: 8px;">
                <div style="width: 24px; height: 24px; border-radius: 50%; background-color: $colorHex; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 10px;">
                  ${_escapeHtml(role.initials)}
                </div>
                <div>
                  <div style="font-weight: 600; color: #0F172A;">${_escapeHtml(role.name)}</div>
                  <div style="color: #64748B; font-size: 10px; margin-top: 1px;">ID: ${_escapeHtml(role.id)}</div>
                </div>
              </div>
            </td>
            <td>${_escapeHtml(role.description)}</td>
            <td><strong>${role.usersCount}</strong> users</td>
            <td><span class="status $statusClass">${_escapeHtml(role.status)}</span></td>
            <td>${_escapeHtml(_formatDisplayDate(role.createdAt))}</td>
          </tr>
    ''');
  }

  htmlBuffer.write('''
        </tbody>
      </table>
      <script>
        window.addEventListener('load', () => {
          setTimeout(() => {
            window.print();
          }, 500);
        });
      </script>
    </body>
    </html>
  ''');

  final blob = html.Blob([htmlBuffer.toString()], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
}

String _formatDisplayDate(String dateStr) {
  if (dateStr.isEmpty) return '';
  try {
    final parsed = DateTime.tryParse(dateStr);
    if (parsed != null) {
      final day = parsed.day.toString().padLeft(2, '0');
      final month = parsed.month.toString().padLeft(2, '0');
      final year = parsed.year;
      return "$day-$month-$year";
    }
    final cleaned = dateStr.replaceAll(',', '');
    final parts = cleaned.split(' ');
    if (parts.length >= 3) {
      final monthStr = parts[0].toLowerCase();
      final dayVal = int.tryParse(parts[1]);
      final yearVal = int.tryParse(parts[2]);
      if (dayVal != null && yearVal != null) {
        const months = {
          'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
          'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
          'january': 1, 'february': 2, 'march': 3, 'april': 4, 'may_full': 5,
          'june': 6, 'july': 7, 'august': 8, 'september': 9, 'october': 10,
          'november': 11, 'december': 12
        };
        int? monthVal;
        months.forEach((key, val) {
          if (monthStr.startsWith(key)) {
            monthVal = val;
          }
        });
        if (monthVal != null) {
          final dayStr = dayVal.toString().padLeft(2, '0');
          final monthStr2 = monthVal!.toString().padLeft(2, '0');
          return "$dayStr-$monthStr2-$yearVal";
        }
      }
    }
  } catch (_) {}
  return dateStr;
}

void printBannedUsersList(List<BannedUserModel> bannedUsers) {
  final htmlBuffer = StringBuffer();
  htmlBuffer.write('''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>Banned Users Directory</title>
      <style>
        body {
          font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
          margin: 40px;
          color: #1E293B;
          background-color: #FFFFFF;
        }
        h1 {
          font-size: 22px;
          margin: 0;
          color: #991B1B;
          font-weight: 700;
        }
        .header-container {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 24px;
          border-bottom: 2px solid #FEE2E2;
          padding-bottom: 16px;
        }
        table {
          width: 100%;
          border-collapse: collapse;
          margin-top: 10px;
        }
        th, td {
          border: 1px solid #E2E8F0;
          padding: 10px 12px;
          text-align: left;
          font-size: 12px;
          vertical-align: middle;
        }
        th {
          background-color: #FEF2F2;
          font-weight: 600;
          color: #991B1B;
          text-transform: uppercase;
          font-size: 11px;
          letter-spacing: 0.5px;
        }
        tr:nth-child(even) {
          background-color: #FAFAFA;
        }
        .ban-badge {
          font-weight: 600;
          font-size: 11px;
          padding: 3px 8px;
          border-radius: 4px;
          display: inline-block;
          background-color: #FEE2E2;
          color: #991B1B;
        }
        @media print {
          body {
            margin: 20px 10px;
          }
          button {
            display: none;
          }
          .header-container {
            border-bottom: 1px solid #FCA5A5;
          }
        }
      </style>
    </head>
    <body>
      <div class="header-container">
        <div>
          <h1>Banned Users Directory</h1>
          <p style="margin: 4px 0 0 0; font-size: 12px; color: #64748B;">Total Banned: ${bannedUsers.length} | Generated on ${DateTime.now().toString().split('.')[0]}</p>
        </div>
        <button onclick="window.print()" style="padding: 10px 20px; background-color: #EF4444; color: white; border: none; border-radius: 6px; font-weight: bold; cursor: pointer; font-family: inherit; font-size: 13px; box-shadow: 0 1px 3px rgba(0,0,0,0.1);">Print / Save PDF</button>
      </div>
      <table>
        <thead>
          <tr>
            <th>User Info</th>
            <th>Contact Details</th>
            <th>Ban Reason</th>
            <th>Ban Type</th>
            <th>Duration</th>
            <th>Banned On</th>
            <th>Banned By</th>
          </tr>
        </thead>
        <tbody>
  ''');

  for (final user in bannedUsers) {
    htmlBuffer.write('''
          <tr>
            <td>
              <div style="font-weight: 600; color: #0F172A;">${_escapeHtml(user.name)}</div>
              <div style="color: #64748B; font-size: 11px; margin-top: 2px;">ID: ${_escapeHtml(user.userId)}</div>
            </td>
            <td>
              <div style="font-size: 12px;">${_escapeHtml(user.email)}</div>
              <div style="color: #64748B; font-size: 11px; margin-top: 2px;">${_escapeHtml(user.phone)}</div>
            </td>
            <td style="color: #991B1B; font-style: italic;">${_escapeHtml(user.reason)}</td>
            <td><span class="ban-badge">${_escapeHtml(user.banType)}</span></td>
            <td>${_escapeHtml(user.banDuration)}</td>
            <td>${_escapeHtml(_formatDisplayDate(user.bannedOn))}</td>
            <td>${_escapeHtml(user.bannedBy)}</td>
          </tr>
    ''');
  }

  htmlBuffer.write('''
        </tbody>
      </table>
      <script>
        window.addEventListener('load', () => {
          setTimeout(() => {
            window.print();
          }, 500);
        });
      </script>
    </body>
    </html>
  ''');

  final blob = html.Blob([htmlBuffer.toString()], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
}

void printWorkersList(List<WorkerModel> workers) {
  final htmlBuffer = StringBuffer();
  htmlBuffer.write('''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>Workers Directory Export</title>
      <style>
        body {
          font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
          margin: 40px; color: #1E293B; background-color: #FFFFFF;
        }
        h1 { font-size: 22px; margin: 0; color: #0F172A; font-weight: 700; }
        .header-container {
          display: flex; justify-content: space-between; align-items: center;
          margin-bottom: 24px; border-bottom: 2px solid #D1FAE5; padding-bottom: 16px;
        }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th, td { border: 1px solid #E2E8F0; padding: 10px 12px; text-align: left; font-size: 12px; vertical-align: middle; }
        th { background-color: #ECFDF5; font-weight: 600; color: #065F46; text-transform: uppercase; font-size: 11px; letter-spacing: 0.5px; }
        tr:nth-child(even) { background-color: #F8FAFC; }
        .status { font-weight: 600; font-size: 11px; padding: 3px 8px; border-radius: 4px; display: inline-block; }
        .status-approved  { background-color: #D1FAE5; color: #065F46; }
        .status-pending   { background-color: #FEF3C7; color: #92400E; }
        .status-rejected  { background-color: #FEE2E2; color: #991B1B; }
        .status-suspended { background-color: #F1F5F9; color: #475569; }
        .verified-badge { font-size: 11px; padding: 2px 6px; border-radius: 4px; font-weight: 500; background-color: #DBEAFE; color: #1E40AF; display: inline-block; }
        @media print { body { margin: 20px 10px; } button { display: none; } .header-container { border-bottom: 1px solid #A7F3D0; } }
      </style>
    </head>
    <body>
      <div class="header-container">
        <div>
          <h1>Workers Directory</h1>
          <p style="margin: 4px 0 0 0; font-size: 12px; color: #64748B;">Total Workers: TOTAL_COUNT | Generated on GENERATED_DATE</p>
        </div>
        <button onclick="window.print()" style="padding: 10px 20px; background-color: #10B981; color: white; border: none; border-radius: 6px; font-weight: bold; cursor: pointer; font-family: inherit; font-size: 13px; box-shadow: 0 1px 3px rgba(0,0,0,0.1);">Print / Save PDF</button>
      </div>
      <table>
        <thead>
          <tr>
            <th>Name &amp; ID</th><th>Contact</th><th>Category</th><th>Experience</th>
            <th>Verification</th><th>Status</th><th>Rating</th><th>Jobs Done</th><th>Joined Date</th>
          </tr>
        </thead>
        <tbody>
  ''');

  for (final w in workers) {
    final statusClass = switch (w.status.toLowerCase()) {
      'approved' => 'status-approved',
      'pending'  => 'status-pending',
      'rejected' => 'status-rejected',
      _          => 'status-suspended',
    };
    final name = _escapeHtml(w.name);
    final id = _escapeHtml(w.id);
    final phone = _escapeHtml(w.phone);
    final email = _escapeHtml(w.email);
    final category = _escapeHtml(w.category);
    final experience = _escapeHtml(w.experience);
    final verification = _escapeHtml(w.verification);
    final status = _escapeHtml(w.status);
    final rating = w.rating.toStringAsFixed(1);
    final ratingsCount = w.ratingsCount;
    final jobsCompleted = w.jobsCompleted;
    final joinedOn = _escapeHtml(w.joinedOn);

    htmlBuffer.write('''
          <tr>
            <td>
              <div style="font-weight: 600; color: #0F172A;">${name}</div>
              <div style="color: #64748B; font-size: 11px; margin-top: 2px;">${id}</div>
            </td>
            <td>
              <div style="font-size: 12px;">${phone}</div>
              <div style="color: #64748B; font-size: 11px; margin-top: 2px;">${email}</div>
            </td>
            <td>${category}</td>
            <td>${experience}</td>
            <td><span class="verified-badge">${verification}</span></td>
            <td><span class="status ${statusClass}">${status}</span></td>
            <td><strong style="color: #F59E0B;">&#9733;</strong> ${rating} <span style="color:#94A3B8;font-size:10px;">(${ratingsCount})</span></td>
            <td><strong>${jobsCompleted}</strong></td>
            <td>${joinedOn}</td>
          </tr>
    ''');
  }

  htmlBuffer.write('''
        </tbody>
      </table>
      <script>
        window.addEventListener('load', () => {
          setTimeout(() => { window.print(); }, 500);
        });
      </script>
    </body>
    </html>
  ''');

  final finalHtml = htmlBuffer
      .toString()
      .replaceFirst('TOTAL_COUNT', workers.length.toString())
      .replaceFirst('GENERATED_DATE', DateTime.now().toString().split('.')[0]);

  final blob = html.Blob([finalHtml], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
}

void printBookingsList(List<BookingModel> bookings) {
  final htmlBuffer = StringBuffer();
  htmlBuffer.write('''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>Bookings Directory Export</title>
      <style>
        body {
          font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
          margin: 40px; color: #1E293B; background-color: #FFFFFF;
        }
        h1 { font-size: 22px; margin: 0; color: #0F172A; font-weight: 700; }
        .header-container {
          display: flex; justify-content: space-between; align-items: center;
          margin-bottom: 24px; border-bottom: 2px solid #DBEAFE; padding-bottom: 16px;
        }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th, td { border: 1px solid #E2E8F0; padding: 10px 12px; text-align: left; font-size: 12px; vertical-align: middle; }
        th { background-color: #EFF6FF; font-weight: 600; color: #1E40AF; text-transform: uppercase; font-size: 11px; letter-spacing: 0.5px; }
        tr:nth-child(even) { background-color: #F8FAFC; }
        .status { font-weight: 600; font-size: 11px; padding: 3px 8px; border-radius: 4px; display: inline-block; }
        .status-completed  { background-color: #D1FAE5; color: #065F46; }
        .status-confirmed  { background-color: #DBEAFE; color: #1E40AF; }
        .status-pending   { background-color: #FEF3C7; color: #92400E; }
        .status-cancelled { background-color: #FEE2E2; color: #991B1B; }
        .payment-status { font-size: 11px; padding: 2px 6px; border-radius: 4px; font-weight: 500; display: inline-block; }
        .payment-paid { background-color: #D1FAE5; color: #065F46; }
        .payment-pending { background-color: #FEF3C7; color: #92400E; }
        .payment-failed { background-color: #FEE2E2; color: #991B1B; }
        @media print { body { margin: 20px 10px; } button { display: none; } .header-container { border-bottom: 1px solid #BFDBFE; } }
      </style>
    </head>
    <body>
      <div class="header-container">
        <div>
          <h1>Bookings Directory</h1>
          <p style="margin: 4px 0 0 0; font-size: 12px; color: #64748B;">Total Bookings: TOTAL_COUNT | Generated on GENERATED_DATE</p>
        </div>
        <button onclick="window.print()" style="padding: 10px 20px; background-color: #3B82F6; color: white; border: none; border-radius: 6px; font-weight: bold; cursor: pointer; font-family: inherit; font-size: 13px; box-shadow: 0 1px 3px rgba(0,0,0,0.1);">Print / Save PDF</button>
      </div>
      <table>
        <thead>
          <tr>
            <th>Booking ID &amp; Date</th><th>Customer</th><th>Worker</th><th>Service &amp; Category</th>
            <th>Amount</th><th>Payment Status</th><th>Status</th>
          </tr>
        </thead>
        <tbody>
  ''');

  for (final b in bookings) {
    final statusClass = switch (b.status.toLowerCase()) {
      'completed' => 'status-completed',
      'confirmed' => 'status-confirmed',
      'cancelled' => 'status-cancelled',
      _          => 'status-pending',
    };
    final paymentClass = switch (b.paymentStatus.toLowerCase()) {
      'paid'   => 'payment-paid',
      'failed' => 'payment-failed',
      _        => 'payment-pending',
    };

    final id = _escapeHtml(b.id);
    final dateTime = _escapeHtml(b.dateTime.replaceAll('\n', ' '));
    final customerName = _escapeHtml(b.customerName);
    final customerPhone = _escapeHtml(b.customerPhone);
    final workerName = _escapeHtml(b.workerName);
    final workerPhone = _escapeHtml(b.workerPhone);
    final serviceName = _escapeHtml(b.serviceName);
    final category = _escapeHtml(b.category);
    final amount = b.amount.toStringAsFixed(2);
    final paymentStatus = _escapeHtml(b.paymentStatus);
    final status = _escapeHtml(b.status);

    htmlBuffer.write('''
          <tr>
            <td>
              <div style="font-weight: 600; color: #0F172A;">${id}</div>
              <div style="color: #64748B; font-size: 11px; margin-top: 2px;">${dateTime}</div>
            </td>
            <td>
              <div style="font-weight: 600;">${customerName}</div>
              <div style="color: #64748B; font-size: 11px; margin-top: 2px;">${customerPhone}</div>
            </td>
            <td>
              <div style="font-weight: 600;">${workerName}</div>
              <div style="color: #64748B; font-size: 11px; margin-top: 2px;">${workerPhone}</div>
            </td>
            <td>
              <div style="font-weight: 600;">${serviceName}</div>
              <div style="color: #64748B; font-size: 11px; margin-top: 2px;">${category}</div>
            </td>
            <td><strong>₹${amount}</strong></td>
            <td><span class="payment-status ${paymentClass}">${paymentStatus}</span></td>
            <td><span class="status ${statusClass}">${status}</span></td>
          </tr>
    ''');
  }

  htmlBuffer.write('''
        </tbody>
      </table>
      <script>
        window.addEventListener('load', () => {
          setTimeout(() => { window.print(); }, 500);
        });
      </script>
    </body>
    </html>
  ''');

  final finalHtml = htmlBuffer
      .toString()
      .replaceFirst('TOTAL_COUNT', bookings.length.toString())
      .replaceFirst('GENERATED_DATE', DateTime.now().toString().split('.')[0]);

  final blob = html.Blob([finalHtml], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
}
