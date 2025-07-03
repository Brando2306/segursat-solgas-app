import 'package:flutter/material.dart';

class TextWidget extends StatelessWidget {
  const TextWidget({
    Key? key,
    required this.text,
    this.fontSize = 11,
    this.style,
    this.fontWeight = FontWeight.w500,
    this.color = Colors.white,
    this.textAlign = TextAlign.center,
    this.overflow = TextOverflow.ellipsis,
    this.maxLines = 1,
  }) : super(key: key);

  final String text;
  final TextStyle? style;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: style ??
          TextStyle(
              fontSize: fontSize,
              fontWeight: fontWeight,
              letterSpacing: 0,
              fontFamily: 'Montserrat',
              color: color),
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}
