import 'package:flutter_test/flutter_test.dart';

import 'package:citamedic/main.dart';

void main() {
  testWidgets('La app abre la pantalla de login', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('CitaMedic'), findsOneWidget);
    expect(find.text('Inicia sesión para continuar.'), findsOneWidget);
    expect(find.text('Correo'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
