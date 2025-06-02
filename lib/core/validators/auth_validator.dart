import 'package:safe_driving_app/utils/constants.dart';

class AuthValidator {
  static String? validateDocument(String? value) {
    if (value == null || value.isEmpty) return SESION.REQUIRED_DOCUMEND;
    return null;
  }

  static String? validateLicensePlate(String? value) {
    if (value == null || value.isEmpty) return SESION.REQUIRED_LICENSEPLATE;
    final regExp = RegExp(r'^[a-zA-Z0-9]{3}-[a-zA-Z0-9]{3}$');
    if (!regExp.hasMatch(value)) return 'Formato de placa inválido';
    return null;
  }
}
