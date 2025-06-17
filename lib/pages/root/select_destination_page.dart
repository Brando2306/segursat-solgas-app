import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:safe_driving_app/core/validators/location_validator.dart';
import 'package:safe_driving_app/features/speedometer/presentation/providers/select_destination_provider.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/shared/dropdown_field_widget.dart';
import 'package:safe_driving_app/shared/form_field_widget.dart';
import 'package:safe_driving_app/utils/root/index.dart';
import 'package:safe_driving_app/utils/style.dart';

class SelectDestinationPage extends StatefulWidget {
  const SelectDestinationPage({super.key});

  @override
  State<SelectDestinationPage> createState() => _SelectDestinationPageState();
}

class _SelectDestinationPageState extends State<SelectDestinationPage> {
  // Controllers y form keys en el widget de UI
  final TextEditingController _textInputController = TextEditingController();
  final TextEditingController _textInputManualControllerLat =
      TextEditingController();
  final TextEditingController _textInputManualControllerLng =
      TextEditingController();

  final GlobalKey<FormState> _formKeyText = GlobalKey<FormState>();
  final GlobalKey<FormState> _formKeyResults = GlobalKey<FormState>();

  @override
  void dispose() {
    // Limpieza de controllers
    _textInputController.dispose();
    _textInputManualControllerLat.dispose();
    _textInputManualControllerLng.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SelectDestinationProvider(),
      child: WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: _buildAppBar(context),
          resizeToAvoidBottomInset: false,
          body: Consumer<SelectDestinationProvider>(
            builder: (context, provider, child) {
              return Column(
                children: [
                  _buildInputs(context, provider),

                  // Sección que cambia según conexión
                  if (!provider.hasInternetConnection)
                    _buildOfflineUI(provider),
                  if (provider.hasInternetConnection) _buildOnlineUI(provider),

                  _buildConfirmButton(context, provider),
                  SizedBox(height: 20),
                  // _buildInputs(context, provider),
                  // Expanded(child: Container()),
                  // SizedBox(
                  //   width: getWidth(context, 90),
                  //   height: getHeight(context, 50),
                  //   child: Stack(
                  //     children: [
                  //       _buildMap(provider),
                  //       _buildCenterPositionButton(provider),
                  //     ],
                  //   ),
                  // ),
                  // Expanded(child: Container()),
                  // _buildConfirmButton(context, provider),
                  // SizedBox(height: getHeight(context, 3)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // Widget para mostrar cuando NO hay internet
  Widget _buildOfflineUI(SelectDestinationProvider provider) {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            _buildCoordinatesDisplay(provider),
            SizedBox(height: 20),
            // Text(
            //   'Sin conexión a internet. Ingrese las coordenadas manualmente.',
            //   style: TextStyle(color: Colors.grey),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoordinatesDisplay(SelectDestinationProvider provider) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ubicación seleccionada:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Latitud:', style: TextStyle(color: Colors.grey)),
                  Text(
                    provider.position.latitude.toStringAsFixed(10),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Longitud:', style: TextStyle(color: Colors.grey)),
                  Text(
                    provider.position.longitude.toStringAsFixed(10),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget para mostrar cuando SÍ hay internet
  Widget _buildOnlineUI(SelectDestinationProvider provider) {
    return Expanded(
      child: Column(
        children: [
          Expanded(child: Container()),
          SizedBox(
            height: 300,
            child: Stack(
              children: [
                _buildMap(provider),
                _buildCenterPositionButton(provider),
              ],
            ),
          ),
          Expanded(child: Container()),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        SELECTDESTINATION.TEXT_HEADER,
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      elevation: 0.0,
      backgroundColor: Colors.white,
      leading: IconButton(
        onPressed: () => Navigator.pushNamed(context, '/menu'),
        icon: Icon(Icons.home),
        color: Colors.black,
        tooltip: 'Salir del registro de ruta',
      ),
      actions: [
        Consumer<SelectDestinationProvider>(
          builder: (context, provider, _) {
            return IconButton(
              icon: Icon(
                provider.changeInputs
                    ? Icons.input
                    : Icons.location_on_outlined,
                color:
                    provider.hasInternetConnection ? Colors.black : Colors.grey,
              ),
              onPressed: () {
                if (provider.hasInternetConnection) {
                  provider.toggleInputMode();
                } else {
                  // Mostrar mensaje si no hay internet
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Modo texto no disponible sin conexión')),
                  );
                }
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildInputs(
      BuildContext context, SelectDestinationProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          if (!provider.hasInternetConnection)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Sin conexión a Internet. Usando modo manual.',
                style: TextStyle(color: Colors.red),
              ),
            ),
          AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            child: provider.changeInputs
                ? Column(
                    key: ValueKey('text-input'),
                    children: [
                      _buildTextInput(provider),
                      SizedBox(height: 20),
                      if (provider.hasInternetConnection)
                        _buildResultsDropdown(provider, context),
                    ],
                  )
                : Column(
                    key: ValueKey('manual-input'),
                    children: [_buildManualInput(context, provider)],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInput(SelectDestinationProvider provider) {
    return Form(
      key: _formKeyText,
      child: FormFieldWidget(
        onChanged: (value) {
          if (value != null) {
            provider.handleTextChanged(value);
          }
        },
        controller: _textInputController,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Se requiere el destino';
          }
          return null;
        },
        labelText: 'Escoja su destino',
      ),
    );
  }

  Widget _buildManualInput(
      BuildContext context, SelectDestinationProvider provider) {
    return Form(
      key: _formKeyResults,
      child: Column(
        children: [
          FormFieldWidget(
            onChanged: (value) => provider.latitudeText = value,
            controller: _textInputManualControllerLat,
            validator: LocationValidator.validateLatitude,
            labelText: 'Latitud',
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.deny(
                  RegExp(r'^\s')), // Niega espacio al inicio
              FilteringTextInputFormatter.deny(
                  RegExp(r'[ ]')), // Niega cualquier espacio
            ],
          ),
          SizedBox(height: 20),
          FormFieldWidget(
            onChanged: (value) => provider.longitudeText = value,
            controller: _textInputManualControllerLng,
            validator: LocationValidator.validateLongitude,
            labelText: 'Longitud',
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.deny(
                  RegExp(r'^\s')), // Niega espacio al inicio
              FilteringTextInputFormatter.deny(
                  RegExp(r'[ ]')), // Niega cualquier espacio
            ],
          ),
          SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                child: const Text('Buscar'),
                onPressed: () {
                  if (_formKeyResults.currentState?.validate() ?? false) {
                    provider.searchManualCoordinates(context);
                    // Limpiar los controllers después de la búsqueda exitosa
                    // _clearManualControllers();
                  }
                },
              ),
              SizedBox(width: 20),
              ElevatedButton(
                onPressed: () {
                  _clearManualControllers();
                  provider.clearManualInput();
                },
                child: const Text('Limpiar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _clearManualControllers() {
    _textInputManualControllerLat.clear();
    _textInputManualControllerLng.clear();
  }

  Widget _buildResultsDropdown(
      SelectDestinationProvider provider, BuildContext context) {
    return Form(
      child: DropdownFieldWidget(
        value: provider.selectedResult,
        labelText: 'Resultados de la búsqueda',
        onChanged: (value) => provider.selectResult(value, context),
        items: provider.results
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildMap(SelectDestinationProvider provider) {
    return FlutterMap(
      mapController: provider.mapController,
      options: MapOptions(
        zoom: 10.0,
        maxZoom: 18.0,
        minZoom: 10.0,
        center: LatLng(provider.position.latitude, provider.position.longitude),
        onTap: provider.handleMapTap,
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://mt0.google.com/vt/lyrs=m&hl=en&x={x}&y={y}&z={z}&s=Ga',
          subdomains: const ['a', 'b', 'c'],
        ),
        MarkerLayer(
          markers: [
            Marker(
              width: 100.0,
              height: 100.0,
              point: LatLng(
                  provider.position.latitude, provider.position.longitude),
              builder: (context) => Icon(
                Icons.location_on,
                size: 50,
                color: Colors.blue[900],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCenterPositionButton(SelectDestinationProvider provider) {
    return Align(
      alignment: Alignment.topRight,
      child: Container(
        width: 50,
        margin: EdgeInsets.all(7),
        child: FloatingActionButton(
          backgroundColor: Color(0xFF2e4792),
          onPressed: provider.centerMapPosition,
          child: Icon(Icons.gps_fixed),
        ),
      ),
    );
  }

  Widget _buildConfirmButton(
      BuildContext context, SelectDestinationProvider provider) {
    return MaterialButton(
      onPressed: () => provider.confirmDestination(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      // color: provider.blockNextButton
      //     ? CustomColors.primary
      //     : CustomColors.primaryOff,
      color: CustomColors.primary,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: getHeight(context, 12),
          vertical: 16,
        ),
        child: Text(
          SELECTSOURCE.TEXT_BUTTON,
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
