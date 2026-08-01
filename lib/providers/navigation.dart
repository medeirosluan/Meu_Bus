import 'package:flutter_riverpod/flutter_riverpod.dart';

class Tabs {
  static const routes = 0;
  static const status = 1;
  static const schedules = 2;
  static const favorites = 3;
  static const history = 4;
}

final selectedTabProvider = StateProvider<int>((ref) => Tabs.routes);
