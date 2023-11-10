import 'dart:convert';

class ENDPOINTS {
  static const String HOST = 'safedriving.segursat.com';
  static const String USERNAME = 'appuser';
  static const String PASSWORD = 'STANHOUSI';
  static const String GET_DRIVER = 'web/api/control/get-driver/<idNumber>/';
  static const String GET_UNIT = 'web/api/control/get-unit/<name>/';
  static const String INSPECTION_UPLOAD = 'control/inspections/upload/';
  static const String CREATE_ROUTE = 'web/api/control/create-route/';
  static const String GET_ROUTE = 'web/api/routes/get-route/<int:id>/';
  static const String CREATE_ROUTE_POSITIONS =
      'web/api/control/insert-route-positions/';
  static const String CREATE_ROUTE_STOPS =
      'web/api/control/insert-route-stops/';
  static const String CREATE_ROUTE_INCIDENTS =
      'web/api/control/insert-route-incidents/';
  static const String MAINTANCE_UPLOAD = 'control/maintenances/upload/';
  static const String GET_LOCATION = 'web/api/control/get-location/';
  static const String FINISH_ROUTE = 'web/api/control/finish-route/';
  static const String CANCEL_ROUTE = 'web/api/control/cancel-route/';

  static auth() {
    var credentials = base64Encode(
        utf8.encode('${ENDPOINTS.USERNAME}:${ENDPOINTS.PASSWORD}'));

    return 'Basic $credentials';
  }
}
