import 'package:flutter/material.dart';
import 'package:safe_driving_app/helpers/functions.dart';
import 'package:safe_driving_app/utils/style.dart';

MaterialButton nextButton(BuildContext context, String text, String? route,
    bool validation, Function function, double? horizontal) {
  return MaterialButton(
    onPressed: () {
      if (validation) {
        function();
        if (route != null) {
          Navigator.pushNamed(context, route);
        }
      }
    },
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    color: validation ? CustomColors.primary : CustomColors.primaryOff,
    child: Padding(
      padding: EdgeInsets.symmetric(
          horizontal: horizontal != null
              ? getHeight(context, horizontal)
              : getHeight(context, 12),
          vertical: 16),
      child: Text(
        text,
        style: TextStyle(color: Colors.white),
      ),
    ),
  );
}

nextButtonV2(BuildContext context, String text, String route, bool validation,
    Function function) {
  return [
    Expanded(child: Container()),
    MaterialButton(
      onPressed: () {
        if (validation) {
          function();
          Navigator.pushNamed(context, route);
        }
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      color: validation ? CustomColors.primary : CustomColors.primaryOff,
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.height * 0.15,
            vertical: 15),
        child: Text(
          text,
          style: TextStyle(color: Colors.white),
        ),
      ),
    ),
    SizedBox(
      height: getHeight(context, 3),
    )
  ];
}
