import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
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
import 'package:safe_driving_app/utils/snackbars.dart';
import 'package:safe_driving_app/utils/storage.dart';
import 'package:safe_driving_app/utils/style.dart';
import 'package:safe_driving_app/widgets/next_button.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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

  late Timer _dataSendTimer;

  late Timer _timerForInternetCheck;

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

      setState(() => _value = position.speed * 3.6);
    });

    dateNow();
    _initialize();

    printStorage();

    attemptToSendPosition();
    _dataSendTimer = Timer.periodic(
        Duration(seconds: 10), (Timer timer) => attemptToSendPosition());

    // checkConnectivity();
    // handleConnectivityCheck(); // Comprobación inicial
    checkConnectivity();
    _timerForInternetCheck =
        Timer.periodic(Duration(seconds: 10), (Timer timer) {
      checkConnectivity(); // Comprobaciones periódicas
    });
  }

  // Método para verificar la conectividad y reintentar el envío
  void checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      log('=== CONNECTION SUCCESS ===');
      retrySendingStoredPositions();
    } else {
      log('=== CONNECTION FAILED ===');
    }

  }



  void attemptToSendPosition() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    Map<String, dynamic> positionData = {
      // "id": 17312,
      // "datetime": "11/12/2023 10:00:38",
      "unitid": readStorage('personal.unitId'),
      "routeid": readStorage('root.createRoute.id'),
      // "unit_name": "APO-988",
      "timestamp": getDate(),
      "latitude": position.latitude,
      "longitude": position.longitude,
      "altitude": position.altitude,
      "speed": position.speed.round(),
      "angle": _currentTime.inSeconds,
      // "atributes": {},
      // "address": ""
    };

    try {
      await createRoutePositions([positionData]);
    } catch (e) {
      savePositionLocally(positionData);
    }
  }

  void savePositionLocally(Map<String, dynamic> positionData) async {
    log(' === REQUEST FAILED === ');

    List<String>? savedPositions =
        readStorage('savedPositions')?.cast<String>();

    if (savedPositions == null || savedPositions.isEmpty) {
      savedPositions = [];
    }
    savedPositions.add(json.encode(positionData));
    writeStorage('savedPositions', savedPositions);
    log('length === ${savedPositions.length}');
  }

  void createOrResumeRoute() async {
    try {
      if (isNotEmptyString(readStorage('root.cronometer')) &&
          isNotEmptyString(readStorage('root.finalPosition'))) {
        if (isNotEmptyString(readStorage('personal.lastRoute'))) {
          writeStorage(
              'root.createRoute.id', readStorage('personal.lastRoute'));
        }
      } else {
        Map<String, dynamic> route = await createRoute();
        writeStorage('root.createRoute.id', route['id']);
      }

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
    if (Platform.isIOS) {
      return WillPopScope(
          onWillPop: () async => false,
          child: Scaffold(
            appBar: AppBar(
              title: Text('Velocímetroyyy',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  )),
              centerTitle: true,
              elevation: 0.0,
              backgroundColor: Colors.white,
              leading: Container(),
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
                    context, 'Realizar parada', '/root/controlStop', true, () {
                  stopLocationUpdates();
                }, 11),
                SizedBox(
                  height: getHeight(context, 3),
                ),
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
          ));
    }
    return PiPSwitcher(
        childWhenEnabled: sfRadialGaugeMin(),
        childWhenDisabled: WillPopScope(
            onWillPop: () async => false,
            child: Scaffold(
              appBar: AppBar(
                title: Text('Velocímetroxx',
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
                        log('error message: ${e.toString()}');
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
                        'Finalizar rutayyy',
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

      log(rootType ?? '');

      if (rootType == null) {
        response = await finishRouteProvider();
      } else {
        response = await cancelRouteProvider();
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

  void stopLocationUpdates() {
    positionStream?.cancel();

    _timer.cancel();

    _timerDateNow.cancel();

    _dataSendTimer.cancel();

    _timerForInternetCheck.cancel();
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
      builder: (BuildContext contextDialog) {
        return AlertDialog(
          title: Text(
            "Emergencia",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 9, 43, 145),
            ),
          ),
          content: Text(
              '¿Desea comunicarse con el área de Emergencia y terminar su ruta?'),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () async {
                Navigator.of(contextDialog, rootNavigator: true).pop();

                // Intentar enviar la notificación SOS con un tiempo de espera de 5 segundos.
                try {
                  await sendCallNotification().timeout(Duration(seconds: 5));
                } catch (e) {
                  log('Error al enviar notificación SOS: $e');
                }

                await callEmergecyPhone();
                await finishRoute(context);
              },
              style: ElevatedButton.styleFrom(primary: Colors.green),
              child: Text('Sí'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
              },
              style: ElevatedButton.styleFrom(primary: Colors.deepOrange),
              child: Text('No'),
            ),
          ],
        );
      },
    );
  }

  Future<void> sendCallNotification() async {
    EasyLoading.show(status: 'Enviando notificación del evento...');

    try {
      final response = await postInsertRouteSos().timeout(Duration(seconds: 5));

      if (response['status'] == STATUSCODE.OK) {
        // Manejo exitoso
      } else {
        Snackbars.showSnackbarError('No se pudo notificar el evento');
      }
    } catch (e) {
      Snackbars.showSnackbarError('Error al enviar notificación SOS: $e');
    }

    EasyLoading.dismiss();
  }

  Future<void> callEmergecyPhone() async {
    EasyLoading.show(status: 'Obteniendo número de emergencia...');

    writeStorage('root.type', ROOT_TYPE.SOS);

    final response = await getEmergencyNumber();

    if (response['status'] == STATUSCODE.OK) {
      final url = Uri(scheme: 'tel', path: response['emergency_phone']);

      if (await canLaunchUrl(url)) {
        launchUrl(url);
      }
    }

    EasyLoading.dismiss();
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

  Future<Map<String, dynamic>> createRoutePositions(
      List<Map<String, dynamic>> positionsList) async {
    Uri url = Uri.parse(
        'http://sfdev.segursat.com/web/api/control/insert-route-positions-batch/');

    final body = jsonEncode(positionsList);

    var response = await http.post(
      url,
      body: body,
      headers: {
        "Content-Type": "application/json",
        'Authorization': ENDPOINTS.auth(),
      },
    );

    if (response.statusCode == STATUSCODE.OK) {
      log(' === REQUEST OK === ');
      return json.decode(response.body);
    }

    return {};
  }

  Future<void> retrySendingStoredPositions() async {
    List<String>? savedPositions =
        readStorage('savedPositions')?.cast<String>();

    const int batchSize = 25;

    if (savedPositions != null && savedPositions.isNotEmpty) {
      try {
        log(' === REENVIANDO POSICIONES AL REQUEST === ${savedPositions.length}');
        // Divide las posiciones guardadas en lotes
        for (int i = 0; i < savedPositions.length; i += batchSize) {
          int end = (i + batchSize < savedPositions.length)
              ? i + batchSize
              : savedPositions.length;
          List<Map<String, dynamic>> positionsList = savedPositions
              .sublist(i, end)
              .map((position) => json.decode(position) as Map<String, dynamic>)
              .toList();

          log(' === ENVIANDO POR LOTES AL REQUEST === ${positionsList.length}');

          // Intenta enviar este lote de posiciones
          await createRoutePositions(positionsList);
        }
        log(' === LIMPIANDO POSICIONES === ');
        // Si todos los lotes se han enviado con éxito, limpia el almacenamiento local
        writeStorage('savedPositions', []);
      } catch (e) {
        // Si hay un error, mantén los datos en el almacenamiento para reintentar más tarde
        log(' === ERROR AL ENVIAR LISTA DE POSICIONES AL REQUEST === ');

        // Hacemos un cast explícito después de decodificar el JSON
        List<Map<String, dynamic>> positionsList = savedPositions
            .map((position) => json.decode(position) as Map<String, dynamic>)
            .toList();

        // Convierte cada posición a una cadena JSON y vuelve a guardar la lista
        List<String> failedPositions =
            positionsList.map((position) => json.encode(position)).toList();

        writeStorage('savedPositions', failedPositions);
        log(' === POSICIONES GUARDADAS NUEVAMENTE EN EL STORAGE === ');
      }
    }
  }
}
