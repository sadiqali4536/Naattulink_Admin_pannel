import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  // Let's use a dummy file ID to test if it hits 404 or 401.
  // 404 means auth worked but file doesn't exist.
  // 401 means auth failed.
  const fileId = 'invalid_file_id_123';
  const privateKey = 'private_KgiMaSuYgh1Xx4Q8ZBOydkQdFx0=';
  
  final authHeader = 'Basic ' + base64Encode(utf8.encode('$privateKey:'));
  
  String targetUrl = 'https://api.imagekit.io/v1/files/$fileId';
  String proxyUrl = 'https://thingproxy.freeboard.io/fetch/$targetUrl';
  
  final uri = Uri.parse(proxyUrl);
  
  print('Attempting to delete via proxy...');
  try {
    final response = await http.delete(
      uri,
      headers: {
        'Authorization': authHeader,
        'Accept': 'application/json',
      },
    );
    
    print('HTTP ${response.statusCode}');
    print('Response: ${response.body}');
  } catch (e) {
    print('Error: $e');
  }
}
