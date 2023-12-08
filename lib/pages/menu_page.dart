import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/utils/constants.dart';
import 'package:safe_driving_app/utils/endpoints.dart';
import 'package:safe_driving_app/utils/storage.dart';
import 'package:safe_driving_app/utils/style.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<StatefulWidget> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  // bool buttonInspection = true;
  // bool buttonRoot = true;
  late Future<bool> buttonInspectionValidation = Future.value(true);
  late Future<bool> buttonRootValidation = Future.value(true);

  @override
  void initState() {
    super.initState();

    init();

    printStorage();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: header(context),
        body: Column(children: [
          Expanded(child: Container()),
          FutureBuilder<bool>(
            future: buttonInspectionValidation,
            builder: (context, snapshot) {
              return snapshot.hasData
                  ? menuBottons(context, 'inspección de unidad',
                      '/inspection/question', snapshot.data!)
                  : CircularProgressIndicator(); // Mostrar un indicador de carga mientras se obtiene la validación
            },
          ),
          SizedBox(
            height: getHeight(context, 3),
          ),
          FutureBuilder<bool>(
            future: buttonRootValidation,
            builder: (context, snapshot) {
              return snapshot.hasData
                  ? menuBottons(context, 'Iniciar una ruta',
                      '/root/selectSource', snapshot.data!)
                  : CircularProgressIndicator(); // Mostrar un indicador de carga mientras se obtiene la validación
            },
          ),
          SizedBox(
            height: getHeight(context, 3),
          ),
          menuBottons(
              context, 'Registrar mantenimiento', '/maintance/odometer', true),
          Expanded(child: Container()),
        ]),
      ),
    );
  }

  AppBar header(context) {
    return AppBar(
      title: Text(MENU.TEXT_HEADER, style: TextStyle(color: Colors.black)),
      centerTitle: true,
      elevation: 0.0,
      backgroundColor: Colors.white,
      leading: Builder(
        builder: (context) => IconButton(
            onPressed: () {
              cleanAll();
              Navigator.pushNamed(context, '/sesion');
            },
            icon: Icon(Icons.logout),
            color: Colors.black,
            tooltip: 'Salir de la sesión'),
      ),
    );
  }

  SizedBox menuBottons(context, String text, String route, bool validation) {
    return SizedBox(
      width: getWidth(context, 80),
      height: getHeight(context, 7),
      child: MaterialButton(
        onPressed: () {
          if (validation) {
            Navigator.pushNamed(context, route);
          }
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        color: validation ? CustomColors.primary : CustomColors.primaryOff,
        child: Text(
          text,
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  void buttonsValidation() {
    String? lastInitialInspection =
        readStorage('personal.lastInitialInpectionDate');

    setState(() {
      bool responseValidation = isNotEmptyString(lastInitialInspection);

      if (responseValidation) {
        DateTime now = DateTime.now();
        String formattedDate = DateFormat('yyyy-MM-dd').format(now);

        bool validationDate = formattedDate == lastInitialInspection;
        print('validationDate: $validationDate');

        responseValidation = validationDate;
      }

      print('responseValidation $responseValidation');
      buttonInspectionValidation = Future.value(!responseValidation);
      buttonRootValidation = Future.value(responseValidation);
    });
  }

  // bool validateTimeInspection(String dateString) {
  //   // String dateString = '04/08/2023 12:38:39';
  //   DateTime dateToCompare =
  //       DateFormat('dd/MM/yyyy HH:mm:ss').parse(dateString);
  //   dateToCompare =
  //       DateTime(dateToCompare.year, dateToCompare.month, dateToCompare.day);

  //   DateTime currentDate = DateTime.now();
  //   DateTime currentDateInPeru = currentDate.toUtc();
  //   // .subtract(Duration(hours: 5)); // Ajuste para UTC-5 (horario de Perú)
  //   DateTime currentDateOnly = DateTime(
  //       currentDateInPeru.year, currentDateInPeru.month, currentDateInPeru.day);

  //   print('dateToCompare $dateToCompare');
  //   print('currentDateOnly $currentDateOnly');

  //   return dateToCompare.isAtSameMomentAs(currentDateOnly);
  // }

  init() async {
    EasyLoading.show(status: 'Validando...');

    try {
      var unit = await getUnit();

      await writeStorage('personal.lastInitialInpectionDate',
          unit['last_initial_inspection_date']);
      await writeStorage('inspection.lastOdometer', unit['last_odometer']);

      buttonsValidation();
    } catch (e) {
      print(e);
    }

    EasyLoading.dismiss();
  }

  getUnit() async {
    var url = Uri.http(
        ENDPOINTS.HOST,
        ENDPOINTS.GET_UNIT
            .replaceAll('<name>', readStorage('personal.licensePlate')));

    var response = await http.get(url, headers: {
      "Content-Type": "application/json",
      'Authorization': ENDPOINTS.auth(),
    });

    log('url menu_page response.body ${response.body}');

    if (response.statusCode != STATUSCODE.OK) {
      return false;
    }

    var obj = json.decode(response.body);
    print('getUnit: $obj');

    if (obj['detail'] != null) {
      return false;
    }

    return obj;
  }
}
