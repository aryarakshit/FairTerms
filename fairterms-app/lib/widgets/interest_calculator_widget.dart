/// Interest calculator — cream brutalist live-ticking counter for MSMED Section 16.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/bias_report.dart';
import '../utils/theme.dart';

class InterestCalculatorWidget extends StatefulWidget {
  final InterestCalculation calculation;

  const InterestCalculatorWidget({super.key, required this.calculation});

  @override
  State<InterestCalculatorWidget> createState() =>
      _InterestCalculatorWidgetState();
}

class _InterestCalculatorWidgetState extends State<InterestCalculatorWidget> {
  late Timer _timer;
  late double _liveTotal;
  late double _perSecondAccrual;

  @override
  void initState() {
    super.initState();
    _liveTotal = widget.calculation.totalOwedInr.toDouble();
    _perSecondAccrual = widget.calculation.dailyAccrualInr / 86400.0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _liveTotal += _perSecondAccrual);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _copyAmount() {
    final amount = _liveTotal.round().toString();
    Clipboard.setData(ClipboardData(text: amount));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied ₹$amount to clipboard',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final calc = widget.calculation;
    final fmt =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.mint,
        border: Border.all(color: AppColors.outline, width: 2),
        boxShadow: brutalShadow(),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.outline, width: 2),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: AppColors.ink,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'LEGAL INTEREST OWED',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  border: Border.all(color: AppColors.outline, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.ink,
                        shape: BoxShape.circle,
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(
                        duration: 600.ms),
                    const SizedBox(width: 6),
                    Text(
                      'LIVE',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.2),
                  end: Offset.zero,
                ).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: Text(
              fmt.format(_liveTotal.round()),
              key: ValueKey(_liveTotal.round()),
              style: GoogleFonts.inter(
                fontSize: 44,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                height: 1.0,
                letterSpacing: -2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total owed (principal + compound interest, ticking every second)',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.outline, width: 2),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _Row(
                  label: 'Principal',
                  value: fmt.format(calc.principalInr),
                ),
                const SizedBox(height: 10),
                _Row(
                  label: 'Delay beyond 45 days',
                  value: '${calc.delayDays} days',
                ),
                const SizedBox(height: 10),
                _Row(
                  label: 'RBI bank rate',
                  value: '${calc.rbiBankRate.toStringAsFixed(2)}%',
                ),
                const SizedBox(height: 10),
                _Row(
                  label: 'Applicable rate (3× RBI)',
                  value: '${calc.applicableRate.toStringAsFixed(2)}% p.a.',
                  highlight: true,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(
                      color: AppColors.outline, thickness: 1, height: 1),
                ),
                _Row(
                  label: 'Compound interest',
                  value: fmt.format(calc.compoundInterestInr),
                ),
                const SizedBox(height: 10),
                _Row(
                  label: 'Daily accrual',
                  value: '${fmt.format(calc.dailyAccrualInr)} / day',
                  highlight: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            calc.legalBasis,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppColors.inkMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _copyAmount,
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('COPY FOR GRIEVANCE LETTER'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _Row({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.inkMuted,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: highlight ? FontWeight.w800 : FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}
