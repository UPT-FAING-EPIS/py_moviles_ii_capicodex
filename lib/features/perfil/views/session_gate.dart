import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../home/views/home_view.dart';
import '../viewmodels/perfil_viewmodel.dart';

/// Evita mostrar el login mientras se restaura una sesión persistente.
class SessionGate extends StatelessWidget {
  const SessionGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PerfilViewModel>(
      builder: (_, perfilVm, _) {
        if (!perfilVm.sesionRestaurada) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return const HomeView();
      },
    );
  }
}
