import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CircularIndicatorWidget extends StatelessWidget {
  const CircularIndicatorWidget({
    Key? key,
    this.padding,
    this.margin,
    this.height = 15,
    this.width = 15,
    this.strokeWidth = 2,
    this.color = Colors.white,
  }) : super(key: key);

  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? height;
  final double? width;
  final double? strokeWidth;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final radius = strokeWidth! * 5.0;
    if (Platform.isIOS) {
      return Container(
        padding: padding,
        margin: margin,
        height: height,
        width: width,
        child: CupertinoActivityIndicator(
            radius: (radius), color: color ?? Colors.white),
      );
    }
    return Container(
        padding: padding,
        margin: margin,
        height: height,
        width: width,
        child: CircularProgressIndicator(
            strokeWidth: strokeWidth ?? 2,
            valueColor: AlwaysStoppedAnimation<Color>(color ?? Colors.white)));
  }
}
