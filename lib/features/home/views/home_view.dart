import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gameon/features/home/models/institucion_deportiva.dart';
import 'package:gameon/core/di/home_dependencies.dart';
import 'package:gameon/features/home/presentation/states/ui_state.dart';
import 'package:gameon/features/reservas/views/reservas_list/reservas_list_view.dart';
import 'package:gameon/features/perfil/views/perfil_view/perfil_view.dart';
import 'package:gameon/features/chat/views/chats_list_view.dart';
import 'package:gameon/features/notificaciones/views/notificaciones_view.dart';
import 'package:gameon/features/notificaciones/viewmodels/notificaciones_viewmodel.dart';

import '../viewmodels/home_viewmodel.dart';
import 'institucion_detail_view.dart';
import 'mapa_instituciones_view.dart';

import 'package:provider/provider.dart';
import 'package:gameon/features/perfil/viewmodels/perfil_viewmodel.dart';
import 'package:gameon/features/perfil/views/login_page/login_page.dart';

// HomeView: controla tabs y bottom navigation
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const HomeTabScaffold(),
      const ReservasListView(),
      const ChatsListView(),
      const PerfilView(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: Colors.black12,
        elevation: 8,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: Colors.black54),
            selectedIcon: Icon(Icons.home, color: Colors.green.shade700),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined, color: Colors.black54),
            selectedIcon: Icon(Icons.event_note, color: Colors.green.shade700),
            label: 'Reservas',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline, color: Colors.black54),
            selectedIcon: Icon(Icons.chat_bubble, color: Colors.green.shade700),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: Colors.black54),
            selectedIcon: Icon(Icons.person, color: Colors.green.shade700),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final perfilVm = context.read<PerfilViewModel>();
    switch (state) {
      case AppLifecycleState.resumed:
        perfilVm.startHeartbeat();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        perfilVm.stopHeartbeat();
        break;
      case AppLifecycleState.hidden:
        perfilVm.stopHeartbeat();
        break;
    }
  }
}

// Tab principal con header moderno y lista
class HomeTabScaffold extends StatefulWidget {
  const HomeTabScaffold({super.key});

  @override
  State<HomeTabScaffold> createState() => _HomeTabScaffoldState();
}

class _HomeTabScaffoldState extends State<HomeTabScaffold> {
  late final HomeViewModel _vm;

  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  NotificacionesViewModel? _notificacionesVm;
  bool _perfilListenerAttached = false;

  @override
  void initState() {
    super.initState();
    _vm = HomeDependencies.createHomeViewModel();
    _vm.cargar();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim());
    });

    // Inicializar el ViewModel de notificaciones y adjuntar listener al perfil
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_perfilListenerAttached) {
        final perfilVm = context.read<PerfilViewModel>();
        perfilVm.addListener(_onPerfilVmChange);
        _perfilListenerAttached = true;
      }
      _initNotificationsViewModel();
    });
  }

  void _onPerfilVmChange() {
    if (!mounted) return;
    _initNotificationsViewModel();
  }

  void _initNotificationsViewModel() {
    final perfilVm = context.read<PerfilViewModel>();
    if (!perfilVm.isLoggedIn || perfilVm.profile == null) {
      // Usuario no autenticado: limpiar VM si existía
      if (_notificacionesVm != null) {
        _notificacionesVm!.dispose();
        _notificacionesVm = null;
        setState(() {});
      }
      return;
    }

    // Si ya está inicializado, no volver a crear
    if (_notificacionesVm != null) {
      return;
    }

    final idRaw = perfilVm.profile!.id;
    final idUsuario = int.tryParse(idRaw);

    if (idUsuario != null) {
      _notificacionesVm = NotificacionesViewModel(usuarioId: idUsuario);
    } else {
      // Soporte para perfiles con id string en Firestore
      _notificacionesVm = NotificacionesViewModel.forStringUser(
        usuarioIdString: idRaw,
      );
    }

    _notificacionesVm!.addListener(() {
      if (mounted) setState(() {});
    });
    _notificacionesVm!.start();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _notificacionesVm?.dispose();
    if (_perfilListenerAttached) {
      final perfilVm = context.read<PerfilViewModel>();
      perfilVm.removeListener(_onPerfilVmChange);
    }
    super.dispose();
  }

  // Método para abrir la vista de mapa
  void _openMapView() async {
    try {
      final current = _vm.estado;
      final instituciones = current is Success<List<InstitucionDeportiva>>
          ? current.data
          : <InstitucionDeportiva>[];
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                MapaInstitucionesView(instituciones: instituciones),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar el mapa: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.of(context)
        .padding
        .top; // para extender el header tras la barra de estado

    // Opción B: barra de estado transparente y header que ocupa el área superior
    final overlay = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      // Como el header es verde oscuro, usamos iconos claros
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Column(
          children: [
            // Header moderno con gradiente verde, extendido tras la barra de estado
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
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 20 + safeTop, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '¡Hola! 👋',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Encuentra tu cancha',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        // Botón de notificaciones (más grande y sin background)
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.notifications_outlined,
                                color: Colors.white,
                                size: 40,
                              ),
                              padding: const EdgeInsets.all(8),
                              onPressed: () {
                                final perfilVm = context
                                    .read<PerfilViewModel>();
                                if (!perfilVm.isLoggedIn ||
                                    perfilVm.profile == null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginPage(),
                                    ),
                                  );
                                  return;
                                }
                                final idUsuario = int.tryParse(
                                  perfilVm.profile!.id,
                                );
                                if (idUsuario == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('ID de usuario inválido'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => NotificacionesView(
                                      usuarioId: idUsuario,
                                    ),
                                  ),
                                );
                              },
                            ),
                            // Badge de notificaciones no leídas
                            if (_notificacionesVm != null &&
                                _notificacionesVm!.unreadCount > 0)
                              Positioned(
                                right: 4,
                                top: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.red[600],
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${_notificacionesVm!.unreadCount}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Barra de búsqueda moderna con botón de mapa
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Buscar instalaciones... ',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Colors.green[600],
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 20,
                                ),
                                border: InputBorder.none,
                                suffixIcon: _query.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.clear,
                                          color: Colors.grey[600],
                                        ),
                                        onPressed: () =>
                                            _searchController.clear(),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Botón de mapa
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _openMapView(),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                child: Icon(
                                  Icons.map_outlined,
                                  color: Colors.green[600],
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Lista de instalaciones
            Expanded(
              child: ListenableBuilder(
                listenable: _vm,
                builder: (context, _) {
                  final estado = _vm.estado;

                  if (estado is Loading<List<InstitucionDeportiva>>) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: Colors.green[600],
                      ),
                    );
                  }

                  if (estado is ErrorState<List<InstitucionDeportiva>>) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Error al cargar instalaciones',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              estado.message,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => estado.retry(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (estado is Empty<List<InstitucionDeportiva>>) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sports_soccer,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No hay instalaciones disponibles',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _vm.cargar,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Actualizar'),
                          ),
                        ],
                      ),
                    );
                  }

                  final instituciones =
                      (estado as Success<List<InstitucionDeportiva>>).data;
                  final q = _query.toLowerCase();
                  final filtradas = q.isEmpty
                      ? instituciones
                      : instituciones.where((inst) {
                          final nombre = inst.nombre.toLowerCase();
                          final direccion = inst.direccion.toLowerCase();
                          return nombre.contains(q) || direccion.contains(q);
                        }).toList();

                  if (filtradas.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay resultados',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Intenta con otra búsqueda',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filtradas.length,
                    itemBuilder: (context, index) {
                      final inst = filtradas[index];
                      return _buildModernCard(context, inst);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Card moderna con diseño mejorado
  Widget _buildModernCard(BuildContext context, InstitucionDeportiva inst) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InstitucionDetailView(institucion: inst),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Imagen con diseño mejorado
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.green[400]!, Colors.green[700]!],
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: inst.imagen != null
                        ? Image.network(
                            inst.imagen!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.sports_soccer,
                                  size: 40,
                                  color: Colors.white,
                                ),
                          )
                        : const Icon(
                            Icons.sports_soccer,
                            size: 40,
                            color: Colors.white,
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                // Información
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inst.nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              inst.direccion,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            inst.telefono,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Precio con badge verde
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.payments_outlined,
                              size: 16,
                              color: Colors.green[700],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'S/. ${inst.tarifa.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Icono de flecha
                Icon(
                  Icons.arrow_forward_ios,
                  size: 20,
                  color: Colors.green[600],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
