import 'dart:convert';

import 'package:safe_driving_app/utils/endpoints.dart';
import 'package:http/http.dart' as http;

abstract class UnitRemoteDataSource {
  Future<Map<String, dynamic>> getUnit(String licensePlate);
}

class UnitRemoteDataSourceImpl implements UnitRemoteDataSource {
  @override
  Future<Map<String, dynamic>> getUnit(String licensePlate) async {
    final response = await http.get(
      Uri.http(ENDPOINTS.HOST,
          ENDPOINTS.GET_UNIT.replaceAll('<name>', licensePlate)),
      headers: {
        "Content-Type": "application/json",
        'Authorization': ENDPOINTS.auth(),
      },
    );

    final responseData = json.decode(response.body);

    if (response.statusCode != 200 || responseData.containsKey('detail')) {
      throw responseData;
    }

    return responseData;
  }
}
