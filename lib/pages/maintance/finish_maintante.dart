import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/utils/inspection/index.dart';
import 'package:safe_driving_app/utils/storage.dart';
import 'package:safe_driving_app/utils/style.dart';

class FinishMaintancePage extends StatefulWidget {
  const FinishMaintancePage({super.key});

  @override
  State<FinishMaintancePage> createState() => _FinishMaintancePageState();
}

class _FinishMaintancePageState extends State<FinishMaintancePage> {
  bool? wasSavedOnline;
  Position? position;
  @override
  void initState() {
    super.initState();
    printStorage();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is bool) {
      wasSavedOnline = args;
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = wasSavedOnline == true
        ? 'Datos enviados correctamente al servidor'
        : 'Sin conexión: datos guardados localmente';

    return WillPopScope(
      onWillPop: (() async => false),
      child: Scaffold(
          body: Column(children: [
        Expanded(child: Container()),
        Image.asset(FINISH.IMAGE),
        SizedBox(
          width: getWidth(context, 80),
          child: Text(
            message,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        // ...nextButtonV2(context, FINISH.TEXT_BUTTON, '/menu', true, () {
        //   submit();
        // })
        Expanded(child: Container()),
        MaterialButton(
          onPressed: () {
            Navigator.pushNamed(context, '/menu');
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          color: CustomColors.primary,
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.height * 0.15,
                vertical: 15),
            child: Text(
              FINISH.TEXT_BUTTON,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        SizedBox(
          height: getHeight(context, 3),
        )
      ])),
    );
  }
}
