import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

const String kDriveAttachmentsFolderName = 'avas-eto';

Future<String?> ensureDriveFolder(
  String accessToken,
  String folderName, {
  http.Client? client,
}) async {
  final http.Client usedClient = client ?? http.Client();
  try {
    final escapedFolderName = folderName.replaceAll("'", r"\'");
    final searchRes = await usedClient.get(
      Uri.parse(
        'https://www.googleapis.com/drive/v3/files?q=${Uri.encodeQueryComponent("mimeType='application/vnd.google-apps.folder' and trashed=false and name='$escapedFolderName'")}&fields=files(id,name)',
      ),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (searchRes.statusCode == 200) {
      final searchJson = jsonDecode(searchRes.body) as Map<String, dynamic>;
      final files = (searchJson['files'] as List<dynamic>? ?? const []);
      if (files.isNotEmpty) {
        final folder = files.first as Map<String, dynamic>;
        return folder['id'] as String?;
      }
    } else {
      debugPrint(
        'Drive folder search failed: ${searchRes.statusCode} ${searchRes.body}',
      );
      return null;
    }

    final createRes = await usedClient.post(
      Uri.parse('https://www.googleapis.com/drive/v3/files'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'name': folderName,
        'mimeType': 'application/vnd.google-apps.folder',
      }),
    );

    if (createRes.statusCode != 200 && createRes.statusCode != 201) {
      debugPrint(
        'Drive folder create failed: ${createRes.statusCode} ${createRes.body}',
      );
      return null;
    }

    final createJson = jsonDecode(createRes.body) as Map<String, dynamic>;
    return createJson['id'] as String?;
  } catch (e, s) {
    debugPrint('Drive ensure folder exception: $e');
    debugPrintStack(stackTrace: s);
    return null;
  } finally {
    if (client == null) {
      usedClient.close();
    }
  }
}

// Minimal Drive upload helper using a two-step upload (create metadata, then upload media).
// Requires an OAuth2 access token with scope 'https://www.googleapis.com/auth/drive.file'.
Future<String?> uploadFileToDrive(
  File file,
  String accessToken, {
  String? parentFolderId,
  http.Client? client,
}) async {
  final http.Client usedClient = client ?? http.Client();
  try {
    final name =
        file.uri.pathSegments.isNotEmpty ? file.uri.pathSegments.last : 'file';
    final mime = _guessMimeType(file.path);
    final metadata = <String, dynamic>{'name': name};
    if (parentFolderId != null && parentFolderId.isNotEmpty) {
      metadata['parents'] = [parentFolderId];
    }

    // Create file metadata
    final metaRes = await usedClient.post(
      Uri.parse('https://www.googleapis.com/drive/v3/files'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(metadata),
    );

    if (metaRes.statusCode != 200 && metaRes.statusCode != 201) {
      debugPrint(
        'Drive metadata create failed: ${metaRes.statusCode} ${metaRes.body}',
      );
      return null;
    }

    final metaJson = jsonDecode(metaRes.body) as Map<String, dynamic>;
    final fileId = metaJson['id'] as String?;
    if (fileId == null) return null;

    // Upload media
    final bytes = await file.readAsBytes();
    final uploadRes = await usedClient.patch(
      Uri.parse(
        'https://www.googleapis.com/upload/drive/v3/files/$fileId?uploadType=media',
      ),
      headers: {'Authorization': 'Bearer $accessToken', 'Content-Type': mime},
      body: bytes,
    );

    if (uploadRes.statusCode == 200 || uploadRes.statusCode == 201) {
      return fileId;
    }
    debugPrint(
      'Drive media upload failed: ${uploadRes.statusCode} ${uploadRes.body}',
    );
    return null;
  } catch (e, s) {
    debugPrint('Drive upload exception: $e');
    debugPrintStack(stackTrace: s);
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
