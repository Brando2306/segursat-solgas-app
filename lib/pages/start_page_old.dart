import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/helpers/gps.dart';
import 'package:safe_driving_app/utils/constants.dart';
import 'package:safe_driving_app/utils/storage.dart';
import 'package:safe_driving_app/utils/style.dart';
import 'package:permission_handler/permission_handler.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    initPermissionsAndLocation();
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
      print('==> StartPage: ${AppLifecycleState.resumed}');

      if (readStorage('startPageValidation') != null) {
        setState(() {
          writeStorage('startPageValidation', null);
          Navigator.of(context).pop();
          Navigator.pushNamed(context, '/');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Column(children: [
            Expanded(child: Container()),
            Expanded(child: Container()),
            centerLogo(context),
            SizedBox(
              height: getHeight(context, 2),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.height * 0.10),
              child: Text(
                'Conduce Seguro',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(child: Container()),
            Expanded(child: Container()),
            button(context),
            SizedBox(
              height: getHeight(context, 3),
            ),
          ]),
        ));
  }

  Container centerLogo(context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5),
      width: MediaQuery.of(context).size.width,
      child: Image.asset(START.LOGO),
    );
  }

  MaterialButton button(context) {
    return MaterialButton(
      onPressed: () async {
        EasyLoading.show(status: 'Verificando GPS...');
        bool validation = await checkGps();
        EasyLoading.dismiss();

        print('validationGPS: $validation');

        if (validation) {
          Navigator.pushNamed(context, '/statement');
        } else {
          await writeStorage('startPageValidation', true);
          showLocationSettingsDialog(context);
        }
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      color: CustomColors.primary,
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: getHeight(context, 12), vertical: 16),
        child: Text(
          START.TEXT_BUTTON,
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void showLocationSettingsDialog(BuildContext context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: Text('Ubicación desactivada'),
            content: Text(
                'Para usar esta aplicación, necesitas activar la ubicación.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Reintentar'),
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
          ),
        );
      },
    );
  }

  void initPermissionsAndLocation() async {
    await Permission.location.request();

    // if (!await Geolocator.isLocationServiceEnabled()) {
    //   await Geolocator.openLocationSettings();
    // }
  }
}
