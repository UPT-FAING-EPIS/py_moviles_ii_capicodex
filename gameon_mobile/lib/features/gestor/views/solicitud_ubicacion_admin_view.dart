import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gameon/core/theme/app_theme.dart';
import 'package:gameon/core/theme/theme_controller.dart';
import 'package:provider/provider.dart';

class SolicitudUbicacionAdminView extends StatelessWidget {
  const SolicitudUbicacionAdminView({
    super.key,
    required this.nombre,
    required this.direccion,
    required this.latitud,
    required this.longitud,
  });

  final String nombre;
  final String direccion;
  final double latitud;
  final double longitud;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = AppTheme.headerBackgroundFor(
      context.watch<ThemeController>().selection,
    );
    final point = LatLng(latitud, longitud);
    return Scaffold(
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.primary, colors.primaryContainer],
              ),
              image: background == null
                  ? null
                  : DecorationImage(
                      image: AssetImage(background),
                      fit: BoxFit.cover,
                      opacity: .42,
                    ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 20, 18),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'UBICACIÓN SOLICITADA',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            nombre,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
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
          Padding(padding: const EdgeInsets.all(16), child: Text(direccion)),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: point, zoom: 16),
              markers: {
                Marker(
                  markerId: const MarkerId('solicitud-centro'),
                  position: point,
                  infoWindow: InfoWindow(title: nombre, snippet: direccion),
                ),
              },
              myLocationButtonEnabled: false,
            ),
          ),
        ],
      ),
    );
  }
}
