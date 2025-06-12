import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';
import 'package:safe_driving_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:safe_driving_app/features/speedometer/presentation/providers/menu_provider.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/shared/button_widget.dart';
import 'package:safe_driving_app/shared/loading_item_widget.dart';
import 'package:safe_driving_app/utils/constants.dart';
import 'package:safe_driving_app/utils/storage.dart';
import 'package:safe_driving_app/utils/style.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MenuProvider(),
      child: _MenuPageContent(),
    );
  }
}

class _MenuPageContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final menuProvider = Provider.of<MenuProvider>(context);

    final inspectionEnabled = menuProvider.buttonInspectionEnabled;
    final rootEnabled = menuProvider.buttonRootEnabled;

    final isLoading = inspectionEnabled == null || rootEnabled == null;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(context),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              isLoading
                  ? LoadingItem(height: getHeight(context, 7))
                  : _buildMenuButton(
                      context,
                      'Inspección de unidad',
                      '/inspection/question',
                      inspectionEnabled,
                    ),
              SizedBox(height: getHeight(context, 3)),
              isLoading
                  ? LoadingItem(height: getHeight(context, 7))
                  : _buildMenuButton(
                      context,
                      'Iniciar una ruta',
                      '/root/selectSource',
                      rootEnabled,
                    ),
              SizedBox(height: getHeight(context, 3)),
              isLoading
                  ? LoadingItem(height: getHeight(context, 7))
                  : _buildMenuButton(
                      context,
                      'Registrar mantenimiento',
                      '/maintance/odometer',
                      true,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(MENU.TEXT_HEADER, style: TextStyle(color: Colors.black)),
      centerTitle: true,
      elevation: 0.0,
      backgroundColor: Colors.white,
      leading: IconButton(
        onPressed: () => _logout(context),
        icon: Icon(Icons.logout),
        color: Colors.black,
        tooltip: 'Salir de la sesión',
      ),
      actions: [
        IconButton(
          onPressed: () => Navigator.pushNamed(context, '/offlineOperations'),
          icon: Icon(Icons.wifi_off_outlined),
          color: Colors.black,
          tooltip: 'Operaciones Offline',
        ),
      ],
    );
  }

  void _logout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    cleanAll();
    Navigator.pushNamed(context, '/sesion');
  }

  Widget _buildMenuButton(
    BuildContext context,
    String text,
    String route,
    bool enabled,
  ) {
    return Center(
      child: SizedBox(
        child: ButtonWidget(
          width: double.infinity,
          onPressed: enabled ? () => Navigator.pushNamed(context, route) : null,
          color: enabled ? CustomColors.primary : CustomColors.primaryOff,
          text: text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
