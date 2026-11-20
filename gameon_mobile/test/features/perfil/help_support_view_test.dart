import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gameon/features/perfil/views/perfil_view/authenticated/help_support_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  group('US-33 · Ayuda y Soporte sobre consulta y cancelación de reservas', () {
    testWidgets(
      'incluye pregunta sobre dónde ver mis reservas indicando las pantallas reales',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: HelpSupportView()),
        );

        expect(find.text('Ayuda y Soporte'), findsOneWidget);
        final preguntaFinder = find.text('¿Dónde puedo ver mis reservas?');
        await scrollAndTap(tester, preguntaFinder);

        expect(find.textContaining('Mis Reservas'), findsOneWidget);
        expect(find.textContaining('Detalle de reserva'), findsOneWidget);
        expect(find.textContaining('N.º de reserva'), findsOneWidget);
      },
    );

    testWidgets(
      'incluye pregunta sobre cómo solicitar la cancelación sin prometer plazos no garantizados',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: HelpSupportView()),
        );

        final preguntaFinder = find.text(
          '¿Cómo solicito la cancelación de una reserva?',
        );
        await scrollAndTap(tester, preguntaFinder);

        final respuestaFinder = find.textContaining(
          'no garantiza la cancelación automática ni promete plazos fijos',
        );
        expect(respuestaFinder, findsOneWidget);
        expect(find.textContaining('Mis Reservas'), findsOneWidget);
        expect(find.textContaining('Detalle de reserva'), findsOneWidget);
        expect(find.textContaining('Copiar número'), findsOneWidget);
        expect(find.textContaining('Contactar por Email'), findsWidgets);

        final respuestaWidget = tester.widget<Text>(respuestaFinder);
        final textoRespuesta = respuestaWidget.data ?? '';
        expect(
          RegExp(
            r'\b\d+\s*(horas?|días?|minutos?|h\b)',
            caseSensitive: false,
          ).hasMatch(textoRespuesta),
          isFalse,
        );
      },
    );

    testWidgets(
      'se lee correctamente en pantalla móvil estrecha sin desbordamientos y conserva preguntas existentes',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          const MaterialApp(home: HelpSupportView()),
        );
        await tester.pumpAndSettle();

        // Conserva preguntas frecuentes previas
        expect(find.text('¿Cómo creo un partido?'), findsOneWidget);
        expect(find.text('¿Cómo edito mi perfil?'), findsOneWidget);

        final verReservasFinder = find.text('¿Dónde puedo ver mis reservas?');
        await scrollAndTap(tester, verReservasFinder);
        expect(find.textContaining('Mis Reservas'), findsOneWidget);

        final cancelarReservaFinder = find.text(
          '¿Cómo solicito la cancelación de una reserva?',
        );
        await scrollAndTap(tester, cancelarReservaFinder);
        expect(
          find.textContaining(
            'no garantiza la cancelación automática ni promete plazos fijos',
          ),
          findsOneWidget,
        );

        expect(tester.takeException(), isNull);
      },
    );
  });
}
