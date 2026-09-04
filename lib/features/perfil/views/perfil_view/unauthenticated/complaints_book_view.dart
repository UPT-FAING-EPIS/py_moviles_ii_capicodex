import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gameon/features/perfil/services/email_service.dart';

class ComplaintsBookView extends StatefulWidget {
  const ComplaintsBookView({super.key});

  @override
  State<ComplaintsBookView> createState() => _ComplaintsBookViewState();
}

class _ComplaintsBookViewState extends State<ComplaintsBookView> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'Reclamo'; // Reclamo vs Queja

  // Controllers
  final _nameController = TextEditingController();
  final _docNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _detailController = TextEditingController();

  final _emailService = EmailService();
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _docNumberController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _loading = true);

      final success = await _emailService.sendComplaint(
        name: _nameController.text,
        docType: 'DNI', // Simplificación por ahora
        docNumber: _docNumberController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        type: _type,
        detail: _detailController.text,
      );

      if (!mounted) return;
      setState(() => _loading = false);

      if (success) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Envío Exitoso'),
            content: const Text(
              'Tu hoja de reclamación ha sido enviada correctamente. Te enviaremos una copia a tu correo electrónico.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back
                },
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al enviar. Inténtalo de nuevo.'),
            backgroundColor: Colors.red,
          ),
        );
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Column(
          children: [
            // Header
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
                                  'Libro de Reclamaciones',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Hoja de Reclamación Virtual',
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
            // Formulario
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('1. Identificación del Consumidor'),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _nameController,
                        label: 'Nombre Completo',
                        icon: Icons.person_outline,
                        validator: (v) =>
                            v?.isEmpty == true ? 'Campo requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildDropdown(
                              items: ['DNI', 'CE', 'Pasaporte'],
                              value: 'DNI',
                              onChanged: (_) {},
                              label: 'Tipo',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: _buildTextField(
                              controller: _docNumberController,
                              label: 'Nro. Documento',
                              icon: Icons.badge_outlined,
                              keyboardType: TextInputType.number,
                              validator: (v) =>
                                  v?.isEmpty == true ? 'Requerido' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) =>
                            v?.isEmpty == true ? 'Campo requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Teléfono',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _addressController,
                        label: 'Dirección',
                        icon: Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('2. Detalle de la Reclamación'),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            RadioListTile<String>(
                              title: const Text('Reclamo'),
                              subtitle: const Text(
                                'Disconformidad con los bienes o servicios.',
                                style: TextStyle(fontSize: 12),
                              ),
                              value: 'Reclamo',
                              groupValue: _type,
                              activeColor: Colors.green,
                              onChanged: (v) => setState(() => _type = v!),
                            ),
                            Divider(height: 1, color: Colors.grey.shade200),
                            RadioListTile<String>(
                              title: const Text('Queja'),
                              subtitle: const Text(
                                'Malestar respecto a la atención al público.',
                                style: TextStyle(fontSize: 12),
                              ),
                              value: 'Queja',
                              groupValue: _type,
                              activeColor: Colors.green,
                              onChanged: (v) => setState(() => _type = v!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _detailController,
                        label: 'Detalle del ${_type.toLowerCase()}',
                        icon: Icons.description_outlined,
                        maxLines: 5,
                        validator: (v) => v?.isEmpty == true
                            ? 'Por favor detalla tu caso'
                            : null,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Enviar Hoja de Reclamación',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: maxLines == 1 ? Icon(icon, color: Colors.grey) : null,
        alignLabelWithHint: maxLines > 1,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade600, width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required List<String> items,
    required String value,
    required ValueChanged<String?> onChanged,
    required String label,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade600, width: 2),
        ),
      ),
    );
  }
}
