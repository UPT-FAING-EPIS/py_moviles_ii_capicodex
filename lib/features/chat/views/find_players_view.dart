import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../viewmodels/find_players_viewmodel.dart';
import 'conversation_view.dart';

class FindPlayersView extends StatefulWidget {
  const FindPlayersView({super.key});

  @override
  State<FindPlayersView> createState() => _FindPlayersViewState();
}

class _FindPlayersViewState extends State<FindPlayersView> {
  late FindPlayersViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minAgeController = TextEditingController();
  final TextEditingController _maxAgeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = FindPlayersViewModel();
    _viewModel.addListener(_onViewModelChanged);
    _viewModel.start();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    _searchController.dispose();
    _minAgeController.dispose();
    _maxAgeController.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) {
      // Sincronizar controladores si los filtros se limpiaron externamente
      if (_viewModel.minAge == null && _minAgeController.text.isNotEmpty) {
        _minAgeController.clear();
      }
      if (_viewModel.maxAge == null && _maxAgeController.text.isNotEmpty) {
        _maxAgeController.clear();
      }
      setState(() {});
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
                      // Barra de navegación
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
                                  'Buscar jugadores',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Encuentra personas para jugar',
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
                      const SizedBox(height: 24),
                      // Campo de búsqueda
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Buscar por nombre...',
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.grey,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      _viewModel.setSearchQuery('');
                                      setState(() {});
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
            // Filtros
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila 1: Deporte y Nivel
                  Row(
                    children: [
                      // Filtro de Deporte
                      Expanded(
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.sports_soccer,
                                size: 22,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int?>(
                                    value: _viewModel.selectedDeporteId,
                                    hint: const Text(
                                      'Deporte',
                                      style: TextStyle(fontSize: 15),
                                    ),
                                    isExpanded: true,
                                    icon: const Icon(
                                      Icons.arrow_drop_down,
                                      size: 24,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                    items: [
                                      const DropdownMenuItem<int?>(
                                        value: null,
                                        child: Text('Todos'),
                                      ),
                                      ..._viewModel.deportes.map((deporte) {
                                        return DropdownMenuItem<int?>(
                                          value: deporte['id'] as int,
                                          child: Text(
                                            deporte['nombre'],
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }),
                                    ],
                                    onChanged: (value) =>
                                        _viewModel.setDeporteFilter(value),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Filtro de Nivel
                      Expanded(
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.military_tech,
                                size: 22,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _viewModel.selectedNivelHabilidad,
                                    hint: const Text(
                                      'Nivel',
                                      style: TextStyle(fontSize: 15),
                                    ),
                                    isExpanded: true,
                                    icon: const Icon(
                                      Icons.arrow_drop_down,
                                      size: 24,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: null,
                                        child: Text('Todos'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Principiante',
                                        child: Text('Principiante'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Intermedio',
                                        child: Text('Intermedio'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Avanzado',
                                        child: Text('Avanzado'),
                                      ),
                                    ],
                                    onChanged: (value) => _viewModel
                                        .setNivelHabilidadFilter(value),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Fila 2: Género y Edad
                  Row(
                    children: [
                      // Filtro de Género
                      Expanded(
                        flex: 4,
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.wc_outlined,
                                size: 22,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _viewModel.selectedGenero,
                                    hint: const Text(
                                      'Género',
                                      style: TextStyle(fontSize: 15),
                                    ),
                                    isExpanded: true,
                                    icon: const Icon(
                                      Icons.arrow_drop_down,
                                      size: 24,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: null,
                                        child: Text('Todos'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'masculino',
                                        child: Text('Masculino'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'femenino',
                                        child: Text('Femenino'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'otro',
                                        child: Text('Otro'),
                                      ),
                                    ],
                                    onChanged: (value) =>
                                        _viewModel.setGeneroFilter(value),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Filtro de Edad
                      Expanded(
                        flex: 5,
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.cake_outlined,
                                size: 22,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  decoration: const InputDecoration(
                                    hintText: 'Min',
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    hintStyle: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  style: const TextStyle(fontSize: 15),
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  controller: _minAgeController,
                                  onChanged: (value) {
                                    final age = int.tryParse(value);
                                    _viewModel.setMinAgeFilter(age);
                                  },
                                ),
                              ),
                              const Text(
                                '-',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  decoration: const InputDecoration(
                                    hintText: 'Max',
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    hintStyle: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  style: const TextStyle(fontSize: 15),
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  controller: _maxAgeController,
                                  onChanged: (value) {
                                    final age = int.tryParse(value);
                                    _viewModel.setMaxAgeFilter(age);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Línea divisoria
            Divider(height: 1, color: Colors.grey.shade300),
            // Lista de jugadores
            Expanded(child: _buildBody()),
          ],
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
                'Error al buscar jugadores',
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
                onPressed: () => _viewModel.searchPlayers(),
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

    // No mostrar mensaje de "busca jugadores" porque ahora cargamos todos al inicio

    if (!_viewModel.hasResults) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_search, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 24),
              Text(
                'No se encontraron jugadores',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Intenta con otros filtros o\nun término de búsqueda diferente',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              if (_viewModel.hasFilters) ...[
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    _viewModel.clearFilters();
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Limpiar filtros'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green.shade700,
                    side: BorderSide(color: Colors.green.shade700),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _viewModel.searchResults.length,
      itemBuilder: (context, index) {
        final player = _viewModel.searchResults[index];
        return _PlayerListItem(
          player: player,
          onChatTap: () => _startChat(player),
        );
      },
    );
  }

  Future<void> _startChat(PlayerSearchResult player) async {
    if (_viewModel.creatingConversation) return;

    // Navegación inmediata con ID determinístico
    final conversationId = _viewModel.getConversationIdForPlayer(player);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ConversationView(
            conversationId: conversationId,
            otherUserName: player.name,
            otherUserAvatar: player.avatarUrl,
          ),
        ),
      );
    }

    // Crear/recuperar conversación en segundo plano (sin esperar)
    _viewModel.createConversation(player);
  }
}

class _PlayerListItem extends StatelessWidget {
  final PlayerSearchResult player;
  final VoidCallback onChatTap;

  const _PlayerListItem({required this.player, required this.onChatTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onChatTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.green.shade100,
                backgroundImage: player.avatarUrl != null
                    ? NetworkImage(player.avatarUrl!)
                    : null,
                child: player.avatarUrl == null
                    ? Text(
                        player.name[0].toUpperCase(),
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              // Información del jugador
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre
                    Text(
                      player.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (player.username != null && player.username!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '@${player.username!}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 4),
                    // Nivel del jugador
                    Row(
                      children: [
                        if (player.nivelHabilidad != null) ...[
                          Icon(
                            Icons.military_tech,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            player.nivelHabilidad!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Botón de chat
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: player.hasExistingConversation
                        ? [Colors.grey.shade600, Colors.grey.shade700]
                        : [Colors.green.shade600, Colors.green.shade700],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      player.hasExistingConversation
                          ? Icons.chat
                          : Icons.chat_bubble_outline,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      player.hasExistingConversation ? 'Ver chat' : 'Chatear',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
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

  String _getDeporteName(String deporteId) {
    // Aquí podrías hacer un lookup si necesitas nombres legibles
    // Por ahora retornamos el ID
    return deporteId;
  }
}
