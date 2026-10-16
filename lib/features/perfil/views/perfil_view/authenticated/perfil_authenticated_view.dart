import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gameon/features/perfil/models/usuario_deportista.dart';
import 'package:gameon/features/perfil/views/perfil_view/authenticated/edit_perfil/edit_perfil_view.dart';
import 'package:gameon/features/perfil/viewmodels/edit_perfil_viewmodel.dart';
import 'package:gameon/features/perfil/viewmodels/perfil_viewmodel.dart';
import 'package:gameon/features/perfil/views/perfil_view/authenticated/help_support_view.dart';
import 'package:gameon/features/perfil/views/perfil_view/authenticated/notification_settings_view.dart';
import 'package:provider/provider.dart';

String _formatDate(DateTime? dt) {
  if (dt == null) return '—';
  return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

class PerfilAuthenticatedView extends StatelessWidget {
  final UsuarioDeportista profile;
  final VoidCallback onLogout;
  const PerfilAuthenticatedView({
    super.key,
    required this.profile,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final p = profile;

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
            // Header moderno con gradiente verde (incluye avatar y badges)
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
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    children: [
                      // Título en la parte superior (más compacto)
                      Row(
                        children: [
                          // Título
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Perfil',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Mi Cuenta',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Icono decorativo
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Avatar, nombre y badges dentro del header
                      _buildProfileHeaderInside(p),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Contenido principal con scroll
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Estadísticas en cards horizontales
                    _buildStatsRow(p),
                    const SizedBox(height: 16),
                    // Sección de deportes favoritos (siempre si hay deportes)
                    if (p.deportesFavoritos.isNotEmpty)
                      _buildDeportesSection(p),
                    if (p.deportesFavoritos.isNotEmpty)
                      const SizedBox(height: 16),
                    // Información personal
                    _buildInfoSection(p),
                    const SizedBox(height: 16),
                    // Opciones de configuración
                    _buildOptionsSection(context, p),
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

  // Header del perfil con avatar y nombre (dentro del área verde)
  Widget _buildProfileHeaderInside(UsuarioDeportista p) {
    return Column(
      children: [
        // Avatar más grande
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipOval(
            child: p.imagenPerfil != null && p.imagenPerfil!.isNotEmpty
                ? Image.network(
                    p.imagenPerfil!,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.green[700],
                        ),
                      );
                    },
                    errorBuilder: (context, error, stack) => Center(
                      child: Text(
                        p.nombre.isNotEmpty ? p.nombre[0].toUpperCase() : 'U',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      p.nombre.isNotEmpty ? p.nombre[0].toUpperCase() : 'U',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        // Nombre
        Text(
          p.nombreCompleto,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 10),
        // Badges de información con colores adaptados al fondo verde
        Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            if (p.edad != null)
              _buildBadgeWhite(Icons.cake_outlined, '${p.edad} años'),
            if (p.nivelHabilidad.isNotEmpty)
              _buildBadgeWhite(
                Icons.sports_soccer,
                'Nivel ${p.nivelHabilidad}',
              ),
          ],
        ),
      ],
    );
  }

  Map<String, dynamic> _getDeporteData(String deporte) {
    switch (deporte.toLowerCase()) {
      case 'fútbol':
      case 'futbol':
        return {'icon': Icons.sports_soccer, 'color': Colors.green.shade700};
      case 'basketball':
      case 'baloncesto':
        return {
          'icon': Icons.sports_basketball,
          'color': Colors.orange.shade700,
        };
      case 'tenis':
        return {'icon': Icons.sports_tennis, 'color': Colors.blue.shade700};
      case 'volleyball':
      case 'voleibol':
        return {'icon': Icons.sports_volleyball, 'color': Colors.red.shade700};
      case 'natación':
      case 'natacion':
        return {'icon': Icons.pool, 'color': Colors.cyan.shade700};
      case 'ciclismo':
        return {'icon': Icons.directions_bike, 'color': Colors.purple.shade700};
      case 'running':
      case 'atletismo':
        return {'icon': Icons.directions_run, 'color': Colors.indigo.shade700};
      case 'gym':
      case 'gimnasio':
        return {'icon': Icons.fitness_center, 'color': Colors.grey.shade700};
      default:
        return {'icon': Icons.sports, 'color': Colors.teal.shade700};
    }
  }

  Widget _buildBadgeWhite(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Fila de estadísticas
  Widget _buildStatsRow(UsuarioDeportista p) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.event_available,
            value: '0',
            label: 'Reservas',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.star,
            value: '4.5',
            label: 'Rating',
            color: Colors.amber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.calendar_today,
            value: _getYearFromDate(p.createdAt),
            label: 'Desde',
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color[50], shape: BoxShape.circle),
            child: Icon(icon, color: color[700], size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getYearFromDate(DateTime? date) {
    if (date == null) return '2024';
    return date.year.toString();
  }

  // Sección de deportes favoritos
  Widget _buildDeportesSection(UsuarioDeportista p) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Icon(Icons.sports, color: Colors.grey[700], size: 18),
                const SizedBox(width: 8),
                Text(
                  'Mis Deportes',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: p.deportesFavoritos
                  .map((deporte) => _buildDeporteCard(deporte))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeporteCard(String deporte) {
    final deporteData = _getDeporteData(deporte);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: deporteData['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: deporteData['color'].withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(deporteData['icon'], size: 18, color: deporteData['color']),
          const SizedBox(width: 8),
          Text(
            deporte,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: deporteData['color'],
            ),
          ),
        ],
      ),
    );
  }

  // Sección de información
  Widget _buildInfoSection(UsuarioDeportista p) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.person_outline, color: Colors.grey[700], size: 20),
                const SizedBox(width: 10),
                Text(
                  'Información Personal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[200]),
          _buildInfoItem(
            icon: Icons.badge_outlined,
            label: 'Nombre completo',
            value: p.nombreCompleto,
          ),
          Divider(height: 1, color: Colors.grey[200], indent: 52),
          _buildInfoItem(
            icon: Icons.alternate_email,
            label: 'Usuario',
            value: p.username.isEmpty ? '—' : '@${p.username}',
          ),
          Divider(height: 1, color: Colors.grey[200], indent: 52),
          _buildInfoItem(
            icon: Icons.phone_outlined,
            label: 'Teléfono',
            value: p.telefono.isEmpty ? '—' : p.telefono,
          ),
          Divider(height: 1, color: Colors.grey[200], indent: 52),
          _buildInfoItem(
            icon: Icons.cake_outlined,
            label: 'Edad',
            value: p.edad?.toString() ?? '—',
          ),
          Divider(height: 1, color: Colors.grey[200], indent: 52),
          _buildInfoItem(
            icon: Icons.calendar_month_outlined,
            label: 'Miembro desde',
            value: _formatDate(p.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[400]),
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
                const SizedBox(height: 4),
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

  // Sección de opciones
  Widget _buildOptionsSection(BuildContext context, UsuarioDeportista p) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildOptionItem(
            context: context,
            icon: Icons.edit_outlined,
            title: 'Editar perfil',
            subtitle: 'Actualiza tu información personal',
            color: Colors.blue,
            onTap: () {
              _navigateToEditPerfil(context);
            },
          ),
          Divider(height: 1, color: Colors.grey[200]),
          _buildOptionItem(
            context: context,
            icon: Icons.notifications_outlined,
            title: 'Notificaciones',
            subtitle: 'Configura tus preferencias',
            color: Colors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationSettingsView(),
                ),
              );
            },
          ),
          Divider(height: 1, color: Colors.grey[200]),
          _buildOptionItem(
            context: context,
            icon: Icons.help_outline,
            title: 'Ayuda y soporte',
            subtitle: '¿Necesitas ayuda?',
            color: Colors.purple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpSupportView()),
              );
            },
          ),
          Divider(height: 1, color: Colors.grey[200]),
          _buildOptionItem(
            context: context,
            icon: Icons.logout,
            title: 'Cerrar sesión',
            subtitle: 'Salir de tu cuenta',
            color: Colors.red,
            onTap: onLogout,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDestructive ? color : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToEditPerfil(BuildContext context) {
    // Obtener el PerfilViewModel del contexto actual
    final perfilVm = context.read<PerfilViewModel>();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => EditPerfilViewModel()..loadDeportes(),
            ),
            // Proporcionar el PerfilViewModel existente
            ChangeNotifierProvider<PerfilViewModel>.value(value: perfilVm),
          ],
          child: EditPerfilView(profile: profile),
        ),
      ),
    );
  }
}
