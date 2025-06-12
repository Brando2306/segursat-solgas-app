import 'dart:convert';

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/helpers/gps.dart';

// import 'package:safe_driving_app/utils/storage.dart';
import 'package:safe_driving_app/utils/root/index.dart';
import 'package:safe_driving_app/utils/storage.dart';
import 'package:safe_driving_app/widgets/header.dart';
import 'package:safe_driving_app/widgets/next_button.dart';

class SelectSourcePage extends StatefulWidget {
  const SelectSourcePage({super.key});

  @override
  State<SelectSourcePage> createState() => _SelectSourcePageState();
}

class _SelectSourcePageState extends State<SelectSourcePage> {
  MapController map = MapController();
  Position position = Position(
      longitude: 0,
      latitude: 0,
      timestamp: null,
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0);

  bool blockIconMovePosition = false;
  bool blockNextButton = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    cleanRoot();
    _getLocation();
    printStorage();
    writeStorage('root.departureDate', DateTime.now().toString());
    writeStorage('root.initialDate', getDate());
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
            appBar: header(context),
            resizeToAvoidBottomInset: false,
            body: Column(
              children: [
                Container(
                  width: getWidth(context, 90),
                  height: getHeight(context, 75),
                  child: Stack(children: [
                    Align(
                      child: _crearMapa(),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: _centerPosition(),
                    )
                  ]),
                ),
                Expanded(child: Container()),
                blockNextButton
                    ? nextButton(context, SELECTSOURCE.TEXT_BUTTON,
                        '/root/selectDestination', blockNextButton, () {}, null)
                    : Container(),
                SizedBox(
                  height: getHeight(context, 3),
                )
              ],
            )));
  }

  AppBar header(BuildContext context) {
    return headerV2(
        SELECTSOURCE.TEXT_HEADER,
        Builder(
          builder: (context) => IconButton(
              onPressed: () {
                // cleanQuestionStorage();
                Navigator.pushNamed(context, '/menu');
              },
              icon: Icon(Icons.home),
              color: Colors.black,
              tooltip: 'Salir del registro de ruta'),
        ));
  }

  Widget _crearMapa() {
    return FlutterMap(
      mapController: map,
      options: MapOptions(
        zoom: 10.0,
        maxZoom: 18.0,
        minZoom: 10.0,
        center: LatLng(-12.047933614518184, -77.06337978247707),
        rotation: 0.0,
      ),
      children: [_cargarTemplate(), _myMarker()],
    );
  }

  TileLayer _cargarTemplate() {
    return TileLayer(
      urlTemplate:
          'https://mt0.google.com/vt/lyrs=m&hl=en&x={x}&y={y}&z={z}&s=Ga',
      subdomains: const ['a', 'b', 'c'],
    );
  }

  void _getLocation() async {
    EasyLoading.show(status: 'Buscando...');

    try {
      position = await determinePosition();

      setState(() {
        map.move(LatLng(position.latitude, position.longitude), 18);
        writeStorage(
            'root.initialPosition',
            json.encode({
              'latitude': position.latitude,
              'longitude': position.longitude
            }));
        blockIconMovePosition = true;
        blockNextButton = true;
      });
    } catch (e) {
      print('Error ===> $e');
      await _checkGps();
    }

    EasyLoading.dismiss();
  }

  Future<void> _checkGps() async {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Aviso",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Icon(
                  Icons.location_off,
                  color: Colors.red,
                  size: 48,
                ),
              ),
              Text(
                'Por favor, activa tu GPS para continuar. Esto es esencial para brindarte la mejor experiencia.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/menu');
              },
              style: ElevatedButton.styleFrom(primary: Colors.grey),
              child: Text('Ir al Menú'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
                _getLocation();
              },
              style: ElevatedButton.styleFrom(primary: Colors.blue),
              child: Text('Reintentar'),
            ),
          ],
        );
      },
    );
  }

  MarkerLayer _myMarker() {
    return MarkerLayer(markers: <Marker>[
      Marker(
          width: 100.0,
          height: 100.0,
          point: LatLng(position.latitude, position.longitude),
          builder: (context) {
            return Container(
              child: Icon(
                Icons.location_on,
                size: 50,
                color: Colors.blue[900],
              ),
            );
          }),
    ]);
  }

  Container _centerPosition() {
    return Container(
      width: 50,
      margin: EdgeInsets.all(7),
      child: FloatingActionButton(
        backgroundColor: Color(0xFF2e4792),
        onPressed: () {
          print(position);
          if (blockIconMovePosition) {
            setState(() {
              map.move(LatLng(position.latitude, position.longitude), 18);
            });
          }
        },
        child: Icon(Icons.gps_fixed),
      ),
    );
  }
}
