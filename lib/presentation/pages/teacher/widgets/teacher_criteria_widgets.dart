import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

// ── INPUT CARD ─────────────────────────────
Widget header(String title) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    child: Row(
      children: [
        GestureDetector(
          onTap: () => Get.back(),
          child: const CircleAvatar(
            backgroundColor: Colors.black12,
            child: Icon(Icons.arrow_back),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.sora(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

Widget Input({
  required String hint,
  required String value,
  required Function(String) onChanged,
}) {
  final controller = TextEditingController(text: value);

  return TextField(
    controller: controller,
    onChanged: onChanged,
    decoration: InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFEDEDED),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

Widget mainButton(String text) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(
      color: const Color(0xFF7B83EB),
      borderRadius: BorderRadius.circular(25),
    ),
    alignment: Alignment.center,
    child: Text(
      text,
      style: const TextStyle(color: Colors.white),
    ),
  );
}
