import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gameon/features/home/models/institucion_deportiva.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'institucion_detail_view.dart';

// US-07: estado del permiso de ubicación del usuario
enum _UbicacionEstado {
  cargando, // esperando respuesta del usuario / sistema
  concedido, // permiso otorgado, GPS activo
  denegado, // rechazado en este ciclo
  denegadoSiempre, // bloqueado permanentemente en ajustes
  error, // GPS o servicio de ubicación no disponible
}

// Coordenadas por defecto: Tacna, Perú
const LatLng _kTacnaLatLng = LatLng(-18.0146, -70.2538);

class MapaInstitucionesView extends StatefulWidget {
  final List<InstitucionDeportiva> instituciones;

  const MapaInstitucionesView({super.key, required this.instituciones});

  @override
  State<MapaInstitucionesView> createState() => _MapaInstitucionesViewState();
}

class _MapaInstitucionesViewState extends State<MapaInstitucionesView> {
  GoogleMapController? _controller;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  bool _isLoadingLocation = true;
  InstitucionDeportiva? _selectedInstitucion;

  // US-07: estado del permiso de ubicación
  _UbicacionEstado _ubicacionEstado = _UbicacionEstado.cargando;

  @override
  void initState() {
    super.initState();
    _iniciarFlujoUbicacion();
    _createMarkers();
  }

  // ────────────────────────────────────────────────────
  // US-07: flujo de consentimiento contextual
  // ────────────────────────────────────────────────────

  /// Punto de entrada del flujo: verifica si ya hay permiso concedido o
  /// muestra el diálogo explicativo antes de solicitarlo al SO.
  Future<void> _iniciarFlujoUbicacion() async {
    if (mounted) {
      setState(() {
        _ubicacionEstado = _UbicacionEstado.cargando;
        _isLoadingLocation = true;
      });
    }
    late final LocationPermission permiso;
    try {
      permiso = await Geolocator.checkPermission();
    } catch (_) {
      if (mounted) {
        setState(() {
          _ubicacionEstado = _UbicacionEstado.error;
          _isLoadingLocation = false;
        });
      }
      return;
    }

    if (permiso == LocationPermission.always ||
        permiso == LocationPermission.whileInUse) {
      // Permiso ya otorgado: obtener posición directamente
      await _obtenerPosicion();
      return;
    }

    if (permiso == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _ubicacionEstado = _UbicacionEstado.denegadoSiempre;
          _isLoadingLocation = false;
        });
      }
      return;
    }

    // Primera vez o denegado previamente: mostrar diálogo contextual
    if (mounted) {
      final aceptado = await _mostrarDialogoConsentimiento();
      if (aceptado == true) {
        await _solicitarPermisoYObtenerPosicion();
      } else {
        if (mounted) {
          setState(() {
            _ubicacionEstado = _UbicacionEstado.denegado;
            _isLoadingLocation = false;
          });
          _showAllInstitutions();
        }
      }
    }
  }

  /// Diálogo que explica al usuario por qué se necesita su ubicación
  /// y qué ocurre si decide no compartirla. (US-07: explicación en contexto)
  Future<bool?> _mostrarDialogoConsentimiento() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        key: const Key('dialogo_consentimiento_ubicacion'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on,
                color: Colors.green[700],
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '¿Compartir tu\nubicación?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            const Text(
              'GameOn usa tu posición GPS únicamente para:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 10),
            _itemConsentimiento(
              Icons.near_me,
              'Centrar el mapa en tu posición actual.',
            ),
            _itemConsentimiento(
              Icons.straighten,
              'Calcular la distancia a cada instalación.',
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Tu ubicación NO se guarda ni se comparte. '
                      'Se usa solo en este momento, en tu dispositivo.',
                      style: TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Si prefieres no compartirla, puedes usar el mapa '
              'con todas las canchas disponibles sin ver tu posición.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            key: const Key('btn_rechazar_ubicacion'),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'No compartir',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            key: const Key('btn_aceptar_ubicacion'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Compartir'),
          ),
        ],
      ),
    );
  }

  Widget _itemConsentimiento(IconData icono, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 16, color: Colors.green[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(fontSize: 13, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  /// Solicita el permiso al SO y, si se concede, obtiene la posición.
  Future<void> _solicitarPermisoYObtenerPosicion() async {
    final permiso = await Geolocator.requestPermission();
    if (permiso == LocationPermission.always ||
        permiso == LocationPermission.whileInUse) {
      await _obtenerPosicion();
    } else if (permiso == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _ubicacionEstado = _UbicacionEstado.denegadoSiempre;
          _isLoadingLocation = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _ubicacionEstado = _UbicacionEstado.denegado;
          _isLoadingLocation = false;
        });
        _showAllInstitutions();
      }
    }
  }

  /// Obtiene la posición actual del dispositivo (llamar solo cuando hay permiso).
  Future<void> _obtenerPosicion() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _ubicacionEstado = _UbicacionEstado.concedido;
          _isLoadingLocation = false;
        });

        // Centrar el mapa en la ubicación actual
        _controller?.animateCamera(
          CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
        );
      }
    } catch (e) {
      debugPrint('Error obteniendo ubicación: $e');
      if (mounted) {
        setState(() {
          _ubicacionEstado = _UbicacionEstado.error;
          _isLoadingLocation = false;
        });
        // Mostrar las instituciones aunque falle la ubicación
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _showAllInstitutions();
        });
      }
    }
  }

  void _createMarkers() {
    _markers = widget.instituciones.map((institucion) {
      return Marker(
        markerId: MarkerId(institucion.id.toString()),
        position: LatLng(institucion.latitud, institucion.longitud),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        onTap: () => _onMarkerTapped(institucion),
      );
    }).toSet();
  }

  void _onMarkerTapped(InstitucionDeportiva institucion) {
    setState(() => _selectedInstitucion = institucion);
  }

  void _goToInstitucionDetail(InstitucionDeportiva institucion) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InstitucionDetailView(institucion: institucion),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;

    // Prioridad 1: Centrar en la ubicación del usuario si ya está disponible
    if (_currentPosition != null) {
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            zoom: 15,
          ),
        ),
      );
    } else {
      // Prioridad 2: Si hay instituciones y aún no hay ubicación, esperar un momento y centrar en usuario o instituciones
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;

        if (_currentPosition != null) {
          // Si ya obtuvimos la ubicación, centrar en ella
          _controller?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ),
                zoom: 15,
              ),
            ),
          );
        } else if (widget.instituciones.isNotEmpty) {
          // Si no, mostrar todas las instituciones
          _showAllInstitutions();
        }
      });
    }
  }

  void _centerOnUserLocation() {
    if (_currentPosition != null && _controller != null) {
      _controller!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            zoom: 15,
          ),
        ),
      );
    }
  }

  void _showAllInstitutions() {
    if (widget.instituciones.isEmpty || _controller == null) return;

    if (widget.instituciones.length == 1) {
      final institucion = widget.instituciones.first;
      _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(institucion.latitud, institucion.longitud),
          15,
        ),
      );
      return;
    }

    // Calcular los límites para mostrar todas las instituciones
    double minLat = widget.instituciones.first.latitud;
    double maxLat = widget.instituciones.first.latitud;
    double minLng = widget.instituciones.first.longitud;
    double maxLng = widget.instituciones.first.longitud;

    for (var inst in widget.instituciones) {
      minLat = minLat < inst.latitud ? minLat : inst.latitud;
      maxLat = maxLat > inst.latitud ? maxLat : inst.latitud;
      minLng = minLng < inst.longitud ? minLng : inst.longitud;
      maxLng = maxLng > inst.longitud ? maxLng : inst.longitud;
    }

    _controller!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0, // padding
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // US-07: centrar en ubicación del usuario si está disponible, si no en Tacna
    final initialLocation = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : _kTacnaLatLng; // Tacna, Perú — ciudad de operación de GameOn

    // Barra de estado transparente con iconos claros
    final overlay = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Column(
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          // Botón atrás
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mapa',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Explora las canchas',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Botón mi ubicación
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.my_location,
                                color: Colors.white,
                              ),
                              onPressed: _centerOnUserLocation,
                              tooltip: 'Mi ubicación',
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Botón ver todas
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.zoom_out_map,
                                color: Colors.white,
                              ),
                              onPressed: _showAllInstitutions,
                              tooltip: 'Ver todas',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Info card dentro del header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.sports_soccer,
                                color: Colors.green[600],
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${widget.instituciones.length} ${widget.instituciones.length == 1 ? 'institución' : 'instituciones'}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Toca un marcador para ver detalles',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_isLoadingLocation)
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.green[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // US-07: banner de fallback cuando la ubicación no está disponible
            if (_ubicacionEstado == _UbicacionEstado.denegado ||
                _ubicacionEstado == _UbicacionEstado.denegadoSiempre ||
                _ubicacionEstado == _UbicacionEstado.error)
              _BannerSinUbicacion(
                key: const Key('banner_sin_ubicacion'),
                denegadoPermanente:
                    _ubicacionEstado == _UbicacionEstado.denegadoSiempre,
                errorUbicacion: _ubicacionEstado == _UbicacionEstado.error,
                onVerTodas: _showAllInstitutions,
                onAbrirAjustes: () => Geolocator.openAppSettings(),
                onReintentar: _iniciarFlujoUbicacion,
              ),
            // Mapa expandido
            Expanded(
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: initialLocation,
                      zoom: 15,
                    ),
                    markers: _markers,
                    // US-07: activar solo si el usuario concedió permiso
                    myLocationEnabled:
                        _ubicacionEstado == _UbicacionEstado.concedido,
                    myLocationButtonEnabled: false,
                    compassEnabled: true,
                    mapToolbarEnabled: false,
                    onMapCreated: _onMapCreated,
                    mapType: MapType.normal,
                    zoomControlsEnabled: false,
                    padding: EdgeInsets.only(
                      bottom: _selectedInstitucion != null ? 200 : 20,
                    ),
                  ),
                  if (widget.instituciones.isEmpty)
                    const Center(
                      child: Card(
                        margin: EdgeInsets.all(24),
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'Aún no hay instalaciones para mostrar en el mapa.',
                          ),
                        ),
                      ),
                    ),
                  // Card de detalle de institución seleccionada
                  if (_selectedInstitucion != null)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Imagen
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.green[400]!,
                                          Colors.green[700]!,
                                        ],
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child:
                                          _selectedInstitucion!.imagen != null
                                          ? Image.network(
                                              _selectedInstitucion!.imagen!,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => const Icon(
                                                    Icons.sports_soccer,
                                                    size: 32,
                                                    color: Colors.white,
                                                  ),
                                            )
                                          : const Icon(
                                              Icons.sports_soccer,
                                              size: 32,
                                              color: Colors.white,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedInstitucion!.nombre,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Color(0xFF2D3748),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.location_on_outlined,
                                              size: 14,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                _selectedInstitucion!.direccion,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green[50],
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            'S/. ${_selectedInstitucion!.tarifa.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.green[700],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Botón cerrar
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 20),
                                    color: Colors.grey[600],
                                    onPressed: () => setState(
                                      () => _selectedInstitucion = null,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                            // Botón ver detalles
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: ElevatedButton(
                                onPressed: () => _goToInstitucionDetail(
                                  _selectedInstitucion!,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[700],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Ver detalles',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

// ────────────────────────────────────────────────────────────────────────────
// US-07: banner informativo cuando el usuario no comparte su ubicación
// ────────────────────────────────────────────────────────────────────────────

class _BannerSinUbicacion extends StatelessWidget {
  final bool denegadoPermanente;
  final bool errorUbicacion;
  final VoidCallback onVerTodas;
  final VoidCallback onAbrirAjustes;
  final VoidCallback onReintentar;

  const _BannerSinUbicacion({
    super.key,
    required this.denegadoPermanente,
    required this.errorUbicacion,
    required this.onVerTodas,
    required this.onAbrirAjustes,
    required this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_off_outlined,
            color: Colors.orange[700],
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Sin ubicación activa',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  denegadoPermanente
                      ? 'Actívala en los ajustes del sistema para centrar el mapa en ti.'
                      : errorUbicacion
                      ? 'No se pudo obtener tu posición. Puedes explorar el mapa o reintentar.'
                      : 'Mostrando todas las instalaciones disponibles.',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Botón de acción contextual según el estado del permiso
          if (denegadoPermanente)
            TextButton(
              key: const Key('btn_abrir_ajustes_ubicacion'),
              onPressed: onAbrirAjustes,
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange[700],
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Ajustes', style: TextStyle(fontSize: 12)),
            )
          else
            TextButton(
              key: const Key('btn_reintentar_ubicacion'),
              onPressed: onReintentar,
              style: TextButton.styleFrom(
                foregroundColor: Colors.green[700],
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Reintentar', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
