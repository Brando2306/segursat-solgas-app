import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> checkGps() async {
  try {
    final permissionStatus = await Permission.locationWhenInUse.status;

    if (permissionStatus.isDenied) {
      return false;
    } else if (permissionStatus.isPermanentlyDenied) {
      return false;
    } else if (permissionStatus.isGranted) {
      print('permissionStatus.isGranted: ${permissionStatus.isGranted}');
      Position position = await determinePosition();

      return true;
    }
  } catch (e) {
    print(e);
  }

  return false;
}

Future<Position> determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  print('determinePosition: true');

  return await Geolocator.getCurrentPosition();
}

int calcularDistanciaEnMetros(double latitudOrigen, double longitudOrigen,
    double latitudDestino, double longitudDestino) {
  double distancia = Geolocator.distanceBetween(
    latitudOrigen,
    longitudOrigen,
    latitudDestino,
    longitudDestino,
  );

  // Redondear la distancia y devolverla como entero en metros.
  int distanciaEnMetros = distancia.round();
  return distanciaEnMetros;
}
