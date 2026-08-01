import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:seu_metro/models/line.dart';

typedef AssetLoader = Future<String> Function(String assetPath);

Future<String> defaultAssetLoader(String assetPath) =>
    rootBundle.loadString(assetPath);

class LineRepository {
  final AssetLoader load;
  LineRepository({AssetLoader? load}) : load = load ?? defaultAssetLoader;

  Future<List<Line>> getAll() async {
    final raw = await load('assets/data/lines.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return (data['lines'] as List)
        .map((e) => Line.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, Line>> byId() async {
    final all = await getAll();
    return {for (final l in all) l.id: l};
  }
}
