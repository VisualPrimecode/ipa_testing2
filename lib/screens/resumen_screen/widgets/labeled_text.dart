import 'package:flutter/material.dart';

class LabeledText extends StatelessWidget {
  final String text;
  const LabeledText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: const TextStyle(fontSize: 16)),
    );
  }
}
