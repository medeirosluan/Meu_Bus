import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/features/favorites/favorites_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('FavoritesPage mostra estado vazio', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: FavoritesPage())));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nenhuma estação'), findsOneWidget);
  });
}
