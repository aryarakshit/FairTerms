/// Tax alert card — dark industrial warning tile for Section 43B(h).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/bias_report.dart';
import '../utils/theme.dart';

class TaxAlertCard extends StatelessWidget {
  final TaxAlert taxAlert;

  const TaxAlertCard({super.key, required this.taxAlert});

  void _sendAlert(BuildContext context) {
    Clipboard.setData(ClipboardData(text: taxAlert.alertText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Tax alert text copied — share with buyer',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.outline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Yellow accent header strip
          Container(
            width: double.infinity,
            color: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              'TAX ALERT — ${taxAlert.section}',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.onPrimary,
                letterSpacing: 1.5,
              ),
            ),
          ),

          // Card body
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon + label
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            width: 1),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'YOUR BUYER IS LOSING',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.inkMuted,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Big amount
                Text(
                  fmt.format(taxAlert.taxDeductionLostInr),
                  style: GoogleFonts.inter(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    height: 1.0,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'in tax deductions by delaying your payment',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 20),

                // Detail box
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    border: Border.all(color: AppColors.outline, width: 1),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Row(
                        label: 'Non-deductible invoice',
                        value: fmt.format(taxAlert.nonDeductibleAmountInr),
                      ),
                      const SizedBox(height: 8),
                      _Row(
                        label: 'Estimated buyer tax rate',
                        value:
                            '${taxAlert.estimatedBuyerTaxRate.toStringAsFixed(1)}%',
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(
                            color: AppColors.outline, thickness: 1, height: 1),
                      ),
                      Text(
                        taxAlert.alertText,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.6,
                          color: AppColors.inkMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // CTA
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () => _sendAlert(context),
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text('SEND TAX ALERT TO BUYER'),
                  ),
                ),
              ],
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

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.inkMuted,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}
