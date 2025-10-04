import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:safe_driving_app/features/route/domain/entities/stop_route_entity.dart';
import 'package:safe_driving_app/features/route/presentation/providers/control_stop_provider.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/utils/constants.dart';
import 'package:safe_driving_app/utils/root/index.dart';
import 'package:safe_driving_app/utils/storage.dart';
import 'package:safe_driving_app/utils/style.dart';
import 'package:safe_driving_app/widgets/header.dart';
import 'package:safe_driving_app/widgets/next_button.dart';
import 'package:intl/intl.dart';

class ControlStopPage extends StatefulWidget {
  const ControlStopPage({super.key});

  @override
  _ControlStopPageState createState() => _ControlStopPageState();
}

class _ControlStopPageState extends State<ControlStopPage> {
  String title = 'Control de parada';

  // Date now
  var time = DateTime.now();
  late Timer _timerDateNow;

  // Cronometer
  static const countdownDuration = Duration(minutes: 15);
  Duration duration = Duration();

  final List<bool> _formOneselectedQuestionOne = <bool>[true, false];
  final List<bool> _formOneselectedQuestionTwo = <bool>[true, false];
  final List<bool> _formOneselectedQuestionThree = <bool>[true, false];

  final List<Widget> _formOnequestionOne = <Widget>[Text('No'), Text('Si')];
  final List<Widget> _formOnequestionTwo = <Widget>[Text('No'), Text('Si')];
  final List<Widget> _formOnequestionThree = <Widget>[Text('No'), Text('Si')];

  bool? _formOneValidationOne = false;
  bool? _formOneValidationTwo = false;
  bool? _formOneValidationThree = false;

  bool vertical = false;

  // Form question 2
  final List<bool> _formTwoselectedQuestionOne = <bool>[true, false];
  final List<bool> _formTwoselectedQuestionTwo = <bool>[true, false];
  final List<bool> _formTwoselectedQuestionThree = <bool>[true, false];

  final List<Widget> _formTwoquestionOne = <Widget>[Text('No'), Text('Si')];
  final List<Widget> _formTwoquestionTwo = <Widget>[Text('No'), Text('Si')];
  final List<Widget> _formTwoquestionThree = <Widget>[Text('No'), Text('Si')];

  bool _formTwoValidationOne = false;
  bool _formTwoValidationTwo = false;
  bool _formTwoValidationThree = false;

  bool verticalTwo = false;
  bool buttonFinish = true;

  // control page
  String? keyPage;

  // Cromometer
  Duration _currentTime = Duration.zero;
  late Timer _timer;

  @override
  void initState() {
    init();

    super.initState();
  }

  @override
  void dispose() {
    stopTimers();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          appBar: header(title),
          body: Column(children: controlPage(keyPage)),
        ));
  }

  init() {
    printStorage();
    dateNow();
    _initialize();
  }

  void stopTimers() {
    _timer.cancel();
    _timerDateNow.cancel();
  }

  List<Widget> controlPage(key) {
    switch (key) {
      case 'formQuestionOne':
        return formQuestionOne(context);

      case 'formQuestionTwo':
        return formQuestionTwo(context);

      default:
        return pageInit();
    }
  }

  void dateNow() {
    _timerDateNow =
        Timer.periodic(const Duration(milliseconds: 1000), (localTimer) async {
      setState(() {
        time = DateTime.now();
      });
    });
  }

// Cronometer
  void _initialize() {
    int savedTime = readStorage('root.stop.cronometer') ?? 0;
    _currentTime = Duration(seconds: savedTime);

    _timer = Timer.periodic(Duration(seconds: 1), _updateTime);
  }

  void _updateTime(Timer timer) {
    setState(() {
      _currentTime = _currentTime + Duration(seconds: 1);
      writeStorage('root.stop.cronometer', _currentTime.inSeconds);
    });
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) {
      if (n >= 10) return "$n";
      return "0$n";
    }

    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));

    return "$minutes:$seconds";
  }

  // Cronometer
  Widget buildTimeCard(
          {required String time,
          required String header,
          required bool small}) =>
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Text(
              time,
              style: TextStyle(
                  // fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: small ? 20 : 25,
                  fontFamily: 'NotoSans'),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Text(header, style: TextStyle(color: Colors.black45)),
        ],
      );

  List<Widget> pageInit() {
    return [
      SizedBox(
        height: getHeight(context, 3),
      ),
      Row(children: [
        Expanded(child: Container()),
        alertButton(context),
        Expanded(child: Container()),
        stopButton(),
        Expanded(child: Container()),
      ]),
      Expanded(child: Container()),
      Text(
          // '${time.day}/${time.month}/${time.year} ${time.hour}:${time.minute}:${time.second}',
          DateFormat('dd/MM/yyyy HH:mm:ss').format(time),
          style: TextStyle(
              fontSize: 25, fontFamily: 'Roboto', fontWeight: FontWeight.bold)),
      SizedBox(
        height: getHeight(context, 1),
      ),
      Text(
        _formatTime(_currentTime),
        style: TextStyle(
            fontSize: 40, fontFamily: 'Roboto', fontWeight: FontWeight.bold),
      ),
      Expanded(child: Container()),
      Expanded(child: Container()),
      nextButton(context, 'Siguiente', null, true, () {
        setState(() {
          keyPage = 'formQuestionOne';
          title = 'Autoevaluación - parada';
        });
      }, null),
      SizedBox(
        height: getHeight(context, 3),
      )
    ];
  }

  Column stopButton() {
    return Column(
      children: [
        MaterialButton(
          onPressed: () {
            writeStorage('root.type', ROOT_TYPE.SOS);
            writeStorage('root.incident.type', ROOT_TYPE.STOP);
            stopTimers();
            Navigator.pushNamed(context, '/root/incidentReport');
          },
          color: Colors.amber,
          textColor: Colors.white,
          //TODO: Make icon here
          // child: FaIcon(
          //   FontAwesomeIcons.circleStop,
          //   color: Colors.white,
          //   size: 25,
          // ),
          child: Icon(Icons.stop, color: Colors.white, size: 25),
          padding: EdgeInsets.all(16),
          shape: CircleBorder(),
        ),
        SizedBox(
          height: 5,
        ),
        Text('Incidencia', style: TextStyle(fontWeight: FontWeight.bold))
      ],
    );
  }

  Column alertButton(context) {
    return Column(
      children: [
        MaterialButton(
          onPressed: () {
            stopTimers();
            writeStorage('root.type', ROOT_TYPE.SOS);

            notificationSoS(context);
          },
          color: Colors.red,
          textColor: Colors.white,
          //TODO: Make icon here
          // child: FaIcon(
          //   FontAwesomeIcons.warning,
          //   color: Colors.white,
          //   size: 25,
          // ),
          child: Icon(Icons.warning, color: Colors.white, size: 25),
          padding: EdgeInsets.all(16),
          shape: CircleBorder(),
        ),
        SizedBox(
          height: 5,
        ),
        Text('SOS', style: TextStyle(fontWeight: FontWeight.bold))
      ],
    );
  }

  notificationSoS(context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Confirmación",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 9, 43, 145),
            ),
          ),
          content: Text('¿Está seguro de que quiere finalizar la ruta?'),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
                Navigator.pushNamed(context, '/root/finish');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('Confirmar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
              child: Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  formQuestionOne(BuildContext context) {
    return [
      Expanded(child: Container()),
      Text(
        QUESTIONSTOP.ONE,
        style: TextStyle(fontSize: 16),
      ),
      SizedBox(
        height: getHeight(context, 1),
      ),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        ToggleButtons(
          direction: vertical ? Axis.vertical : Axis.horizontal,
          onPressed: (int index) {
            setState(() {
              for (int i = 0; i < _formOneselectedQuestionOne.length; i++) {
                _formOneselectedQuestionOne[i] = i == index;
              }
              // writeStorage('question.one', index == 1 ? true : false);
              _formOneValidationOne = index == 1 ? true : false;
            });
          },
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          selectedBorderColor: Colors.blue[700],
          selectedColor: Colors.white,
          fillColor: Colors.blue[200],
          color: Colors.blue[400],
          constraints: const BoxConstraints(
            minHeight: 40.0,
            minWidth: 80.0,
          ),
          isSelected: _formOneselectedQuestionOne,
          children: _formOnequestionOne,
        )
      ]),
      Expanded(child: Container()),
      Text(
        QUESTIONSTOP.TWO,
        style: TextStyle(fontSize: 16),
      ),
      SizedBox(
        height: getHeight(context, 1),
      ),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        ToggleButtons(
          direction: vertical ? Axis.vertical : Axis.horizontal,
          onPressed: (int index) {
            setState(() {
              for (int i = 0; i < _formOneselectedQuestionTwo.length; i++) {
                _formOneselectedQuestionTwo[i] = i == index;
              }
              // writeStorage('question.two', index == 1 ? true : false);
              _formOneValidationTwo = index == 1 ? true : false;
            });
          },
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          selectedBorderColor: Colors.blue[700],
          selectedColor: Colors.white,
          fillColor: Colors.blue[200],
          color: Colors.blue[400],
          constraints: const BoxConstraints(
            minHeight: 40.0,
            minWidth: 80.0,
          ),
          isSelected: _formOneselectedQuestionTwo,
          children: _formOnequestionTwo,
        )
      ]),
      Expanded(child: Container()),
      Text(
        QUESTIONSTOP.THREE,
        style: TextStyle(fontSize: 16),
      ),
      SizedBox(
        height: getHeight(context, 1),
      ),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        ToggleButtons(
          direction: vertical ? Axis.vertical : Axis.horizontal,
          onPressed: (int index) {
            setState(() {
              for (int i = 0; i < _formOneselectedQuestionThree.length; i++) {
                _formOneselectedQuestionThree[i] = i == index;
              }
              // writeStorage('question.three', index == 1 ? true : false);
              _formOneValidationThree = index == 1 ? true : false;
            });
          },
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          selectedBorderColor: Colors.blue[700],
          selectedColor: Colors.white,
          fillColor: Colors.blue[200],
          color: Colors.blue[400],
          constraints: const BoxConstraints(
            minHeight: 40.0,
            minWidth: 80.0,
          ),
          isSelected: _formOneselectedQuestionThree,
          children: _formOnequestionThree,
        )
      ]),
      Expanded(child: Container()),
      Expanded(child: Container()),
      nextButton(
          context,
          'Siguiente',
          null,
          ((_formOneValidationOne ?? false) &&
              (_formOneValidationTwo ?? false) &&
              (_formOneValidationThree ?? false)), () {
        setState(() => keyPage = 'formQuestionTwo');

        writeStorage(
            'root.recurringStop.questionOne',
            json.encode({
              'one': _formOneValidationOne,
              'two': _formOneValidationTwo,
              'three': _formOneValidationThree
            }));
      }, null),
      SizedBox(
        height: getHeight(context, 3),
      )
    ];
  }

  formQuestionTwo(context) {
    return [
      Expanded(child: Container()),
      Text(
        QUESTIONSTOP.FOUR,
        style: TextStyle(fontSize: 16),
      ),
      SizedBox(
        height: getHeight(context, 1),
      ),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        ToggleButtons(
          direction: verticalTwo ? Axis.vertical : Axis.horizontal,
          onPressed: (int index) {
            setState(() {
              for (int i = 0; i < _formTwoselectedQuestionOne.length; i++) {
                _formTwoselectedQuestionOne[i] = i == index;
              }
              // writeStorage('question.one', index == 1 ? true : false);
              _formTwoValidationOne = index == 1 ? true : false;
            });
          },
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          selectedBorderColor: Colors.blue[700],
          selectedColor: Colors.white,
          fillColor: Colors.blue[200],
          color: Colors.blue[400],
          constraints: const BoxConstraints(
            minHeight: 40.0,
            minWidth: 80.0,
          ),
          isSelected: _formTwoselectedQuestionOne,
          children: _formTwoquestionOne,
        )
      ]),
      Expanded(child: Container()),
      Text(
        QUESTIONSTOP.FIVE,
        style: TextStyle(fontSize: 16),
      ),
      SizedBox(
        height: getHeight(context, 1),
      ),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        ToggleButtons(
          direction: verticalTwo ? Axis.vertical : Axis.horizontal,
          onPressed: (int index) {
            setState(() {
              for (int i = 0; i < _formTwoselectedQuestionTwo.length; i++) {
                _formTwoselectedQuestionTwo[i] = i == index;
              }
              // writeStorage('question.two', index == 1 ? true : false);
              _formTwoValidationTwo = index == 1 ? true : false;
            });
          },
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          selectedBorderColor: Colors.blue[700],
          selectedColor: Colors.white,
          fillColor: Colors.blue[200],
          color: Colors.blue[400],
          constraints: const BoxConstraints(
            minHeight: 40.0,
            minWidth: 80.0,
          ),
          isSelected: _formTwoselectedQuestionTwo,
          children: _formTwoquestionTwo,
        )
      ]),
      Expanded(child: Container()),
      Expanded(child: Container()),
      buttonFinish
          ? MaterialButton(
              onPressed: () {
                setState(() => keyPage = 'formQuestionTwo');

                writeStorage(
                    'root.recurringStop.questionTwo',
                    json.encode({
                      'one': _formTwoValidationOne,
                      'two': _formTwoValidationTwo,
                    }));

                finishRecurringStop(context);
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              color: ((_formTwoValidationOne ?? false) &&
                      (_formTwoValidationTwo ?? false))
                  ? CustomColors.primary
                  : CustomColors.primaryOff,
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: getHeight(context, 12), vertical: 16),
                child: Text(
                  'Finalizar parada',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            )
          : Container(),
      SizedBox(
        height: getHeight(context, 3),
      )
    ];
  }

  finishRecurringStop(context) async {
    setState(() => buttonFinish = false);

    EasyLoading.show(status: 'Enviando...');

    try {
      stopTimers();

      final provider = Provider.of<ControlStopProvider>(context, listen: false);
      final position = await Geolocator.getCurrentPosition();

      final stop = StopRouteEntity(
        routeId: readStorage('root.createRoute.id'),
        unitId: readStorage('personal.unitId'),
        timestamp: getDate(),
        latitude: position.latitude,
        longitude: position.longitude,
        type: readStorage('personal.type') ?? '',
        description: "Ninguno",
        address: readStorage('root.address') ?? 'No Encontrado',
        time: readStorage('root.stop.cronometer') ?? 0,
        questions: [
          {
            'question': QUESTIONSTOP.ONE,
            'answer': json
                .decode(readStorage('root.recurringStop.questionOne'))['one'],
            'type': 'bool',
          },
          {
            'question': QUESTIONSTOP.TWO,
            'answer': json
                .decode(readStorage('root.recurringStop.questionOne'))['two'],
            'type': 'bool',
          },
          {
            'question': QUESTIONSTOP.THREE,
            'answer': json
                .decode(readStorage('root.recurringStop.questionOne'))['three'],
            'type': 'bool',
          },
          {
            'question': QUESTIONSTOP.FOUR,
            'answer': json
                .decode(readStorage('root.recurringStop.questionTwo'))['one'],
            'type': 'bool',
          },
          {
            'question': QUESTIONSTOP.FIVE,
            'answer': json
                .decode(readStorage('root.recurringStop.questionTwo'))['two'],
            'type': 'bool',
          },
        ],
      );

      await provider.submitStop(stop);
      cleanRootRecurringStop();
    } catch (e) {
      notificationError(context, e.toString());
      setState(() => buttonFinish = true);
      print(e);
    } finally {
      EasyLoading.dismiss();
      Navigator.pushNamed(context, '/root/speedometer');
    }

    EasyLoading.dismiss();
  }
}
