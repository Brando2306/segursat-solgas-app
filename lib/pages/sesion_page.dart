import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'package:safe_driving_app/utils/style.dart';
import 'package:safe_driving_app/helpers/gps.dart';
import 'package:safe_driving_app/utils/errors.dart';
import 'package:safe_driving_app/utils/storage.dart';
import 'package:safe_driving_app/utils/constants.dart';
import 'package:safe_driving_app/utils/snackbars.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/widgets/next_button.dart';
import 'package:safe_driving_app/shared/button_widget.dart';
import 'package:safe_driving_app/shared/form_field_widget.dart';
import 'package:safe_driving_app/core/validators/auth_validator.dart';
import 'package:safe_driving_app/features/unit/presentation/providers/unit_provider.dart';
import 'package:safe_driving_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:safe_driving_app/features/route/presentation/providers/route_provider.dart';
import 'package:safe_driving_app/features/driver/presentation/providers/driver_provider.dart';
import 'package:safe_driving_app/features/speedometer/presentation/providers/speedometer_provider.dart';

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
      context.read<RouteProvider>().handleAppResumed(context);
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
          body: _buildBody(context),
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

  Widget _buildBody(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (contextProvider, authProvider, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildForm(authProvider, context),
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

  Widget _buildForm(AuthProvider authProvider, BuildContext context) {
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
            helperText: '*Ingrese la placa con guion, por ejemplo: ABC-123',
          ),
          const SizedBox(height: 40),
          if (!authProvider.nextButtonValidation)
            _buildValidationButton(context),
        ],
      ),
    );
  }

  Widget _buildValidationButton(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
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
    final authProvider = context.read<AuthProvider>();
    final driverProvider = context.read<DriverProvider>();
    final unitProvider = context.read<UnitProvider>();

    if (_formKey.currentState?.validate() ?? false) {
      try {
        EasyLoading.show(status: 'Validando...');
        FocusManager.instance.primaryFocus?.unfocus();
        // Fetch con providers (como pediste)
        await driverProvider.fetchDriver(_documentController.text);
        await unitProvider.fetchUnit(_licensePlateController.text);

        final driver = driverProvider.driver;
        final unit = unitProvider.unit;

        bool validationDriver = driver != null && !driverProvider.hasError;
        bool validationUnit = unit != null && !unitProvider.hasError;

        if (validationDriver && validationUnit) {
          // Guardar sesión con provider (como pediste)
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

          // FLUJO REGULAR
          if (!isNotEmptyString(unit.lastRouteStatus) ||
              !isNotEmptyString(unit.lastRoute) ||
              unit.lastRouteStatus != SESION.RUNNING) {
            // Mostrar anotaciones si existen
            EasyLoading.dismiss();
            await _showUserAnnotations(driver, unit);
          } else {
            // FLUJO CONTINUAR RUTA
            await writeStorage('personal.lastRoute', unit.lastRoute);
            await writeStorage('root.createRoute.id', unit.lastRoute);
            await writeStorage(
                'personal.lastRouteStatus', unit.lastRouteStatus);

            bool validation = await checkGps();

            EasyLoading.dismiss();

            // Usar un nuevo contexto seguro
            if (mounted) {
              final safeContext = context;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                notificationInfoWithoutWillPopScope(
                  context: safeContext,
                  onWillPop: false,
                  barrierDismissible: false,
                  content:
                      'Tienes una ruta activa en curso.\n¿Deseas recuperar la ruta?',
                  callBack: () async {
                    if (validation) {
                      await writeStorage('personal.pushRouteSpeedometer', true);
                      await safeContext
                          .read<RouteProvider>()
                          .resumeRouteFlow(safeContext);
                    } else {
                      await writeStorage('sesionPageValidation', true);
                      safeContext
                          .read<RouteProvider>()
                          .showLocationSettingsDialog(safeContext);
                    }
                  },
                  callBackDont: () async {
                    final navigatorContext = Navigator.of(context).context;

                    try {
                      EasyLoading.show(status: 'Finalizando ruta...');

                      // Reutilizar finishRoute del SpeedometerProvider
                      final speedometerProvider =
                          Provider.of<SpeedometerProvider>(navigatorContext,
                              listen: false);

                      await speedometerProvider.finishRoute();

                      EasyLoading.dismiss();

                      // Mostrar confirmación
                      Snackbars.showSnackbarSuccess(
                          'Ruta finalizada correctamente');
                    } catch (e) {
                      EasyLoading.dismiss();
                      if (mounted) {
                        notificationError(
                            context, 'Error al finalizar ruta: $e');
                      }
                    }
                  },
                );
              });
            }
            return;
          }
        } else {
          authProvider.setSubmitValidation(true);

          if (driverProvider.hasError) {
            notificationAlert(
                context,
                errorTranslations[handleApiError(driverProvider.error)] ??
                    handleApiError(driver));
          } else if (unitProvider.hasError) {
            notificationAlert(
                context,
                errorTranslations[handleApiError(unitProvider.error)] ??
                    handleApiError(driver));
          }
        }
      } catch (e) {
        // Dialogs.showErrorDialog(context, 'Error', e.toString());
        notificationError(context, e.toString());
      } finally {
        EasyLoading.dismiss();
      }
    } else {
      EasyLoading.dismiss();
    }
  }

  Future<void> _showUserAnnotations(dynamic driver, dynamic unit) async {
    if (unit.annotations is List) {
      List<dynamic> annotations = unit.annotations;
      if (annotations.isNotEmpty) {
        if (annotations[0] is Map<String, dynamic> &&
            annotations[0].containsKey('description')) {
          var list = annotations.map((e) => e['description'] as String);
          var newList = list.join('\n\n');
          notificationInfo(context, newList, () {});
        }
      }
    }
    if (driver.annotations is List) {
      List<dynamic> annotations = driver.annotations;
      if (annotations.isNotEmpty) {
        if (annotations[0] is Map<String, dynamic> &&
            annotations[0].containsKey('description')) {
          var list = annotations.map((e) => e['description'] as String);
          var newList = list.join('\n\n');
          notificationInfo(context, newList, () {});
        }
      }
    }
  }
}
