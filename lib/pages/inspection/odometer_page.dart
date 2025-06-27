import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:image_picker/image_picker.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/utils/inspection/index.dart';
import 'package:safe_driving_app/utils/storage.dart';
import 'package:safe_driving_app/widgets/header.dart';
import 'package:safe_driving_app/widgets/next_button.dart';

class OdometerPage extends StatefulWidget {
  const OdometerPage({super.key});

  @override
  State<OdometerPage> createState() => _OdometerPageState();
}

class _OdometerPageState extends State<OdometerPage> {
  final _formKeyOdometer = GlobalKey<FormBuilderState>();
  final _odometerInpuController = TextEditingController();

  bool validationNextButton = false;

  // Image
  final ImagePicker _picker = ImagePicker();
  var fileImage;

  @override
  void initState() {
    super.initState();
    printStorage();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: (() async => false),
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
            appBar: header(ODOMETER.TEXT_HEADER),
            resizeToAvoidBottomInset: false,
            body: Column(
              children: [
                SizedBox(
                  height: getHeight(context, 4),
                ),
                form(context),
                SizedBox(
                  height: getHeight(context, 4),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(
                      getWidth(context, 5), 0, getWidth(context, 5), 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      ODOMETER.LABEL_IMAGE,
                      // textAlign: TextAlign.left,
                      style: TextStyle(
                          fontSize: 14,
                          // fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                  ),
                ),
                SizedBox(
                  height: getHeight(context, 2),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(
                      getWidth(context, 5), 0, getWidth(context, 5), 0),
                  height: getHeight(context, 35),
                  child: FadeInImage(
                      placeholder: AssetImage('assets/images/odometer.jpg'),
                      image: fileImage ??
                          AssetImage('assets/images/odometer.jpg')),
                ),
                SizedBox(
                  height: getHeight(context, 1),
                ),
                ElevatedButton.icon(
                  onPressed: captureImage,
                  label: Text(
                    'Tomar fotografía',
                    style: TextStyle(color: Color(0xff00a86b)),
                  ),
                  icon: Icon(Icons.camera_alt, color: Color(0xff00a86b)),
                  style: ButtonStyle(
                      // overlayColor: MaterialStateProperty.all(Colors.green),
                      backgroundColor:
                          MaterialStateProperty.all(Color(0xffcffaea))),
                ),
                Expanded(child: Container()),
                nextButton(context, 'Siguiente', '/inspection/selfie',
                    validationNextButton && (fileImage == null ? false : true),
                    () {
                  writeStorage(
                      'odometer.odometerNumber', _odometerInpuController.text);
                }, null),
                SizedBox(
                  height: getHeight(context, 3),
                ),
              ],
            )),
      ),
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

          writeStorage('odometerPhoto.file', file.path);

          EasyLoading.dismiss();
        }
      } catch (e) {
        print(e);
      }
    }
  }

  Container form(context) {
    return Container(
      margin:
          EdgeInsets.fromLTRB(getWidth(context, 5), 0, getWidth(context, 5), 0),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: const [Text(ODOMETER.LABEL_ODOMETER)],
        ),
        SizedBox(height: getHeight(context, 2)),
        odometerInput(context)
      ]),
    );
  }

  FormBuilder odometerInput(context) {
    return FormBuilder(
      key: _formKeyOdometer,
      child: FormBuilderTextField(
          name: 'odometer',
          onChanged: (value) {
            setState(() => validationNextButton =
                _formKeyOdometer.currentState!.validate());
          },
          decoration: InputDecoration(
              enabled: true,
              labelText: ODOMETER.TEXT_LABEL,
              filled: true,
              fillColor: Colors.blue.shade100,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly
          ],
          controller: _odometerInpuController,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Se requiere el odómetro';
            }

            int newOdometerValue = int.tryParse(value) ?? 0;
            int previousOdometerValue =
                readStorage('inspection.lastOdometer') ??
                    0; // Valor anterior del odómetro

            if (newOdometerValue == previousOdometerValue) {
              return 'El valor del odómetro no puede ser igual al registro anterior';
            }

            if (newOdometerValue < previousOdometerValue) {
              return 'El valor del odómetro no puede ser menor al registro anterior';
            }
            return null;
          }),
    );
  }
}
