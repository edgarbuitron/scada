import 'package:scada/main_prensado.dart';
import 'package:flutter_test/flutter_test.dart';

// 👇 IMPORTA TU APP REAL


void main() {
  testWidgets('SCADA carga correctamente', (WidgetTester tester) async {
    
    // 👇 AQUÍ ESTABA EL ERROR (Myapp → ScadaMasterApp)
    await tester.pumpWidget(const ScadaPrensadoScreen());

    // Verifica que el dashboard inicial se muestre
    expect(find.text('Dashboard SCADA'), findsOneWidget);

    // Verifica que existe el menú lateral
    expect(find.text('Neumático'), findsOneWidget);

    // Simula click en Centro Neumático
    await tester.tap(find.text('Neumático'));
    await tester.pump();

    // Verifica que cambió la vista
    expect(find.text('SCADA NEUMÁTICO FUNCIONANDO'), findsOneWidget);
  });
}