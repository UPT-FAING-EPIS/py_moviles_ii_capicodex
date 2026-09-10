import 'package:flutter/material.dart';

class DeportesSelectorSheet extends StatefulWidget {
  final List<String> disponibles;
  final Set<String> seleccionados;
  final IconData Function(String deporte) getDeporteIcon;
  final void Function(Set<String> seleccion) onConfirm;

  const DeportesSelectorSheet({
    super.key,
    required this.disponibles,
    required this.seleccionados,
    required this.getDeporteIcon,
    required this.onConfirm,
  });

  @override
  State<DeportesSelectorSheet> createState() => _DeportesSelectorSheetState();
}

class _DeportesSelectorSheetState extends State<DeportesSelectorSheet> {
  late Set<String> _seleccionTemporal;

  @override
  void initState() {
    super.initState();
    _seleccionTemporal = {...widget.seleccionados};
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Selecciona tus deportes',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: widget.disponibles.length,
              itemBuilder: (context, index) {
                final deporte = widget.disponibles[index];
                final isSelected = _seleccionTemporal.contains(deporte);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _seleccionTemporal.remove(deporte);
                          } else {
                            _seleccionTemporal.add(deporte);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.green.shade50
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.green.shade700
                                : Colors.grey.shade200,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              widget.getDeporteIcon(deporte),
                              color: isSelected
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                              size: 28,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                deporte,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.green.shade700
                                      : Colors.black87,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: Colors.green.shade700,
                                size: 24,
                              )
                            else
                              Icon(
                                Icons.circle_outlined,
                                color: Colors.grey.shade400,
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  widget.onConfirm(_seleccionTemporal);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Confirmar (${_seleccionTemporal.length} seleccionados)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
