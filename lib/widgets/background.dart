import 'package:flutter/material.dart';
import 'package:safe_driving_app/utils/style.dart';

Stack customBackground(BuildContext context, Widget newWidget) {
  return Stack(
    children: <Widget>[
      Container(
        color: Color(0xFF2e4792),
        //decoration: BoxDecoration(borderRadius: BorderRadius.only()),
      ),
      Align(
        alignment: Alignment.topCenter,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.90,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(500)),
              color: Color(0xFF19317a)),
        ),
      ),
      Align(
        alignment: Alignment.topCenter,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.70,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(500)),
              color: CustomColors.primary),
        ),
      ),
      newWidget,
    ],
  );
}
