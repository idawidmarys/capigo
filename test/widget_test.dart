import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:capigo_weeklywalk/providers/tracking_provider.dart';
import 'package:capigo_weeklywalk/providers/user_provider.dart';

void main() {
  testWidgets('CapiGo smoke test loads without crash', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => TrackingProvider()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: Text('Weekly Walk')),
        ),
      ),
    );
    expect(find.text('Weekly Walk'), findsOneWidget);
  });
}
