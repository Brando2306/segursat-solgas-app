import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safe_driving_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/utils/constants.dart';
import 'package:safe_driving_app/utils/style.dart';
import 'package:safe_driving_app/widgets/next_button.dart';

class StatementPage extends StatefulWidget {
  const StatementPage({super.key});

  @override
  State<StatementPage> createState() => _StatementPageState();
}

class _StatementPageState extends State<StatementPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: header(context),
        body: Column(children: [
          statement(context),
          selected(context),
          Expanded(child: Container()),
          Expanded(child: Container()),
          nextButton(
            context,
            STATEMENT.TEXT_BUTTON,
            '/sesion',
            authProvider.checkSelected,
            () {},
            null,
          ),
          SizedBox(
            height: getHeight(context, 3),
          )
        ]),
      ),
    );
  }

  Container statement(context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.50,
      alignment: Alignment.topCenter,
      padding: EdgeInsets.all(25.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const <Widget>[
            Text(STATEMENT.TEXT_STATEMENT),
            SizedBox(height: 20),
            Text(STATEMENT.TEXT_STATEMENT_1),
            SizedBox(height: 10),
            Text(STATEMENT.TEXT_STATEMENT_2),
            SizedBox(height: 10),
            Text(STATEMENT.TEXT_STATEMENT_3),
            SizedBox(height: 10),
            Text(STATEMENT.TEXT_STATEMENT_4),
          ],
        ),
      ),
    );
  }

  Container selected(context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Container(
      padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Theme(
            data: Theme.of(context).copyWith(
              unselectedWidgetColor: Colors.white,
            ),
            child: Checkbox(
              checkColor: Colors.white,
              activeColor: CustomColors.primary,
              value: authProvider.checkSelected,
              side: BorderSide(color: CustomColors.primary),
              onChanged: (bool? value) {
                if (value != null) {
                  authProvider.setCheckSelected(value);
                }
              },
            ),
          ),
          Text(STATEMENT.TEXT_CHECKBOX,
              style: TextStyle(color: Colors.black, fontSize: 13)),
        ],
      ),
    );
  }

  AppBar header(context) {
    return AppBar(
      title: Text(STATEMENT.TEXT_HEADER, style: TextStyle(color: Colors.black)),
      centerTitle: true,
      elevation: 0.0,
      backgroundColor: Colors.white,
      // leading: BackButton(color: Colors.black),
      leading: Container(),
    );
  }
}
