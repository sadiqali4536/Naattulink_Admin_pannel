import 'dart:io';

void main() {
  final dir = Directory('d:/nattulinkapp/naattulink_admin_pannel/Naattulink_Admin_pannel/lib');
  int filesUpdated = 0;
  
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = entity.readAsStringSync();
      if (content.contains('DropdownButtonFormField') || content.contains('ChoiceChip') || content.contains('FilterChip')) {
        print('Found widgets in: \${entity.path}');
        // We will do a manual review of some of them to see if we can do a smart regex replace.
      }
    }
  }
}
