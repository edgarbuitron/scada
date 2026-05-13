import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: unused_import
import 'package:analytics_dashboard/main.dart';

void main() {
  testWidgets('Analytics dashboard loads correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AnalyticsApp() as Widget);

    expect(find.text('Analytics / Reportes'), findsOneWidget);
    expect(find.text('Generar'), findsOneWidget);
    expect(find.text('Producción'), findsWidgets);
    expect(find.text('Fallas'), findsWidgets);
  });
}

class AnalyticsApp {
  const AnalyticsApp();
}
