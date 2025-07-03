class LocationValidator {
  static String? validateLatitude(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingrese latitud';
    }
    final lat = double.tryParse(value);
    if (lat == null || lat < -90 || lat > 90) {
      return 'Latitud inválida (-90 a 90)';
    }
    return null;
  }

  static String? validateLongitude(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingrese longitud';
    }
    final lng = double.tryParse(value);
    if (lng == null || lng < -180 || lng > 180) {
      return 'Longitud inválida (-180 a 180)';
    }
    return null;
  }
}
