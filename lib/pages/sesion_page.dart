import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/helpers/gps.dart';
import 'package:safe_driving_app/providers/route.dart';
import 'package:safe_driving_app/utils/constants.dart';
import 'package:safe_driving_app/utils/endpoints.dart';
import 'package:safe_driving_app/utils/errors.dart';
import 'package:safe_driving_app/utils/storage.dart';
import 'package:safe_driving_app/widgets/next_button.dart';
import 'package:http/http.dart' as http;

import 'package:app_settings/app_settings.dart';

class SesionPage extends StatefulWidget {
  const SesionPage({super.key});

  @override
  State<SesionPage> createState() => _SesionPageState();
}

class _SesionPageState extends State<SesionPage> with WidgetsBindingObserver {
  final _formKeyDocument = GlobalKey<FormBuilderState>();
  final _formKeyLicensePlate = GlobalKey<FormBuilderState>();

  final _documentInpuController = TextEditingController();
  final _licensePlateInpuController = TextEditingController();

  bool _submitValidation = false;
  bool _nextButtonValidation = false;

  String _nameCard = '';
  String _lastNameCard = '';
  String _documentCard = '';
  String _licensePlate = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    printStorage();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      print('==> SesionPage: ${AppLifecycleState.resumed}');

      if (readStorage('sesionPageValidation') != null) {
        await validationResume();
      }
    }
  }

  Future<void> validationResume() async {
    try {
      print(
          'personal.pushRouteSpeedometer: ${readStorage('personal.pushRouteSpeedometer')}');

      if (readStorage('personal.pushRouteSpeedometer') != null) {
        EasyLoading.show(status: 'Verificando GPS...');
        bool validationGps = await checkGps();
        EasyLoading.dismiss();

        if (validationGps) {
          EasyLoading.show(status: 'Redireccionando...');
          int lastRoute = readStorage('personal.lastRoute');

          print(lastRoute);

          Map<String, dynamic> route = await getRoute(lastRoute);

          if (route['status'] == STATUSCODE.OK) {
            List<dynamic> positions = route['positions'];
            print('GetLatRoute: $route');

            print('positions $positions');

            print('isNotEmptyString(positions) ${isNotEmptyString(positions)}');
            print(
                'isNotEmptyString(route[destination_latitude] ${isNotEmptyString(route['destination_latitude'])}');
            print(
                'isNotEmptyString(route[destination_longitude]) ${isNotEmptyString(route['destination_longitude'])}');

            if (isNotEmptyString(positions)) {
              Map<String, dynamic> lastObject = positions.last;
              print('lastObject $lastObject');

              if (isNotEmptyString(lastObject) &&
                  isNotEmptyString(lastObject['angle'])) {
                await writeStorage('root.cronometer', lastObject['angle']);
              } else {
                await writeStorage('root.cronometer', 0);
              }
            }

            if (isNotEmptyString(route['destination_latitude']) &&
                isNotEmptyString(route['destination_longitude'])) {
              print('destination_latitude ${route['destination_latitude']}');
              print('destination_longitude ${route['destination_longitude']}');

              await writeStorage(
                  'root.finalPosition',
                  json.encode({
                    'latitude': route['destination_latitude'],
                    'longitude': route['destination_longitude']
                  }));

              await writeStorage('personal.pushRouteSpeedometer', null);

              EasyLoading.dismiss();

              setState(() {
                Navigator.pushNamed(context, '/root/speedometer');
              });
            } else {
              cleanResumeRoute();
              setState(() {
                Navigator.pushNamed(context, '/menu');
              });
            }
          } else {
            cleanResumeRoute();
            setState(() {
              Navigator.pushNamed(context, '/menu');
            });
          }

          EasyLoading.dismiss();
        } else {
          await writeStorage('sesionPageValidation', true);
          setState(() {
            showLocationSettingsDialog(context);
          });
        }
      }
    } catch (e) {
      print('Ocurrio algun error al traer la ruta $e');

      cleanResumeRoute();

      setState(() {
        Navigator.pushNamed(context, '/menu');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          appBar: header(context),
          resizeToAvoidBottomInset: false,
          body: Column(
            children: [
              form(context),
              _nextButtonValidation ? miCardImage() : Container(),
              Expanded(child: Container()),
              _nextButtonValidation
                  ? nextButton(context, SESION.TEXT_BUTTON, '/menu',
                      _nextButtonValidation, () {}, null)
                  : Container(),
              SizedBox(
                height: getHeight(context, 3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar header(context) {
    return AppBar(
      title: Text(SESION.TEXT_HEADER, style: TextStyle(color: Colors.black)),
      centerTitle: true,
      elevation: 0.0,
      backgroundColor: Colors.white,
      leading: Container(),
    );
  }

  Container form(context) {
    return Container(
      margin: EdgeInsets.fromLTRB(getWidth(context, 5), getHeight(context, 2),
          getWidth(context, 5), getHeight(context, 2)),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: const [Text(SESION.LABEL_DOCUMENTINPUT)],
        ),
        SizedBox(height: getHeight(context, 1)),
        documentInput(context),
        SizedBox(height: getHeight(context, 2)),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: const [Text(SESION.LABEL_LICENSEPLATE)],
        ),
        SizedBox(height: getHeight(context, 1)),
        licensePlateInput(context),
        SizedBox(height: getHeight(context, 2)),
        ElevatedButton(
          onPressed: () async {
            if (_submitValidation) {
              await submit(context);
            }
          },
          child: const Text('Validar información'),
        )
      ]),
    );
  }

  FormBuilder documentInput(context) {
    return FormBuilder(
      key: _formKeyDocument,
      child: FormBuilderTextField(
          name: 'text',
          onChanged: (value) {
            setState(() {
              _submitValidation = _formKeyDocument.currentState!.validate() &&
                  _formKeyLicensePlate.currentState!.validate();
              _nextButtonValidation = false;
            });
          },
          decoration: InputDecoration(
              enabled: true,
              labelText: SESION.PLACEHOLDER_DOCUMENTINPUT,
              // hintText: 'ejem 75652679',
              // errorText: 'Colocar un DNI valido',
              filled: true,
              fillColor: Colors.blue.shade100,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly
          ],
          controller: _documentInpuController,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return SESION.REQUIRED_DOCUMEND;
            }
            return null;
          }),
    );
  }

  FormBuilder licensePlateInput(context) {
    return FormBuilder(
      key: _formKeyLicensePlate,
      child: FormBuilderTextField(
        name: 'text',
        onChanged: (value) {
          setState(() {
            _submitValidation = _formKeyDocument.currentState!.validate() &&
                _formKeyLicensePlate.currentState!.validate() &&
                validationLicensePlate(value);
            _nextButtonValidation = false;
          });
        },
        decoration: InputDecoration(
            enabled: true,
            labelText: SESION.PLACEHOLDER_LICENSEPLATE,
            // hintText: 'ejem 75652679',
            // errorText: 'Colocar un DNI valido',
            filled: true,
            fillColor: Colors.blue.shade100,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
        keyboardType: TextInputType.text,
        // inputFormatters: <TextInputFormatter>[
        //   FilteringTextInputFormatter.digitsOnly
        // ],
        controller: _licensePlateInpuController,
        validator: (String? value) {
          if (value == null || value.isEmpty) {
            return SESION.REQUIRED_LICENSEPLATE;
          }
          return null;
        },
      ),
    );
  }

  void clearInputs() {
    _documentInpuController.clear();
    _licensePlateInpuController.clear();
  }

  Future<Map<String, dynamic>> getDriver() async {
    var urlAuth = Uri.http(
        ENDPOINTS.HOST,
        ENDPOINTS.GET_DRIVER
            .replaceAll('<idNumber>', _documentInpuController.text));

    var response = await http.get(urlAuth, headers: {
      "Content-Type": "application/json",
      'Authorization': ENDPOINTS.auth(),
    });

    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> getUnit() async {
    var url = Uri.http(
        ENDPOINTS.HOST,
        ENDPOINTS.GET_UNIT
            .replaceAll('<name>', _licensePlateInpuController.text));

    var response = await http.get(url, headers: {
      "Content-Type": "application/json",
      'Authorization': ENDPOINTS.auth(),
    });

    return json.decode(response.body);
  }

  Future<void> submit(context) async {
    EasyLoading.show(status: 'Validando...');
    FocusManager.instance.primaryFocus?.unfocus();

    if (_formKeyDocument.currentState!.validate() &&
        _formKeyLicensePlate.currentState!.validate()) {
      // var snackBarMessage = ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('Validando los datos ingresados')),
      // );

      try {
        setState(() => _submitValidation = false);

        Map<String, dynamic> driver = await getDriver();
        Map<String, dynamic> unit = await getUnit();

        bool validationDriver =
            driver.isNotEmpty && !driver.containsKey('detail');

        bool validationUnit = unit.isNotEmpty && !unit.containsKey('detail');

        if (validationDriver && validationUnit) {
          setState(() => _nextButtonValidation = true);

          print(unit);

          await writeStorage('personal.name', driver['firstname']);
          await writeStorage('personal.lastName', driver['lastname']);
          await writeStorage('personal.document', driver['id_number']);
          await writeStorage('personal.licensePlate', unit['name']);
          await writeStorage('personal.unitId', unit['id']);
          await writeStorage('personal.lastInitialInpectionDate',
              unit['last_initial_inspection_date']);
          await writeStorage('inspection.lastOdometer', unit['last_odometer']);
          await writeStorage('personal.technicalReviewExpirationDate',
              unit['technical_review_expiration_date']);
          await writeStorage(
              'personal.soatExpirationDate', unit['soat_expiration_date']);
          await writeStorage('personal.insuranceExpirationDate',
              unit['insurance_expiration_date']);

          _nameCard = readStorage('personal.name');
          _lastNameCard = readStorage('personal.lastName');
          _documentCard = readStorage('personal.document');
          _licensePlate = readStorage('personal.licensePlate');

          print('last_route_status ${unit['last_route_status']}');
          print('last_route ${unit['last_route']}');

          // FLUJO REGULAR
          if (!isNotEmptyString(unit['last_route_status']) ||
              !isNotEmptyString(unit['last_route']) ||
              unit['last_route_status'] != SESION.RUNNING) {
            if (unit['annotations'] is List) {
              List<dynamic> annotations = unit['annotations'];
              if (annotations.isNotEmpty) {
                if (annotations[0] is Map<String, dynamic> &&
                    annotations[0].containsKey('description')) {
                  var list = annotations.map((e) => e['description'] as String);
                  var newList = list.join('\n\n');
                  notificationInfo(context, newList, () {});
                }
              }
            }
            if (driver['annotations'] is List) {
              List<dynamic> annotations = driver['annotations'];
              if (annotations.isNotEmpty) {
                if (annotations[0] is Map<String, dynamic> &&
                    annotations[0].containsKey('description')) {
                  var list = annotations.map((e) => e['description'] as String);
                  var newList = list.join('\n\n');
                  notificationInfo(context, newList, () {});
                }
              }
            }
            // FLUJO CONTINUAR RUTA
          } else {
            await writeStorage('personal.lastRoute', unit['last_route']);
            await writeStorage(
                'personal.lastRouteStatus', unit['last_route_status']);

            bool validation = await checkGps();

            EasyLoading.dismiss();

            notificationInfo(context,
                'Tienes una ruta activa en curso.\nPor favor, completa la ruta antes de iniciar una nueva.',
                () async {
              print('validation $validation');

              if (validation) {
                await writeStorage('personal.pushRouteSpeedometer', true);
                await validationResume();
              } else {
                await writeStorage('sesionPageValidation', true);
                showLocationSettingsDialog(context);
              }
            });
          }
        } else {
          setState(() {
            _submitValidation = true;
          });

          if (driver.containsKey('detail')) {
            notificationAlert(
                context,
                errorTranslations[handleApiError(driver)] ??
                    handleApiError(driver));
          } else if (unit.containsKey('detail')) {
            notificationAlert(
                context,
                errorTranslations[handleApiError(unit)] ??
                    handleApiError(unit));
          }
        }
      } catch (e) {
        notificationError(context, e.toString());
      }

      // snackBarMessage.close();
      EasyLoading.dismiss();
    }
  }

  SizedBox miCardImage() {
    return SizedBox(
      // height: getHeight(context, 36),
      width: getHeight(context, 36),
      child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          // margin: EdgeInsets.fromLTRB(
          //     getWidth(context, 20), 0, getWidth(context, 20), 0),
          elevation: 10,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Column(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(10),
                  child: Text('Información personal'),
                ),
                Container(
                    padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                    child: Image.asset(SESION.LOGO_PERSONAL)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(5),
                      child: Text('Nombres:'),
                    ),
                    Container(
                      padding: EdgeInsets.all(5),
                      child: Text(
                        _nameCard,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(5),
                      child: Text('Apellidos:'),
                    ),
                    Container(
                      padding: EdgeInsets.all(5),
                      child: Text(
                        _lastNameCard,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(5),
                      child: Text('DNI:'),
                    ),
                    Container(
                      padding: EdgeInsets.all(5),
                      child: Text(
                        _documentCard,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(5),
                      child: Text('Placa:'),
                    ),
                    Container(
                      padding: EdgeInsets.all(5),
                      child: Text(
                        _licensePlate,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )),
    );
  }

  String checkExpirations(
      String technicalReview, String soat, String insurance) {
    DateTime now = DateTime.now().toLocal(); // Ajustar a la zona horaria local
    DateTime technicalReviewDate =
        DateFormat('yyyy-MM-dd').parse(technicalReview).toLocal();
    DateTime soatDate = DateFormat('yyyy-MM-dd').parse(soat).toLocal();
    DateTime insuranceDate =
        DateFormat('yyyy-MM-dd').parse(insurance).toLocal();

    List<String> expiredProperties = [];

    if (technicalReviewDate.isBefore(now)) {
      expiredProperties.add("Technical Review");
    }

    if (soatDate.isBefore(now)) {
      expiredProperties.add("SOAT");
    }

    if (insuranceDate.isBefore(now)) {
      expiredProperties.add("Insurance");
    }

    if (expiredProperties.isEmpty) {
      return "All documents are up to date.";
    } else {
      String expiredPropertiesText = expiredProperties.join(', ');
      return "The following documents have expired: $expiredPropertiesText.";
    }
  }

  void showLocationSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ubicación desactivada'),
          content:
              Text('Para usar esta función, necesitas activar la ubicación.'),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                cleanAll();

                await Navigator.pushNamed(context, '/sesion');
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                // Navigator.of(context).pop();

                await writeStorage('personal.pushRouteSpeedometer', true);
                await AppSettings.openAppSettings(
                    type: AppSettingsType.location);
              },
              child: Text('Abrir configuración'),
            ),
          ],
        );
      },
    );
  }
}
