import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/utils/constants.dart';
import 'package:safe_driving_app/utils/storage.dart';
import 'package:safe_driving_app/utils/endpoints.dart';
import 'package:http/http.dart' as http;

class MenuProvider with ChangeNotifier {
  bool? buttonInspectionEnabled;
  bool? buttonRootEnabled;

  MenuProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      final unit = await _getUnit();

      await writeStorage('personal.lastInitialInspectionDate',
          unit['last_initial_inspection_date']);
      await writeStorage('inspection.lastOdometer', unit['last_odometer']);

      final lastInspection = unit['last_initial_inspection_date'];
      final hasValidInspection = isNotEmptyString(lastInspection) &&
          DateFormat('yyyy-MM-dd').format(DateTime.now()) == lastInspection;

      buttonInspectionEnabled = !hasValidInspection;
      buttonRootEnabled = hasValidInspection;
    } catch (e) {
      // Si hay error, habilita los botones
      buttonInspectionEnabled = true;
      buttonRootEnabled = true;
    }

    notifyListeners();
  }

  Future<Map<String, dynamic>> _getUnit() async {
    final url = Uri.http(
      ENDPOINTS.HOST,
      ENDPOINTS.GET_UNIT
          .replaceAll('<name>', readStorage('personal.licensePlate')),
    );

    final response = await http.get(url, headers: {
      "Content-Type": "application/json",
      'Authorization': ENDPOINTS.auth(),
    });

    if (response.statusCode != STATUSCODE.OK) {
      throw Exception('Failed to load unit data');
    }

    return json.decode(response.body);
  }
}
