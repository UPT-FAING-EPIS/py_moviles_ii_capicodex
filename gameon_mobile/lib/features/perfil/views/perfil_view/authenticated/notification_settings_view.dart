import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gameon/main.dart';
import 'package:gameon/features/perfil/viewmodels/perfil_viewmodel.dart';
import 'package:provider/provider.dart';

class NotificationSettingsView extends StatefulWidget {
  const NotificationSettingsView({super.key});

  @override
  State<NotificationSettingsView> createState() =>
      _NotificationSettingsViewState();
}

class _NotificationSettingsViewState extends State<NotificationSettingsView> {
  // Estado local
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _loading = true;
  AuthorizationStatus? _permissionStatus;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final permissionStatus = await notificationService.getPermissionStatus();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _soundEnabled = prefs.getBool('notifications_sound') ?? true;
      _vibrationEnabled = prefs.getBool('notifications_vibration') ?? true;
      _permissionStatus = permissionStatus;
      _loading = false;
    });
  }

  Future<void> _setNotificationsEnabled(bool value) async {
    setState(() => _notificationsEnabled = value);
    try {
      await notificationService.setNotificationsEnabled(value);
      if (mounted) {
        await context.read<PerfilViewModel>().setNotificationsEnabled(value);
      }
    } catch (_) {
      if (!mounted) return;
      await notificationService.setNotificationsEnabled(!value);
      setState(() => _notificationsEnabled = !value);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo actualizar la preferencia. Inténtalo otra vez.'),
        ),
      );
    }
  }

  Future<void> _requestPermission() async {
    final status = await notificationService.requestPermission();
    if (!mounted) return;
    setState(() => _permissionStatus = status);
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    // Actualizar el canal de notificaciones si cambiamos sonido o vibración
    if (key == 'notifications_sound' || key == 'notifications_vibration') {
      await notificationService.updateNotificationPreferences();
    }
  }

  @override
  Widget build(BuildContext context) {
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
            // Header con gradiente
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
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
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
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Notificaciones',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Configura tus preferencias',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Contenido
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        _buildPermissionCard(),
                        const SizedBox(height: 24),
                        _buildSectionHeader('Avisos de GameOn'),
                        _buildSwitchTile(
                          title: 'Recibir notificaciones',
                          subtitle:
                              'Activa o suspende los avisos en este dispositivo',
                          icon: Icons.notifications_active_outlined,
                          value: _notificationsEnabled,
                          onChanged: _setNotificationsEnabled,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 24),
                        _buildSectionHeader('General'),
                        Opacity(
                          opacity: _notificationsEnabled ? 1 : .5,
                          child: IgnorePointer(
                            ignoring: !_notificationsEnabled,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
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
                                  _buildSwitchTileItem(
                                    title: 'Sonido',
                                    icon: Icons.volume_up_outlined,
                                    value: _soundEnabled,
                                    onChanged: (val) {
                                      setState(() => _soundEnabled = val);
                                      _saveSetting('notifications_sound', val);
                                    },
                                    color: Colors.orange,
                                    showDivider: true,
                                  ),
                                  _buildSwitchTileItem(
                                    title: 'Vibración',
                                    icon: Icons.vibration,
                                    value: _vibrationEnabled,
                                    onChanged: (val) {
                                      setState(() => _vibrationEnabled = val);
                                      _saveSetting('notifications_vibration', val);
                                    },
                                    color: Colors.purple,
                                    showDivider: false,
                                  ),
                                ],
                              ),
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

  Widget _buildPermissionCard() {
    final allowed = _permissionStatus == AuthorizationStatus.authorized ||
        _permissionStatus == AuthorizationStatus.provisional;
    final color = allowed ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(.25)),
      ),
      child: Row(
        children: [
          Icon(
            allowed ? Icons.verified_outlined : Icons.notifications_off_outlined,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              allowed
                  ? 'Permiso del sistema concedido'
                  : 'Permite las notificaciones para recibir avisos de GameOn',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (!allowed)
            TextButton(onPressed: _requestPermission, child: const Text('Permitir')),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // Tile individual con estilo de tarjeta
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.green.shade600,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }

  // Item para lista agrupada (General)
  Widget _buildSwitchTileItem({
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color color,
    bool showDivider = false,
  }) {
    return Column(
      children: [
        SwitchListTile(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.green.shade600,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 4,
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          secondary: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 70,
            endIndent: 20,
            color: Colors.grey.shade100,
          ),
      ],
    );
  }
}
