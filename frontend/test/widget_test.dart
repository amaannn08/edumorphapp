import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shiksha_verse/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ShikshaVerseApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
