import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gameon/features/perfil/models/usuario_deportista.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gameon/features/perfil/viewmodels/edit_perfil_viewmodel.dart';
import 'package:gameon/features/perfil/viewmodels/perfil_viewmodel.dart';
import 'widgets/perfil_header.dart';
import 'widgets/profile_avatar.dart';
import 'widgets/section_title.dart';
import 'widgets/labeled_text_field.dart';
import 'widgets/date_field.dart';
import 'widgets/dropdown_field.dart';
import 'widgets/deportes_selector_card.dart';
import 'widgets/deportes_selector_sheet.dart';

class EditPerfilView extends StatefulWidget {
  final UsuarioDeportista profile;

  const EditPerfilView({super.key, required this.profile});

  @override
  State<EditPerfilView> createState() => _EditPerfilViewState();
}

class _EditPerfilViewState extends State<EditPerfilView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _usernameController;
  late TextEditingController _apellidosController;
  late TextEditingController _telefonoController;
  DateTime? _fechaNacimiento;
  String _genero = 'otro';
  String _nivelHabilidad = '';
  bool _isSaving = false;
  String? _localImageUrl;
  Uint8List? _pendingImageBytes;
  String? _pendingImageFilename;

  // Variables para deportes favoritos
  List<String> _deportesFavoritos = [];

  // ViewModel persistente
  late EditPerfilViewModel _viewModel;

  @override
  void initState() {
    super.initState();

    final p = widget.profile;
    _nombreController = TextEditingController(text: p.nombre);
    _usernameController = TextEditingController(text: p.username);
    _apellidosController = TextEditingController(text: p.apellidos);
    _telefonoController = TextEditingController(text: p.telefono);
    _fechaNacimiento = p.fechaNacimiento;
    _deportesFavoritos = List.from(p.deportesFavoritos);

    _genero = _normalizeGenero(p.genero);
    _nivelHabilidad = _normalizeNivelHabilidad(p.nivelHabilidad);

    // ✅ Se crea el ViewModel una sola vez (no en cada build)
    _viewModel = EditPerfilViewModel()..loadDeportes();
    _localImageUrl = widget.profile.imagenPerfil;
  }

  String _normalizeGenero(String genero) {
    final generoLower = genero.toLowerCase().trim();
    if (generoLower == 'masculino' || generoLower == 'm') return 'masculino';
    if (generoLower == 'femenino' || generoLower == 'f') return 'femenino';
    return 'otro';
  }

  String _normalizeNivelHabilidad(String nivel) {
    final nivelLower = nivel.toLowerCase().trim();
    if (nivelLower == 'principiante' ||
        nivelLower == 'inicial' ||
        nivelLower == 'basico' ||
        nivelLower == 'básico') {
      return 'Principiante';
    }
    if (nivelLower == 'intermedio' || nivelLower == 'medio') {
      return 'Intermedio';
    }
    if (nivelLower == 'avanzado' ||
        nivelLower == 'experto' ||
        nivelLower == 'profesional') {
      return 'Avanzado';
    }
    return 'Principiante';
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _usernameController.dispose();
    _apellidosController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _selectFechaNacimiento() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('es'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green.shade700,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _fechaNacimiento) {
      setState(() {
        _fechaNacimiento = picked;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Seleccionar fecha';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showDeportesSelector(BuildContext ctx) {
    final disponibles = ctx.read<EditPerfilViewModel>().deportesDisponibles;
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: DeportesSelectorSheet(
            disponibles: disponibles,
            seleccionados: _deportesFavoritos.toSet(),
            getDeporteIcon: _getDeporteIcon,
            onConfirm: (seleccion) {
              setState(() {
                _deportesFavoritos = seleccion.toList();
              });
            },
          ),
        );
      },
    );
  }

  IconData _getDeporteIcon(String deporte) {
    switch (deporte.toLowerCase()) {
      case 'fútbol':
      case 'futbol':
        return Icons.sports_soccer;
      case 'basketball':
      case 'baloncesto':
        return Icons.sports_basketball;
      case 'tenis':
        return Icons.sports_tennis;
      case 'volleyball':
      case 'voleibol':
        return Icons.sports_volleyball;
      case 'natación':
      case 'natacion':
        return Icons.pool;
      case 'ciclismo':
        return Icons.directions_bike;
      case 'running':
      case 'atletismo':
        return Icons.directions_run;
      case 'gym':
      case 'gimnasio':
        return Icons.fitness_center;
      default:
        return Icons.sports;
    }
  }

  Future<void> _selectProfileImage() async {
    final picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource?>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Seleccionar de la galería'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tomar foto'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancelar'),
                onTap: () => Navigator.pop(ctx, null),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    final XFile? picked;
    try {
      picked = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al abrir selector: $e')));
      }
      return;
    }

    if (picked == null) return;

    try {
      final bytes = await picked.readAsBytes();
      debugPrint('📷 Imagen seleccionada: ${bytes.length} bytes');

      // Guardar imagen temporalmente para mostrar preview
      setState(() {
        _pendingImageBytes = bytes;
        _pendingImageFilename =
            'user_${widget.profile.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        // Crear URL local temporal para preview
        _localImageUrl = 'pending';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      String? imageUrl;

      // Si hay una imagen pendiente, subirla primero
      if (_pendingImageBytes != null && _pendingImageFilename != null) {
        debugPrint('📤 Subiendo imagen pendiente: $_pendingImageFilename');
        imageUrl = await _viewModel.uploadProfileImage(
          _pendingImageBytes!,
          _pendingImageFilename!,
        );

        if (imageUrl == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se pudo subir la imagen'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        debugPrint('✅ Imagen subida: $imageUrl');
      }

      final res = await _viewModel.upsertUsuarioDeportista(
        id: int.tryParse(widget.profile.id.toString()),
        username: _usernameController.text,
        nombre: _nombreController.text,
        apellidos: _apellidosController.text,
        telefono: _telefonoController.text,
        fechaNacimiento: _fechaNacimiento,
        genero: _genero,
        nivelHabilidad: _nivelHabilidad,
        imagenPerfil: imageUrl ?? _localImageUrl,
      );
      if (!res.ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res.message ?? 'Error al actualizar perfil'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        return;
      }

      // Guardar deportes favoritos para ese usuario
      await _viewModel.saveDeportesFavoritos(
        res.usuarioId!,
        _deportesFavoritos,
      );

      if (mounted) {
        // Limpiar imagen pendiente
        _pendingImageBytes = null;
        _pendingImageFilename = null;

        // Recargar el perfil en el PerfilViewModel para reflejar cambios en la UI
        final perfilVm = context.read<PerfilViewModel>();
        await perfilVm.reloadProfile();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Perfil actualizado correctamente'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar perfil: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final overlay = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    );

    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlay,
        child: Scaffold(
          backgroundColor: Colors.grey[50],
          body: Column(
            children: [
              PerfilHeader(
                isSaving: _isSaving,
                onBack: () => Navigator.pop(context),
                onSave: _saveProfile,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar
                        Center(
                          child: ProfileAvatar(
                            initial: widget.profile.nombre,
                            onTap: _selectProfileImage,
                            imageUrl:
                                _localImageUrl ?? widget.profile.imagenPerfil,
                            pendingImageBytes: _pendingImageBytes,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton.icon(
                            onPressed: _selectProfileImage,
                            icon: const Icon(Icons.edit),
                            label: const Text('Cambiar foto de perfil'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.green.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const SectionTitle(
                          icon: Icons.person_outline,
                          title: 'Información Personal',
                        ),
                        const SizedBox(height: 16),
                        LabeledTextField(
                          controller: _nombreController,
                          label: 'Nombre',
                          icon: Icons.badge_outlined,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El nombre es requerido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        LabeledTextField(
                          controller: _apellidosController,
                          label: 'Apellidos',
                          icon: Icons.badge_outlined,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: LabeledTextField(
                                controller: _usernameController,
                                label: 'Usuario',
                                icon: Icons.alternate_email,
                                validator: (value) {
                                  final v = value?.trim() ?? '';
                                  if (v.isEmpty) return 'Requerido';
                                  if (v.length < 3) return 'Min 3';
                                  if (v.length > 30) return 'Max 30';
                                  final re = RegExp(r'^[a-z0-9_]+$');
                                  if (!re.hasMatch(v)) {
                                    return 'Solo a-z, 0-9 y _';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: LabeledTextField(
                                controller: _telefonoController,
                                label: 'Teléfono',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value != null &&
                                      value.trim().isNotEmpty &&
                                      value.length < 9) {
                                    return 'Min 9 dígitos';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DateField(
                          dateText: _formatDate(_fechaNacimiento),
                          onTap: _selectFechaNacimiento,
                        ),
                        const SizedBox(height: 24),
                        const SectionTitle(
                          icon: Icons.info_outline,
                          title: 'Información Adicional',
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: DropdownField(
                                label: 'Género',
                                icon: Icons.wc_outlined,
                                value: _genero,
                                horizontalPadding: 14,
                                items: const [
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
                                onChanged: (value) {
                                  setState(() {
                                    _genero = value!;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownField(
                                label: 'Nivel',
                                icon: Icons.sports_soccer,
                                value: _nivelHabilidad,
                                horizontalPadding: 14,
                                items: const [
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
                                onChanged: (value) {
                                  setState(() {
                                    _nivelHabilidad = value!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const SectionTitle(
                          icon: Icons.sports,
                          title: 'Deportes Favoritos',
                        ),
                        if (context
                            .watch<EditPerfilViewModel>()
                            .loadingDeportes)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('Cargando deportes...'),
                              ],
                            ),
                          )
                        else if (context
                                .watch<EditPerfilViewModel>()
                                .deportesError !=
                            null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  context
                                      .watch<EditPerfilViewModel>()
                                      .deportesError!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        DeportesSelectorCard(
                          deportesFavoritos: _deportesFavoritos,
                          onOpenSelector: () => _showDeportesSelector(context),
                          onRemoveDeporte: (dep) {
                            setState(() {
                              _deportesFavoritos.remove(dep);
                            });
                          },
                          getDeporteIcon: _getDeporteIcon,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: (_isSaving) ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Guardar Cambios',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
