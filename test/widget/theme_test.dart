import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seu_metro/main.dart';

void main() {
  testWidgets('tema claro usa fundo F6F7FB', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SeuMetroApp()));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(Scaffold).first);
    final theme = Theme.of(context);
    expect(theme.scaffoldBackgroundColor, const Color(0xFFF6F7FB));
  });
}
