import 'package:flutter/cupertino.dart';
import 'package:safe_driving_app/shared/circular_indicator_widget.dart';
import 'package:safe_driving_app/shared/text_widget.dart';

class ButtonWidget extends StatelessWidget {
  const ButtonWidget({
    Key? key,
    required this.text,
    required this.onPressed,
    this.color,
    this.decoration,
    this.colorDisabled = const Color.fromARGB(72, 155, 142, 142),
    this.padding,
    this.margin,
    this.constraints,
    this.loading = false,
    this.disabled,
    this.style,
    this.boxShadow,
    this.icon = "",
  }) : super(key: key);

  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  final Decoration? decoration;
  final Color? colorDisabled;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxConstraints? constraints;
  final bool? loading;
  final bool? disabled;
  final TextStyle? style;
  final List<BoxShadow>? boxShadow;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      alignment: Alignment.topRight,
      minSize: 0,
      padding: EdgeInsets.zero,
      onPressed: disabled == true ? null : onPressed,
      child: Container(
        constraints: constraints,
        padding: padding ?? const EdgeInsets.all(15),
        margin: margin ?? EdgeInsets.zero,
        decoration: decoration ??
            BoxDecoration(
              color: disabled == true ? colorDisabled : color,
              borderRadius: BorderRadius.circular(7),
              boxShadow: boxShadow,
            ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextWidget(text: text, style: style, textAlign: TextAlign.center),
            (loading == true)
                ? const CircularIndicatorWidget(
                    margin: EdgeInsets.only(left: 10))
                : Container(),
          ],
        ),
      ),
    );
  }
}
