import 'package:flutter/material.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/utils/inspection/index.dart';
import 'package:safe_driving_app/utils/storage.dart';
import 'package:safe_driving_app/utils/style.dart';

class FinishRootPage extends StatefulWidget {
  const FinishRootPage({super.key});

  @override
  State<FinishRootPage> createState() => _FinishRootPageState();
}

class _FinishRootPageState extends State<FinishRootPage> {
  bool buttonFinish = true;

  @override
  void initState() {
    super.initState();
    printStorage();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: (() async => false),
      child: Scaffold(
          body: Column(children: [
        Expanded(child: Container()),
        Image.asset(FINISH.IMAGE),
        SizedBox(
          width: getWidth(context, 80),
          child: Text(
            'La unidad ha llegado su destino',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        // ...nextButtonV2(context, FINISH.TEXT_BUTTON, '/menu', true, () {
        // cleanQuestionStorage();
        // cleanInspection();
        // })
        Expanded(child: Container()),
        buttonFinish
            ? MaterialButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/menu');
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                color: CustomColors.primary,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.height * 0.15,
                      vertical: 15),
                  child: Text(
                    FINISH.TEXT_BUTTON,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              )
            : Container(),
        SizedBox(
          height: getHeight(context, 3),
        )
      ])),
    );
  }
}
