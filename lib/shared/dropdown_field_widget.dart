import 'package:flutter/material.dart';

class DropdownFieldWidget<T> extends StatelessWidget {
  final String labelText;
  final String? hintText;
  final String? helperText;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool enabled;
  final EdgeInsetsGeometry? contentPadding;
  final Color? fillColor;
  final bool filled;
  final InputBorder? border;
  final InputBorder? enabledBorder;
  final InputBorder? focusedBorder;
  final InputBorder? errorBorder;
  final InputBorder? focusedErrorBorder;
  final BorderRadius? borderRadius;
  final bool isExpanded;

  const DropdownFieldWidget({
    Key? key,
    required this.labelText,
    this.hintText,
    this.helperText,
    required this.value,
    required this.items,
    this.onChanged,
    this.validator,
    this.suffixIcon,
    this.prefixIcon,
    this.enabled = true,
    this.contentPadding = const EdgeInsets.all(16),
    this.fillColor = const Color(0xFFF2F5F8),
    this.filled = true,
    this.border,
    this.enabledBorder,
    this.focusedBorder,
    this.errorBorder,
    this.focusedErrorBorder,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.isExpanded = true,
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
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: enabled ? onChanged : null,
          validator: validator,
          isExpanded: isExpanded,
          decoration: InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.never,
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
          icon: const Icon(Icons.arrow_drop_down),
    
        ),
      ],
    );
  }
}
