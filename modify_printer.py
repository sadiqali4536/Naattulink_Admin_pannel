import sys

file_path = r"d:\nattulinkapp\naattulink_admin_pannel\Naattulink_Admin_pannel\lib\MVVM\utils\printer_web.dart"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

imports = """import 'package:swiftclean_admin/MVVM/view/pages.dart/Services/Services.dart';
import 'package:swiftclean_admin/MVVM/view/pages.dart/Services/Categories.dart';
"""
content = content.replace("import 'package:swiftclean_admin/MVVM/view/pages.dart/Bookings/Bookings.dart';", "import 'package:swiftclean_admin/MVVM/view/pages.dart/Bookings/Bookings.dart';\n" + imports)

addition = """
void printServicesList(List<ServiceModel> services) {
  final htmlBuffer = StringBuffer();
  htmlBuffer.write('''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>Services Directory Export</title>
      <style>
        body { font-family: 'Inter', sans-serif; margin: 40px; color: #1E293B; background-color: #FFFFFF; }
        h1 { font-size: 22px; margin: 0; color: #0F172A; font-weight: 700; }
        .header-container { display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px; border-bottom: 2px solid #DBEAFE; padding-bottom: 16px; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th, td { border: 1px solid #E2E8F0; padding: 10px 12px; text-align: left; font-size: 12px; }
        th { background-color: #EFF6FF; font-weight: 600; color: #1E40AF; text-transform: uppercase; font-size: 11px; }
        tr:nth-child(even) { background-color: #F8FAFC; }
      </style>
    </head>
    <body>
      <div class="header-container">
        <div>
          <h1>Services Directory</h1>
          <p style="margin: 4px 0 0 0; font-size: 12px; color: #64748B;">Total Services: TOTAL_COUNT | Generated on GENERATED_DATE</p>
        </div>
        <button onclick="window.print()" style="padding: 10px 20px; background-color: #3B82F6; color: white; border: none; border-radius: 6px; font-weight: bold; cursor: pointer; font-family: inherit; font-size: 13px;">Print / Save PDF</button>
      </div>
      <table>
        <thead>
          <tr>
            <th>Service ID</th>
            <th>Name</th>
            <th>Category</th>
            <th>Type</th>
            <th>Original Price</th>
            <th>Final Price</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody>
  ''');

  for (final s in services) {
    final id = _escapeHtml(s.id);
    final name = _escapeHtml(s.name);
    final category = _escapeHtml(s.category);
    final type = _escapeHtml(s.type);
    final originalPrice = s.originalPrice.toStringAsFixed(2);
    final finalPrice = s.finalPrice.toStringAsFixed(2);
    final status = _escapeHtml(s.status);

    htmlBuffer.write('''
          <tr>
            <td>\${id}</td>
            <td><strong>\${name}</strong></td>
            <td>\${category}</td>
            <td>\${type}</td>
            <td>₹\${originalPrice}</td>
            <td>₹\${finalPrice}</td>
            <td>\${status}</td>
          </tr>
    ''');
  }

  htmlBuffer.write('''
        </tbody>
      </table>
      <script> window.addEventListener('load', () => { setTimeout(() => { window.print(); }, 500); }); </script>
    </body>
    </html>
  ''');

  final finalHtml = htmlBuffer
      .toString()
      .replaceFirst('TOTAL_COUNT', services.length.toString())
      .replaceFirst('GENERATED_DATE', DateTime.now().toString().split('.')[0]);

  final blob = html.Blob([finalHtml], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
}

void printCategoriesList(List<CategoryModel> categories) {
  final htmlBuffer = StringBuffer();
  htmlBuffer.write('''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>Categories Directory Export</title>
      <style>
        body { font-family: 'Inter', sans-serif; margin: 40px; color: #1E293B; background-color: #FFFFFF; }
        h1 { font-size: 22px; margin: 0; color: #0F172A; font-weight: 700; }
        .header-container { display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px; border-bottom: 2px solid #DBEAFE; padding-bottom: 16px; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th, td { border: 1px solid #E2E8F0; padding: 10px 12px; text-align: left; font-size: 12px; }
        th { background-color: #EFF6FF; font-weight: 600; color: #1E40AF; text-transform: uppercase; font-size: 11px; }
        tr:nth-child(even) { background-color: #F8FAFC; }
      </style>
    </head>
    <body>
      <div class="header-container">
        <div>
          <h1>Categories Directory</h1>
          <p style="margin: 4px 0 0 0; font-size: 12px; color: #64748B;">Total Categories: TOTAL_COUNT | Generated on GENERATED_DATE</p>
        </div>
        <button onclick="window.print()" style="padding: 10px 20px; background-color: #3B82F6; color: white; border: none; border-radius: 6px; font-weight: bold; cursor: pointer; font-family: inherit; font-size: 13px;">Print / Save PDF</button>
      </div>
      <table>
        <thead>
          <tr>
            <th>Category ID</th>
            <th>Name</th>
          </tr>
        </thead>
        <tbody>
  ''');

  for (final c in categories) {
    final id = _escapeHtml(c.id);
    final name = _escapeHtml(c.name);

    htmlBuffer.write('''
          <tr>
            <td>\${id}</td>
            <td><strong>\${name}</strong></td>
          </tr>
    ''');
  }

  htmlBuffer.write('''
        </tbody>
      </table>
      <script> window.addEventListener('load', () => { setTimeout(() => { window.print(); }, 500); }); </script>
    </body>
    </html>
  ''');

  final finalHtml = htmlBuffer
      .toString()
      .replaceFirst('TOTAL_COUNT', categories.length.toString())
      .replaceFirst('GENERATED_DATE', DateTime.now().toString().split('.')[0]);

  final blob = html.Blob([finalHtml], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
}
"""
with open(file_path, "w", encoding="utf-8") as f:
    f.write(content + addition)
