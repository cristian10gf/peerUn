import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/theme/teacher_colors.dart';

class TeacherTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffixIcon;
  final TextInputType keyboardType;

  const TeacherTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure      = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller:   controller,
      obscureText:  obscure,
      keyboardType: keyboardType,
      style: GoogleFonts.sora(fontSize: 13, color: tkText),
      cursorColor: tkGold,
      decoration: InputDecoration(
        hintText:   hint,
        hintStyle:  GoogleFonts.sora(fontSize: 13, color: tkTextFaint),
        prefixIcon: Icon(icon, size: 18, color: tkTextFaint),
        suffixIcon: suffixIcon,
        filled:     true,
        fillColor:  tkSurfaceAlt,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:   const BorderSide(color: tkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:   const BorderSide(color: tkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:   const BorderSide(color: tkGold, width: 1.5),
        ),
      ),
    );
  }
}

class TeacherPrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;

  const TeacherPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width:   double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color:        loading ? tkGold.withValues(alpha: 0.6) : tkGold,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: loading
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                    color: Color(0xFF0E1117), strokeWidth: 2),
              )
            : Text(
                label,
                style: GoogleFonts.sora(
                  fontSize:   14,
                  fontWeight: FontWeight.w700,
                  color:      const Color(0xFF0E1117),
                ),
              ),
      ),
    );
  }
}
