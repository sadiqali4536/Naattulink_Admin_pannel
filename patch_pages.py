import sys
import re

def update_services():
    file_path = r"d:\nattulinkapp\naattulink_admin_pannel\Naattulink_Admin_pannel\lib\MVVM\view\pages.dart\Services\Services.dart"
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    if "printer_helper.dart" not in content:
        content = content.replace("import 'package:swiftclean_admin/modules/services/service_image_service.dart';", "import 'package:swiftclean_admin/modules/services/service_image_service.dart';\nimport 'package:swiftclean_admin/MVVM/utils/printer_helper.dart';")

    content = content.replace("Widget _buildFiltersCard(bool isSmall) {", "Widget _buildFiltersCard(bool isSmall, List<ServiceModel> filteredList) {")
    content = content.replace("_buildFiltersCard(isSmall),", "_buildFiltersCard(isSmall, filteredList),")
    
    export_button_old = """    final exportButton = ElevatedButton.icon(
      onPressed: () {},"""
    export_button_new = """    final exportButton = ElevatedButton.icon(
      onPressed: () => _exportToPdf(filteredList),"""
    content = content.replace(export_button_old, export_button_new)

    method_addition = """
  Future<void> _exportToPdf(List<ServiceModel> filteredList) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Preparing export... Please wait.")),
    );
    try {
      printServicesList(filteredList);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error exporting: $e")));
      }
    }
  }
}
"""
    content = re.sub(r'}\s*$', method_addition, content)
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)

def update_categories():
    file_path = r"d:\nattulinkapp\naattulink_admin_pannel\Naattulink_Admin_pannel\lib\MVVM\view\pages.dart\Services\Categories.dart"
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    if "printer_helper.dart" not in content:
        content = re.sub(r"(import 'package:swiftclean_admin/modules/services/service_image_service\.dart';)", r"\1\nimport 'package:swiftclean_admin/MVVM/utils/printer_helper.dart';", content)
        if "printer_helper.dart" not in content:
            content = content.replace("import 'package:cloud_firestore/cloud_firestore.dart';", "import 'package:cloud_firestore/cloud_firestore.dart';\nimport 'package:swiftclean_admin/MVVM/utils/printer_helper.dart';")

    content = content.replace("Widget _buildFiltersCard(bool isSmall) {", "Widget _buildFiltersCard(bool isSmall, List<CategoryModel> filteredList) {")
    content = content.replace("_buildFiltersCard(isSmall),", "_buildFiltersCard(isSmall, filteredList),")

    export_button_old = """    final exportButton = ElevatedButton.icon(
      onPressed: () {},"""
    export_button_new = """    final exportButton = ElevatedButton.icon(
      onPressed: () => _exportToPdf(filteredList),"""
    content = content.replace(export_button_old, export_button_new)

    method_addition = """
  Future<void> _exportToPdf(List<CategoryModel> filteredList) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Preparing export... Please wait.")),
    );
    try {
      printCategoriesList(filteredList);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error exporting: $e")));
      }
    }
  }
}
"""
    content = re.sub(r'}\s*$', method_addition, content)
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)

update_services()
update_categories()
