import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gameon/features/home/models/institucion_deportiva.dart';
import 'package:gameon/features/home/models/horario_atencion.dart';
import 'package:gameon/features/home/models/deporte.dart';
import 'package:gameon/features/home/viewmodels/institucion_detail_viewmodel.dart';

import 'areas_deportivas_view.dart';

class InstitucionDetailView extends StatefulWidget {
  final InstitucionDeportiva institucion;

  const InstitucionDetailView({super.key, required this.institucion});

  @override
  State<InstitucionDetailView> createState() => _InstitucionDetailViewState();
}

class _InstitucionDetailViewState extends State<InstitucionDetailView> {
  late InstitucionDetailViewModel viewModel;
  late Future<List<HorarioAtencion>> _horariosFuture;
  late Future<List<Deporte>> _deportesFuture;

  @override
  void initState() {
    super.initState();
    viewModel = InstitucionDetailViewModel(widget.institucion.id);
    _horariosFuture = viewModel.fetchHorarios();
    _deportesFuture = viewModel.fetchDeportes();
  }

  @override
  Widget build(BuildContext context) {
    final institucion = widget.institucion;

    // Barra de estado transparente como HomeView
    final overlay = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    );

    final safeTop = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlay,
        child: Column(
          children: [
            // Header con imagen de fondo de la institución
            Container(
              height: 300,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Imagen de fondo
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    child: institucion.imagen != null
                        ? Image.network(
                            institucion.imagen!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.green[600]!,
                                        Colors.green[800]!,
                                      ],
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.sports_soccer,
                                      size: 80,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.green[600]!,
                                  Colors.green[800]!,
                                ],
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.sports_soccer,
                                size: 80,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),
                  // Overlay oscuro para mejorar legibilidad del texto
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  // Contenido del header
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, 12 + safeTop, 24, 20),
                    child: Column(
                      children: [
                        // Barra de navegación superior
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 24,
                              ),
                              onPressed: () => Navigator.pop(context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Información en la parte inferior
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              institucion.nombre,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    institucion.direccion,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _buildHeaderRating(institucion.calificacion),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Contenido scrolleable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Botón principal para ver áreas deportivas
                    _buildMainActionButton(context, institucion),
                    const SizedBox(height: 20),
                    // Tarjeta de información de contacto
                    _buildContactCard(institucion),
                    const SizedBox(height: 16),
                    // Tarjeta de precio
                    _buildPriceCard(institucion),
                    const SizedBox(height: 16),
                    // Tarjeta de descripción (si existe)
                    if (institucion.descripcion != null &&
                        institucion.descripcion!.isNotEmpty)
                      _buildDescriptionCard(institucion),
                    if (institucion.descripcion != null &&
                        institucion.descripcion!.isNotEmpty)
                      const SizedBox(height: 16),
                    // Tarjeta de horarios
                    _buildScheduleCard(),
                    const SizedBox(height: 16),
                    // Tarjeta de deportes
                    _buildSportsCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRating(double calificacion) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 16),
          const SizedBox(width: 4),
          Text(
            calificacion.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainActionButton(
    BuildContext context,
    InstitucionDeportiva institucion,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Colors.green[600]!, Colors.green[700]!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
                builder: (context) =>
                    AreasDeportivasView(institucionId: institucion.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.sports,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Ver Áreas Deportivas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(InstitucionDeportiva institucion) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.contact_phone_outlined,
                    color: Colors.green[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Información de Contacto',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildContactRow(
              Icons.phone_outlined,
              'Teléfono',
              institucion.telefono,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildContactRow(
              Icons.email_outlined,
              'Email',
              institucion.email,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildContactRow(
              Icons.location_on_outlined,
              'Dirección',
              institucion.direccion,
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(InstitucionDeportiva institucion) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[600]!, Colors.green[700]!],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.payments_outlined,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tarifa desde',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'S/. ${institucion.tarifa.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  Text(
                    'por hora',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Text(
                'Mejor precio',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard(InstitucionDeportiva institucion) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    color: Colors.green[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Acerca de nosotros',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              institucion.descripcion!,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard() {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.access_time_outlined,
                    color: Colors.green[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Horarios de Atención',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<HorarioAtencion>>(
              future: _horariosFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.green[600],
                      ),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return _buildErrorState(
                    'Error al cargar horarios\n${snapshot.error}',
                  );
                }
                final horarios = snapshot.data ?? [];
                if (horarios.isEmpty) {
                  return _buildEmptyState(
                    Icons.schedule_outlined,
                    'No hay horarios registrados',
                  );
                }
                return Column(
                  children: horarios.map((h) => _buildScheduleItem(h)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleItem(HorarioAtencion horario) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[600]!, Colors.green[700]!],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getDayName(horario.dia),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Icon(Icons.schedule, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '${horario.horaApertura} - ${horario.horaCierre}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSportsCard() {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.sports_soccer,
                    color: Colors.green[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Deportes Disponibles',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Deporte>>(
              future: _deportesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.green[600],
                      ),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return _buildErrorState(
                    'Error al cargar deportes\n${snapshot.error}',
                  );
                }
                final deportes = snapshot.data ?? [];
                if (deportes.isEmpty) {
                  return _buildEmptyState(
                    Icons.sports_outlined,
                    'No hay deportes registrados',
                  );
                }
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: deportes.map((d) => _buildSportChip(d)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSportChip(Deporte deporte) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[50]!, Colors.green[100]!],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[300]!, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sports, size: 18, color: Colors.green[700]),
          const SizedBox(width: 8),
          Text(
            deporte.nombre,
            style: TextStyle(
              color: Colors.green[700],
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: Colors.black54, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: Colors.black54, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getDayName(String dia) {
    final days = {
      'Lunes': 'Lun',
      'Martes': 'Mar',
      'Miércoles': 'Mié',
      'Jueves': 'Jue',
      'Viernes': 'Vie',
      'Sábado': 'Sáb',
      'Domingo': 'Dom',
    };
    return days[dia] ?? dia;
  }
}
