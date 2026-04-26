import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:fairterms/screens/login_screen.dart';
import 'package:fairterms/screens/dashboard_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('LoginScreen renders without crashing', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );
    await tester.pump();
  });

  testWidgets('DashboardScreen renders without crashing', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: DashboardScreen())),
    );
    await tester.pump();
  });
}
