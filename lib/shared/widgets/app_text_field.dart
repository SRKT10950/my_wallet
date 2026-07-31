import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Styled text field matching the My Wallet dark design system.
class AppTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputAction textInputAction;
  final FocusNode? focusNode;
  final void Function(String)? onFieldSubmitted;
  final bool autofocus;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.validator,
    this.onChanged,
    this.textInputAction = TextInputAction.next,
    this.focusNode,
    this.onFieldSubmitted,
    this.autofocus = false,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.obscureText ? _obscured : false,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      focusNode: widget.focusNode,
      onFieldSubmitted: widget.onFieldSubmitted,
      autofocus: widget.autofocus,
      validator: widget.validator,
      onChanged: widget.onChanged,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, size: 20, color: AppTheme.textHint)
            : null,
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _obscured
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: AppTheme.textHint,
                ),
                onPressed: () => setState(() => _obscured = !_obscured),
              )
            : null,
      ),
    );
  }
}
