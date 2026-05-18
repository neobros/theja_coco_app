import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:theja_coco/main.dart';

void main() {
  testWidgets('shows native network error screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: AppNetworkErrorView(onRetry: () {})),
    );

    expect(find.text('No internet connection'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
  });
}
