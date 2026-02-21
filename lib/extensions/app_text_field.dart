import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../extensions/extension_util/string_extensions.dart';
import '../../extensions/extension_util/bool_extensions.dart';
import '../../extensions/extension_util/widget_extensions.dart';
import '../../extensions/extension_util/int_extensions.dart';
import '../../extensions/extension_util/double_extensions.dart';
import '../../extensions/text_styles.dart';
import '../main.dart';
import '../utils/app_images.dart';
import 'constants.dart';
import 'decorations.dart';

enum TextFieldType {
  EMAIL,
  PASSWORD,
  NAME,
  @Deprecated('Use MULTILINE instead')
  ADDRESS,
  MULTILINE,
  OTHER,
  PHONE,
  URL,
  NUMBER,
  USERNAME
}

class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final TextFieldType textFieldType;
  final InputDecoration? decoration;
  final FocusNode? focus;
  final FormFieldValidator<String>? validator;
  final bool? isValidationRequired;
  final Function(String)? onFieldSubmitted;
  final FocusNode? nextFocus;
  final TextStyle? textStyle;
  final int? maxLines;
  final int? minLines;
  final bool? enabled;
  final bool? readOnly; // ✅ ADDED BACK
  final VoidCallback? onTap; // ✅ ADDED BACK
  final Function(String)? onChanged;
  final Color? cursorColor;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final Iterable<String>? autoFillHints;

  const AppTextField({
    super.key,
    this.controller,
    required this.textFieldType,
    this.decoration,
    this.focus,
    this.validator,
    this.isValidationRequired,
    this.onFieldSubmitted,
    this.nextFocus,
    this.textStyle,
    this.maxLines,
    this.minLines,
    this.enabled,
    this.readOnly, // ✅
    this.onTap, // ✅
    this.onChanged,
    this.cursorColor,
    this.suffix,
    this.keyboardType,
    this.autoFillHints,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool isPasswordVisible = false;

  void togglePassword() {
    setState(() => isPasswordVisible = !isPasswordVisible);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focus,
      readOnly: widget.readOnly ?? false, // ✅ FIX
      onTap: widget.onTap, // ✅ FIX
      obscureText:
          widget.textFieldType == TextFieldType.PASSWORD && !isPasswordVisible,
      validator: widget.validator,
      keyboardType: widget.keyboardType ??
          (widget.textFieldType == TextFieldType.EMAIL
              ? TextInputType.emailAddress
              : widget.textFieldType == TextFieldType.PHONE
                  ? TextInputType.phone
                  : TextInputType.text),
      textInputAction:
          widget.nextFocus != null ? TextInputAction.next : TextInputAction.done,
      onFieldSubmitted: (val) {
        if (widget.nextFocus != null) {
          FocusScope.of(context).requestFocus(widget.nextFocus);
        }
        widget.onFieldSubmitted?.call(val);
      },
      onChanged: widget.onChanged,
      style: widget.textStyle ??
          TextStyle(
            color: cs.onSurface,
            fontSize: 15,
          ),
      cursorColor: widget.cursorColor ?? cs.primary,
      enabled: widget.enabled ?? true,
      maxLines: widget.textFieldType == TextFieldType.MULTILINE
          ? null
          : widget.maxLines ?? 1,
      minLines: widget.minLines ??
          (widget.textFieldType == TextFieldType.MULTILINE ? 3 : 1),
      autofillHints: widget.autoFillHints,
      keyboardAppearance:
          isDark ? Brightness.dark : Brightness.light,
      decoration: (widget.decoration ?? const InputDecoration()).copyWith(
        filled: true,
        fillColor: cs.surface,
        hintStyle: TextStyle(
          color: cs.onSurface.withOpacity(0.5),
        ),
        labelStyle: TextStyle(
          color: cs.onSurface.withOpacity(0.7),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: cs.onSurface.withOpacity(0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        suffixIcon: widget.textFieldType == TextFieldType.PASSWORD
            ? IconButton(
                onPressed: togglePassword,
                icon: Icon(
                  isPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: cs.onSurface.withOpacity(0.7),
                ),
              )
            : widget.suffix,
      ),
    );
  }
}
