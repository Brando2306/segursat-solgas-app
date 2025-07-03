import 'dart:convert';

import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/utils/endpoints.dart';
import 'package:safe_driving_app/utils/storage.dart';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> createRoute() async {
  var urlAuth = Uri.http(ENDPOINTS.HOST, ENDPOINTS.CREATE_ROUTE);

  var initialPosition = json.decode(readStorage('root.initialPosition'));
  var finalPosition = json.decode(readStorage('root.finalPosition'));

  var body = json.encode({
    'unit_name': readStorage('personal.licensePlate'),
    'timestamp': getDate(),
    'source_latitude': initialPosition['latitude'],
    'source_longitude': initialPosition['longitude'],
    'destination_latitude': finalPosition['latitude'],
    'destination_longitude': finalPosition['longitude']
  });

  http.Response response = await http.post(urlAuth,
      headers: {
        "Content-Type": "application/json",
        'Authorization': ENDPOINTS.auth(),
      },
      body: body);

  // print('createRoute.response: ${response.body}');

  return formatResponse(response);
}

Future<Map<String, dynamic>> getRoute(int id) async {
  var urlAuth = Uri.http(
      ENDPOINTS.HOST, ENDPOINTS.GET_ROUTE.replaceAll('<int:id>', '$id'));

  http.Response response = await http.get(
    urlAuth,
    headers: {
      'Authorization': ENDPOINTS.auth(),
    },
  );

  // print('getRoute.response: ${response.body}');

  return formatResponse(response);
}
