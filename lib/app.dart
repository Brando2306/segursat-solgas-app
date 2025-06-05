import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:safe_driving_app/features/offline_operations/presentation/pages/offline_operations_screen.dart';
import 'package:safe_driving_app/features/offline_operations/presentation/widgets/offline_operations_list_widget.dart';
import 'package:safe_driving_app/pages/inspection/accessories_page.dart';
import 'package:safe_driving_app/pages/inspection/finish_page.dart';
import 'package:safe_driving_app/pages/inspection/odometer_page.dart';
import 'package:safe_driving_app/pages/inspection/panoramic_page.dart';
import 'package:safe_driving_app/pages/inspection/question_page.dart';
import 'package:safe_driving_app/pages/inspection/seatbelt_page.dart';
import 'package:safe_driving_app/pages/inspection/selfie_page.dart';
import 'package:safe_driving_app/pages/load_page.dart';
import 'package:safe_driving_app/pages/maintance/finish_maintante.dart';
import 'package:safe_driving_app/pages/maintance/form_page.dart';
import 'package:safe_driving_app/pages/maintance/odometer_maintance_page.dart';
import 'package:safe_driving_app/pages/maintance/upload_page.dart';
import 'package:safe_driving_app/pages/menu_page.dart';
import 'package:safe_driving_app/pages/root/speedometer_page.dart';
import 'package:safe_driving_app/pages/root/control_stop_page.dart';
import 'package:safe_driving_app/pages/root/finish_root_page.dart';
import 'package:safe_driving_app/pages/root/incident_report_page.dart';
import 'package:safe_driving_app/pages/root/select_destination_page.dart';
import 'package:safe_driving_app/pages/root/select_source_page.dart';
import 'package:safe_driving_app/pages/sesion_page.dart';
import 'package:safe_driving_app/pages/start_page.dart';
import 'package:safe_driving_app/pages/statement_page.dart';
import 'package:safe_driving_app/services/notification_services.dart';
import 'package:safe_driving_app/utils/snackbars.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addObserver(this);

    super.dispose();
  }

  Future<void> main() async {
    WidgetsFlutterBinding.ensureInitialized();

    await initNotifications();

    runApp(
      MaterialApp(
        home: LoadPage(),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.paused:
        log('==> MyApp: ${AppLifecycleState.paused}');
        break;
      case AppLifecycleState.resumed:
        log('==> MyApp: ${AppLifecycleState.resumed}');
        break;
      case AppLifecycleState.inactive:
        log('==> MyApp: ${AppLifecycleState.inactive}');
        break;
      case AppLifecycleState.detached:
        log('==> MyApp: ${AppLifecycleState.detached}');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Safe Driving App',
      initialRoute: '/',
      routes: {
        '/': (context) => LoadPage(),
        '/startPage': (context) => StartPage(),
        '/statement': (context) => StatementPage(),
        '/sesion': (content) => SesionPage(),
        '/menu': (context) => MenuPage(),
        '/offlineOperations': (context) => OfflineOperationsPage(),
        '/offlineOperationsList': (context) => OfflineOperationsListPage(
              title: 'Operaciones Offline',
              operations: const [],
            ),
        '/inspection/question': (context) => QuestionPage(),
        '/inspection/odometer': (context) => OdometerPage(),
        '/inspection/selfie': (context) => SelfiePage(), // Photo
        '/inspection/accessories': (context) => AccessoriesPage(), // Photo
        '/inspection/panoramic': (context) => PanoramicPage(), // Photo
        '/inspection/seatbelt': (context) => SeatbeltPage(), // Photo
        // '/inspection/odometerPhoto': (context) => OdometerPhotoPage(), // Photo
        '/inspection/finish': (context) => FinishPage(),
        '/root/selectSource': (context) => SelectSourcePage(),
        '/root/selectDestination': (context) => SelectDestinationPage(),
        '/root/speedometer': (context) => SpeedometerPage(),
        '/root/controlStop': (context) => ControlStopPage(),
        '/root/incidentReport': (context) => IncidentReportPage(),
        '/root/finish': (context) => FinishRootPage(),
        '/maintance/odometer': (context) => OdometerMaintancePage(),
        '/maintance/form': (context) => FormPage(),
        '/maintance/upload': (context) => UploadPage(),
        '/maintance/finish': (context) => FinishMaintancePage(),
      },
      builder: EasyLoading.init(),
      scaffoldMessengerKey: Snackbars.messengerKey,
    );
  }
}
