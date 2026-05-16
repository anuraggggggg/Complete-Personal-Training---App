import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FaqCard extends StatefulWidget {
  final String question;
  final String answer;

  const FaqCard({
    required this.question,
    required this.answer,
  });

  @override
  State<FaqCard> createState() => _faqCardState();
}

class _faqCardState extends State<FaqCard>
    with SingleTickerProviderStateMixin {

  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: expanded
            ? const LinearGradient(
                colors: [
                  Color(0xFF1A1A1A),
                  Color(0xFF111111),
                ],
              )
            : const LinearGradient(
                colors: [
                  Color(0xFF141414),
                  Color(0xFF0F0F0F),
                ],
              ),
        border: Border.all(
          color: expanded
              ? Colors.redAccent
              : Colors.white12,
        ),
        boxShadow: [
          if (expanded)
            const BoxShadow(
              color: Color(0x33FF0000),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
        ],
      ),
      child: Column(
        children: [

          /// 🔥 QUESTION ROW
          GestureDetector(
            onTap: () {
              setState(() {
                expanded = !expanded;
              });
            },
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.question,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 300),
                  turns: expanded ? 0.5 : 0,
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          /// 🔥 ANSWER
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                widget.answer,
                style: GoogleFonts.montserrat(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
