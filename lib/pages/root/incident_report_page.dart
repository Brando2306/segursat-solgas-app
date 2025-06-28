import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:safe_driving_app/features/route/domain/entities/incident_route_entity.dart';
import 'package:safe_driving_app/features/route/domain/entities/route_response_entity.dart';
import 'package:safe_driving_app/features/route/presentation/providers/incident_provider.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/utils/constants.dart';
import 'package:safe_driving_app/utils/endpoints.dart';
import 'package:safe_driving_app/utils/storage.dart';
import 'package:safe_driving_app/utils/style.dart';
import 'package:safe_driving_app/widgets/header.dart';
import 'package:http/http.dart' as http;

class IncidentReportPage extends StatefulWidget {
  const IncidentReportPage({super.key});

  @override
  _IncidentReportPageState createState() => _IncidentReportPageState();
}

class _IncidentReportPageState extends State<IncidentReportPage> {
  // final _formKey = GlobalKey<FormBuilderState>();
  final _formKeyTextArea = GlobalKey<FormBuilderState>();
  final _textAreaController = TextEditingController();

  String categoriaSeleccionada = '';
  String texto = '';

  List<String> categorias = [
    'Colisión vial',
    'Condición meteorológica adversa',
    'Trabajos en la calzada',
    'Congestión de tráfico',
    'Avería mecánica',
    'Desvío de ruta',
    'Riesgo vial',
    'Presencia de fauna en la vía',
    'Intervención policial en carretera',
    'Falla en el sistema de navegación',
    'Reserva de combustible agotada',
    'Problemas de salud del conductor',
    'Iluminación deficiente en la vía',
    'Otros',
  ];

  bool blockButton = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => true,
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: header('Reporte de Incidencia'),
            body: Column(
              children: [
                SizedBox(
                  height: getHeight(context, 2),
                ),
                Container(
                    padding: EdgeInsets.fromLTRB(
                        getWidth(context, 5), 0, getWidth(context, 5), 0),
                    child: FormBuilderDropdown(
                      name: 'categoria',
                      decoration: InputDecoration(
                        labelText: 'Seleccione una categoría',
                        // contentPadding: EdgeInsets.symmetric(
                        //     horizontal: 16.0),
                      ),
                      items: categorias.map((String categoria) {
                        return DropdownMenuItem<String>(
                          value: categoria,
                          child: Text(categoria),
                        );
                      }).toList(),
                      onChanged: (String? nuevaCategoria) {
                        setState(() {
                          categoriaSeleccionada = nuevaCategoria ?? '';
                          blockButton = (texto != "" ? true : false) &&
                              (categoriaSeleccionada != "" ? true : false);
                        });
                      },
                    )),
                SizedBox(
                  height: getHeight(context, 6),
                ),
                SizedBox(
                  width: getWidth(context, 90),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Describa la incidencia'),
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
                        texto = value ?? ' ';
                        blockButton = (texto != "" ? true : false) &&
                            (categoriaSeleccionada != null &&
                                    categoriaSeleccionada != ""
                                ? true
                                : false);
                      },
                      style: TextStyle(fontSize: 16.0),
                      decoration: InputDecoration(
                        border:
                            InputBorder.none, // Sin borde adicional en el input
                        contentPadding:
                            EdgeInsets.all(8.0), // Espaciado interno
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
                Expanded(child: Container()),
                Text(
                  'La ultima ubicación del carro será enviada',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(
                  height: getHeight(context, 2),
                ),
                nextButton(context),
                SizedBox(
                  height: getHeight(context, 3),
                )
              ],
            ),
          ),
        ));
  }

  MaterialButton nextButton(context) {
    return MaterialButton(
      onPressed: () async {
        if (blockButton) {
          await createIncidents(context);
        }
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      color: blockButton ? CustomColors.primary : CustomColors.primaryOff,
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: getHeight(context, 12), vertical: 16),
        child: Text(
          'Siguiente',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  createIncidents(context) async {
    setState(() => blockButton = false);

    EasyLoading.show(status: 'Enviando...');

    try {
      final provider = Provider.of<IncidentProvider>(context, listen: false);

      Position position = await Geolocator.getCurrentPosition();

      final incident = IncidentRouteEntity(
        routeId: readStorage('root.createRoute.id'),
        timestamp: getDate(),
        latitude: position.latitude,
        longitude: position.longitude,
        type: categoriaSeleccionada,
        description: texto,
        address: readStorage('root.address') ?? "No Encontrado",
        unitId: readStorage('personal.unitId'),
      );

      await provider.submitIncident(incident);
    } catch (e) {
      EasyLoading.dismiss();
      notificationAlert(context, e.toString());
      setState(() => blockButton = true);
      print(e);
    } finally {
      EasyLoading.dismiss();
      writeStorage('root.type', ROOT_TYPE.INCIDENTS);
      if (readStorage('root.incident.type') != null) {
        await removeStorage('root.incident.type');
        Navigator.pushNamed(context, '/root/controlStop');
      } else {
        Navigator.pushNamed(context, '/root/speedometer');
      }
    }
  }
}
