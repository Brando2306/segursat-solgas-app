import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'package:safe_driving_app/helpers/gps.dart';
import 'package:safe_driving_app/utils/style.dart';
import 'package:safe_driving_app/utils/errors.dart';
import 'package:safe_driving_app/utils/storage.dart';
import 'package:safe_driving_app/utils/constants.dart';
import 'package:safe_driving_app/providers/route.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/widgets/next_button.dart';
import 'package:safe_driving_app/shared/button_widget.dart';
import 'package:safe_driving_app/shared/form_field_widget.dart';
import 'package:safe_driving_app/core/validators/auth_validator.dart';
import 'package:safe_driving_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:safe_driving_app/features/unit/presentation/providers/unit_provider.dart';
import 'package:safe_driving_app/features/driver/presentation/providers/driver_provider.dart';

class SesionPage extends StatefulWidget {
  const SesionPage({super.key});

  @override
  State<SesionPage> createState() => _SesionPageState();
}

class _SesionPageState extends State<SesionPage> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();

  final _documentInpuController = TextEditingController();
  final _licensePlateInpuController = TextEditingController();

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
      if (readStorage('sesionPageValidation') != null) {
        await validationResume();
      }
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
          backgroundColor: Colors.white,
          resizeToAvoidBottomInset: false,
          body: Consumer<AuthProvider>(builder: (context, authProvider, _) {
            final bool nextButtonValidation = authProvider.nextButtonValidation;
            return Column(
              children: [
                form(context),
                nextButtonValidation ? miCardImage() : Container(),
                Expanded(child: SizedBox()),
                nextButtonValidation
                    ? nextButton(context, SESION.TEXT_BUTTON, '/menu',
                        nextButtonValidation, () {}, null)
                    : SizedBox(),
                SizedBox(
                  height: getHeight(context, 3),
                ),
              ],
            );
          }),
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

  Form form(context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Form(
      key: _formKey,
      child: Container(
        margin: EdgeInsets.fromLTRB(getWidth(context, 5), getHeight(context, 2),
            getWidth(context, 5), getHeight(context, 2)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FormFieldWidget(
              controller: _documentInpuController,
              labelText: SESION.LABEL_DOCUMENTINPUT,
              hintText: SESION.PLACEHOLDER_DOCUMENTINPUT,
              keyboardType: TextInputType.number,
              validator: AuthValidator.validateDocument,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                FilteringTextInputFormatter.deny(RegExp(r'^\s')),
                FilteringTextInputFormatter.deny(RegExp(r'[ ]')),
              ],
              onChanged: (value) {
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                authProvider.setSubmitValidation(
                  _formKey.currentState?.validate() ?? false,
                );
                authProvider.setNextButtonValidation(false);
              },
            ),
            SizedBox(height: 20),
            FormFieldWidget(
              controller: _licensePlateInpuController,
              labelText: SESION.LABEL_LICENSEPLATE,
              hintText: SESION.PLACEHOLDER_LICENSEPLATE,
              validator: AuthValidator.validateLicensePlate,
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'^\s')),
                FilteringTextInputFormatter.deny(RegExp(r'[ ]')),
              ],
              onChanged: (value) {
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                authProvider.setSubmitValidation(
                  _formKey.currentState?.validate() ?? false,
                );
                authProvider.setNextButtonValidation(false);
              },
              helperText: '*Ingresar la placa con guión, por ejemplo: ABC-123',
            ),
            SizedBox(height: 40),
            (authProvider.nextButtonValidation)
                ? SizedBox()
                : Center(
                    child: ButtonWidget(
                      padding:
                          EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      text: 'Validar información',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                      color: CustomColors.primary,
                      onPressed: () {
                        final authProvider =
                            Provider.of<AuthProvider>(context, listen: false);

                        if (authProvider.submitValidation) {
                          submit(context);
                        }
                      },
                    ),
                  )
          ],
        ),
      ),
    );
  }

  Future<void> submit(context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final unitProvider = Provider.of<UnitProvider>(context, listen: false);
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);

    if (!(_formKey.currentState?.validate() ?? false)) {
      authProvider.setSubmitValidation(false);
      return;
    }

    EasyLoading.show(status: 'Validando...');
    FocusManager.instance.primaryFocus?.unfocus();

    try {
      authProvider.setSubmitValidation(false);

      await driverProvider.fetchDriver(_documentInpuController.text);
      await unitProvider.fetchUnit(_licensePlateInpuController.text);

      if (driverProvider.error != null) {
        notificationAlert(
          context,
          errorTranslations[handleApiError(driverProvider.error!)] ??
              driverProvider.error!,
        );
        return;
      }

      if (unitProvider.error != null) {
        notificationAlert(
          context,
          errorTranslations[handleApiError(unitProvider.error!)] ??
              unitProvider.error!,
        );
        return;
      }

      bool validationDriver = driverProvider.driver != null;
      bool validationUnit = unitProvider.unit != null;

      if (validationDriver && validationUnit) {
        authProvider.setNextButtonValidation(true);

        final driver = driverProvider.driver!;
        final unit = unitProvider.unit!;

        await authProvider.login(
          name: driverProvider.driver!.firstName,
          lastName: driverProvider.driver!.lastName,
          document: driverProvider.driver!.idNumber,
          licensePlate: unitProvider.unit!.name,
          unitId: unitProvider.unit!.id,
          lastInitialInspectionDate:
              unitProvider.unit!.lastInitialInspectionDate,
          lastOdometer: unitProvider.unit!.lastOdometer,
          technicalReviewExpirationDate:
              unitProvider.unit!.technicalReviewExpiration,
          soatExpirationDate: unitProvider.unit!.soatExpiration,
          insuranceExpirationDate: unitProvider.unit!.insuranceExpiration,
          lastRoute: unitProvider.unit!.lastRoute,
          lastRouteStatus: unitProvider.unit!.lastRouteStatus,
        );

        // FLUJO REGULAR
        if (!isNotEmptyString(unit.lastRouteStatus) ||
            !isNotEmptyString(unit.lastRoute) ||
            unit.lastRouteStatus != SESION.RUNNING) {
          if (unit.annotations is List) {
            List<dynamic> annotations = unit.annotations;
            if (annotations.isNotEmpty) {
              if (annotations[0] is Map<String, dynamic> &&
                  annotations[0].containsKey('description')) {
                var list = annotations.map((e) => e['description'] as String);
                var newList = list.join('\n\n');
                notificationInfo(context, newList, () {});
              }
            }
          }
          if (driver.annotations is List) {
            List<dynamic> annotations = driver.annotations;
            if (annotations.isNotEmpty) {
              if (annotations[0] is Map<String, dynamic> &&
                  annotations[0].containsKey('description')) {
                var list = annotations.map((e) => e['description'] as String);
                var newList = list.join('\n\n');
                // LICENCIA DE CONDUCIR HA VENCIDO
                notificationInfo(context, newList, () {});
              }
            }
          }
          // FLUJO CONTINUAR RUTA
        } else {
          await writeStorage('personal.lastRoute', unit.lastRoute);
          await writeStorage('root.createRoute.id', unit.lastRoute);
          await writeStorage('personal.lastRouteStatus', unit.lastRouteStatus);

          bool validation = await checkGps();

          EasyLoading.dismiss();

          notificationInfoWithoutWillPopScope(
            context: context,
            onWillPop: true,
            barrierDismissible: true,
            content:
                'Tienes una ruta activa en curso.\n¿Deseas recuperar la ruta?',
            callBack: () async {
              if (validation) {
                await writeStorage('personal.pushRouteSpeedometer', true);
                await validationResume();
              } else {
                await writeStorage('sesionPageValidation', true);
                showLocationSettingsDialog(context);
              }
            },
          );
        }
      } else {
        authProvider.setSubmitValidation(true);
      }
    } catch (e) {
      notificationError(context, e.toString());
    } finally {
      EasyLoading.dismiss();
    }
    EasyLoading.dismiss();
  }

  SizedBox miCardImage() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) return const SizedBox.shrink();

    return SizedBox(
      width: getHeight(context, 36),
      child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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
                        authProvider.currentUser?.name ?? '',
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
                        authProvider.currentUser?.lastName ?? '',
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
                        authProvider.currentUser?.document ?? '',
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
                        authProvider.currentUser?.licensePlate ?? '',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )),
    );
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

              Navigator.pushNamed(context, '/root/speedometer');
            } else {
              cleanResumeRoute();
              Navigator.pushNamed(context, '/menu');
            }
          } else {
            cleanResumeRoute();
            Navigator.pushNamed(context, '/menu');
          }

          EasyLoading.dismiss();
        } else {
          await writeStorage('sesionPageValidation', true);
          showLocationSettingsDialog(context);
        }
      }
    } catch (e) {
      print('Ocurrio algun error al traer la ruta $e');

      cleanResumeRoute();

      Navigator.pushNamed(context, '/menu');
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
                await Navigator.pushNamed(context, '/sesion');
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
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
