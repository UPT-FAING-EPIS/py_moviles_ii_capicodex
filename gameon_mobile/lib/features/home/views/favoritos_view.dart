import 'package:flutter/material.dart';
import 'package:gameon/features/home/models/institucion_deportiva.dart';
import 'package:gameon/features/home/views/institucion_detail_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Muestra exclusivamente las instalaciones guardadas por la cuenta activa.
class FavoritosView extends StatefulWidget {
  const FavoritosView({super.key});

  @override
  State<FavoritosView> createState() => _FavoritosViewState();
}

class _FavoritosViewState extends State<FavoritosView> {
  late Future<List<InstitucionDeportiva>> _favorites;

  @override
  void initState() {
    super.initState();
    _favorites = _loadFavorites();
  }

  Future<List<InstitucionDeportiva>> _loadFavorites() async {
    final client = Supabase.instance.client;
    final authId = client.auth.currentUser?.id;
    if (authId == null) return [];

    final profile = await client
        .from('usuarios_deportistas')
        .select('id')
        .eq('auth_id', authId)
        .maybeSingle();
    if (profile == null) return [];

    final favoriteRows = await client
        .from('instituciones_favoritas')
        .select('institucion_deportiva_id')
        .eq('usuario_deportista_id', profile['id']);
    final ids = (favoriteRows as List)
        .map((row) => row['institucion_deportiva_id'])
        .whereType<int>()
        .toList();
    if (ids.isEmpty) return [];

    final institutions = await client
        .from('instituciones_deportivas')
        .select()
        .inFilter('id', ids);
    return (institutions as List)
        .map((row) => InstitucionDeportiva.fromJson(row))
        .toList();
  }

  void _refresh() => setState(() => _favorites = _loadFavorites());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis favoritos')),
      body: FutureBuilder<List<InstitucionDeportiva>>(
        future: _favorites,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: TextButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text(
                  'No se pudieron cargar los favoritos. Reintentar',
                ),
              ),
            );
          }
          final favorites = snapshot.data ?? [];
          if (favorites.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border, size: 56),
                    SizedBox(height: 16),
                    Text('Aún no tienes instalaciones favoritas'),
                    SizedBox(height: 6),
                    Text(
                      'Guarda una instalación para encontrarla aquí.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: favorites.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = favorites[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.favorite, color: Colors.red),
                    title: Text(item.nombre),
                    subtitle: Text(item.direccion),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              InstitucionDetailView(institucion: item),
                        ),
                      );
                      _refresh();
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
