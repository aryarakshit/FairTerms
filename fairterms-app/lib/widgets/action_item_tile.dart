/// Action item tile — cream brutalist checklist row.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/theme.dart';

class ActionItemTile extends StatefulWidget {
  final int index;
  final String text;

  const ActionItemTile({
    super.key,
    required this.index,
    required this.text,
  });

  @override
  State<ActionItemTile> createState() => _ActionItemTileState();
}

class _ActionItemTileState extends State<ActionItemTile> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _checked = !_checked),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _checked ? AppColors.mint : AppColors.surface,
              border: Border.all(color: AppColors.outline, width: 2),
              boxShadow: brutalShadowSmall(),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _checked ? AppColors.ink : AppColors.primary,
                    border: Border.all(color: AppColors.outline, width: 2),
                  ),
                  child: _checked
                      ? const Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ).animate().scale(
                            duration: 200.ms, curve: Curves.easeOutBack)
                      : Center(
                          child: Text(
                            '${widget.index}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                      color: _checked
                          ? AppColors.inkMuted
                          : AppColors.ink,
                      decoration:
                          _checked ? TextDecoration.lineThrough : null,
                      decorationColor: AppColors.ink,
                      decorationThickness: 2,
                    ),
                    child: Text(widget.text),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
