import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' show Rectangle;

import 'package:flutter/material.dart';
import 'package:floating/floating.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'package:safe_driving_app/helpers/gps.dart';
import 'package:safe_driving_app/utils/style.dart';
import 'package:safe_driving_app/utils/storage.dart';
import 'package:safe_driving_app/utils/constants.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/shared/button_widget.dart';
import 'package:safe_driving_app/features/speedometer/presentation/providers/speedometer_provider.dart';

class SpeedometerPage extends StatefulWidget {
  const SpeedometerPage({super.key});

  @override
  _SpeedometerPageState createState() => _SpeedometerPageState();
}

class _SpeedometerPageState extends State<SpeedometerPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // EasyLoading.show(status: 'Iniciando ruta...');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SpeedometerProvider>();
      provider.initialize();
    });
    // EasyLoading.dismiss();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Escuchar cambios en el estado de la aplicación
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!Platform.isAndroid) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // _enterPipModeAutomatically();
        break;
      case AppLifecycleState.resumed:
        // El PiP se cierra automáticamente cuando la app vuelve al frente
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _enterPipModeAutomatically() async {
    try {
      final canUsePiP = await Floating().isPipAvailable;
      if (canUsePiP && mounted) {
        // await Floating().enable(ImmediatePiP());
        print('PiP automático activado al minimizar la app');
      }
    } catch (e) {
      print('Error activando PiP automático: $e');
    }
  }

  Future<void> _enterPipModeManually() async {
    try {
      final canUsePiP = await Floating().isPipAvailable;
      if (canUsePiP && mounted) {
        // await Floating().enable(ImmediatePiP());
      } else {
        _showPipNotAvailableDialog();
      }
    } catch (e) {
      print('Error activando PiP manual: $e');
      _showPipErrorDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SpeedometerProvider>(
      builder: (context, provider, child) {
        final content = WillPopScope(
          onWillPop: () async {
            // Al presionar back, activar PiP en lugar de salir
            if (Platform.isAndroid) {
              // await _enterPipModeAutomatically();
              return false;
            }
            return false;
          },
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: Text(
                'Velocímetro',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              centerTitle: true,
              elevation: 0.0,
              backgroundColor: Colors.white,
              leading: Container(),
              actions: Platform.isAndroid
                  ? [
                      _pipButton(), // Nuevo control de PiP
                    ]
                  : null,
            ),
            body: _buildBody(context, provider),
          ),
        );

        // Solo para Android, envolver con PiPSwitcher
        if (Platform.isAndroid) {
          return PiPSwitcher(
            childWhenEnabled: _buildMinimizedGauge(provider),
            childWhenDisabled: content,
          );
        }

        return content;
      },
    );
  }

  // Diálogo para cuando PiP no está disponible
  void _showPipNotAvailableDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('PiP No Disponible'),
        content: Text(
            'El modo Picture-in-Picture no está disponible en este dispositivo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _showPipErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error de PiP'),
        content: Text('No se pudo activar el modo Picture-in-Picture.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimizedGauge(SpeedometerProvider provider) {
    return SfRadialGauge(
      axes: <RadialAxis>[
        RadialAxis(
          minimum: 0,
          maximum: 200,
          labelOffset: 30,
          axisLineStyle: const AxisLineStyle(
            thicknessUnit: GaugeSizeUnit.factor,
            thickness: 0.03,
          ),
          majorTickStyle: const MajorTickStyle(
            length: 6,
            thickness: 4,
            color: Colors.black,
          ),
          minorTickStyle: const MinorTickStyle(
            length: 3,
            thickness: 3,
            color: Colors.black,
          ),
          axisLabelStyle: const GaugeTextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          ranges: <GaugeRange>[
            GaugeRange(
              startValue: 0,
              endValue: 200,
              sizeUnit: GaugeSizeUnit.factor,
              startWidth: 0.03,
              endWidth: 0.03,
              gradient: const SweepGradient(
                colors: <Color>[Colors.green, Colors.yellow, Colors.red],
                stops: <double>[0.0, 0.5, 1],
              ),
            ),
          ],
          pointers: <GaugePointer>[
            NeedlePointer(
              value: provider.speed,
              needleLength: 0.95,
              enableAnimation: true,
              animationType: AnimationType.ease,
              needleStartWidth: 1.5,
              needleEndWidth: 6,
              needleColor: Colors.red,
              knobStyle: const KnobStyle(knobRadius: 0.09),
            ),
          ],
          annotations: <GaugeAnnotation>[
            GaugeAnnotation(
              widget: Center(
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 10),
                    Text(
                      '${provider.speed.round().toString()} KM/H',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              angle: 90,
              positionFactor: 1.55,
            ),
          ],
        ),
      ],
    );
  }

  Widget _pipButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 20.0),
      child: GestureDetector(
        onTap: _enterPipModeManually,
        child: const Icon(
          // Icons.photo_size_select_large,
          Icons.picture_in_picture_alt,
          size: 30,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, SpeedometerProvider provider) {
    return Column(
      children: [
        // _buildPendingPositionsCount(),
        const SizedBox(height: 20),
        _topActionButtons(context, provider),
        const Spacer(),
        _currentTimeDisplay(provider),
        const Spacer(),
        _speedometerGauge(provider),
        const Spacer(),
        _controlButtons(context, provider),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPendingPositionsCount() {
    return Consumer<SpeedometerProvider>(
      builder: (context, provider, child) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: provider.pendingPositionsCountValue > 0
              ? GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/offline-operations');
                  },
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_off,
                            color: Colors.orange[800], size: 16),
                        const SizedBox(width: 8),
                        Text(
                          '${provider.pendingPositionsCountValue} posiciones pendientes',
                          style: TextStyle(
                            color: Colors.orange[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (provider.hasInternetConnection)
                          const SizedBox(width: 8),
                        if (provider.hasInternetConnection)
                          const Icon(Icons.autorenew, size: 16),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _topActionButtons(BuildContext context, SpeedometerProvider provider) {
    return Row(
      children: [
        const Spacer(),
        _emergencyButton(context, provider),
        const Spacer(),
        _stopButton(context),
        const Spacer(),
      ],
    );
  }

  Widget _emergencyButton(BuildContext context, SpeedometerProvider provider) {
    return Column(
      children: [
        MaterialButton(
          onPressed: () => _showEmergencyConfirmation(context, provider),
          color: Colors.red,
          //TODO: Make icon here
          // child: const FaIcon(
          //   FontAwesomeIcons.warning,
          //   color: Colors.white,
          //   size: 25,
          // ),
          child: Icon(Icons.warning, color: Colors.white, size: 25),
          padding: const EdgeInsets.all(16),
          shape: const CircleBorder(),
        ),
        const SizedBox(height: 5),
        const Text('SOS', style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _stopButton(BuildContext context) {
    return Column(
      children: [
        MaterialButton(
          onPressed: () {
            writeStorage('root.type', ROOT_TYPE.SOS);
            Provider.of<SpeedometerProvider>(context, listen: false)
                .stopLocationUpdates();
            Navigator.pushNamed(context, '/root/incidentReport');
          },
          color: Colors.amber,
          //TODO: Make icon here
          // child: const FaIcon(
          //   FontAwesomeIcons.circleStop,
          //   color: Colors.white,
          //   size: 25,
          // ),
          child: Icon(Icons.stop, color: Colors.white, size: 25),
          padding: const EdgeInsets.all(16),
          shape: const CircleBorder(),
        ),
        const SizedBox(height: 5),
        const Text('Incidencia', style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _currentTimeDisplay(SpeedometerProvider provider) {
    return Text(
      provider.formattedTime,
      style: const TextStyle(
        fontSize: 25,
        fontFamily: 'Roboto',
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _speedometerGauge(SpeedometerProvider provider) {
    return SfRadialGauge(
      axes: <RadialAxis>[
        RadialAxis(
          minimum: 0,
          maximum: 200,
          labelOffset: 30,
          axisLineStyle: const AxisLineStyle(
            thicknessUnit: GaugeSizeUnit.factor,
            thickness: 0.03,
          ),
          majorTickStyle: const MajorTickStyle(
            length: 6,
            thickness: 4,
            color: Colors.black,
          ),
          minorTickStyle: const MinorTickStyle(
            length: 3,
            thickness: 3,
            color: Colors.black,
          ),
          axisLabelStyle: const GaugeTextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          ranges: <GaugeRange>[
            GaugeRange(
              startValue: 0,
              endValue: 200,
              sizeUnit: GaugeSizeUnit.factor,
              startWidth: 0.03,
              endWidth: 0.03,
              gradient: const SweepGradient(
                colors: <Color>[Colors.green, Colors.yellow, Colors.red],
                stops: <double>[0.0, 0.5, 1],
              ),
            ),
          ],
          pointers: <GaugePointer>[
            NeedlePointer(
              value: provider.speed,
              needleLength: 0.95,
              enableAnimation: true,
              animationType: AnimationType.ease,
              needleStartWidth: 1.5,
              needleEndWidth: 6,
              needleColor: Colors.red,
              knobStyle: const KnobStyle(knobRadius: 0.09),
            ),
          ],
          annotations: <GaugeAnnotation>[
            GaugeAnnotation(
              widget: Column(
                children: <Widget>[
                  Text(
                    '${provider.speed.round().toString()} KM/H',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    provider.formattedDuration,
                    style: const TextStyle(
                      fontSize: 25,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              angle: 90,
              positionFactor: 1.75,
            ),
          ],
        ),
      ],
    );
  }

  Widget _controlButtons(BuildContext context, SpeedometerProvider provider) {
    return Column(
      children: [
        ButtonWidget(
          width: double.infinity,
          // loading: provider.isLoading,
          // disabled: provider.isLoading,
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          margin: EdgeInsets.symmetric(horizontal: 40),
          text: 'Realizar parada',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
          ),
          color: (provider.buttonFinishEnabled && _hasValidPositions())
              ? CustomColors.primary
              : CustomColors.primaryOff,
          onPressed: provider.buttonFinishEnabled && _hasValidPositions()
              ? () {
                  Provider.of<SpeedometerProvider>(context, listen: false)
                      .stopLocationUpdates();
                  Navigator.pushNamed(context, '/root/controlStop');
                }
              : null,
        ),
        const SizedBox(height: 20),
        ButtonWidget(
          width: double.infinity,
          // loading: provider.isLoading,
          // disabled: provider.isLoading,
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          margin: EdgeInsets.symmetric(horizontal: 40),
          text: 'Finalizar ruta',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
          ),
          color: (provider.buttonFinishEnabled && _hasValidPositions())
              ? CustomColors.primary
              : CustomColors.primaryOff,
          onPressed: provider.buttonFinishEnabled && _hasValidPositions()
              ? () => _handleFinishRoute(context, provider)
              : null,
        ),
      ],
    );
  }

  bool _hasValidPositions() {
    try {
      // Si no hay currentPosition, usar posición actual
      var currentPos = readStorage('root.currentPosition');
      if (currentPos == null) {
        // Intentar obtener posición actual
        _setCurrentPositionAsFallback();
        currentPos = readStorage('root.currentPosition');
      }

      // Si no hay finalPosition, usar posición actual como destino
      var finalPos = readStorage('root.finalPosition');
      if (finalPos == null) {
        _setCurrentPositionAsFinal();
        finalPos = readStorage('root.finalPosition');
      }

      if (currentPos == null || finalPos == null) return false;

      // Verificar que el JSON sea válido
      final currentJson = json.decode(currentPos) as Map<String, dynamic>;
      final finalJson = json.decode(finalPos) as Map<String, dynamic>;

      return currentJson['latitude'] != null &&
          currentJson['longitude'] != null &&
          finalJson['latitude'] != null &&
          finalJson['longitude'] != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> _setCurrentPositionAsFallback() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );

      await writeStorage(
        'root.currentPosition',
        json.encode({
          'latitude': position.latitude,
          'longitude': position.longitude,
        }),
      );
    } catch (e) {
      log('Error al obtener posición actual: $e');
    }
  }

  Future<void> _setCurrentPositionAsFinal() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );

      await writeStorage(
        'root.finalPosition',
        json.encode({
          'latitude': position.latitude,
          'longitude': position.longitude,
        }),
      );
    } catch (e) {
      log('Error al establecer posición final: $e');
    }
  }

  Future<void> _handleFinishRoute(
    BuildContext context,
    SpeedometerProvider provider,
  ) async {
    try {
      final currentPositionStr = readStorage('root.currentPosition');
      final finalPositionStr = readStorage('root.finalPosition');

      if (currentPositionStr == null || finalPositionStr == null) {
        throw Exception('Posiciones no encontradas en el almacenamiento');
      }

      final currentPosition = json.decode(currentPositionStr);
      final finalPosition = json.decode(finalPositionStr);

      final distance = calcularDistanciaEnMetros(
        currentPosition['latitude'],
        currentPosition['longitude'],
        finalPosition['latitude'],
        finalPosition['longitude'],
      );

      if (distance < 100) {
        await provider.finishRoute();
        //TODO: Creo ruta desde postman, luego activo internet para que me aparezca modal de recuperar ruta
        // Hay internet para validar ruta luego desactivo mi internet y clic en recuperar ruta luego entro al
        // velocimetro y se habilitaron los botones luego como no hay internet finalizo la ruta y no se guarda
        // en el storage del celular, ocurre porque no se creo una  ruta offline y no se guardo el id offline
        // por q no hubo necesidad de guardar la ruta creada con internet que ahora la queremos terminar sin internet
        Navigator.pushNamed(context, '/root/finish',
            arguments: 'La unidad ha llegado a su destino');
      } else {
        _showDistanceWarningDialog(context, provider);
      }
    } catch (e) {
      notificationError(context, e.toString());
      Navigator.pushNamed(context, '/root/finish');
    }
  }

  void _showEmergencyConfirmation(
    BuildContext context,
    SpeedometerProvider provider,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          "Emergencia",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 9, 43, 145),
          ),
        ),
        content: const Text(
            '¿Desea comunicarse con el área de Emergencia y terminar su ruta?'),
        actions: <Widget>[
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext, rootNavigator: true).pop();
              EasyLoading.show(status: 'Procesando...');
              try {
                await provider.triggerEmergency();
                if (!mounted) return;
                Navigator.pushNamed(context, '/root/finish',
                    arguments:
                        'Hemos enviado tu solicitud de SOS a tu supervisor');
              } catch (e) {
                notificationError(context, 'Error en emergencia: $e');
              }
              EasyLoading.dismiss();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Sí'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(dialogContext, rootNavigator: true).pop(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
            child: const Text('No'),
          ),
        ],
      ),
    );
  }

  void _showDistanceWarningDialog(
    BuildContext context,
    SpeedometerProvider provider,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'Confirmación',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        content: const Text(
          'La unidad aún no ha llegado a su destino. ¿Está seguro que desea finalizar la ruta?',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              // Navigator.of(context, rootNavigator: true).pop();
              EasyLoading.show(status: 'Finalizando ruta...');
              try {
                // Intenta finalizar la ruta
                await provider.finishRoute();

                // Navega a '/root/finish' usando Navigator.pushNamed
                // **¡Importante!** Usamos `if (mounted)` para evitar el error.
                if (mounted) {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    '/root/finish',
                    arguments: 'Has finalizado la ruta sin llegar a tu destino',
                  );
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(builder: (_) => FinishRootPage()),
                  // );
                }
              } catch (e) {
                // Si hay error, lo mostramos (solo si el widget sigue activo)
                if (mounted) {
                  notificationError(context, 'Error al finalizar: $e');
                }
              } finally {
                // Cerramos el loading
                EasyLoading.dismiss();
              }
            },
            child: const Text(
              'Aceptar',
              style: TextStyle(
                fontSize: 16,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
