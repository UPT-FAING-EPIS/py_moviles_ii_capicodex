import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gameon/features/home/models/area_deportiva.dart';
import 'package:gameon/features/reservas/viewmodels/reserva_calendario_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:gameon/features/perfil/viewmodels/perfil_viewmodel.dart';
import 'package:gameon/features/perfil/views/login_page/login_page.dart';
import 'widgets/area_resume.dart';
import 'widgets/calendario_selector.dart';
import 'widgets/slots_grid.dart';
import 'widgets/confirm_button_bar.dart';
import '../reserva_resumen_view.dart';

class ReservaCalendarioView extends StatefulWidget {
  final AreaDeportiva area;
  const ReservaCalendarioView({super.key, required this.area});

  @override
  State<ReservaCalendarioView> createState() => _ReservaCalendarioViewState();
}

class _ReservaCalendarioViewState extends State<ReservaCalendarioView> {
  late final ReservaCalendarioViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = ReservaCalendarioViewModel(areaId: widget.area.id);
    _init();
  }

  Future<void> _init() async {
    await viewModel.cargarHorarios();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Status bar transparente con iconos claros
    final overlay = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: viewModel.cargando
            ? const Center(child: CircularProgressIndicator())
            : viewModel.error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      viewModel.error!,
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  // Header moderno con gradiente verde
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.green.shade600, Colors.green.shade800],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                // Botón atrás
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.arrow_back,
                                      color: Colors.white,
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Título
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Reservar',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.area.nombreArea,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Card de resumen del área dentro del header
                            AreaResume(area: widget.area),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Contenido scrolleable
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          CalendarioSelector(
                            viewModel: viewModel,
                            onChanged: () {
                              if (mounted) setState(() {});
                            },
                          ),
                          const SizedBox(height: 24),
                          SlotsGrid(
                            viewModel: viewModel,
                            onSelectionChanged: () {
                              if (mounted) setState(() {});
                            },
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: ConfirmButtonBar(
          viewModel: viewModel,
          area: widget.area,
          onConfirm: _confirmarReserva,
        ),
      ),
    );
  }

  void _confirmarReserva() {
    if (viewModel.selectedDay == null || !viewModel.tieneRangoValido) return;
    final perfilVm = context.read<PerfilViewModel>();
    if (!perfilVm.isLoggedIn || perfilVm.profile == null) {
      // Redirigir a login
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const LoginPage()));
      return;
    }

    // Redirigir directamente a la vista de resumen de pago
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReservaResumenView(
          area: widget.area,
          viewModel: viewModel,
          userId: perfilVm.profile!.id,
        ),
      ),
    );
  }
}
