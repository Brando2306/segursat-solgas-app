import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:safe_driving_app/class/index.dart';
import 'package:http/http.dart' as http;

double getHeight(BuildContext context, double height) =>
    MediaQuery.of(context).size.height * (height / 100);

double getWidth(BuildContext context, double width) =>
    MediaQuery.of(context).size.width * (width / 100);

void notificationError(BuildContext context, String content) {
  showDialog(
    barrierDismissible: false,
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 40,
              ),
              SizedBox(height: 10),
              Text(
                "Error",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 10),
              Text(
                content,
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                },
                style: ElevatedButton.styleFrom(
                  primary: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Cerrar',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void notificationAlert(BuildContext context, String content) {
  showDialog(
    barrierDismissible: false,
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue,
                size: 40,
              ),
              SizedBox(height: 10),
              Text(
                "Alerta",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              SizedBox(height: 10),
              Text(
                content,
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                },
                style: ElevatedButton.styleFrom(
                  primary: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Aceptar',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void notificationInfo(BuildContext context, String content, Function callBack) {
  showDialog(
    barrierDismissible: false,
    context: context,
    builder: (BuildContext context) {
      return WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded, // Ícono de aviso
                  color: Colors.orange, // Color de aviso
                  size: 40,
                ),
                SizedBox(height: 10),
                Text(
                  "Aviso",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange, // Color de aviso
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  content,
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    callBack();
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Colors.orange, // Color de aviso
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Aceptar',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

notificationConfirmation(context, Widget? content, Function function) {
  showDialog(
    barrierDismissible: false,
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          "Mensaje",
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 9, 43, 145)),
        ),
        content: content,
        actions: <Widget>[
          MaterialButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              function();
            },
            child: Text('Confirmar'),
          ),
          MaterialButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
            },
            textColor: Colors.deepOrange,
            child: Text('Cerrar'),
          )
        ],
      );
    },
  );
}

bool validationLicensePlate(String? texto) {
  RegExp patron = RegExp(r'^[a-zA-Z0-9]{3}-[a-zA-Z0-9]{3}$');
  return patron.hasMatch(texto ?? '');
}

console(String e) {
  // List<String> division = e.split(': ');

  // if (division[1] != 'null') {
  print('Storage ==> ${e}');
  // }
}

int getDate() {
  DateTime fechaHoraActual =
      DateTime.now().toUtc().add(const Duration(hours: -5));

  double result = fechaHoraActual.millisecondsSinceEpoch / 1000;
  return result.toInt();
}

void logMap(data) {
  if (data is String) {
    var map = json.decode(data);

    map.forEach((key, value) {
      print('Propiedad: $key, Valor: $value');
    });
  }

  if (data is Map<String, dynamic>) {
    data.forEach((key, value) {
      print('Propiedad: $key, Valor: $value');
    });
  }
}

List<Map<String, dynamic>> removeDuplicates(
    List<Map<String, dynamic>> list, String property) {
  List<String> uniqueValues = [];
  List<Map<String, dynamic>> result = [];

  for (var item in list) {
    if (!uniqueValues.contains(item[property])) {
      uniqueValues.add(item[property]);
      result.add(item);
    }
  }

  return result;
}

List<DirectionDto> removeDuplicatesDirectionDto(List<DirectionDto> list) {
  List<String> uniqueValues = [];
  List<DirectionDto> result = [];

  for (var item in list) {
    if (!uniqueValues.contains(item.direction)) {
      uniqueValues.add(item.direction);
      result.add(item);
    }
  }

  return result;
}

String handleApiError(dynamic response) {
  if (response is Map<String, dynamic>) {
    if (response.containsKey('errors')) {
      List<dynamic> errors = response['errors'];

      if (errors.isNotEmpty && errors.first is Map<String, dynamic>) {
        Map<String, dynamic> firstError = errors.first;

        String errorText = "Ocurrió un error en la API";

        for (String propertyName in firstError.keys) {
          dynamic propertyErrors = firstError[propertyName];

          if (propertyErrors is List && propertyErrors.isNotEmpty) {
            errorText = "Error en $propertyName: ${propertyErrors.first}";
            break;
          }
        }

        return errorText;
      }
    } else if (response.containsKey('detail')) {
      return "${response['detail']}";
    }
  }

  return "Ocurrió un error en la API";
}

Map<String, dynamic> formatResponse(http.Response response) {
  Map<String, dynamic> responseData = json.decode(response.body);
  responseData['status'] = response.statusCode;
  return responseData;
}

bool isNotEmptyString(dynamic value) {
  if (value == null) {
    return false;
  }

  if (value is String) {
    return value.trim().isNotEmpty;
  }

  if (value is List || value is Map) {
    return value.isNotEmpty;
  }

  if (value is num || value is double) {
    return true; // Los números se consideran válidos
  }

  return false;
}
