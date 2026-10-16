import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gameon/main.dart';

class NotificationSettingsView extends StatefulWidget {
  const NotificationSettingsView({super.key});

  @override
  State<NotificationSettingsView> createState() =>
      _NotificationSettingsViewState();
}

class _NotificationSettingsViewState extends State<NotificationSettingsView> {
  // Estado local
  bool _newMessages = true;
  bool _matchReminders = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _newMessages = prefs.getBool('notifications_new_messages') ?? true;
      _matchReminders = prefs.getBool('notifications_match_reminders') ?? true;
      _soundEnabled = prefs.getBool('notifications_sound') ?? true;
      _vibrationEnabled = prefs.getBool('notifications_vibration') ?? true;
      _loading = false;
    });
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
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildSectionHeader('Chats y Mensajes'),
                  _buildSwitchTile(
                    title: 'Nuevos mensajes',
                    subtitle: 'Recibe notificaciones cuando te escriban',
                    icon: Icons.chat_bubble_outline,
                    value: _newMessages,
                    onChanged: (val) {
                      setState(() => _newMessages = val);
                      _saveSetting('notifications_new_messages', val);
                    },
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Mis Reservas'),
                  _buildSwitchTile(
                    title: 'Actividad de reservas',
                    subtitle:
                        'Recibe avisos al reservar, antes y al inicio del juego',
                    icon: Icons.sports_soccer,
                    value: _matchReminders,
                    onChanged: (val) {
                      setState(() => _matchReminders = val);
                      _saveSetting('notifications_match_reminders', val);
                    },
                    color: Colors.green,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('General'),
                  Container(
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
                ],
              ),
            ),
          ],
        ),
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
