import 'dart:html' as html;
import 'package:swiftclean_admin/MVVM/view/pages.dart/User/Profile_user.dart';

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
