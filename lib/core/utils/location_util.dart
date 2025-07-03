import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safe_driving_app/utils/storage.dart';

class LocationUtils {
  static Future<bool> checkLocationPermission() async {
    final status = await Geolocator.checkPermission();
    if (status == LocationPermission.denied) {
      final requestedStatus = await Geolocator.requestPermission();
      return requestedStatus == LocationPermission.always ||
          requestedStatus == LocationPermission.whileInUse;
    }
    return status == LocationPermission.always ||
        status == LocationPermission.whileInUse;
  }

  static Future<void> showLocationSettingsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubicación desactivada'),
        content: const Text(
            'Para usar esta aplicación, necesitas activar la ubicación.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await writeStorage('personal.pushRouteSpeedometer', true);
              await AppSettings.openAppSettings(type: AppSettingsType.location);
              Navigator.pop(context);
            },
            child: const Text('Abrir configuración'),
          ),
        ],
      ),
    );
  }
}
