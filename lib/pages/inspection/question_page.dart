import 'package:flutter/material.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/utils/inspection/index.dart';
import 'package:safe_driving_app/utils/storage.dart';
import 'package:safe_driving_app/widgets/header.dart';
import 'package:safe_driving_app/widgets/next_button.dart';

class QuestionPage extends StatefulWidget {
  const QuestionPage({super.key});

  @override
  State<StatefulWidget> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  final List<bool> _selectedQuestionOne = <bool>[true, false];
  final List<bool> _selectedQuestionTwo = <bool>[true, false];
  final List<bool> _selectedQuestionThree = <bool>[true, false];

  final List<Widget> _questionOne = <Widget>[Text('No'), Text('Si')];
  final List<Widget> _questionTwo = <Widget>[Text('No'), Text('Si')];
  final List<Widget> _questionThree = <Widget>[Text('No'), Text('Si')];

  bool vertical = false;

  @override
  void initState() {
    super.initState();
    printStorage();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: header(context),
        body: Column(children: [
          Expanded(child: Container()),
          Text(QUESTION.TEXT_QUESTION_ONE),
          SizedBox(
            height: getHeight(context, 1),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            ToggleButtons(
              direction: vertical ? Axis.vertical : Axis.horizontal,
              onPressed: (int index) {
                setState(() {
                  for (int i = 0; i < _selectedQuestionOne.length; i++) {
                    _selectedQuestionOne[i] = i == index;
                  }
                  writeStorage('question.one', index == 1 ? true : false);
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
              isSelected: _selectedQuestionOne,
              children: _questionOne,
            )
          ]),
          Expanded(child: Container()),
          Text(QUESTION.TEXT_QUESTION_TWO),
          SizedBox(
            height: getHeight(context, 1),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            ToggleButtons(
              direction: vertical ? Axis.vertical : Axis.horizontal,
              onPressed: (int index) {
                setState(() {
                  for (int i = 0; i < _selectedQuestionTwo.length; i++) {
                    _selectedQuestionTwo[i] = i == index;
                  }
                  writeStorage('question.two', index == 1 ? true : false);
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
              isSelected: _selectedQuestionTwo,
              children: _questionTwo,
            )
          ]),
          Expanded(child: Container()),
          Text(QUESTION.TEXT_QUESTION_THREE),
          SizedBox(
            height: getHeight(context, 1),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            ToggleButtons(
              direction: vertical ? Axis.vertical : Axis.horizontal,
              onPressed: (int index) {
                setState(() {
                  for (int i = 0; i < _selectedQuestionThree.length; i++) {
                    _selectedQuestionThree[i] = i == index;
                  }
                  writeStorage('question.three', index == 1 ? true : false);
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
              isSelected: _selectedQuestionThree,
              children: _questionThree,
            )
          ]),
          Expanded(child: Container()),
          Expanded(child: Container()),
          Expanded(child: Container()),
          nextButton(
              context,
              QUESTION.TEXT_BUTTON,
              '/inspection/odometer',
              (readStorage('question.one') ?? false) &&
                  (readStorage('question.two') ?? false) &&
                  (readStorage('question.three') ?? false),
              () {},
              null),
          SizedBox(
            height: getHeight(context, 3),
          )
        ]),
      ),
    );
  }

  AppBar header(context) {
    return headerV2(
        QUESTION.TEXT_HEADER,
        Builder(
          builder: (context) => IconButton(
              onPressed: () {
                cleanQuestionStorage();
                Navigator.pushNamed(context, '/menu');
              },
              icon: Icon(Icons.home),
              color: Colors.black,
              tooltip: 'Salir de la inspección'),
        ));
  }
}
