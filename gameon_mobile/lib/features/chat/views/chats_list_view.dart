import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:gameon/features/perfil/viewmodels/perfil_viewmodel.dart';
import 'package:gameon/features/perfil/views/login_page/login_page.dart';
import '../viewmodels/chat_list_viewmodel.dart';
import '../models/conversation.dart';
import 'conversation_view.dart';
import 'find_players_view.dart';
import 'bot_conversation_view.dart';
import 'package:gameon/core/theme/app_theme.dart';
import 'package:gameon/core/theme/theme_controller.dart';

class ChatsListView extends StatefulWidget {
  const ChatsListView({super.key});

  @override
  State<ChatsListView> createState() => _ChatsListViewState();
}

class _ChatsListViewState extends State<ChatsListView> {
  late ChatListViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = ChatListViewModel();
    _viewModel.addListener(_onViewModelChanged);
    _viewModel.start();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final headerBackground = AppTheme.headerBackgroundFor(
      context.watch<ThemeController>().selection,
    );
    final overlay = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    );

    final perfilVm = context.watch<PerfilViewModel>();
    final isLoggedIn = perfilVm.isLoggedIn && perfilVm.profile != null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Column(
          children: [
            // Header moderno con gradiente verde
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colors.primary, colors.primaryContainer],
                ),
                image: headerBackground == null
                    ? null
                    : DecorationImage(
                        image: AssetImage(headerBackground),
                        fit: BoxFit.cover,
                        opacity: .34,
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
                          // Ícono de chat
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.chat_bubble,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Título
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Chats',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Conecta con otros jugadores',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Badge de notificaciones si hay mensajes no leídos
                          if (isLoggedIn && _viewModel.unreadCount > 0)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_viewModel.unreadCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Campo de búsqueda
                      Container(
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextField(
                          controller: _searchController,
                          readOnly: !isLoggedIn,
                          onTap: !isLoggedIn
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginPage(),
                                    ),
                                  );
                                }
                              : null,
                          decoration: InputDecoration(
                            hintText: 'Buscar conversaciones...',
                            prefixIcon: Icon(
                              Icons.search,
                              color: colors.secondary,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: colors.secondary,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      _viewModel.clearSearch();
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (value) {
                            _viewModel.setSearchQuery(value);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Lista de conversaciones
            Expanded(
              child: isLoggedIn
                  ? _buildBody()
                  : ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [_buildBotListItem()],
                    ),
            ),
          ],
        ),
        // Botón flotante para buscar jugadores
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            if (isLoggedIn) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FindPlayersView(),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            }
          },
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          icon: Icon(Icons.person_add, color: colors.onPrimary),
          label: Text(
            'Buscar jugadores',
            style: TextStyle(
              color: colors.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_viewModel.loading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
        ),
      );
    }

    if (_viewModel.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'Error al cargar conversaciones',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _viewModel.error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _viewModel.refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Siempre mostrar el bot como primer elemento, incluso sin conversaciones

    return RefreshIndicator(
      onRefresh: () => _viewModel.refresh(),
      color: Colors.green,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _viewModel.conversations.length + 1, // +1 para el bot
        itemBuilder: (context, index) {
          // El primer item es el bot
          if (index == 0) {
            return _buildBotListItem();
          }

          // Los demás items son conversaciones normales
          final conversation = _viewModel.conversations[index - 1];
          final otherUser = _viewModel.getOtherUser(conversation);
          final isOnline = _viewModel.isUserOnline(otherUser?.id ?? '');

          return _ConversationListItem(
            conversation: conversation,
            otherUserName: otherUser?.nombre ?? 'Usuario',
            otherUserAvatar: otherUser?.fotoPerfil,
            isOnline: isOnline,
            onTap: () async {
              if (mounted) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConversationView(
                      conversationId: conversation.id,
                      otherUserName: otherUser?.nombre ?? 'Usuario',
                      otherUserAvatar: otherUser?.fotoPerfil,
                    ),
                  ),
                );
                // Refrescar al volver para asegurar que se muestren los cambios
                if (mounted) {
                  _viewModel.refresh();
                }
              }

              _viewModel.markConversationAsRead(conversation.id);
            },
            onDelete: () async {
              try {
                await _viewModel.deleteConversation(conversation.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Conversación eliminada'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildBotListItem() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BotConversationView()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(
            bottom: BorderSide(color: theme.dividerColor, width: 1),
          ),
        ),
        child: Row(
          children: [
            // Avatar del bot
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: colors.primary,
                  child: Icon(
                    Icons.smart_toy_rounded,
                    color: colors.onPrimary,
                    size: 26,
                  ),
                ),
                // Badge BOT
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: colors.secondary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // Información del bot
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre y hora
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Asistente GameOn',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.secondary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'BOT',
                              style: TextStyle(
                                color: colors.onSecondary,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Ahora',
                        style: TextStyle(fontSize: 12, color: theme.hintColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Mensaje
                  Text(
                    '¿En qué puedo ayudarte hoy?',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.hintColor,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationListItem extends StatelessWidget {
  final Conversation conversation;
  final String otherUserName;
  final String? otherUserAvatar;
  final bool isOnline;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ConversationListItem({
    required this.conversation,
    required this.otherUserName,
    required this.otherUserAvatar,
    required this.isOnline,
    required this.onTap,
    required this.onDelete,
  });

  String get currentUserId {
    final user = Supabase.instance.client.auth.currentUser;
    return user?.id ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = conversation.getUnreadCountForUser(currentUserId) > 0;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Dismissible(
      key: Key(conversation.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white, size: 32),
      ),
      confirmDismiss: (direction) async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Eliminar conversación'),
            content: const Text(
              '¿Estás seguro de que quieres eliminar esta conversación?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        );
        return confirm ?? false;
      },
      onDismissed: (direction) => onDelete(),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: hasUnread
                ? colors.primary.withValues(alpha: isDark ? .24 : .10)
                : colors.surface,
            border: Border(
              bottom: BorderSide(color: theme.dividerColor, width: 1),
            ),
          ),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: colors.primary.withValues(alpha: .22),
                    backgroundImage: otherUserAvatar != null
                        ? NetworkImage(otherUserAvatar!)
                        : null,
                    child: otherUserAvatar == null
                        ? Text(
                            otherUserName[0].toUpperCase(),
                            style: TextStyle(
                              color: colors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          )
                        : null,
                  ),
                  // Indicador de usuario en línea
                  if (isOnline)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Información de la conversación
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre y hora
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            otherUserName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: hasUnread
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: colors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatTime(
                            conversation.lastMessageTime ??
                                conversation.createdAt,
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: hasUnread ? colors.primary : theme.hintColor,
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Último mensaje
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.lastMessage != null
                                ? '${conversation.lastMessageSenderId == currentUserId ? 'Tú: ' : ''}${conversation.lastMessage}'
                                : 'Nueva conversación',
                            style: TextStyle(
                              fontSize: 14,
                              color: hasUnread
                                  ? colors.onSurface
                                  : theme.hintColor,
                              fontWeight: hasUnread
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasUnread)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${conversation.getUnreadCountForUser(currentUserId)}',
                              style: TextStyle(
                                color: colors.onPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(time);
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE', 'es').format(time);
    } else {
      return DateFormat('dd/MM/yyyy').format(time);
    }
  }
}
