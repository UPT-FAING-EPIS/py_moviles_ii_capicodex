import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../viewmodels/bot_conversation_viewmodel.dart';

class BotConversationView extends StatefulWidget {
  const BotConversationView({super.key});

  @override
  State<BotConversationView> createState() => _BotConversationViewState();
}

class _BotConversationViewState extends State<BotConversationView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  late BotConversationViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = BotConversationViewModel();
    _viewModel.addListener(_onVmChanged);
    _messageController.addListener(_onTextChanged);
    _initializeConversation();
  }

  /// Inicializar conversación con datos del usuario actual
  Future<void> _initializeConversation() async {
    final user = Supabase.instance.client.auth.currentUser;
    
    String userId;
    String userName;
    String? userPhoto;

    if (user != null) {
      userId = user.id;
      userName = user.userMetadata?['username'] ??
          user.userMetadata?['nombre'] ??
          'Usuario';
      userPhoto = user.userMetadata?['avatar_url'];
    } else {
      // Generar ID temporal para invitado
      final randomId = Random().nextInt(100000);
      userId = 'guest_${DateTime.now().millisecondsSinceEpoch}_$randomId';
      userName = 'Invitado';
      userPhoto = null;
    }

    await _viewModel.initialize(
      userId: userId,
      userName: userName,
      userPhoto: userPhoto,
    );
  }

  void _onVmChanged() {
    if (mounted) setState(() {});
  }

  bool _lastQuickRepliesState = true;

  void _onTextChanged() {
    // Solo actualizar el estado si cambia la visibilidad de las sugerencias
    // para evitar rebuilds innecesarios que hagan perder el foco del TextField
    final hasText = _messageController.text.trim().isNotEmpty;
    final shouldShow =
        !_viewModel.isTyping &&
        !_viewModel.busy &&
        !hasText &&
        _quickReplies.isNotEmpty;

    if (_lastQuickRepliesState != shouldShow) {
      _lastQuickRepliesState = shouldShow;
      if (mounted) {
        setState(() {
          // El rebuild se hará para actualizar las sugerencias
        });
      }
    }
  }

  // Opciones de respuesta rápida
  final List<String> _quickReplies = [
    '🔍 Buscar canchas',
    '📅 Mis reservas',
    '💬 Buscar jugadores',
    '❓ Ayuda',
  ];

  @override
  void dispose() {
    _viewModel.removeListener(_onVmChanged);
    _messageController.removeListener(_onTextChanged);
    _viewModel.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
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
        appBar: AppBar(
          backgroundColor: Colors.blue.shade700,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          toolbarHeight: 70,
          leading: Container(
            margin: const EdgeInsets.only(left: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: Row(
            children: [
              // Avatar del bot
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.smart_toy_rounded,
                    color: Colors.blue.shade700,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Nombre
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Asistente GameOn',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'BOT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
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
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.more_horiz,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: _showActions,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // Lista de mensajes
            Expanded(child: _buildMessagesList()),
            // Botones de respuesta rápida
            // Solo mostrar cuando: bot no está escribiendo, no está ocupado, y usuario no está escribiendo
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: _shouldShowQuickReplies()
                  ? _buildQuickReplies()
                  : const SizedBox.shrink(),
            ),
            // Input de mensaje
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    // Campo de texto
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          key: const ValueKey('message_input_field'),
                          controller: _messageController,
                          focusNode: _focusNode,
                          enableInteractiveSelection: true,
                          decoration: const InputDecoration(
                            hintText: 'Escribe tu pregunta...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          onTapOutside: (event) {
                            // Evitar que pierda el foco al tocar fuera
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Botón de enviar
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade600, Colors.blue.shade700],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Determina si se deben mostrar las sugerencias según convenciones de chatbot:
  /// - No mostrar si el bot está escribiendo (isTyping)
  /// - No mostrar si el bot está procesando (busy)
  /// - No mostrar si el usuario está escribiendo (campo de texto tiene contenido)
  /// - Mostrar en caso contrario (bot esperando respuesta del usuario)
  bool _shouldShowQuickReplies() {
    if (_viewModel.isTyping) return false; // Bot está escribiendo
    if (_viewModel.busy) return false; // Bot está procesando
    if (_messageController.text.trim().isNotEmpty)
      return false; // Usuario escribiendo
    if (_quickReplies.isEmpty) return false; // No hay sugerencias configuradas
    return true; // Mostrar sugerencias
  }

  Widget _buildMessagesList() {
    if (_viewModel.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.smart_toy_rounded,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Inicia una conversación',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: _viewModel.messages.length + (_viewModel.isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        // Si es el primer elemento y está escribiendo, mostrar animación
        if (index == 0 && _viewModel.isTyping) {
          return const _TypingIndicator();
        }

        // Ajustar índice si hay animación de typing
        final messageIndex = _viewModel.isTyping ? index - 1 : index;
        // Como getMessages devuelve los mensajes en orden descendente (más reciente primero)
        // y reverse: true invierte la lista visual, accedemos directamente al índice
        final message = _viewModel.messages[messageIndex];
        final isBot = message.senderId == 'bot_assistant';

        return _BotMessageBubble(
          text: message.content,
          isBot: isBot,
          timestamp: message.timestamp,
        );
      },
    );
  }

  Widget _buildQuickReplies() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tips_and_updates,
                size: 16,
                color: Colors.blue.shade700,
              ),
              const SizedBox(width: 6),
              Text(
                'Sugerencias',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickReplies.map((reply) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: Icon(
                        Icons.flash_on,
                        size: 16,
                        color: Colors.blue.shade700,
                      ),
                      label: Text(
                        reply,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onPressed: () => _handleQuickReply(reply),
                      backgroundColor: Colors.blue.shade50,
                      shape: StadiumBorder(
                        side: BorderSide(color: Colors.blue.shade100),
                      ),
                      elevation: 0,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    await _viewModel.sendMessage(text);

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleQuickReply(String reply) {
    _messageController.text = reply;
    _sendMessage();
  }

  void _showActions() {
    final rootContext = context;
    showModalBottomSheet(
      context: rootContext,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.cleaning_services),
                title: const Text('Limpiar chat'),
                onTap: () async {
                  Navigator.pop(context);
                  if (!mounted) return;
                  final confirm = await showDialog<bool>(
                    context: rootContext,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Limpiar chat'),
                      content: const Text('¿Quieres borrar todo el historial con el asistente?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Limpiar'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await _viewModel.clearConversation();
                    if (!mounted) return;
                    ScaffoldMessenger.of(rootContext).showSnackBar(
                      const SnackBar(content: Text('Historial eliminado')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Acerca del bot'),
                onTap: () {
                  Navigator.pop(context);
                  _showBotInfo();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBotInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.smart_toy_rounded, color: Colors.blue.shade700),
            const SizedBox(width: 12),
            const Text('Acerca del bot'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¡Hola! Soy tu asistente virtual de GameOn.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text('Puedo ayudarte con:'),
            SizedBox(height: 8),
            Text('• Buscar canchas disponibles'),
            Text('• Consultar tus reservas'),
            Text('• Encontrar jugadores'),
            Text('• Responder preguntas frecuentes'),
            SizedBox(height: 12),
            Text(
              'Estoy disponible 24/7 para asistirte.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar del bot
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue.shade700,
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          // Burbuja con animación de puntos
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: Colors.blue.shade100, width: 1),
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    final delay = index * 0.2;
                    final value = (_controller.value - delay) % 1.0;
                    final opacity = value < 0.5 ? value * 2 : 2 - value * 2;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      child: Opacity(
                        opacity: opacity.clamp(0.3, 1.0),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade700,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BotMessageBubble extends StatelessWidget {
  final String text;
  final bool isBot;
  final DateTime timestamp;

  const _BotMessageBubble({
    required this.text,
    required this.isBot,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: isBot
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBot) ...[
            // Avatar del bot
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade700,
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Burbuja de mensaje
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isBot ? Colors.white : Colors.blue.shade700,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isBot ? 4 : 18),
                  topRight: Radius.circular(isBot ? 18 : 4),
                  bottomLeft: const Radius.circular(18),
                  bottomRight: const Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: isBot
                    ? Border.all(color: Colors.blue.shade100, width: 1)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 15,
                      color: isBot ? Colors.black87 : Colors.white,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isBot ? Colors.grey.shade500 : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
