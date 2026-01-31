import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

enum TopicCardType { study, question }

class TopicCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final TopicCardType type;
  final List<String> stats;
  final VoidCallback? onTap;
  final Color? customColor;
  final IconData? customIcon;

  const TopicCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.stats,
    this.onTap,
    this.customColor,
    this.customIcon,
  });

  @override
  Widget build(BuildContext context) {
    // Theme configurations based on type
    final Color themeColor = customColor ??
        (type == TopicCardType.study
            ? const Color(0xFF10B981) // Mint Green
            : const Color(0xFF2F80ED)); // Electric Blue

    final IconData iconData = customIcon ??
        (type == TopicCardType.study
            ? Icons.psychology_outlined // Brain-like
            : Icons.track_changes_rounded); // Target-like

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Glassmorphism Icon Box (The Squircle)
                  _buildSquircleIcon(themeColor, iconData),
                  const SizedBox(width: 18),

                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            color: Colors.white38,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Stats Chips Row
                        Wrap(
                          spacing: 8,
                          children: stats
                              .map((s) => _buildStatChip(s, themeColor))
                              .toList(),
                        ),
                      ],
                    ),
                  ),

                  // Optional Arrow for premium feel
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white.withValues(alpha: 0.1),
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSquircleIcon(Color color, IconData icon) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Soft Neon Glow Shadow
        Container(
          width: 50,
          height: 50,
          decoration: ShapeDecoration(
            shape: ContinuousRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            shadows: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
        ),

        // Glassmorphism Container
        ClipPath(
          clipper: ShapeBorderClipper(
            shape: ContinuousRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 56,
              height: 56,
              decoration: ShapeDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: 26,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: color.withValues(alpha: 0.9),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
