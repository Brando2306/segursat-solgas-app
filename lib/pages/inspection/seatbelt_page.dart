import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:safe_driving_app/features/inspection/domain/entities/inspection_entity.dart';
import 'package:safe_driving_app/features/inspection/presentation/providers/inspection_provider.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/shared/button_widget.dart';
import 'package:safe_driving_app/utils/errors.dart';
import 'package:safe_driving_app/utils/inspection/index.dart';
import 'package:safe_driving_app/utils/storage.dart';
import 'package:safe_driving_app/utils/style.dart';
import 'package:safe_driving_app/widgets/header.dart';
import 'dart:io';

import 'package:safe_driving_app/widgets/inspection/title_photo.dart';

class SeatbeltPage extends StatefulWidget {
  const SeatbeltPage({super.key});

  @override
  State<SeatbeltPage> createState() => _SeatbeltPageState();
}

class _SeatbeltPageState extends State<SeatbeltPage> {
  final ImagePicker _picker = ImagePicker();
  var fileImage;

  @override
  void initState() {
    super.initState();
    printStorage();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return WillPopScope(
      onWillPop: (() async => false),
      child: Scaffold(
          appBar: header(SEATBELT.TEXT_HEADER),
          body: Column(
            children: [
              SizedBox(
                height: getHeight(context, 3),
              ),
              titlePhoto(SEATBELT.TEXT_IMAGE),
              SizedBox(
                height: getHeight(context, 2),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                height: getHeight(context, 55),
                child: FadeInImage(
                    width: size.width * 0.8,
                    placeholder: AssetImage('assets/images/seatbelt2.png'),
                    image:
                        fileImage ?? AssetImage('assets/images/seatbelt2.png')),
              ),
              SizedBox(
                height: getHeight(context, 2),
              ),
              ElevatedButton.icon(
                onPressed: captureImage,
                label: Text(
                  'Tomar fotografia',
                  style: TextStyle(color: Color(0xff00a86b)),
                ),
                icon: Icon(Icons.camera_alt, color: Color(0xff00a86b)),
                style: ButtonStyle(
                    // overlayColor: MaterialStateProperty.all(Colors.green),
                    backgroundColor:
                        MaterialStateProperty.all(Color(0xffcffaea))),
              ),
              Expanded(child: Container()),
              (fileImage == null ? false : true)
                  // ? nextButton(
                  //     context,
                  //     SEATBELT.TEXT_BUTTON,
                  //     '/inspection/finish',
                  //     fileImage == null ? false : true,
                  //     () {},
                  //     null)
                  ? Consumer<InspectionProvider>(
                      builder: (context, provider, child) {
                        return ButtonWidget(
                          width: double.infinity,
                          loading: provider.isLoading,
                          disabled: provider.isLoading,
                          colorDisabled: CustomColors.primary.withOpacity(0.5),
                          padding: EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                          margin: EdgeInsets.symmetric(horizontal: 40),
                          text: provider.isLoading ? 'Enviando...' : 'Guardar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                          color: CustomColors.primary,
                          onPressed: provider.isLoading
                              ? null
                              : () async {
                                  await submit(context, provider);
                                },
                        );
                      },
                    )
                  : SizedBox(),
              SizedBox(
                height: getHeight(context, 3),
              )
            ],
          )),
    );
  }

  void captureImage() async {
    {
      try {
        XFile? image = await _picker.pickImage(
            source: ImageSource.camera, maxHeight: 720, maxWidth: 1280);

        if (image != null) {
          EasyLoading.show(status: 'Cargando...');

          File file = File(image.path);

          setState(() {
            fileImage = FileImage(file);
          });

          writeStorage('seatbelt.file', file.path);

          EasyLoading.dismiss();
        }
      } catch (e) {
        print(e);
      }
    }
  }

  Future<void> submit(BuildContext context, InspectionProvider provider) async {
    bool wasSavedOnline = true;
    EasyLoading.show(status: 'Enviando...');

    try {
      final position = await Geolocator.getCurrentPosition();

      final inspection = InspectionEntity(
        driverIdNumber: readStorage('personal.document'),
        driverFullName:
            '${readStorage('personal.name')} ${readStorage('personal.lastName')}',
        unitName: readStorage('personal.licensePlate'),
        odometer: readStorage('odometer.odometerNumber'),
        timestamp: getDate(),
        latitude: position.latitude,
        longitude: position.longitude,
        questions: [
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
        ],
        odometerImagePath: readStorage('odometerPhoto.file'),
        selfieImagePath: readStorage('selfie.file'),
        panoramicImagePath: readStorage('panoramic.file'),
        seatbeltImagePath: readStorage('seatbelt.file'),
        accessoriesImagePath: readStorage('accessories.file'),
      );

      await provider.submitInspectionData(inspection);

      writeStorage(
        'inspection.isCompleted',
        '${readStorage('personal.document')}-${FINISH.COMPLETED}',
      );
    } catch (e) {
      wasSavedOnline = false;
      notificationError(
          context, errorTranslations[e.toString()] ?? e.toString());
    } finally {
      cleanQuestionStorage();
      cleanInspection();
      EasyLoading.dismiss();
      Navigator.pushNamed(
        context,
        '/inspection/finish',
        arguments: wasSavedOnline,
      );
    }
  }
}
