import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:safe_driving_app/features/speedometer/presentation/providers/select_source_provider.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/utils/root/index.dart';
import 'package:safe_driving_app/utils/storage.dart';
import 'package:safe_driving_app/widgets/header.dart';
import 'package:safe_driving_app/widgets/next_button.dart';

class SelectSourcePage extends StatefulWidget {
  const SelectSourcePage({super.key});

  @override
  State<SelectSourcePage> createState() => _SelectSourcePageState();
}

class _SelectSourcePageState extends State<SelectSourcePage> {
  SelectSourceProvider? _provider;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  void _initializePage() async {
    cleanRoot();
    printStorage();
    writeStorage('root.departureDate', DateTime.now().toString());
    writeStorage('root.initialDate', getDate());

    // Usar addPostFrameCallback de forma más segura
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Verificar que el widget aún esté montado
        _provider = Provider.of<SelectSourceProvider>(context, listen: false);
        _provider!.initialize(context);
      }
    });
  }

  @override
  void dispose() {
    // IMPORTANTE: Invalidar el context antes de dispose
    _provider?.invalidateContext();
    _provider?.disposeResources();
    super.dispose();
  }

  @override
  void deactivate() {
    // También invalidar cuando el widget se desactiva
    _provider?.invalidateContext();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Invalidar context cuando se intente hacer pop
        _provider?.invalidateContext();
        return false;
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            _buildMainContent(),
            _buildStatusOverlay(),
            _buildConnectivityBanner(),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return headerV2(
      SELECTSOURCE.TEXT_HEADER,
      Builder(
        builder: (context) => IconButton(
          onPressed: () {
            // Invalidar context antes de navegar
            _provider?.invalidateContext();
            Navigator.pushReplacementNamed(context, '/menu');
          },
          icon: const Icon(Icons.home),
          color: Colors.black,
          tooltip: 'Salir del registro de ruta',
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Consumer<SelectSourceProvider>(
      builder: (context, provider, child) {
        _provider = provider;
        return Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  _buildMap(provider),
                  _buildGpsButton(provider),
                ],
              ),
            ),
            _buildBottomControls(provider),
          ],
        );
      },
    );
  }

  Widget _buildMap(SelectSourceProvider provider) {
    return FlutterMap(
      key: ValueKey(
          provider.hasInternet), // <-- Forzamos la reconstrucción del mapa
      mapController: provider.map,
      options: MapOptions(
        zoom: 10.0,
        maxZoom: 18.0,
        minZoom: 10.0,
        center: LatLng(-12.047933614518184, -77.06337978247707),
        rotation: 0.0,
      ),
      children: [
        // Solo mostrar tiles si hay internet
        if (provider.hasInternet) _buildTileLayer(),
        // Si no hay internet, mostrar un fondo básico
        if (!provider.hasInternet) _buildOfflineBackground(),
        _buildMarkerLayer(provider),
        _buildGridOverlay(), // Agregar una grilla para referencia offline
      ],
    );
  }

  TileLayer _buildTileLayer() {
    return TileLayer(
      urlTemplate:
          'https://mt0.google.com/vt/lyrs=m&hl=en&x={x}&y={y}&z={z}&s=Ga',
      subdomains: const ['a', 'b', 'c'],
    );
  }

  Widget _buildOfflineBackground() {
    return Consumer<SelectSourceProvider>(
      builder: (context, provider, child) {
        return Container(
          color: Colors.grey[100],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.offline_pin,
                  size: 80,
                  color: Colors.green[600],
                ),
                const SizedBox(height: 16),
                Text(
                  'Modo GPS Offline',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sin mapas pero GPS activo',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (provider.position.latitude != 0) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_on,
                                size: 16, color: Colors.red),
                            const SizedBox(width: 4),
                            const Text(
                              'Tu ubicación actual:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${provider.position.latitude.toStringAsFixed(6)}, ${provider.position.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (provider.gpsAccuracy > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Precisión: ±${provider.gpsAccuracy.toStringAsFixed(1)}m',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridOverlay() {
    return Consumer<SelectSourceProvider>(
      builder: (context, provider, child) {
        if (provider.hasInternet) return const SizedBox();

        return CustomPaint(
          painter: GridPainter(),
          size: Size.infinite,
        );
      },
    );
  }

  MarkerLayer _buildMarkerLayer(SelectSourceProvider provider) {
    return MarkerLayer(
      markers: [
        Marker(
          width: 80.0,
          height: 80.0,
          point:
              LatLng(provider.position.latitude, provider.position.longitude),
          builder: (context) => Column(
            children: [
              Icon(
                Icons.location_on,
                size: 50,
                color: provider.noSignalMode
                    ? Colors.orange
                    : provider.hasInternet
                        ? Colors.blue[900]
                        : Colors.green[700], // Verde para offline con GPS
              ),
              if (provider.gpsAccuracy > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    '±${provider.gpsAccuracy.toStringAsFixed(1)}m',
                    style: TextStyle(
                      color: provider.noSignalMode
                          ? Colors.orange
                          : provider.hasInternet
                              ? Colors.blue[900]
                              : Colors.green[700],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGpsButton(SelectSourceProvider provider) {
    return Positioned(
      top: 16,
      right: 16,
      child: FloatingActionButton(
        mini: true,
        backgroundColor: provider.hasInternet
            ? Theme.of(context).primaryColor
            : Colors.green[700],
        onPressed: provider.centerMapOnPosition,
        child: const Icon(Icons.gps_fixed, color: Colors.white),
      ),
    );
  }

  Widget _buildConnectivityBanner() {
    return Consumer<SelectSourceProvider>(
      builder: (context, provider, child) {
        if (provider.isCheckingConnectivity) {
          return Positioned(
            top: MediaQuery.of(context).padding.top + kToolbarHeight,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.blue[100],
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  const Text('Verificando conectividad...'),
                ],
              ),
            ),
          );
        }

        if (!provider.hasInternet) {
          return Positioned(
            top: MediaQuery.of(context).padding.top + kToolbarHeight,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.green[100],
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.offline_pin, size: 20, color: Colors.green[800]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Modo GPS sin Internet',
                          style: TextStyle(
                            color: Colors.green[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        if (provider.position.latitude != 0)
                          Text(
                            'Lat: ${provider.position.latitude.toStringAsFixed(4)}, Lng: ${provider.position.longitude.toStringAsFixed(4)}',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (provider.gpsAccuracy > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green[700],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '±${provider.gpsAccuracy.toStringAsFixed(0)}m',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildBottomControls(SelectSourceProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Text('provider.blockNextButton ${provider.blockNextButton}'),
          if (provider.blockNextButton)
            nextButton(
              context,
              SELECTSOURCE.TEXT_BUTTON,
              '/root/selectDestination',
              provider.blockNextButton,
              () {
                final storedPosition = readStorage('root.initialPosition');
                log('Contenido de root.initialPosition: $storedPosition');
              },
              // provider.hasInternet ? null : Colors.green[700],
              null,
            ),
          const SizedBox(height: 8),
          if (provider.isLoading)
            LinearProgressIndicator(
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                provider.noSignalMode
                    ? Colors.orange
                    : provider.hasInternet
                        ? Theme.of(context).primaryColor
                        : Colors.green[700]!,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusOverlay() {
    return Consumer<SelectSourceProvider>(
      builder: (context, provider, child) {
        if (!provider.noSignalMode &&
            !provider.isLoading &&
            provider.hasInternet) return const SizedBox();

        Color overlayColor;
        IconData overlayIcon;
        String overlayText;

        if (provider.noSignalMode) {
          overlayColor = Colors.orange;
          overlayIcon = Icons.signal_wifi_off;
          overlayText =
              'Modo offline - Precisión reducida (±${provider.gpsAccuracy.toStringAsFixed(1)}m)';
        } else if (!provider.hasInternet) {
          overlayColor = Colors.green[700]!;
          overlayIcon = Icons.offline_pin;
          overlayText = 'Modo offline - GPS activo';
        } else {
          overlayColor = Theme.of(context).primaryColor;
          overlayIcon = Icons.gps_not_fixed;
          overlayText = provider.gpsStatus;
        }

        return Positioned(
          top: MediaQuery.of(context).padding.top + kToolbarHeight + 48,
          left: 16,
          right: 16,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            color: overlayColor,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(overlayIcon, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      overlayText,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// 4. PAINTER PARA LA GRILLA (REFERENCIA VISUAL OFFLINE)
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1.0;

    const double gridSize = 50.0;

    // Líneas verticales
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Líneas horizontales
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
