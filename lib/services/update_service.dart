import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';

import '../app_info.dart';
import '../design/motion.dart';

/// A published APK newer (or not) than the installed one.
class UpdateInfo {
  const UpdateInfo({
    required this.build,
    required this.apkUrl,
    required this.notes,
    required this.size,
  });

  final int build;
  final String apkUrl;
  final String notes;
  final int size;
}

/// Reads a GitHub release JSON. The first body line must be `build=<number>`;
/// the rest is the release notes. Returns null when it has no APK or build.
UpdateInfo? parseRelease(Map<String, dynamic> json) {
  final body = (json['body'] as String?) ?? '';
  final m = RegExp(r'build=(\d+)').firstMatch(body);
  final assets = (json['assets'] as List?) ?? const [];
  final apk = assets.cast<Map<String, dynamic>>().where(
      (a) => (a['name'] as String? ?? '').endsWith('.apk')).firstOrNull;
  if (m == null || apk == null) return null;
  final notes = body.replaceFirst(RegExp(r'^\s*build=\d+\s*'), '').trim();
  return UpdateInfo(
    build: int.parse(m.group(1)!),
    apkUrl: apk['browser_download_url'] as String,
    notes: notes,
    size: (apk['size'] as num?)?.toInt() ?? 0,
  );
}

abstract class UpdateService {
  /// The latest published build, or null when nothing is published.
  Future<UpdateInfo?> latest();

  /// Downloads the APK; reports progress 0..1. Returns the local path.
  Future<String> download(UpdateInfo info, void Function(double) onProgress);

  /// Opens the system installer; false when it could not be opened.
  Future<bool> install(String path);
}

class GithubUpdateService implements UpdateService {
  static const _repo = 'm-damer/azkar';

  @override
  Future<UpdateInfo?> latest() async {
    final client = HttpClient()..connectionTimeout = AppMotion.networkTimeout;
    try {
      final req = await client.getUrl(Uri.parse(
          'https://api.github.com/repos/$_repo/releases/tags/$updateTag'));
      req.headers.set('Accept', 'application/vnd.github+json');
      final res = await req.close();
      if (res.statusCode == 404) return null;
      if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
      final text = await res.transform(utf8.decoder).join();
      return parseRelease(jsonDecode(text) as Map<String, dynamic>);
    } finally {
      client.close();
    }
  }

  @override
  Future<String> download(
      UpdateInfo info, void Function(double) onProgress) async {
    final client = HttpClient()..connectionTimeout = AppMotion.networkTimeout;
    try {
      final req = await client.getUrl(Uri.parse(info.apkUrl));
      req.followRedirects = true;
      req.maxRedirects = 8;
      final res = await req.close();
      if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
      final total = res.contentLength > 0 ? res.contentLength : info.size;
      final file = File('${Directory.systemTemp.path}/azkar-update.apk');
      final sink = file.openWrite();
      var got = 0;
      await for (final chunk in res) {
        sink.add(chunk);
        got += chunk.length;
        if (total > 0) onProgress((got / total).clamp(0.0, 1.0));
      }
      await sink.close();
      return file.path;
    } finally {
      client.close();
    }
  }

  @override
  Future<bool> install(String path) async {
    final r = await OpenFilex.open(
        path, type: 'application/vnd.android.package-archive');
    return r.type == ResultType.done;
  }
}

final updateServiceProvider =
    Provider<UpdateService>((_) => GithubUpdateService());
