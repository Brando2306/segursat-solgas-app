import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:safe_driving_app/core/utils/dialog_util.dart';
import 'package:safe_driving_app/core/utils/location_util.dart';

import 'package:safe_driving_app/core/validators/auth_validator.dart';
import 'package:safe_driving_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:safe_driving_app/features/driver/domain/entities/driver_entity.dart';
import 'package:safe_driving_app/features/driver/presentation/providers/driver_provider.dart';
import 'package:safe_driving_app/features/route/presentation/providers/route_provider.dart';
import 'package:safe_driving_app/features/unit/domain/entities/unit_entity.dart';
import 'package:safe_driving_app/features/unit/presentation/providers/unit_provider.dart';
import 'package:safe_driving_app/shared/button_widget.dart';
import 'package:safe_driving_app/shared/form_field_widget.dart';
import 'package:safe_driving_app/utils/constants.dart';
import 'package:safe_driving_app/utils/storage.dart';
import 'package:safe_driving_app/utils/style.dart';
import 'package:safe_driving_app/widgets/next_button.dart';

class SesionPage extends StatefulWidget {
  const SesionPage({super.key});

  @override
  State<SesionPage> createState() => _SesionPageState();
}

class _SesionPageState extends State<SesionPage> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _documentController = TextEditingController();
  final _licensePlateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPendingSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _documentController.dispose();
    _licensePlateController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        readStorage('sesionPageValidation') != null) {
      _handleResumeRoute();
    }
  }

  Future<void> _checkPendingSession() async {
    if (readStorage('sesionPageValidation') != null) {
      await _handleResumeRoute();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          appBar: _buildAppBar(),
          backgroundColor: Colors.white,
          resizeToAvoidBottomInset: false,
          body: _buildBody(),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title:
          Text(SESION.TEXT_HEADER, style: const TextStyle(color: Colors.black)),
      centerTitle: true,
      elevation: 0.0,
      backgroundColor: Colors.white,
      leading: const SizedBox(),
    );
  }

  Widget _buildBody() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              _buildForm(authProvider),
              if (authProvider.nextButtonValidation) _buildUserInfoCard(),
              const Spacer(),
              if (authProvider.nextButtonValidation) _buildNextButton(),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildForm(AuthProvider authProvider) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          FormFieldWidget(
            controller: _documentController,
            labelText: SESION.LABEL_DOCUMENTINPUT,
            hintText: SESION.PLACEHOLDER_DOCUMENTINPUT,
            keyboardType: TextInputType.number,
            validator: AuthValidator.validateDocument,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              FilteringTextInputFormatter.deny(RegExp(r'^\s')),
              FilteringTextInputFormatter.deny(RegExp(r'[ ]')),
            ],
            onChanged: (_) => _updateValidationState(),
          ),
          const SizedBox(height: 20),
          FormFieldWidget(
            controller: _licensePlateController,
            labelText: SESION.LABEL_LICENSEPLATE,
            hintText: SESION.PLACEHOLDER_LICENSEPLATE,
            validator: AuthValidator.validateLicensePlate,
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'^\s')),
              FilteringTextInputFormatter.deny(RegExp(r'[ ]')),
            ],
            onChanged: (_) => _updateValidationState(),
            helperText: '*Ingresar la placa con guión, por ejemplo: ABC-123',
          ),
          const SizedBox(height: 40),
          if (!authProvider.nextButtonValidation) _buildValidationButton(),
        ],
      ),
    );
  }

  Widget _buildValidationButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Center(
          child: ButtonWidget(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            text: 'Validar información',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
            color: CustomColors.primary,
            onPressed: () {
              if (authProvider.submitValidation) {
                _submitForm(context);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildUserInfoCard() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) return const SizedBox();

    return SizedBox(
      width: MediaQuery.of(context).size.height * 0.36,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 10,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                child: const Text('Información personal'),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: Image.asset(SESION.LOGO_PERSONAL),
              ),
              _buildUserInfoRow('Nombres:', user.name ?? ''),
              _buildUserInfoRow('Apellidos:', user.lastName ?? ''),
              _buildUserInfoRow('DNI:', user.document ?? ''),
              _buildUserInfoRow('Placa:', user.licensePlate ?? ''),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          child: Text(label),
        ),
        Container(
          padding: const EdgeInsets.all(5),
          child: Text(value),
        ),
      ],
    );
  }

  Widget _buildNextButton() {
    final authProvider = context.read<AuthProvider>();
    final bool nextButtonValidation = authProvider.nextButtonValidation;

    return nextButton(context, SESION.TEXT_BUTTON, '/menu',
        nextButtonValidation, () {}, null);
  }

  void _updateValidationState() {
    final isValid = _formKey.currentState?.validate() ?? false;
    context.read<AuthProvider>().setSubmitValidation(isValid);
    context.read<AuthProvider>().setNextButtonValidation(false);
  }

  Future<void> _submitForm(BuildContext context) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authProvider = context.read<AuthProvider>();
    final driverProvider = context.read<DriverProvider>();
    final unitProvider = context.read<UnitProvider>();
    final routeProvider = context.read<RouteProvider>();

    try {
      EasyLoading.show(status: 'Validando...');

      await _validateUserCredentials(driverProvider, unitProvider);

      final driver = driverProvider.driver!;
      final unit = unitProvider.unit!;

      await _saveUserSession(authProvider, driver, unit);

      await _handlePendingRoute(routeProvider, unit);

      await _showUserAnnotations(driver, unit);
    } catch (e) {
      Dialogs.showErrorDialog(context, 'Error', e.toString());
    } finally {
      EasyLoading.dismiss();
    }
  }

  Future<void> _validateUserCredentials(
      DriverProvider driverProvider, UnitProvider unitProvider) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw 'No hay conexión a internet. Por favor, conectate para iniciar sesión.';
      }

      await driverProvider.fetchDriver(_documentController.text);
      await unitProvider.fetchUnit(_licensePlateController.text);

      if (driverProvider.error != null) {
        throw driverProvider.error!;
      }

      if (unitProvider.error != null) {
        throw unitProvider.error!;
      }

      if (driverProvider.driver == null || unitProvider.unit == null) {
        throw 'No se pudo obtener la información del usuario o vehículo';
      }
    } catch (e) {
      throw 'Error de conexión: $e';
    }
  }

  Future<void> _saveUserSession(
      AuthProvider authProvider, DriverEntity driver, UnitEntity unit) async {
    authProvider.setNextButtonValidation(true);

    await authProvider.login(
      name: driver.firstName,
      lastName: driver.lastName,
      document: driver.idNumber,
      licensePlate: unit.name,
      unitId: unit.id,
      lastInitialInspectionDate: unit.lastInitialInspectionDate,
      lastOdometer: unit.lastOdometer,
      technicalReviewExpirationDate: unit.technicalReviewExpiration,
      soatExpirationDate: unit.soatExpiration,
      insuranceExpirationDate: unit.insuranceExpiration,
      lastRoute: unit.lastRoute,
      lastRouteStatus: unit.lastRouteStatus,
    );
  }

  Future<void> _handlePendingRoute(
      RouteProvider routeProvider, UnitEntity unit) async {
    final hasPendingRoute =
        unit.lastRouteStatus == SESION.RUNNING && unit.lastRoute != null;

    if (hasPendingRoute) {
      final lastRoute = unit.lastRoute?.toString() ?? '';
      await _showResumeRouteDialog(routeProvider, lastRoute);
    }
  }

  Future<void> _showResumeRouteDialog(
      RouteProvider routeProvider, String lastRoute) async {
    await writeStorage('personal.lastRoute', lastRoute);
    await writeStorage('root.createRoute.id', lastRoute);
    await writeStorage('personal.lastRouteStatus', SESION.RUNNING);

    EasyLoading.dismiss();

    await Dialogs.showConfirmationDialog(
      context: context,
      title: 'Ruta pendiente',
      message: 'Tienes una ruta activa en curso. ¿Deseas recuperar la ruta?',
      onConfirm: () async {
        await _tryResumeRoute(routeProvider, lastRoute);
      },
    );
  }

  Future<void> _tryResumeRoute(
      RouteProvider routeProvider, String lastRoute) async {
    try {
      EasyLoading.show(status: 'Verificando GPS...');
      final hasLocation = await LocationUtils.checkLocationPermission();

      if (!hasLocation) {
        await writeStorage('sesionPageValidation', true);
        LocationUtils.showLocationSettingsDialog(context);
        return;
      }

      await writeStorage('personal.pushRouteSpeedometer', true);
      await routeProvider.tryResumePendingRoute(context);
    } catch (e) {
      EasyLoading.dismiss();
      Dialogs.showErrorDialog(context, 'Error al recuperar ruta', e.toString());
    }
  }

  Future<void> _handleResumeRoute() async {
    try {
      final routeProvider = context.read<RouteProvider>();
      await writeStorage('sesionPageValidation', null);
      await routeProvider.tryResumePendingRoute(context);
    } catch (e) {
      Navigator.pushReplacementNamed(context, '/menu');
    }
  }

  Future<void> _showUserAnnotations(
      DriverEntity driver, UnitEntity unit) async {
    final annotations = <String>[];

    if (unit.annotations is List) {
      annotations.addAll(_extractAnnotations(unit.annotations as List));
    }

    if (driver.annotations is List) {
      annotations.addAll(_extractAnnotations(driver.annotations as List));
    }

    if (annotations.isNotEmpty) {
      await Dialogs.showInfoDialog(
          context, 'Anotaciones', annotations.join('\n\n'));
    }
  }

  List<String> _extractAnnotations(List<dynamic> annotations) {
    return annotations
        .where((a) => a is Map<String, dynamic> && a.containsKey('description'))
        .map((a) => a['description'] as String)
        .toList();
  }
}
