import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:safe_driving_app/class/index.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/providers/route.dart';
import 'package:safe_driving_app/utils/constants.dart';
import 'package:safe_driving_app/utils/endpoints.dart';
// import 'package:safe_driving_app/utils/storage.dart';
import 'package:safe_driving_app/utils/root/index.dart';
import 'package:safe_driving_app/utils/storage.dart';
import 'package:safe_driving_app/utils/style.dart';
import 'package:http/http.dart' as http;

class SelectDestinationPage extends StatefulWidget {
  const SelectDestinationPage({super.key});

  @override
  State<SelectDestinationPage> createState() => _SelectDestinationPageState();
}

class _SelectDestinationPageState extends State<SelectDestinationPage> {
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

  bool changeInputs = true;

  final _formKeyText = GlobalKey<FormBuilderState>();
  final _formKeyTextManual = GlobalKey<FormBuilderState>();
  final _textInpuController = TextEditingController();
  final _textInpuManualController = TextEditingController();

  List<DirectionDto> list = [];
  List<String> results = [SELECTDESTINATION.TEXT_TOP_LIST];
  final _formKeyResults = GlobalKey<FormBuilderState>();

  String? coordinateText;

  Timer? _timer;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    printStorage();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancelar el temporizador antes de salir de la página
    super.dispose();
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
                Expanded(child: Container()),
                ...inputsAuto(context),
                Expanded(child: Container()),
                SizedBox(
                  width: getWidth(context, 90),
                  height: getHeight(context, 50),
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
                MaterialButton(
                  onPressed: () async {
                    print('blockNextButton: $blockNextButton');
                    print('position $position');
                    print(
                        'root.finalPosition: ${position.latitude},${position.longitude}');

                    await writeStorage(
                        'root.finalPosition',
                        json.encode({
                          'latitude': position.latitude,
                          'longitude': position.longitude
                        }));

                    if (blockNextButton) {
                      setState(() {
                        Navigator.pushNamed(context, '/root/speedometer');
                      });
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  color: blockNextButton
                      ? CustomColors.primary
                      : CustomColors.primaryOff,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: getHeight(context, 12), vertical: 16),
                    child: Text(
                      SELECTSOURCE.TEXT_BUTTON,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(
                  height: getHeight(context, 3),
                )
              ],
            )));
  }

  inputsAuto(context) {
    return changeInputs
        ? [
            SizedBox(
              width: getWidth(context, 90),
              child: textInput(),
            ),
            Expanded(child: Container()),
            SizedBox(
              width: getWidth(context, 90),
              child: listResult(),
            ),
          ]
        : [
            SizedBox(
              width: getWidth(context, 90),
              child: textInputManual(context),
            )
          ];
  }

  AppBar header(BuildContext context) {
    return AppBar(
      title: Text(SELECTDESTINATION.TEXT_HEADER,
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          )),
      centerTitle: true,
      elevation: 0.0,
      backgroundColor: Colors.white,
      leading: Builder(
        builder: (context) => IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/menu');
            },
            icon: Icon(Icons.home),
            color: Colors.black,
            tooltip: 'Salir del registro de ruta'),
      ),
      actions: <Widget>[
        IconButton(
          icon: Icon(
            Icons.input,
            color: Colors.black,
          ),
          onPressed: () {
            setState(() => changeInputs = !changeInputs);
          },
        )
      ],
    );
  }

  Widget _crearMapa() {
    return FlutterMap(
      mapController: map,
      options: MapOptions(
        zoom: 10.0,
        maxZoom: 18.0,
        minZoom: 10.0,
        center: LatLng(-12.047933614518184, -77.06337978247707),
        onTap: _handleMapTap,
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

  void _handleMapTap(_, LatLng tappedPoint) {
    setState(() {
      position = Position(
          longitude: tappedPoint.longitude,
          latitude: tappedPoint.latitude,
          timestamp: null,
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0);

      blockNextButton = true;
      blockIconMovePosition = true;
    });
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

  FormBuilder textInputManual(context) {
    return FormBuilder(
      key: _formKeyTextManual,
      child: Column(
        children: [
          FormBuilderTextField(
              name: 'textManual',
              onChanged: (value) {
                if (value != null && value != '') {
                  coordinateText = value;
                }
              },
              decoration: InputDecoration(
                enabled: true,
                labelText: 'Ingrese las coordenadas',
                // hintText: 'ejem 75652679',
                // errorText: 'Colocar un DNI valido',
                filled: true,
                fillColor: Colors.blue.shade100,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              keyboardType: TextInputType.text,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.singleLineFormatter
              ],
              controller: _textInpuManualController,
              validator: (value) {
                print(value);
                if (value == null || value.isEmpty) {
                  return 'Se requiere el documento de indentidad';
                }
                return null;
              }),
          SizedBox(
            height: 5,
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            ElevatedButton(
              child: const Text('Buscar'),
              onPressed: () {
                if (coordinateText != null) {
                  EasyLoading.show(status: 'Buscando coordenadas...');
                  try {
                    var raw = coordinateText!.split(',');

                    if (raw.length == 1) {
                      throw Exception('No se tiene las coordenadas correctas');
                    }

                    position = Position(
                      longitude: double.parse(raw[1].trim()),
                      latitude: double.parse(raw[0].trim()),
                      timestamp: null,
                      accuracy: 0,
                      altitude: 0,
                      heading: 0,
                      speed: 0,
                      speedAccuracy: 0,
                      altitudeAccuracy: 0,
                      headingAccuracy: 0,
                    );

                    setState(() {
                      map.move(
                          LatLng(position.latitude, position.longitude), 18);
                      blockIconMovePosition = true;
                      blockNextButton = true;

                      FocusManager.instance.primaryFocus
                          ?.unfocus(); // close keyboard
                    });
                  } catch (e) {
                    print('search coordinate Text: $e');
                    notificationError(
                        context, 'Has ingresado una coordenada incorrecta');
                  }

                  EasyLoading.dismiss();
                }
              },
            ),
            SizedBox(
              width: 20,
            ),
            ElevatedButton(
              child: const Text('Limpiar'),
              onPressed: () {
                print('limpia');
                _textInpuManualController.clear();
              },
            ),
          ]),
        ],
      ),
    );
  }

  FormBuilder textInput() {
    return FormBuilder(
      key: _formKeyText,
      child: FormBuilderTextField(
          name: 'text',
          onChanged: _handleTextChanged,
          decoration: InputDecoration(
            enabled: true,
            labelText: 'Escoja su destino',
            // hintText: 'ejem 75652679',
            // errorText: 'Colocar un DNI valido',
            filled: true,
            fillColor: Colors.blue.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          keyboardType: TextInputType.text,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.singleLineFormatter
          ],
          controller: _textInpuController,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Se requiere el documento de indentidad';
            }
            return null;
          }),
    );
  }

  listResult() {
    return FormBuilder(
        key: _formKeyResults,
        child: FormBuilderDropdown<String>(
          name: 'results',
          decoration: InputDecoration(
              labelText: 'Resultados de la busqueda',
              filled: true,
              fillColor: Colors.blue.shade100,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          onChanged: (value) {
            if (value != null &&
                value != '' &&
                value != SELECTDESTINATION.TEXT_TOP_LIST) {
              var direction =
                  list.firstWhere((element) => element.direction == value);

              writeStorage('root.address', value);

              position = Position(
                  longitude: double.parse(direction.longitude),
                  latitude: double.parse(direction.latitude),
                  timestamp: null,
                  accuracy: 0,
                  altitude: 0,
                  heading: 0,
                  speed: 0,
                  speedAccuracy: 0,
                  altitudeAccuracy: 0,
                  headingAccuracy: 0);

              setState(() {
                map.move(LatLng(position.latitude, position.longitude), 18);
                blockIconMovePosition = true;
                blockNextButton = true;
              });
            }
            // else {
            //   setState(() {
            //     blockIconMovePosition = false;
            //     blockNextButton = false;
            //     position = Position(
            //         longitude: -77.06337978247707,
            //         latitude: -12.047933614518184,
            //         timestamp: null,
            //         accuracy: 0,
            //         altitude: 0,
            //         heading: 0,
            //         speed: 0,
            //         speedAccuracy: 0);
            //     map.move(LatLng(position.latitude, position.longitude), 18);
            //   });
            // }
          },
          items: results
              .map((item) => DropdownMenuItem(
                    alignment: AlignmentDirectional.center,
                    value: item,
                    child: Text(
                      item,
                      style: TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 16,
                      ),
                    ),
                  ))
              .toList(),
        ));
  }

  Future<List<DirectionDto>> searchDirection(direction) async {
    print('searchDirection: $direction');

    var url = Uri.http(ENDPOINTS.HOST, ENDPOINTS.GET_LOCATION);

    var response = await http.post(url,
        body: json.encode({
          'address': direction,
        }),
        headers: {
          "Content-Type": "application/json",
          "Authorization": ENDPOINTS.auth()
        });
    Map<String, dynamic> data = json.decode(response.body);

    if (response.statusCode != STATUSCODE.OK) {
      setState(() =>
          notificationInfo(context, 'No se encontro la ubicación 😔', () {}));
      throw Exception('No se encontra la ubicación');
    }

    var directionsObjsJson = data['results'][0];

    // print([directionsObjsJson].isEmpty);
    // if ([directionsObjsJson].isEmpty) {
    //   return listDefault;
    // }

    List<DirectionDto> formatList = [directionsObjsJson]
        .map((tagJson) => DirectionDto.fromJson(tagJson))
        .toList();

    return formatList;
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer(Duration(seconds: 2), () {
      inputSearchDirection(_searchText);
    });
  }

  void _handleTextChanged(text) {
    setState(() {
      _searchText = text;
    });

    _startTimer();
  }

  inputSearchDirection(value) async {
    try {
      print('inputSearchDirection: $value');

      if (value != null && value != '' && value is String && value.length > 3) {
        FocusManager.instance.primaryFocus?.unfocus();

        EasyLoading.show(status: 'Buscando destino...');

        list = await searchDirection(value);

        if (list.isNotEmpty) {
          _formKeyResults.currentState!.fields['results']?.reset();

          List<DirectionDto> formatList = removeDuplicatesDirectionDto(list);

          results = [SELECTDESTINATION.TEXT_TOP_LIST];

          setState(() {
            for (var element in formatList) {
              results.add(element.direction);
            }
          });
        }

        EasyLoading.dismiss();
      }
    } catch (e) {
      print('inputSearchDirection: $e');
    }
    EasyLoading.dismiss();
  }
}
