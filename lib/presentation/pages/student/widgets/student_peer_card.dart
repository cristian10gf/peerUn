import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:example/domain/models/peer_evaluation.dart';
import 'package:example/presentation/theme/app_colors.dart';

class StudentPeerCard extends StatelessWidget {
  final Peer peer;
  final VoidCallback onTap;

  const StudentPeerCard({super.key, required this.peer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: peer.evaluated ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: peer.evaluated ? skPrimaryLight : skSurface,
          border: Border.all(color: peer.evaluated ? skPrimaryMid : skBorder),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: peer.evaluated ? skPrimary : skSurfaceAlt,
                border: Border.all(
                  color: peer.evaluated ? skPrimary : skBorder,
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: peer.evaluated
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    )
                  : Text(
                      peer.initials,
                      style: GoogleFonts.dmMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: skTextMid,
                      ),
                    ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    peer.name,
                    style: GoogleFonts.sora(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: skText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    peer.evaluated ? 'Evaluado' : 'Pendiente',
                    style: GoogleFonts.sora(
                      fontSize: 11,
                      fontWeight: peer.evaluated
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: peer.evaluated ? skPrimary : skTextFaint,
                    ),
                  ),
                ],
              ),
            ),
            if (!peer.evaluated)
              const Icon(
                Icons.chevron_right_rounded,
                size: 14,
                color: skTextFaint,
              ),
          ],
        ),
      ),
    );
  }
}
