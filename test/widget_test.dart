import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:netlearn/presentation/capaian/capaian_screen.dart';

void main() {
  testWidgets('CapaianScreen renders learning objectives', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: CapaianScreen()));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Capaian Pembelajaran (CP)'), findsOneWidget);
    expect(find.text('Tujuan Pembelajaran'), findsOneWidget);
  });
}
