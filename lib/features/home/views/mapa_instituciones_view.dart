import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gameon/features/home/models/institucion_deportiva.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'institucion_detail_view.dart';

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

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _createMarkers();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _isLoadingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(
          seconds: 10,
        ), // Timeout para evitar carga infinita
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoadingLocation = false;
        });

        // Centrar el mapa en la ubicación actual
        _controller?.animateCamera(
          CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
        );
      }
    } catch (e) {
      print('Error obteniendo ubicación: $e');
      if (mounted) setState(() => _isLoadingLocation = false);

      // Mostrar las instituciones aunque falle la ubicación
      if (mounted && widget.instituciones.isNotEmpty) {
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
    // Centrar en ubicación del usuario si está disponible
    final initialLocation = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : LatLng(-12.0464, -77.0428); // Lima, Perú por defecto

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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mapa',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
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
                              color: Colors.white.withOpacity(0.2),
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
                              color: Colors.white.withOpacity(0.2),
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
                              color: Colors.black.withOpacity(0.1),
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
                    myLocationEnabled: true,
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
                              color: Colors.black.withOpacity(0.15),
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
