import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dekorin_apps/config/theme/app_theme.dart';

/// A reusable text field widget with Dekorin styling.
///
/// Supports label, hint, prefix icon, suffix icon, obscure text
/// (with toggle visibility), and validation.
class DekorinTextField extends StatelessWidget {
  const DekorinTextField({
    super.key,
    required this.controller,
    this.label = '',
    this.hint,
    this.helperText,
    this.prefixIcon,
    this.prefixWidget,
    this.suffixIcon,
    this.prefixText,
    this.prefixStyle,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
    this.onChanged,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? helperText;
  final IconData? prefixIcon;
  final Widget? prefixWidget;
  final Widget? suffixIcon;
  final String? prefixText;
  final TextStyle? prefixStyle;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final void Function(String)? onChanged;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      onChanged: onChanged,
      maxLines: maxLines,
      style: AppTypography.bodyLarge,
      decoration: InputDecoration(
        labelText: label.isNotEmpty ? label : null,
        hintText: hint,
        helperText: helperText,
        prefixIcon: prefixWidget ?? (prefixIcon != null ? Icon(prefixIcon) : null),
        prefixText: prefixText,
        prefixStyle: prefixStyle,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
