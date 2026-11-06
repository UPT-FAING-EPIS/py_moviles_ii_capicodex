import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gameon/features/perfil/viewmodels/perfil_viewmodel.dart';

/// Muestra únicamente las vistas autorizadas para la cuenta autenticada.
class RoleSwitcher extends StatelessWidget {
  const RoleSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PerfilViewModel>();
    final modes = <AppUserMode>[
      if (vm.hasAthleteProfile) AppUserMode.deportista,
      if (vm.managerStatus != null) AppUserMode.gestor,
      if (vm.isAdmin) AppUserMode.admin,
    ];
    const labels = {
      AppUserMode.deportista: 'Deportista',
      AppUserMode.gestor: 'Gestor de canchas',
      AppUserMode.admin: 'Administrador',
    };
    return PopupMenuButton<AppUserMode>(
      tooltip: 'Cambiar tipo de usuario',
      icon: const Icon(Icons.person, color: Colors.white),
      onSelected: vm.selectMode,
      itemBuilder: (_) => modes
          .map(
            (mode) => PopupMenuItem<AppUserMode>(
              value: mode,
              child: Row(
                children: [
                  if (mode == vm.mode) ...[
                    const Icon(Icons.check, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(labels[mode]!),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
