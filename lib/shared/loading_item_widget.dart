import 'package:flutter/material.dart';

class LoadingItem extends StatelessWidget {
  final double height;
  final Color? color;

  const LoadingItem({
    super.key,
    this.height = 40,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color ?? Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
