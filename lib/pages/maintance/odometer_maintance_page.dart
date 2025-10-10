import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:image_picker/image_picker.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/utils/maintance/index.dart';
import 'package:safe_driving_app/utils/snackbars.dart';
import 'package:safe_driving_app/utils/storage.dart';
import 'package:safe_driving_app/widgets/header.dart';
import 'package:safe_driving_app/widgets/next_button.dart';

class OdometerMaintancePage extends StatefulWidget {
  const OdometerMaintancePage({super.key});

  @override
  State<OdometerMaintancePage> createState() => _OdometerMaintancePageState();
}

class _OdometerMaintancePageState extends State<OdometerMaintancePage> {
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
          appBar: header(context),
          resizeToAvoidBottomInset: false,
          body: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: getWidth(context, 5)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: getHeight(context, 1)),

                  // 💬 Subtítulo
                  Text(
                    'Por favor ingresa el valor actual del odómetro y toma una fotografía como evidencia para continuar con el mantenimiento.',
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

                  // ⚠️ Mensaje informativo
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.amber.shade800, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Recuerda: el valor que ingreses debe ser mayor al odómetro anterior.',
                            style: TextStyle(
                                color: Colors.amber.shade800, fontSize: 13.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: getHeight(context, 3)),

                  // 🧮 Campo de texto (odómetro
                  Text(
                    ODOMETERMAINTANCE.LABEL_ODOMETER,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),

                  SizedBox(height: getHeight(context, 1.5)),

                  // 🧮 Campo de texto (Formulario)
                  odometerInput(context),
                  SizedBox(height: getHeight(context, 4)),

                  // 📷 Imagen del odómetro
                  Text(
                    ODOMETERMAINTANCE.LABEL_IMAGE,
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
                      label: Text(
                        'Tomar fotografía',
                        style: TextStyle(color: Color(0xff00a86b)),
                      ),
                      icon: Icon(Icons.camera_alt, color: Color(0xff00a86b)),
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Color(0xffcffaea)),
                      ),
                    ),
                  ),

                  SizedBox(height: getHeight(context, 4)),

                  // 🔘 Botón siguiente
                  Center(
                    child: nextButton(
                      context,
                      'Siguiente',
                      '/maintance/form',
                      validationNextButton && (fileImage != null),
                      () {
                        writeStorage('maintance.odometer.odometerNumber',
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

          writeStorage('maintance.odometer.file', file.path);

          EasyLoading.dismiss();

          Snackbars.showSnackbarSuccess(
              'Foto del odómetro guardada correctamente');
        }
      } catch (e) {
        print(e);
      }
    }
  }

  Container form(context) {
    int? previousOdometerValue = readStorage('inspection.lastOdometer');

    return Container(
      margin:
          EdgeInsets.fromLTRB(getWidth(context, 5), 0, getWidth(context, 5), 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: const [
              Text(ODOMETERMAINTANCE.LABEL_ODOMETER),
            ],
          ),
          SizedBox(height: getHeight(context, 1.5)),

          // 👇 Aquí viene el mensaje si hay un odómetro anterior
          if (previousOdometerValue != null && previousOdometerValue > 0)
            Container(
              margin: EdgeInsets.only(bottom: getHeight(context, 1)),
              child: Row(
                children: [
                  Icon(Icons.history, color: Colors.grey.shade600, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Tu odómetro anterior fue: ',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  Text(
                    '$previousOdometerValue km',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blueGrey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // 👇 Este mensaje informativo siempre aparece antes del input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: Colors.amber.shade800, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recuerda: el valor del odómetro que ingreses debe ser mayor al registrado anteriormente.',
                    style:
                        TextStyle(color: Colors.amber.shade800, fontSize: 13.5),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: getHeight(context, 3)),

          SizedBox(height: getHeight(context, 1.5)),

          // 👇 Aquí sigue tu campo de texto original
          odometerInput(context),
        ],
      ),
    );
  }

  FormBuilder odometerInput(context) {
    return FormBuilder(
      key: _formKeyOdometer,
      child: FormBuilderTextField(
          name: 'odometer',
          onChanged: (value) {
            setState(() {
              validationNextButton = _formKeyOdometer.currentState!.validate();
            });
          },
          decoration: InputDecoration(
              enabled: true,
              labelText: ODOMETERMAINTANCE.TEXT_LABEL,
              hintText: 'Ejemplo: 125000',
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
                readStorage('inspection.lastOdometer') ?? 0;

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

  AppBar header(context) {
    return headerV2(
        ODOMETERMAINTANCE.TEXT_HEADER,
        Builder(
          builder: (context) => IconButton(
              onPressed: () {
                cleanMaintance();
                Navigator.pushNamed(context, '/menu');
              },
              icon: Icon(Icons.home),
              color: Colors.black,
              tooltip: 'Salir del mantenimiento'),
        ));
  }
}
