import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/utils/constants.dart';
import 'package:safe_driving_app/utils/endpoints.dart';
import 'package:safe_driving_app/utils/errors.dart';
import 'package:safe_driving_app/utils/inspection/index.dart';
import 'package:safe_driving_app/utils/storage.dart';
import 'package:safe_driving_app/utils/style.dart';

class FinishPage extends StatefulWidget {
  const FinishPage({super.key});

  @override
  State<FinishPage> createState() => _FinishPageState();
}

class _FinishPageState extends State<FinishPage> {
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
            FINISH.TEXT_CENTER,
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

      Position position = await Geolocator.getCurrentPosition();

      FormData formData = FormData.fromMap({
        'timestamp': getDate(),
        'latitude': position.latitude,
        'longitude': position.longitude,
        'driver_id_number': readStorage('personal.document'),
        'driver_fullname':
            '${readStorage('personal.name')} ${readStorage('personal.lastName')}',
        'unit_name': readStorage('personal.licensePlate'),
        'duration_time': 123151,
        'odometer': readStorage('odometer.odometerNumber'),
        'questions': json.encode([
          {
            'question': QUESTION.TEXT_QUESTION_ONE,
            'answer': readStorage('question.one'),
            'type': 'bool',
          },
          {
            'question': QUESTION.TEXT_QUESTION_TWO,
            'answer': readStorage('question.two'),
            'type': 'bool',
          },
          {
            'question': QUESTION.TEXT_QUESTION_THREE,
            'answer': readStorage('question.three'),
            'type': 'bool',
          },
        ]),
      });

      // Add images conditionally
      if (readStorage('odometerPhoto.file') != null) {
        formData.files.add(MapEntry(
          'image1',
          await MultipartFile.fromFile(readStorage('odometerPhoto.file')),
        ));
      }

      if (readStorage('selfie.file') != null) {
        formData.files.add(MapEntry(
          'image2',
          await MultipartFile.fromFile(readStorage('selfie.file')),
        ));
      }

      if (readStorage('panoramic.file') != null) {
        formData.files.add(MapEntry(
          'image3',
          await MultipartFile.fromFile(readStorage('panoramic.file')),
        ));
      }

      if (readStorage('seatbelt.file') != null) {
        formData.files.add(MapEntry(
          'image4',
          await MultipartFile.fromFile(readStorage('seatbelt.file')),
        ));
      }

      if (readStorage('accessories.file') != null) {
        formData.files.add(MapEntry(
          'image5',
          await MultipartFile.fromFile(readStorage('accessories.file')),
        ));
      }

      for (var entry in formData.fields) {
        print('Campo: ${entry.key}, Valor: ${entry.value}');
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
          'http://${ENDPOINTS.HOST}/${ENDPOINTS.INSPECTION_UPLOAD}',
          data: formData,
          options: Options(headers: {
            'Authorization': ENDPOINTS.auth(),
          }));

      print('response: ${ENDPOINTS.INSPECTION_UPLOAD} => $response');

      if (response.statusCode == STATUSCODE.OK) {
        EasyLoading.dismiss();
        cleanQuestionStorage();
        cleanInspection();

        writeStorage('inspection.isCompleted',
            '${readStorage('personal.document')}-${FINISH.COMPLETED}');

        Navigator.pushNamed(context, '/menu');
      } else {
        notificationAlert(context, 'Algo ocurrió, intente finalizar otra vez.');
        setState(() => blockButton = true);
      }
    } catch (e) {
      notificationError(
          context, errorTranslations[e.toString()] ?? e.toString());
      setState(() => blockButton = true);
    }
    EasyLoading.dismiss();
  }
}
