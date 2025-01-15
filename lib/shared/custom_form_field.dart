import 'package:flutter/material.dart';

class CustomFormField extends StatelessWidget {
  final String hintPlaceHolder;
  final double height;
  final RegExp validationRegExp;
  final bool obscureText;

  final void Function(String?) onSaved;

  const CustomFormField(
      {super.key,
      required this.hintPlaceHolder,
      required this.height,
      required this.onSaved,
      required this.validationRegExp,
      this.obscureText = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: TextFormField(
        obscureText: obscureText,
        onSaved: onSaved,
        validator: (value) {
          if (value != null && validationRegExp.hasMatch(value)) {
            return null;
          }
          return "Enter a valid ${hintPlaceHolder.toLowerCase()}";
        },
        decoration: InputDecoration(
          hintText: hintPlaceHolder,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
