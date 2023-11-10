import 'dart:async';
import 'dart:convert';

import 'package:floating/floating.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/helpers/gps.dart';
import 'package:safe_driving_app/providers/index.dart';
import 'package:safe_driving_app/providers/route.dart';
import 'package:safe_driving_app/utils/constants.dart';
import 'package:safe_driving_app/utils/endpoints.dart';
import 'package:safe_driving_app/utils/storage.dart';
import 'package:safe_driving_app/utils/style.dart';
import 'package:safe_driving_app/widgets/next_button.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class SpeedometerPage extends StatefulWidget {
  const SpeedometerPage({super.key});

  @override
  _SpeedometerPageState createState() => _SpeedometerPageState();
}

class _SpeedometerPageState extends State<SpeedometerPage>
    with WidgetsBindingObserver {
  // StreamSubscription
  StreamSubscription<Position>? positionStream;
  late LocationSettings locationSettings;
  double _value = 0;

  // Date now
  var time = DateTime.now();
  late Timer _timerDateNow;

  final floating = Floating();

  // Cromometer
  Duration _currentTime = Duration.zero;
  late Timer _timer;

  bool buttonFinish = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    createOrResumeRoute();

    // POSITION STREAM
    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 0,
          intervalDuration: const Duration(seconds: 3),
          //(Optional) Set foreground notification config to keep the app alive
          //when going to the background
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationText:
                "La aplicación continuará recibiendo tu ubicación incluso cuando no la estés utilizando",
            notificationTitle: "Corriendo en segundo plano",
            enableWakeLock: true,
          ));
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.fitness,
        distanceFilter: 100,
        pauseLocationUpdatesAutomatically: true,
        // Only set to true if our app will be started up in the background.
        showBackgroundLocationIndicator: false,
      );
    } else {
      locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      );
    }

    positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position? position) async {
      writeStorage(
          'root.currentPosition',
          json.encode({
            'latitude': position!.latitude,
            'longitude': position.longitude
          }));

      if (readStorage('root.createRoute.id') != null) {
        // var finalPosition = json.decode(readStorage('root.finalPosition'));

        await registerPositions([
          {
            "routeid": readStorage('root.createRoute.id'),
            "timestamp": getDate(),
            "latitude": position.latitude,
            "longitude": position.longitude,
            "altitude": position.altitude,
            "speed": position.speed.round(),
            "angle": _currentTime.inSeconds,
            // "attributes": json.encode({
            //   'rootFinalPosition': {
            //     'latitude': finalPosition['latitude'],
            //     'longitude': finalPosition['longitude']
            //   }
            // }),
            "unitid": readStorage('personal.unitId')
          }
        ]);
      }

      setState(() => _value = position.speed * 3.6);

      // if ((_value).round() > 100) await showNotification();
    });

    dateNow();
    _initialize();

    printStorage();
  }

  void createOrResumeRoute() async {
    print('==> createOrResumeRoute');
    try {
      if (isNotEmptyString(readStorage('root.cronometer')) &&
          isNotEmptyString(readStorage('root.finalPosition'))) {
        if (isNotEmptyString(readStorage('personal.lastRoute'))) {
          writeStorage(
              'root.createRoute.id', readStorage('personal.lastRoute'));
          print('RESUME ROUTE: ${readStorage('root.createRoute.id')}');
        }
      } else {
        print('createOrResumeRoute: New route');
        Map<String, dynamic> route = await createRoute();
        writeStorage('root.createRoute.id', route['id']);
      }

      print('root.createRoute.id ${readStorage('root.createRoute.id')}');
    } catch (e) {
      print(e);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    stopLocationUpdates();

    super.dispose();
  }

  void _initialize() {
    int savedTime = readStorage('root.cronometer') ?? 0;
    _currentTime = Duration(seconds: savedTime);

    _timer = Timer.periodic(Duration(seconds: 1), _updateTime);
  }

  void _updateTime(Timer timer) {
    setState(() {
      _currentTime = _currentTime + Duration(seconds: 1);
      writeStorage('root.cronometer', _currentTime.inSeconds);
    });
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) {
      if (n >= 10) return "$n";
      return "0$n";
    }

    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));

    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return PiPSwitcher(
        childWhenEnabled: sfRadialGaugeMin(),
        childWhenDisabled: WillPopScope(
            onWillPop: () async => false,
            child: Scaffold(
              appBar: AppBar(
                title: Text('Velocímetro',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    )),
                centerTitle: true,
                elevation: 0.0,
                backgroundColor: Colors.white,
                leading: Container(),
                actions: [
                  Padding(
                      padding: EdgeInsets.only(right: 20.0),
                      child: GestureDetector(
                        onTap: () async {
                          final canUsePiP = await floating.isPipAvailable;
                          if (canUsePiP) {
                            final statusAfterEnabling = await floating.enable();
                            print(statusAfterEnabling);
                          }
                        },
                        child: Icon(
                          Icons.photo_size_select_large,
                          size: 30,
                          color: Colors.black,
                        ),
                      )),
                ],
              ),
              body: Column(
                children: [
                  SizedBox(
                    height: getHeight(context, 3),
                  ),
                  Row(children: [
                    Expanded(child: Container()),
                    alertButton(context),
                    Expanded(child: Container()),
                    stopButton(),
                    Expanded(child: Container()),
                  ]),
                  Expanded(child: Container()),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                          // '${time.day}/${time.month}/${time.year} ${time.hour}:${time.minute}:${time.second}',
                          DateFormat('dd/MM/yyyy HH:mm:ss').format(time),
                          style: TextStyle(
                              fontSize: 25,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.bold))
                    ],
                  ),
                  Expanded(child: Container()),
                  sfRadialGauge(),
                  Expanded(child: Container()),
                  nextButton(
                      context, 'Realizar parada', '/root/controlStop', true,
                      () {
                    stopLocationUpdates();
                  }, 11),
                  SizedBox(
                    height: getHeight(context, 3),
                  ),
                  // nextButton(context, 'Finalizar ruta', '/root/finish', true,
                  //     () async {
                  //   stopLocationUpdates();
                  //   try {
                  //     Map<String, dynamic> currentPosition =
                  //         json.decode(readStorage('root.currentPosition'));
                  //     Map<String, dynamic> finalPosition =
                  //         json.decode(readStorage('root.finalPosition'));

                  //     int metros = calcularDistanciaEnMetros(
                  //         currentPosition['latitude'],
                  //         currentPosition['longitude'],
                  //         finalPosition['latitude'],
                  //         finalPosition['longitude']);

                  //     if (metros < 100) {
                  //       await finishRoute(context);
                  //     } else {
                  //       showConfirmationDialog(context);
                  //     }
                  //   } catch (e) {
                  //     notificationError(context, e.toString());
                  //   }
                  // }, null),
                  MaterialButton(
                    onPressed: () async {
                      try {
                        Map<String, dynamic> currentPosition =
                            json.decode(readStorage('root.currentPosition'));
                        Map<String, dynamic> finalPosition =
                            json.decode(readStorage('root.finalPosition'));

                        int metros = calcularDistanciaEnMetros(
                            currentPosition['latitude'],
                            currentPosition['longitude'],
                            finalPosition['latitude'],
                            finalPosition['longitude']);

                        if (metros < 100) {
                          await finishRoute(context);
                        } else {
                          showConfirmationDialog(context);
                        }
                      } catch (e) {
                        notificationError(context, e.toString());
                      }
                      // if (validation) {
                      //   function();
                      //   if (route != null) {
                      //     Navigator.pushNamed(context, route);
                      //   }
                      // }
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    color: buttonFinish
                        ? CustomColors.primary
                        : CustomColors.primaryOff,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: getHeight(context, 12), vertical: 16),
                      child: Text(
                        'Finalizar ruta',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: getHeight(context, 3),
                  )
                ],
              ),
            )));
  }

  void showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async {
            return false; // Evita que el modal se cierre al tocar fuera de él
          },
          child: AlertDialog(
            title: Text(
              'Confirmación',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            content: Text(
              'La unidad aún no ha llegado a su destino. ¿Está seguro que desea finalizar la ruta?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  // Navigator.pushNamed(context, '/root/speedometer');
                  // Navigator.pushNamed(context, '/root/speedometer');
                },
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red, // Color de botón de cancelar
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  // Navigator.of(context, rootNavigator: true).pop();

                  await finishRoute(context);
                },
                child: Text(
                  'Aceptar',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.green, // Color de botón de aceptar
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> finishRoute(context) async {
    setState(() => buttonFinish = false);

    Map<String, dynamic>? response;

    EasyLoading.show(status: 'Enviando...');

    try {
      String? rootType = readStorage('root.type');

      print(rootType);

      if (rootType == null) {
        response = await finishRouteProvider();
        print('finishRouteProvider.response: $response');
      } else {
        response = await cancelRouteProvider();
        print('cancelRouteProvider.response: $response');
      }

      if (response['status'] == STATUSCODE.OK) {
        stopLocationUpdates();
        cleanQuestionStorage();
        cleanResumeRoute();
        cleanRoot();
        cleanRootRecurringStop();

        EasyLoading.dismiss();

        // Navigator.pushNamed(context, '/menu');
        // await _showArrivedDialog(context);
        Navigator.pushNamed(context, '/root/finish');
      } else {
        notificationAlert(context, handleApiError(response));

        setState(() => buttonFinish = true);
      }
    } catch (e) {
      notificationError(context, e.toString());

      setState(() => buttonFinish = true);
    }

    EasyLoading.dismiss();
  }

  // Future<void> _showArrivedDialog(BuildContext context) async {
  //   notificationInfo(context, 'La unidad ha llegado a su destino.', () {
  //     setState(() {
  //       Navigator.pushNamed(context, '/menu');
  //     });
  //   });
  // }

  void stopLocationUpdates() {
    positionStream?.cancel();

    _timer.cancel();

    _timerDateNow.cancel();
  }

  setLocationSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 0,
          intervalDuration: const Duration(seconds: 3),
          //(Optional) Set foreground notification config to keep the app alive
          //when going to the background
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationText:
                "La aplicación continuará recibiendo tu ubicación incluso cuando no la estés utilizando",
            notificationTitle: "Corriendo en segundo plano",
            enableWakeLock: true,
          ));
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.fitness,
        distanceFilter: 100,
        pauseLocationUpdatesAutomatically: true,
        // Only set to true if our app will be started up in the background.
        showBackgroundLocationIndicator: false,
      );
    } else {
      locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      );
    }
  }

  notificationSoS(context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Confirmación",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 9, 43, 145),
            ),
          ),
          content: Text('Está seguro que quiere finalizar la ruta.'),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
                writeStorage('root.type', ROOT_TYPE.SOS);
                stopLocationUpdates();
                Navigator.pushNamed(context, '/root/finish');
              },
              style: ElevatedButton.styleFrom(primary: Colors.green),
              child: Text('Confirmar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
              },
              style: ElevatedButton.styleFrom(primary: Colors.deepOrange),
              child: Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Column alertButton(context) {
    return Column(
      children: [
        MaterialButton(
          onPressed: () => notificationSoS(context),
          color: Colors.red,
          textColor: Colors.white,
          child: FaIcon(
            FontAwesomeIcons.warning,
            color: Colors.white,
            size: 25,
          ),
          padding: EdgeInsets.all(16),
          shape: CircleBorder(),
        ),
        SizedBox(
          height: 5,
        ),
        Text('SOS', style: TextStyle(fontWeight: FontWeight.bold))
      ],
    );
  }

  Column stopButton() {
    return Column(
      children: [
        MaterialButton(
          onPressed: () {
            writeStorage('root.type', ROOT_TYPE.SOS);
            stopLocationUpdates();
            Navigator.pushNamed(context, '/root/incidentReport');
          },
          color: Colors.amber,
          textColor: Colors.white,
          child: FaIcon(
            FontAwesomeIcons.circleStop,
            color: Colors.white,
            size: 25,
          ),
          padding: EdgeInsets.all(16),
          shape: CircleBorder(),
        ),
        SizedBox(
          height: 5,
        ),
        Text('Incidencia', style: TextStyle(fontWeight: FontWeight.bold))
      ],
    );
  }

  void labelCreated(AxisLabelCreatedArgs args) {
    if (args.text == '0') {
      args.text = 'N';
      args.labelStyle = GaugeTextStyle(
          color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14);
    } else if (args.text == '10')
      args.text = '';
    else if (args.text == '20')
      args.text = 'E';
    else if (args.text == '30')
      args.text = '';
    else if (args.text == '40')
      args.text = 'S';
    else if (args.text == '50')
      args.text = '';
    else if (args.text == '60')
      args.text = 'W';
    else if (args.text == '70') args.text = '';
  }

  Future<Position> _determinePosition() async {
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

    return await Geolocator.getCurrentPosition();
  }

  void dateNow() {
    _timerDateNow =
        Timer.periodic(const Duration(milliseconds: 1000), (timerLocal) async {
      setState(() {
        time = DateTime.now();
      });
    });
  }

  SfRadialGauge sfRadialGauge() {
    return SfRadialGauge(axes: <RadialAxis>[
      RadialAxis(
        minimum: 0,
        maximum: 200,
        labelOffset: 30,
        axisLineStyle:
            AxisLineStyle(thicknessUnit: GaugeSizeUnit.factor, thickness: 0.03),
        majorTickStyle:
            MajorTickStyle(length: 6, thickness: 4, color: Colors.black),
        minorTickStyle:
            MinorTickStyle(length: 3, thickness: 3, color: Colors.black),
        axisLabelStyle: GaugeTextStyle(
            color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
        ranges: <GaugeRange>[
          GaugeRange(
              startValue: 0,
              endValue: 200,
              sizeUnit: GaugeSizeUnit.factor,
              startWidth: 0.03,
              endWidth: 0.03,
              gradient: SweepGradient(colors: const <Color>[
                Colors.green,
                Colors.yellow,
                Colors.red
              ], stops: const <double>[
                0.0,
                0.5,
                1
              ]))
        ],
        pointers: <GaugePointer>[
          NeedlePointer(
              value: _value,
              needleLength: 0.95,
              enableAnimation: true,
              animationType: AnimationType.ease,
              needleStartWidth: 1.5,
              needleEndWidth: 6,
              needleColor: Colors.red,
              knobStyle: KnobStyle(knobRadius: 0.09))
        ],
        annotations: <GaugeAnnotation>[
          GaugeAnnotation(
              widget: Container(
                  child: Column(children: <Widget>[
                Text('${(_value).round().toString()} KM/H',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(
                  _formatTime(_currentTime),
                  style: TextStyle(
                      fontSize: 25,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.bold),
                )
              ])),
              angle: 90,
              positionFactor: 1.75)
        ],
      ),
      // RadialAxis(
      //     startAngle: 270,
      //     endAngle: 270,
      //     minimum: 0,
      //     maximum: 80,
      //     interval: 10,
      //     radiusFactor: 0.4,
      //     onLabelCreated: labelCreated),
      // RadialAxis(
      //     startAngle: 270,
      //     endAngle: 270,
      //     minimum: 0,
      //     maximum: 80,
      //     interval: 10,
      //     radiusFactor: 0.4,
      //     showAxisLine: false,
      //     showLastLabel: false,
      //     minorTicksPerInterval: 4,
      //     majorTickStyle: MajorTickStyle(
      //         length: 8, thickness: 3, color: Colors.black),
      //     minorTickStyle: MinorTickStyle(
      //         length: 3, thickness: 1.5, color: Colors.black),
      //     axisLabelStyle: GaugeTextStyle(
      //         color: Colors.black,
      //         fontWeight: FontWeight.bold,
      //         fontSize: 14),
      //     onLabelCreated: labelCreated),
    ]);
  }

  SfRadialGauge sfRadialGaugeMin() {
    return SfRadialGauge(axes: <RadialAxis>[
      RadialAxis(
        minimum: 0,
        maximum: 200,
        labelOffset: 30,
        axisLineStyle:
            AxisLineStyle(thicknessUnit: GaugeSizeUnit.factor, thickness: 0.03),
        majorTickStyle:
            MajorTickStyle(length: 6, thickness: 4, color: Colors.black),
        minorTickStyle:
            MinorTickStyle(length: 3, thickness: 3, color: Colors.black),
        axisLabelStyle: GaugeTextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ranges: <GaugeRange>[
          GaugeRange(
              startValue: 0,
              endValue: 200,
              sizeUnit: GaugeSizeUnit.factor,
              startWidth: 0.03,
              endWidth: 0.03,
              gradient: SweepGradient(colors: const <Color>[
                Colors.green,
                Colors.yellow,
                Colors.red
              ], stops: const <double>[
                0.0,
                0.5,
                1
              ]))
        ],
        pointers: <GaugePointer>[
          NeedlePointer(
              value: _value,
              needleLength: 0.95,
              enableAnimation: true,
              animationType: AnimationType.ease,
              needleStartWidth: 1.5,
              needleEndWidth: 6,
              needleColor: Colors.red,
              knobStyle: KnobStyle(knobRadius: 0.09))
        ],
        annotations: <GaugeAnnotation>[
          GaugeAnnotation(
              widget: Container(
                  child: Column(children: <Widget>[
                SizedBox(
                  height: 10,
                ),
                Text('${(_value).round().toString()} KM/H',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ])),
              angle: 90,
              positionFactor: 1.55)
        ],
      ),
    ]);
  }

  registerPositions(List<Map<String, dynamic>> body) async {
    try {
      print('registerPositions.body ==> $body');
      var register = await createRoutePositions(body);

      print('registerPositions ==> $register');
    } catch (e) {
      print('registerPositions.error: $e');
    }
  }

  Future<Map<String, dynamic>> createRoutePositions(
      List<Map<String, dynamic>> body) async {
    var url = Uri.http(ENDPOINTS.HOST, ENDPOINTS.CREATE_ROUTE_POSITIONS);

    var response = await http.post(url,
        headers: {
          "Content-Type": "application/json",
          'Authorization': ENDPOINTS.auth(),
        },
        body: json.encode(body));

    if (response.statusCode == STATUSCODE.OK) return json.decode(response.body);

    return {};
  }
}
