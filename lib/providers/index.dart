import 'dart:convert';
import 'dart:developer';
import 'package:geolocator/geolocator.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/utils/constants.dart';
import 'package:safe_driving_app/utils/endpoints.dart';
import 'package:http/http.dart' as http;
import 'package:safe_driving_app/utils/root/index.dart';
import 'package:safe_driving_app/utils/storage.dart';

Future<Map<String, dynamic>> insertRouteStops(context) async {
  var urlAuth = Uri.http(ENDPOINTS.HOST, ENDPOINTS.CREATE_ROUTE_STOPS);

  Position position = await Geolocator.getCurrentPosition();

  var body = json.encode([
    {
      "routeid": readStorage('root.createRoute.id'),
      "timestamp": getDate(),
      "latitude": position.latitude,
      "longitude": position.longitude,
      "type": readStorage('personal.type') ?? '',
      "description": "Ninguno",
      "address": readStorage('root.address') ?? 'No Encontrado',
      "unitid": readStorage('personal.unitId'),
      "time": readStorage('root.stop.cronometer') ?? 0,
      "questions": json.encode([
        {
          'question': QUESTIONSTOP.ONE,
          'answer':
              json.decode(readStorage('root.recurringStop.questionOne'))['one'],
          'type': 'bool',
        },
        {
          'question': QUESTIONSTOP.TWO,
          'answer':
              json.decode(readStorage('root.recurringStop.questionOne'))['two'],
          'type': 'bool',
        },
        {
          'question': QUESTIONSTOP.THREE,
          'answer': json
              .decode(readStorage('root.recurringStop.questionOne'))['three'],
          'type': 'bool',
        },
        {
          'question': QUESTIONSTOP.FOUR,
          'answer':
              json.decode(readStorage('root.recurringStop.questionTwo'))['one'],
          'type': 'bool',
        },
        {
          'question': QUESTIONSTOP.FIVE,
          'answer':
              json.decode(readStorage('root.recurringStop.questionTwo'))['two'],
          'type': 'bool',
        },
      ])
    }
  ]);

  print('insertRouteStops.body: $body');

  var response = await http.post(urlAuth, body: body, headers: {
    "Content-Type": "application/json",
    "Authorization": ENDPOINTS.auth()
  });

  return json.decode(response.body);
}

Future<Map<String, dynamic>> cancelRouteProvider() async {
  var urlAuth = Uri.http(ENDPOINTS.HOST, ENDPOINTS.CANCEL_ROUTE);

  Position position = await Geolocator.getCurrentPosition();

  var body = json.encode({
    "routeid": readStorage('root.createRoute.id'),
    "cancel_timestamp": getDate(),
    "cancel_latitude": position.latitude,
    "cancel_longitude": position.longitude,
    "time": readStorage('root.cronometer') ?? 0
  });

  print('cancelRouteProvider.body: $body');

  var response = await http.post(urlAuth, body: body, headers: {
    "Content-Type": "application/json",
    "Authorization": ENDPOINTS.auth()
  });

  return formatResponse(response);
}

Future<Map<String, dynamic>> finishRouteProvider() async {
  var urlAuth = Uri.http(ENDPOINTS.HOST, ENDPOINTS.FINISH_ROUTE);

  Position position = await Geolocator.getCurrentPosition();

  var body = json.encode({
    "routeid": readStorage('root.createRoute.id'),
    "finish_timestamp": getDate(),
    "finish_latitude": position.latitude,
    "finish_longitude": position.longitude,
    "time": readStorage('root.cronometer') ?? 0
  });

  log('finishRouteProvider.body: $body');

  var response = await http.post(urlAuth, body: body, headers: {
    "Content-Type": "application/json",
    "Authorization": ENDPOINTS.auth()
  });

  return formatResponse(response);
}

Future<Map<String, dynamic>> getEmergencyNumber() async {
  Uri urlAuth = Uri.http(ENDPOINTS.HOST, ENDPOINTS.EMERGENCY_PHONE);

  var response = await http.get(urlAuth, headers: {
    "Content-Type": "application/json",
    "Authorization": ENDPOINTS.auth()
  });

  log(response.toString());

  return formatResponse(response);
}
