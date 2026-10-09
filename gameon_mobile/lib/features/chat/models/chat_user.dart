class ChatUser {
  final String id;
  final String nombre;
  final String? fotoPerfil;
  final bool isOnline;

  ChatUser({
    required this.id,
    required this.nombre,
    this.fotoPerfil,
    this.isOnline = false,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      fotoPerfil: json['foto_perfil'] as String?,
      isOnline: json['is_online'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'foto_perfil': fotoPerfil,
      'is_online': isOnline,
    };
  }
}
