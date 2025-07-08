import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safe_driving_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:safe_driving_app/features/route/presentation/providers/route_provider.dart';
import 'package:safe_driving_app/utils/storage.dart';
import 'package:safe_driving_app/widgets/background.dart';
import 'package:safe_driving_app/utils/constants.dart';

class LoadPage extends StatefulWidget {
  const LoadPage({super.key});

  @override
  State<LoadPage> createState() => _LoadPageState();
}

class _LoadPageState extends State<LoadPage> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    FocusManager.instance.primaryFocus?.unfocus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(
        Duration(milliseconds: 200),
        () => Provider.of<AuthProvider>(context, listen: false)
            .toggleVisibility(),
      );
    });

    await _determineInitialRoute();
  }

  Future<void> _determineInitialRoute() async {
    final authProvider = context.read<AuthProvider>();

    await authProvider.checkAuthStatus();

    if (!authProvider.isAuthenticated) {
      _navigateTo('/startPage');
      return;
    }

    _navigateTo('/menu');
  }

  void _navigateTo(String route) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 1500),
          () => Navigator.pushReplacementNamed(context, route));
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildLoadingScreen();
  }

  Widget _buildLoadingScreen() {
    final visible = Provider.of<AuthProvider>(context).visible;

    return Scaffold(
      body: customBackground(
        context,
        Align(
          alignment: Alignment.center,
          child: Column(
            children: <Widget>[
              Expanded(child: SizedBox()),
              _buildLogo(visible),
              Expanded(child: SizedBox()),
              _buildFooter(visible),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(bool visible) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5),
      width: MediaQuery.of(context).size.width,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: Duration(seconds: 2),
        child: Image.asset(LOAD.LOGO),
      ),
    );
  }

  Widget _buildFooter(bool visible) {
    return Column(
      children: <Widget>[
        AnimatedOpacity(
          opacity: visible ? 1.0 : 0.0,
          duration: Duration(seconds: 2),
          child: Text(
            LOAD.TITLE,
            style: TextStyle(color: Colors.white),
          ),
        ),
        AnimatedOpacity(
          opacity: visible ? 1.0 : 0.0,
          duration: Duration(seconds: 2),
          child: Text(
            LOAD.SUBTITLE,
            style: TextStyle(color: Colors.white),
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.05),
      ],
    );
  }
}
