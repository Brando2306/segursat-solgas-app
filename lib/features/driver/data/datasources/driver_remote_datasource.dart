import 'dart:convert';

import 'package:safe_driving_app/utils/endpoints.dart';
import 'package:http/http.dart' as http;

abstract class DriverRemoteDataSource {
  Future<Map<String, dynamic>> getDriver(String idNumber);
}

class DriverRemoteDataSourceImpl implements DriverRemoteDataSource {
  @override
  Future<Map<String, dynamic>> getDriver(String idNumber) async {
    final response = await http.get(
      Uri.http(ENDPOINTS.HOST,
          ENDPOINTS.GET_DRIVER.replaceAll('<idNumber>', idNumber)),
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
