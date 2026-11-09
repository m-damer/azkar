import 'package:azkar/services/update_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseRelease reads the build number, notes and apk url', () {
    final info = parseRelease({
      'body': 'build=42\nإصلاح البحث',
      'assets': [
        {'name': 'notes.txt', 'browser_download_url': 'https://x/n.txt'},
        {
          'name': 'azkar-debug.apk',
          'browser_download_url': 'https://x/a.apk',
          'size': 1234,
        },
      ],
    })!;
    expect(info.build, 42);
    expect(info.apkUrl, 'https://x/a.apk');
    expect(info.notes, 'إصلاح البحث');
    expect(info.size, 1234);
  });

  test('parseRelease ignores a release without apk or build', () {
    expect(parseRelease({'body': 'build=1', 'assets': []}), isNull);
    expect(
        parseRelease({
          'body': 'no build here',
          'assets': [
            {'name': 'a.apk', 'browser_download_url': 'u'}
          ],
        }),
        isNull);
  });
}
