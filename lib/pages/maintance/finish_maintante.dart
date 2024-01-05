import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/utils/endpoints.dart';
import 'package:safe_driving_app/utils/inspection/index.dart';
import 'package:safe_driving_app/utils/storage.dart';
import 'package:safe_driving_app/utils/style.dart';

class FinishMaintancePage extends StatefulWidget {
  const FinishMaintancePage({super.key});

  @override
  State<FinishMaintancePage> createState() => _FinishMaintancePageState();
}

class _FinishMaintancePageState extends State<FinishMaintancePage> {
  bool blockButton = true;
  Position? position;
  @override
  void initState() {
    super.initState();
    printStorage();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: (() async => false),
      child: Scaffold(
          body: Column(children: [
        Expanded(child: Container()),
        Image.asset(FINISH.IMAGE),
        SizedBox(
          width: getWidth(context, 80),
          child: Text(
            'Datos ingresados correctamente',
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
            if (blockButton) {
              submit(context);
            }
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

  submit(context) async {
    setState(() => blockButton = false);
    EasyLoading.show(status: 'Enviando...');

    try {
      Dio dio = Dio();

      FormData formData = FormData.fromMap({
        'timestamp': getDate(),
        'driver_id_number': readStorage('personal.document'),
        'driver_fullname':
            '${readStorage('personal.name')} ${readStorage('personal.lastName')}',
        'unit_name': readStorage('personal.licensePlate'),
        'duration_time': 123151,
        'next_maintenance_odometer':
            readStorage('maintance.form.nextOdometerNumber'),
        'odometer': readStorage('maintance.odometer.odometerNumber'),
        'image1': await MultipartFile.fromFile(
          readStorage('maintance.odometer.file'),
        ),
      });

      if (readStorage('maintance.form.file.one') != null) {
        formData.files.add(
          MapEntry(
            'image2',
            await MultipartFile.fromFile(
              readStorage('maintance.form.file.one'),
            ),
          ),
        );
      }

      if (readStorage('maintance.form.file.thow') != null) {
        formData.files.add(
          MapEntry(
            'image3',
            await MultipartFile.fromFile(
              readStorage('maintance.form.file.thow'),
            ),
          ),
        );
      }

      if (readStorage('maintance.form.file.three') != null) {
        formData.files.add(
          MapEntry(
            'image4',
            await MultipartFile.fromFile(
              readStorage('maintance.form.file.three'),
            ),
          ),
        );
      }

      for (var entry in formData.fields) {
        if (entry.value != null) {
          print('Campo: ${entry.key}, Valor: ${entry.value ?? ''}');
        }
      }

      for (var entry in formData.files) {
        String nombreArchivo = entry.key;
        String? nombreCompleto = entry.value.filename;
        String extension = entry.value.filename!.split('.').last;

        print('Nombre del archivo: $nombreArchivo');
        print('Nombre completo: $nombreCompleto');
        print('Extensión: $extension');
      }

      var response = await dio.post(
          'http://${ENDPOINTS.HOST}/${ENDPOINTS.MAINTANCE_UPLOAD}',
          data: formData,
          options: Options(headers: {
            'Authorization': ENDPOINTS.auth(),
          }));

      print('response: ${ENDPOINTS.MAINTANCE_UPLOAD} => $response');

      if (response.statusCode == 200 && response.data['status'] == 'OK') {
        cleanMaintance();

        Navigator.pushNamed(context, '/menu');
      } else {
        notificationAlert(context, 'Algo ocurrió, intente finalizar otra vez.');
        setState(() => blockButton = true);
      }
    } catch (e) {
      notificationError(context, e.toString());

      setState(() => blockButton = true);
    }
    EasyLoading.dismiss();
  }
}
