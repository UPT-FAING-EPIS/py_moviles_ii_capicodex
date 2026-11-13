/// Valida una ubicación registrada. El par (0, 0) indica una ubicación sin configurar.
bool validarCoordenadas(num? latitud, num? longitud) {
  if (latitud == null || longitud == null) return false;
  final lat = latitud.toDouble();
  final lng = longitud.toDouble();
  if (lat.isNaN || lng.isNaN || lat.isInfinite || lng.isInfinite) {
    return false;
  }
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
    return false;
  }
  if (lat == 0 && lng == 0) return false;
  return true;
}
