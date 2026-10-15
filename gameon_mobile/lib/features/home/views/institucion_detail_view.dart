import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gameon/features/home/models/institucion_deportiva.dart';
import 'package:gameon/features/home/models/horario_atencion.dart';
import 'package:gameon/features/home/models/deporte.dart';
import 'package:gameon/features/home/viewmodels/institucion_detail_viewmodel.dart';
import 'areas_deportivas_view.dart';
import 'package:gameon/core/theme/app_theme.dart';

class InstitucionDetailView extends StatefulWidget {
  final InstitucionDeportiva institucion;
  final InstitucionDetailViewModel? viewModel;

  const InstitucionDetailView({
    super.key,
    required this.institucion,
    this.viewModel,
  });

  @override
  State<InstitucionDetailView> createState() => _InstitucionDetailViewState();
}

class _InstitucionDetailViewState extends State<InstitucionDetailView> {
  late InstitucionDetailViewModel viewModel;
  late final bool _isCustomViewModel;

  @override
  void initState() {
    super.initState();
    _isCustomViewModel = widget.viewModel != null;
    viewModel = widget.viewModel ?? InstitucionDetailViewModel(widget.institucion.id);
    viewModel.addListener(_onViewModelUpdate);

    // Si no tiene datos ya cargados previamente en el viewModel personalizado, cargar
    if (!_isCustomViewModel ||
        (viewModel.horarios.isEmpty &&
            viewModel.deportes.isEmpty &&
            viewModel.servicios.isEmpty &&
            viewModel.errorMessage == null)) {
      viewModel.loadDetail(institucion: widget.institucion);
    }
  }

  @override
  void dispose() {
    viewModel.removeListener(_onViewModelUpdate);
    if (!_isCustomViewModel) {
      viewModel.dispose();
    }
    super.dispose();
  }

  void _onViewModelUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final institucion = widget.institucion;
    final theme = Theme.of(context);

    // Barra de estado transparente
    final overlay = const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    );

    final safeTop = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlay,
        child: Column(
          children: [
            // Header con imagen de fondo de la institución
            _buildHeader(context, institucion, safeTop),
            const SizedBox(height: 16),
            // Contenido scrolleable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Aviso de modo sin conexión con datos en caché
                    if (viewModel.isFromCache) _buildOfflineWarningBanner(context),

                    // Mensaje de error general si falló y no hay caché
                    if (viewModel.errorMessage != null && !viewModel.isFromCache)
                      _buildGeneralErrorBanner(context),

                    // Botón principal para ver áreas deportivas
                    _buildMainActionButton(context, institucion),
                    const SizedBox(height: 20),

                    // Tarjeta de información de contacto
                    _buildContactCard(context, institucion),
                    const SizedBox(height: 16),

                    // Tarjeta de precio / tarifa
                    _buildPriceCard(context, institucion),
                    const SizedBox(height: 16),

                    // Tarjeta de descripción (si existe)
                    if (institucion.descripcion != null &&
                        institucion.descripcion!.isNotEmpty) ...[
                      _buildDescriptionCard(context, institucion),
                      const SizedBox(height: 16),
                    ],

                    // Tarjeta de fotografías
                    _buildPhotosCard(context),
                    const SizedBox(height: 16),

                    // Tarjeta de servicios complementarios
                    _buildServicesCard(context),
                    const SizedBox(height: 16),

                    // Tarjeta de horarios
                    _buildScheduleCard(context),
                    const SizedBox(height: 16),

                    // Tarjeta de deportes
                    _buildSportsCard(context),
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

  Widget _buildHeader(
    BuildContext context,
    InstitucionDeportiva institucion,
    double safeTop,
  ) {
    final hasImage = institucion.imagen != null && institucion.imagen!.isNotEmpty;

    return Container(
      height: 300,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
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
            child: hasImage
                ? Image.network(
                    institucion.imagen!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildHeaderFallback(),
                  )
                : _buildHeaderFallback(),
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
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.7),
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
                      key: const Key('institucion_back_button'),
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
    );
  }

  Widget _buildHeaderFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: const Center(
        child: Icon(Icons.sports_soccer, size: 80, color: Colors.white),
      ),
    );
  }

  Widget _buildHeaderRating(double calificacion) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
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

  /// Banner de advertencia cuando se cargan datos guardados previamente en modo sin conexión
  Widget _buildOfflineWarningBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade400, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: Colors.amber.shade900, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Modo sin conexión',
                  style: TextStyle(
                    color: Colors.amber.shade900,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Estás viendo la información guardada. Los datos podrían estar desactualizados.',
            style: TextStyle(
              color: Colors.amber.shade900,
              fontSize: 13,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              key: const Key('offline_retry_button'),
              onPressed: () => viewModel.loadDetail(
                institucion: widget.institucion,
                isRetry: true,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade800,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reintentar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  /// Banner cuando el servidor falla (ej: error 500) y no hay datos en caché
  Widget _buildGeneralErrorBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade300, width: 1.5),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 40),
          const SizedBox(height: 10),
          Text(
            viewModel.errorMessage ??
                'No fue posible cargar los detalles de la instalación.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.red.shade900,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            key: const Key('error_retry_button'),
            onPressed: () => viewModel.loadDetail(
              institucion: widget.institucion,
              isRetry: true,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Reintentar', style: TextStyle(fontWeight: FontWeight.bold)),
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
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
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
                    color: Colors.white.withValues(alpha: 0.2),
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

  Widget _buildContactCard(BuildContext context, InstitucionDeportiva institucion) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? AppColors.primaryDark
              : Colors.transparent,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.contact_phone_outlined,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Información de Contacto',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildContactRow(
              context,
              Icons.phone_outlined,
              'Teléfono',
              institucion.telefono,
              AppColors.accent,
            ),
            const SizedBox(height: 12),
            _buildContactRow(
              context,
              Icons.email_outlined,
              'Email',
              institucion.email,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildContactRow(
              context,
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
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkBackground
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
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
                    color: Theme.of(context).hintColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(BuildContext context, InstitucionDeportiva institucion) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? AppColors.primaryDark
              : Colors.transparent,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
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
                      color: theme.hintColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'S/. ${institucion.tarifa.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'por hora',
                    style: TextStyle(fontSize: 12, color: theme.hintColor),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryDark),
              ),
              child: const Text(
                'Mejor precio',
                style: TextStyle(
                  color: AppColors.primary,
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

  Widget _buildDescriptionCard(
    BuildContext context,
    InstitucionDeportiva institucion,
  ) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? AppColors.primaryDark
              : Colors.transparent,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Acerca de nosotros',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
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
                color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tarjeta de Fotografías (Galería o indicación de sin fotografías)
  Widget _buildPhotosCard(BuildContext context) {
    final theme = Theme.of(context);
    final fotos = viewModel.fotografias.isNotEmpty
        ? viewModel.fotografias
        : (widget.institucion.imagen != null && widget.institucion.imagen!.isNotEmpty
            ? [widget.institucion.imagen!]
            : <String>[]);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? AppColors.primaryDark
              : Colors.transparent,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.photo_library_outlined,
                    color: Colors.deepPurple.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Fotografías',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (viewModel.isLoading && fotos.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (fotos.isEmpty)
              _buildEmptyState(
                Icons.image_not_supported_outlined,
                'Sin fotografías registradas',
                subtitle:
                    'Esta instalación aún no cuenta con fotografías complementarias registradas.',
              )
            else
              SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: fotos.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final url = fotos[index];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 220,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                        ),
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey.shade300,
                            child: const Center(
                              child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Tarjeta de Servicios complementarios (o indicación de sin servicios)
  Widget _buildServicesCard(BuildContext context) {
    final theme = Theme.of(context);
    final servicios = viewModel.servicios;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? AppColors.primaryDark
              : Colors.transparent,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.room_service_outlined,
                    color: Colors.teal.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Servicios',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (viewModel.isLoading && servicios.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (servicios.isEmpty)
              _buildEmptyState(
                Icons.info_outline,
                'Sin servicios registrados',
                subtitle:
                    'Esta instalación no cuenta con servicios adicionales registrados.',
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: servicios.map((s) => _buildServiceChip(context, s)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceChip(BuildContext context, String servicio) {
    IconData icon = Icons.check_circle_outline;
    final lower = servicio.toLowerCase();

    if (lower.contains('estacionamiento') || lower.contains('parking')) {
      icon = Icons.local_parking;
    } else if (lower.contains('iluminaci') || lower.contains('led')) {
      icon = Icons.lightbulb_outline;
    } else if (lower.contains('vestuario') || lower.contains('ducha')) {
      icon = Icons.shower_outlined;
    } else if (lower.contains('cafeter') || lower.contains('snack')) {
      icon = Icons.local_cafe_outlined;
    } else if (lower.contains('wifi') || lower.contains('wi-fi')) {
      icon = Icons.wifi;
    } else if (lower.contains('csped') || lower.contains('cesped')) {
      icon = Icons.grass;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.teal.shade200, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.teal.shade700),
          const SizedBox(width: 8),
          Text(
            servicio,
            style: TextStyle(
              color: Colors.teal.shade900,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(BuildContext context) {
    final theme = Theme.of(context);
    final horarios = viewModel.horarios;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? AppColors.primaryDark
              : Colors.transparent,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.access_time_outlined,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Horarios de Atención',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (viewModel.isLoading && horarios.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (horarios.isEmpty)
              _buildEmptyState(
                Icons.schedule_outlined,
                'Sin horarios registrados',
                subtitle:
                    'Esta instalación no tiene horarios de atención registrados.',
              )
            else
              Column(
                children: horarios
                    .map((h) => _buildScheduleItem(context, h))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleItem(BuildContext context, HorarioAtencion horario) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkBackground
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
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
          Icon(Icons.schedule, size: 18, color: Theme.of(context).hintColor),
          const SizedBox(width: 8),
          Text(
            '${horario.horaApertura} - ${horario.horaCierre}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSportsCard(BuildContext context) {
    final theme = Theme.of(context);
    final deportes = viewModel.deportes;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? AppColors.primaryDark
              : Colors.transparent,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.sports_soccer,
                    color: Colors.green.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Deportes Disponibles',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (viewModel.isLoading && deportes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (deportes.isEmpty)
              _buildEmptyState(
                Icons.sports_outlined,
                'Sin deportes registrados',
                subtitle:
                    'Esta instalación no tiene deportes disponibles registrados.',
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: deportes
                    .map((d) => _buildSportChip(context, d))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSportChip(BuildContext context, Deporte deporte) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.green.shade100],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade300, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sports, size: 18, color: Colors.green.shade700),
          const SizedBox(width: 8),
          Text(
            deporte.nombre,
            style: TextStyle(
              color: Colors.green.shade800,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    IconData icon,
    String title, {
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 28, color: Colors.grey.shade500),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
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
