import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gameon/features/reservas/views/reservas_list/widgets/reserva_numero_copiable.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('copia solo el número de reserva y confirma la acción', (
    tester,
  ) async {
    String? textoCopiado;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        textoCopiado =
            (call.arguments as Map<Object?, Object?>)['text'] as String?;
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ReservaNumeroCopiable(numero: 12345)),
      ),
    );

    expect(find.text('N.º de reserva: 12345'), findsOneWidget);
    await tester.tap(find.text('Copiar número'));
    await tester.pump();

    expect(textoCopiado, '12345');
    expect(find.text('Número de reserva copiado'), findsOneWidget);
  });
}
