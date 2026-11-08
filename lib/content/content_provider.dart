import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart';

const String contentAsset = 'content/content.json';

Future<Content> loadContent(AssetBundle bundle) async {
  final raw = await bundle.loadString(contentAsset);
  return Content.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

final contentProvider = FutureProvider<Content>((ref) => loadContent(rootBundle));
