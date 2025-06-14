import 'package:flutter/material.dart';
import 'package:safe_driving_app/widgets/background.dart';
import 'package:safe_driving_app/utils/constants.dart';

class LoadPage extends StatefulWidget {
  const LoadPage({super.key});

  @override
  State<LoadPage> createState() => _LoadPageState();
}

class _LoadPageState extends State<LoadPage> {
  bool _visible = false;
  @override
  void initState() {
    super.initState();

    FocusManager.instance.primaryFocus?.unfocus();

    Future.delayed(
        Duration(seconds: 4), () => Navigator.pushNamed(context, '/startPage'));
    Future.delayed(Duration(milliseconds: 100),
        () => setState(() => _visible = !_visible));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: customBackground(
          context,
          Align(
              alignment: Alignment.center,
              child: Column(
                children: <Widget>[
                  Expanded(child: Container()),
                  centerLogo(context),
                  Expanded(child: Container()),
                  footer(context),
                ],
              ))),
    );
  }

  Container centerLogo(context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5),
      width: MediaQuery.of(context).size.width,
      child: AnimatedOpacity(
          opacity: _visible ? 1.0 : 0.0,
          duration: Duration(seconds: 2),
          child: Image.asset(LOAD.LOGO)),
    );
  }

  Column footer(context) {
    return Column(
      children: <Widget>[
        AnimatedOpacity(
            opacity: _visible ? 1.0 : 0.0,
            duration: Duration(seconds: 2),
            child: Text(
              LOAD.TITLE,
              style: TextStyle(color: Colors.white),
            )),
        AnimatedOpacity(
            opacity: _visible ? 1.0 : 0.0,
            duration: Duration(seconds: 2),
            child: Text(
              LOAD.SUBTITLE,
              style: TextStyle(color: Colors.white),
            )),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.05,
        )
      ],
    );
  }
}
