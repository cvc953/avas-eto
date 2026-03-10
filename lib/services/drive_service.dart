import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// Minimal Drive upload helper using a two-step upload (create metadata, then upload media).
// Requires an OAuth2 access token with scope 'https://www.googleapis.com/auth/drive.file'.
Future<String?> uploadFileToDrive(File file, String accessToken, {http.Client? client}) async {
  final http.Client usedClient = client ?? http.Client();
  try {
    final name = file.uri.pathSegments.isNotEmpty ? file.uri.pathSegments.last : 'file';
    final mime = _guessMimeType(file.path);

    // Create file metadata
    final metaRes = await usedClient.post(
      Uri.parse('https://www.googleapis.com/drive/v3/files'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({'name': name}),
    );

    if (metaRes.statusCode != 200 && metaRes.statusCode != 201) {
      return null;
    }

    final metaJson = jsonDecode(metaRes.body) as Map<String, dynamic>;
    final fileId = metaJson['id'] as String?;
    if (fileId == null) return null;

    // Upload media
    final bytes = await file.readAsBytes();
    final uploadRes = await usedClient.put(
      Uri.parse('https://www.googleapis.com/upload/drive/v3/files/$fileId?uploadType=media'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': mime,
      },
      body: bytes,
    );

    if (uploadRes.statusCode == 200) return fileId;
    return null;
  } catch (e) {
    return null;
  } finally {
    if (client == null) {
      usedClient.close();
    }
  }
}

String _guessMimeType(String path) {
  final ext = path.split('.').last.toLowerCase();
  switch (ext) {
    case 'png':
      return 'image/png';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'gif':
      return 'image/gif';
    case 'webp':
      return 'image/webp';
    case 'pdf':
      return 'application/pdf';
    case 'txt':
      return 'text/plain';
    case 'csv':
      return 'text/csv';
    case 'mp4':
      return 'video/mp4';
    default:
      return 'application/octet-stream';
  }
}
