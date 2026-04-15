import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final Color textColor;
  final Color mutedTextColor;
  final Color borderColor;
  final Color fieldColor;
  final Color accentColor;

  const AuthField({super.key, 
    required this.controller,
    required this.hint,
    required this.icon,
    required this.textColor,
    required this.mutedTextColor,
    required this.borderColor,
    required this.fieldColor,
    required this.accentColor,
    this.obscure = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    // On web, <input type="email"> does not support setSelectionRange(), which
    // the Flutter Web semantics engine calls during text editing. Fall back to
    // TextInputType.text (<input type="text">) to avoid that browser error.
    final effectiveKeyboardType =
        kIsWeb && keyboardType == TextInputType.emailAddress
            ? TextInputType.text
            : keyboardType;

    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: effectiveKeyboardType,
      style: GoogleFonts.sora(fontSize: 13, color: textColor),
      cursorColor: accentColor,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.sora(fontSize: 13, color: mutedTextColor),
        prefixIcon: Icon(icon, size: 18, color: mutedTextColor),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: fieldColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
      ),
    );
  }
}
