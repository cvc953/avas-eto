import 'dart:io';
import 'package:test/test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:avas_eto/services/drive_service.dart';

void main() {
  test('uploadFileToDrive uploads metadata and media, returns file id', () async {
    // Create a temporary file with some bytes
    final tmp = Directory.systemTemp.createTempSync('avas_test_');
    final file = File('${tmp.path}/sample.txt');
    await file.writeAsBytes([1, 2, 3, 4, 5]);

    // Mock client to simulate Drive responses
    final mockClient = MockClient((request) async {
      if (request.method == 'POST' && request.url.path == '/drive/v3/files') {
        return http.Response('{"id":"mock-drive-id"}', 200, headers: {
          'content-type': 'application/json; charset=UTF-8'
        });
      }

      if (request.method == 'PUT' && request.url.path.startsWith('/upload/drive/v3/files/')) {
        return http.Response('', 200);
      }

      return http.Response('Not Found', 404);
    });

    final id = await uploadFileToDrive(file, 'fake-token', client: mockClient);
    expect(id, equals('mock-drive-id'));

    // cleanup
    await file.delete();
    await tmp.delete();
  });
}
