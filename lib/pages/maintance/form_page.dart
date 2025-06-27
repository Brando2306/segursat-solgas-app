import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/utils/maintance/index.dart';
import 'package:safe_driving_app/utils/storage.dart';
import 'package:safe_driving_app/widgets/header.dart';
import 'package:safe_driving_app/widgets/next_button.dart';

class FormPage extends StatefulWidget {
  const FormPage({super.key});

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final _formKeyOdometer = GlobalKey<FormBuilderState>();
  final _formKeyTextArea = GlobalKey<FormBuilderState>();

  final _odometerInputController = TextEditingController();
  final _textAreaController = TextEditingController();

  bool validationNextButtonOne = false;
  bool validationNextButtonTwo = false;

  @override
  void initState() {
    super.initState();
    printStorage();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: header(ODOMETERMAINTANCE.TEXT_HEADER),
          body: Column(
            children: [
              SizedBox(
                height: getHeight(context, 4),
              ),
              SizedBox(
                width: getWidth(context, 90),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Describa el mantenimiento realizado'),
                ),
              ),
              SizedBox(
                height: getHeight(context, 2),
              ),
              Container(
                width: getWidth(context, 90),
                height: getWidth(context,
                    50), // Mismo valor que el ancho para obtener un cuadrado
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey), // Borde gris
                  borderRadius:
                      BorderRadius.circular(10.0), // Bordes redondeados
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                      bottom:
                          4.0), // Espacio para la barra de input en la parte inferior
                  child: FormBuilderTextField(
                    key: _formKeyTextArea,
                    name: 'texto',
                    maxLength: 1000,
                    maxLines: null,
                    controller: _textAreaController,
                    onChanged: (value) {
                      if (value != null && value != '') {
                        setState(() => validationNextButtonTwo = true);
                        print(value);
                      }
                    },
                    style: TextStyle(fontSize: 16.0),
                    decoration: InputDecoration(
                      border:
                          InputBorder.none, // Sin borde adicional en el input
                      contentPadding: EdgeInsets.all(8.0), // Espaciado interno
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Se requiere el campo';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              SizedBox(
                height: getHeight(context, 4),
              ),
              SizedBox(
                width: getWidth(context, 90),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child:
                      Text('Introducir le odómetro del próximo mantenimiento'),
                ),
              ),
              SizedBox(
                height: getHeight(context, 2),
              ),
              SizedBox(
                width: getWidth(context, 90),
                child: FormBuilder(
                  key: _formKeyOdometer,
                  child: FormBuilderTextField(
                      name: 'odometer',
                      onChanged: (value) {
                        setState(() => validationNextButtonOne =
                            _formKeyOdometer.currentState!.validate());
                      },
                      decoration: InputDecoration(
                          enabled: true,
                          labelText: ODOMETERMAINTANCE.TEXT_LABEL,
                          filled: true,
                          fillColor: Colors.blue.shade100,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10))),
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      controller: _odometerInputController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Se require el odometro';
                        }

                        int newOdometerValue = int.tryParse(value) ?? 0;
                        int oldOdometer = int.tryParse(readStorage(
                                'maintance.odometer.odometerNumber')) ??
                            0;
                        print(
                            'oldOdometer ${readStorage('maintance.odometer.odometerNumber')}');
                        print(
                            'Validation odometers: ${newOdometerValue <= oldOdometer}');
                        if (newOdometerValue <= oldOdometer) {
                          return 'Se require una cantidad mayor al anterior registro';
                        }

                        return null;
                      }),
                ),
              ),
              Expanded(child: Container()),
              Text(
                'La ultima ubicación del carro será enviada',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(
                height: getHeight(context, 2),
              ),
              nextButton(context, 'Siguiente', '/maintance/upload',
                  (validationNextButtonOne && validationNextButtonTwo), () {
                try {
                  writeStorage('maintance.form.nextOdometerNumber',
                      _odometerInputController.text);
                  writeStorage('maintance.form.textArea',
                      _textAreaController.value.text);
                } catch (e) {
                  print('nextButton: $e');
                }
              }, null),
              SizedBox(
                height: getHeight(context, 3),
              )
            ],
          ),
        ),
      ),
    );
  }
}
