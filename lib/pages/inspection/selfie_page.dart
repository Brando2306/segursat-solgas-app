import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:image_picker/image_picker.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/utils/inspection/index.dart';
import 'package:safe_driving_app/utils/storage.dart';
import 'package:safe_driving_app/utils/style.dart';
import 'package:safe_driving_app/widgets/header.dart';
import 'package:safe_driving_app/widgets/next_button.dart';
import 'dart:io';

import 'package:safe_driving_app/widgets/inspection/title_photo.dart';

class SelfiePage extends StatefulWidget {
  const SelfiePage({super.key});

  @override
  State<StatefulWidget> createState() => _SelfiePageState();
}

class _SelfiePageState extends State<SelfiePage> {
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
      child: Scaffold(
          appBar: header(
            SELFIE.TEXT_HEADER,
          ),
          body: Column(
            children: [
              SizedBox(
                height: getHeight(context, 3),
              ),
              titlePhoto(SELFIE.TEXT_IMAGE),
              SizedBox(
                height: getHeight(context, 2),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                height: getHeight(context, 55),
                child: FadeInImage(
                    placeholder: AssetImage('assets/images/selfie.png'),
                    image: fileImage ?? AssetImage('assets/images/selfie.png')),
              ),
              SizedBox(
                height: getHeight(context, 2),
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
              (fileImage == null ? false : true)
                  ? nextButton(
                      context,
                      SELFIE.TEXT_BUTTON,
                      '/inspection/accessories',
                      fileImage == null ? false : true,
                      () {},
                      null)
                  : Container(),
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

          writeStorage('selfie.file', file.path);

          EasyLoading.dismiss();
        }
      } catch (e) {
        print(e);
      }
    }
  }
}
