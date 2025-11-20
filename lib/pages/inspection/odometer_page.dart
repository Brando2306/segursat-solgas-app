import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:image_picker/image_picker.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/utils/inspection/index.dart';
import 'package:safe_driving_app/utils/snackbars.dart';
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
    // Leemos aquí el valor anterior para mostrarlo en la UI
    final int previousOdometer =
        (readStorage('inspection.lastOdometer') ?? 0) as int;

    return WillPopScope(
      onWillPop: (() async => false),
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: header(ODOMETER.TEXT_HEADER),
          resizeToAvoidBottomInset: false,
          body: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: getWidth(context, 5)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: getHeight(context, 1)),

                  // 💬 Descripción corta
                  Text(
                    'Por favor ingresa el valor actual del odómetro y toma una fotografía como evidencia para continuar con la inspección.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                  SizedBox(height: getHeight(context, 3)),

                  // 🕓 Mostrar odómetro anterior si existe
                  if (previousOdometer > 0) ...[
                    Row(
                      children: [
                        Icon(Icons.history,
                            color: Colors.grey.shade600, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Tu odómetro anterior fue:',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade700),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$previousOdometer km',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blueGrey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: getHeight(context, 2)),
                  ],

                  // ℹ️ Mensaje informativo (actualizado: "mayor o igual")
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            previousOdometer > 0
                                ? 'Importante: el valor que ingreses puede ser mayor o igual al odómetro anterior.'
                                : 'Importante: ingresa el valor actual del odómetro.',
                            style: TextStyle(
                                color: Colors.blue.shade700, fontSize: 13.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: getHeight(context, 3)),

                  // 🧮 Campo de texto (odómetro)
                  Text(
                    ODOMETER.LABEL_ODOMETER,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),

                  SizedBox(height: getHeight(context, 1.5)),

                  odometerInput(context),

                  SizedBox(height: getHeight(context, 4)),

                  // 📸 Imagen del odómetro
                  Text(
                    ODOMETER.LABEL_IMAGE,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: getHeight(context, 1)),

                  Container(
                    height: getHeight(context, 40),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey.shade100,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: FadeInImage(
                      placeholder: AssetImage('assets/images/odometer.jpg'),
                      image:
                          fileImage ?? AssetImage('assets/images/odometer.jpg'),
                      fit: BoxFit.fill,
                    ),
                  ),

                  SizedBox(height: getHeight(context, 1.5)),

                  Center(
                    child: ElevatedButton.icon(
                      onPressed: captureImage,
                      icon: Icon(Icons.camera_alt, color: Color(0xff00a86b)),
                      label: Text(
                        'Tomar fotografía',
                        style: TextStyle(color: Color(0xff00a86b)),
                      ),
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Color(0xffcffaea)),
                      ),
                    ),
                  ),

                  SizedBox(height: getHeight(context, 4)),

                  // 🔘 Botón siguiente (centrado)
                  Center(
                    child: nextButton(
                      context,
                      'Siguiente',
                      '/inspection/selfie',
                      validationNextButton && (fileImage != null),
                      () {
                        writeStorage('odometer.odometerNumber',
                            _odometerInpuController.text);
                      },
                      null,
                    ),
                  ),
                  SizedBox(height: getHeight(context, 5)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void captureImage() async {
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

        Snackbars.showSnackbarSuccess(
            'Foto del odómetro guardada correctamente');
      }
    } catch (e) {
      print(e);
    }
  }

  FormBuilder odometerInput(context) {
    return FormBuilder(
      key: _formKeyOdometer,
      child: FormBuilderTextField(
        name: 'odometer',
        onChanged: (value) {
          setState(() =>
              validationNextButton = _formKeyOdometer.currentState!.validate());
        },
        decoration: InputDecoration(
          enabled: true,
          labelText: ODOMETER.TEXT_LABEL,
          hintText: 'Ejemplo: 125000',
          filled: true,
          fillColor: Colors.blue.shade100,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
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
              readStorage('inspection.lastOdometer') ?? 0;

          // Permitimos igualdad: valor >= anterior
          if (newOdometerValue < previousOdometerValue) {
            return 'El valor del odómetro no puede ser menor al registro anterior';
          }
          return null;
        },
      ),
    );
  }
}
