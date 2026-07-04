import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab16dart/core/theme/app_theme.dart';
import 'package:lab16dart/presentation/widgets/status_pill.dart';

void main() {
  testWidgets('aplica el tema y muestra un estado', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: StatusPill(label: 'Disponible', type: StatusType.success),
        ),
      ),
    );

    expect(find.text('Disponible'), findsOneWidget);
    expect(find.byType(StatusPill), findsOneWidget);
  });
}
