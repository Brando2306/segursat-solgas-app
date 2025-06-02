import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FormFieldWidget extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final String? helperText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onChanged;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool enabled;
  final TextCapitalization textCapitalization;
  final String? initialValue;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final EdgeInsetsGeometry? contentPadding;
  final Color? fillColor;
  final bool filled;
  final InputBorder? border;
  final InputBorder? enabledBorder;
  final InputBorder? focusedBorder;
  final InputBorder? errorBorder;
  final InputBorder? focusedErrorBorder;
  final BorderRadius? borderRadius;

  const FormFieldWidget({
    Key? key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.helperText,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.inputFormatters,
    this.onChanged,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.suffixIcon,
    this.prefixIcon,
    this.enabled = true,
    this.textCapitalization = TextCapitalization.none,
    this.initialValue,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
    this.contentPadding = const EdgeInsets.all(16),
    this.fillColor = const Color(0xFFF2F5F8),
    this.filled = true,
    this.border,
    this.enabledBorder,
    this.focusedBorder,
    this.errorBorder,
    this.focusedErrorBorder,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              labelText,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.never,
            enabled: enabled,
            contentPadding: contentPadding,
            fillColor: fillColor,
            filled: filled,
            border: border ??
                OutlineInputBorder(
                  borderRadius: borderRadius!,
                  borderSide: BorderSide.none,
                ),
            enabledBorder: enabledBorder ??
                OutlineInputBorder(
                  borderRadius: borderRadius!,
                  borderSide: BorderSide.none,
                ),
            focusedBorder: focusedBorder ??
                OutlineInputBorder(
                  borderRadius: borderRadius!,
                  borderSide: BorderSide.none,
                ),
            errorBorder: errorBorder ??
                OutlineInputBorder(
                  borderRadius: borderRadius!,
                  borderSide: BorderSide.none,
                ),
            focusedErrorBorder: focusedErrorBorder ??
                OutlineInputBorder(
                  borderRadius: borderRadius!,
                  borderSide: BorderSide.none,
                ),
            disabledBorder: OutlineInputBorder(
              borderRadius: borderRadius!,
              borderSide: BorderSide.none,
            ),
            alignLabelWithHint: false,
            hintText: hintText,
            helperText: helperText,
            suffixIcon: suffixIcon,
            prefixIcon: prefixIcon,
          ),
          keyboardType: keyboardType,
          validator: validator,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          obscureText: obscureText,
          maxLines: maxLines,
          minLines: minLines,
          enabled: enabled,
          textCapitalization: textCapitalization,
          initialValue: initialValue,
          focusNode: focusNode,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
        ),
      ],
    );
  }
}
