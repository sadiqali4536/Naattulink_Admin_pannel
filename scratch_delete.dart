import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const fileId = '6a72d1085c7cd75eb819545e';
  const privateKey = 'private_KgiMaSuYgh1Xx4Q8ZBOydkQdFx0=';
  
  final authHeader = 'Basic ' + base64Encode(utf8.encode('$privateKey:'));
  final uri = Uri.parse('https://api.imagekit.io/v1/files/$fileId');
  
  print('Attempting to delete $fileId...');
  try {
    final response = await http.delete(
      uri,
      headers: {'Authorization': authHeader},
    );
    
    if (response.statusCode == 204) {
      print('Successfully deleted file $fileId');
    } else {
      print('Failed to delete: HTTP ${response.statusCode}');
      print('Response: ${response.body}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
