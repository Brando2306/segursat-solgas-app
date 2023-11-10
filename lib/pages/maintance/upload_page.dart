import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/utils/maintance/index.dart';
import 'package:safe_driving_app/utils/storage.dart';
import 'package:safe_driving_app/widgets/header.dart';
import 'package:safe_driving_app/widgets/next_button.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  late final ImagePicker _imagePicker;
  bool imageVisibility1 = false;
  bool imageVisibility2 = false;
  bool imageVisibility3 = false;

  @override
  void initState() {
    super.initState();
    _imagePicker = ImagePicker();
    printStorage();
  }

  Future<void> _selectFile(String storage) async {
    final pickedFile =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        writeStorage('maintance.form.file.$storage', pickedFile.path);
        showLabelCompleted(storage);
      });
    }
  }

  Future<void> _takePhoto(String storage) async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        writeStorage('maintance.form.file.$storage', pickedFile.path);
        showLabelCompleted(storage);
      });
    }
  }

  void showLabelCompleted(String storage) {
    if (storage == 'one') {
      imageVisibility1 = true;
    } else if (storage == 'thow') {
      imageVisibility2 = true;
    } else if (storage == 'three') {
      imageVisibility3 = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          appBar: header(ODOMETERMAINTANCE.TEXT_HEADER),
          resizeToAvoidBottomInset: false,
          body: Column(
            children: [
              SizedBox(
                height: getHeight(context, 4),
              ),
              SizedBox(
                width: getWidth(context, 90),
                child: Align(
                  // alignment: Alignment.centerLeft,
                  child: Text(
                    'Evidencia - Imagen 01 (opciónal)',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              SizedBox(
                height: getHeight(context, 2),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _selectFile('one'),
                    label: Text(
                      'Cargar imagen',
                      style: TextStyle(color: Color(0xff00a86b)),
                    ),
                    icon: Icon(Icons.attach_file, color: Color(0xff00a86b)),
                    style: ButtonStyle(
                        // overlayColor: MaterialStateProperty.all(Colors.green),
                        backgroundColor:
                            MaterialStateProperty.all(Color(0xffcffaea))),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _takePhoto('one'),
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
                ],
              ),
              Visibility(
                visible: imageVisibility1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8), // Espacio entre el icono y el texto
                    Text(
                      'Imagen subida correctamente',
                      style: TextStyle(color: Colors.green, fontSize: 16),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: getHeight(context, 6),
              ),
              SizedBox(
                width: getWidth(context, 90),
                child: Align(
                  // alignment: Alignment.centerLeft,
                  child: Text(
                    'Evidencia - Imagen 02 (opciónal)',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              SizedBox(
                height: getHeight(context, 2),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _selectFile('thow'),
                    label: Text(
                      'Cargar imagen',
                      style: TextStyle(color: Color(0xff00a86b)),
                    ),
                    icon: Icon(Icons.attach_file, color: Color(0xff00a86b)),
                    style: ButtonStyle(
                        // overlayColor: MaterialStateProperty.all(Colors.green),
                        backgroundColor:
                            MaterialStateProperty.all(Color(0xffcffaea))),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _takePhoto('thow'),
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
                ],
              ),
              Visibility(
                visible: imageVisibility2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8), // Espacio entre el icono y el texto
                    Text(
                      'Imagen subida correctamente',
                      style: TextStyle(color: Colors.green, fontSize: 16),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: getHeight(context, 6),
              ),
              SizedBox(
                width: getWidth(context, 90),
                child: Align(
                  // alignment: Alignment.centerLeft,
                  child: Text(
                    'Evidencia - Imagen 03 (opciónal)',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              SizedBox(
                height: getHeight(context, 2),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _selectFile('three'),
                    label: Text(
                      'Cargar imagen',
                      style: TextStyle(color: Color(0xff00a86b)),
                    ),
                    icon: Icon(Icons.attach_file, color: Color(0xff00a86b)),
                    style: ButtonStyle(
                        // overlayColor: MaterialStateProperty.all(Colors.green),
                        backgroundColor:
                            MaterialStateProperty.all(Color(0xffcffaea))),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _takePhoto('three'),
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
                ],
              ),
              Visibility(
                visible: imageVisibility3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8), // Espacio entre el icono y el texto
                    Text(
                      'Imagen subida correctamente',
                      style: TextStyle(color: Colors.green, fontSize: 16),
                    ),
                  ],
                ),
              ),
              Expanded(child: Container()),
              nextButton(
                  context, 'siguiente', '/maintance/finish', true, () {}, null),
              SizedBox(
                height: getHeight(context, 3),
              ),
              // if (_selectedFileOne != null) Image.file(_selectedFileOne!),
            ],
          ),
        ));
  }
}
