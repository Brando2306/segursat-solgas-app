import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:safe_driving_app/features/maintenance/domain/entities/maintenance_entity.dart';
import 'package:safe_driving_app/features/maintenance/presentation/providers/maintenance_provider.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/shared/button_widget.dart';
import 'package:safe_driving_app/utils/maintance/index.dart';
import 'package:safe_driving_app/utils/storage.dart';
import 'package:safe_driving_app/utils/style.dart';
import 'package:safe_driving_app/widgets/header.dart';

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
              Consumer<MaintenanceProvider>(
                builder: (context, provider,  child) {
                  return ButtonWidget(
                    width: double.infinity,
                    loading: provider.isLoading,
                    disabled: provider.isLoading,
                    colorDisabled: CustomColors.primary.withOpacity(0.5),
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
                            await _submit(context, provider);
                          },
                  );
                },
              ),
              // nextButton(
              //     context, 'siguiente', '/maintance/finish', true, () {}, null),
              SizedBox(
                height: getHeight(context, 3),
              ),
              // if (_selectedFileOne != null) Image.file(_selectedFileOne!),
            ],
          ),
        ));
  }

  Future<void> _submit(
      BuildContext context, MaintenanceProvider provider) async {
    bool wasSavedOnline = true;

    try {
      final maintenance = MaintenanceEntity(
        driverIdNumber: readStorage('personal.document'),
        driverFullName:
            '${readStorage('personal.name')} ${readStorage('personal.lastName')}',
        unitName: readStorage('personal.licensePlate'),
        odometer: readStorage('maintance.odometer.odometerNumber'),
        nextMaintenanceOdometer:
            readStorage('maintance.form.nextOdometerNumber'),
        durationTime: 123151, // Este valor debería venir de algún cálculo
        timestamp: getDate(),
        odometerImagePath: readStorage('maintance.odometer.file'),
        additionalImagePaths: [
          if (readStorage('maintance.form.file.one') != null)
            readStorage('maintance.form.file.one'),
          if (readStorage('maintance.form.file.thow') != null)
            readStorage('maintance.form.file.thow'),
          if (readStorage('maintance.form.file.three') != null)
            readStorage('maintance.form.file.three'),
        ].where((path) => path != null).cast<String>().toList(),
      );

      await provider.submitMaintenanceData(maintenance);
    } catch (e) {
      wasSavedOnline = false;
    } finally {
      cleanMaintance();
      Navigator.pushNamed(
        context,
        '/maintance/finish',
        arguments: wasSavedOnline,
      );
    }
  }
}
