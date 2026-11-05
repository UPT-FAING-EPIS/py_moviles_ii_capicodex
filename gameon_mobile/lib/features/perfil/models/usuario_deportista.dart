class UsuarioDeportista {
  final String id; // id interno de la tabla
  final String authId; // id del usuario en auth.users
  final String username;
  final String nombre;
  final String apellidos;
  final String telefono;
  final DateTime? fechaNacimiento;
  final String genero;
  final String nivelHabilidad;
  final int? estado;
  final String? imagenPerfil;
  final DateTime? createdAt; // mapea a creado_en
  final List<String>
  deportesFavoritos; // Lista de deportes favoritos del usuario

  UsuarioDeportista({
    required this.id,
    required this.authId,
    required this.username,
    required this.nombre,
    required this.apellidos,
    required this.telefono,
    required this.fechaNacimiento,
    required this.genero,
    required this.nivelHabilidad,
    required this.estado,
    this.imagenPerfil,
    required this.createdAt,
    this.deportesFavoritos = const [],
  });

  factory UsuarioDeportista.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString());
    }

    return UsuarioDeportista(
      id: (json['id'] ?? '').toString(),
      authId: json['auth_id']?.toString() ?? json['authId']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      apellidos: json['apellidos']?.toString() ?? '',
      telefono: json['telefono']?.toString() ?? '',
      fechaNacimiento: parseDate(json['fecha_nacimiento']),
      genero: json['genero']?.toString() ?? 'otro',
      nivelHabilidad:
          json['nivel_habilidad']?.toString() ??
          json['nivelHabilidad']?.toString() ??
          '',
      estado: json['estado'] is int
          ? json['estado'] as int
          : int.tryParse(json['estado']?.toString() ?? ''),
      imagenPerfil: json['imagen_perfil']?.toString(),
      createdAt: parseDate(json['creado_en'] ?? json['created_at']),
      deportesFavoritos: json['deportes_favoritos'] != null
          ? (json['deportes_favoritos'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                []
          : [],
    );
  }

  UsuarioDeportista copyWith({
    String? id,
    String? authId,
    String? username,
    String? nombre,
    String? apellidos,
    String? telefono,
    DateTime? fechaNacimiento,
    String? genero,
    String? nivelHabilidad,
    int? estado,
    String? imagenPerfil,
    DateTime? createdAt,
    List<String>? deportesFavoritos,
  }) {
    return UsuarioDeportista(
      id: id ?? this.id,
      authId: authId ?? this.authId,
      username: username ?? this.username,
      nombre: nombre ?? this.nombre,
      apellidos: apellidos ?? this.apellidos,
      telefono: telefono ?? this.telefono,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      genero: genero ?? this.genero,
      nivelHabilidad: nivelHabilidad ?? this.nivelHabilidad,
      estado: estado ?? this.estado,
      imagenPerfil: imagenPerfil ?? this.imagenPerfil,
      createdAt: createdAt ?? this.createdAt,
      deportesFavoritos: deportesFavoritos ?? List<String>.from(this.deportesFavoritos),
    );
  }

  String get nombreCompleto => '$nombre $apellidos'.trim();

  int? get edad {
    final fn = fechaNacimiento;
    if (fn == null) return null;
    final now = DateTime.now();
    int years = now.year - fn.year;
    final hasHadBirthday =
        (now.month > fn.month) || (now.month == fn.month && now.day >= fn.day);
    if (!hasHadBirthday) years -= 1;
    return years;
  }
}
