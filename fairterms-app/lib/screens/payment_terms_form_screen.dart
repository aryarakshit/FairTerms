/// Payment terms form — input payment terms (paste or upload PDF).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/analysis_request.dart';
import '../providers/analysis_provider.dart';
import '../providers/profile_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../widgets/loading_overlay.dart';

class PaymentTermsFormScreen extends ConsumerStatefulWidget {
  final String? mode;

  const PaymentTermsFormScreen({super.key, this.mode});

  @override
  ConsumerState<PaymentTermsFormScreen> createState() =>
      _PaymentTermsFormScreenState();
}

class _PaymentTermsFormScreenState
    extends ConsumerState<PaymentTermsFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _buyerNameCtrl = TextEditingController();
  final _buyerAddressCtrl = TextEditingController();
  final _paymentTermsDaysCtrl = TextEditingController();
  final _orderValueCtrl = TextEditingController();
  final _paymentTermsOfferedCtrl = TextEditingController();
  final _smePaymentToSuppliersCtrl = TextEditingController();
  final _interestRateCtrl = TextEditingController();
  final _additionalContextCtrl = TextEditingController();

  String? _selectedBuyerType;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (ref.read(activeProfileIdProvider).valueOrNull == null) {
        try {
          final profile = await ApiService.instance.getMyProfile();
          if (profile?.profileId != null && mounted) {
            ref.read(activeProfileIdProvider.notifier).setId(profile!.profileId!);
          }
        } catch (_) {}
      }
    });
  }

  @override
  void dispose() {
    _buyerNameCtrl.dispose();
    _buyerAddressCtrl.dispose();
    _paymentTermsDaysCtrl.dispose();
    _orderValueCtrl.dispose();
    _paymentTermsOfferedCtrl.dispose();
    _smePaymentToSuppliersCtrl.dispose();
    _interestRateCtrl.dispose();
    _additionalContextCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    // Resolve profile ID — provider may still be loading from SharedPreferences.
    // Fall back to a live API fetch so a page-refresh or cold-start doesn't block submit.
    String? profileId = ref.read(activeProfileIdProvider).valueOrNull;
    if (profileId == null) {
      try {
        final profile = await ApiService.instance.getMyProfile();
        profileId = profile?.profileId;
        if (profileId != null && mounted) {
          ref.read(activeProfileIdProvider.notifier).setId(profileId);
        }
      } catch (_) {}
    }

    if (profileId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No profile found. Please create your profile first.'),
          ),
        );
        setState(() => _isSubmitting = false);
      }
      return;
    }

    final request = AnalysisRequest(
      profileId: profileId,
      buyerName: _buyerNameCtrl.text.trim(),
      buyerType: _selectedBuyerType!,
      buyerAddress: _buyerAddressCtrl.text.trim(),
      paymentTermsDays: int.parse(_paymentTermsDaysCtrl.text.trim()),
      orderValueInr:
          int.parse(_orderValueCtrl.text.trim().replaceAll(',', '')),
      paymentTermsOfferedToSme: _paymentTermsOfferedCtrl.text.trim(),
      smePaymentToSuppliersDays:
          int.parse(_smePaymentToSuppliersCtrl.text.trim()),
      interestRateOnShortTermLoan:
          double.parse(_interestRateCtrl.text.trim()),
      additionalContext: _additionalContextCtrl.text.trim().isEmpty
          ? null
          : _additionalContextCtrl.text.trim(),
    );

    try {
      await ref.read(analysisProvider.notifier).startAnalysis(request);
      if (!mounted) return;

      final analysisState = ref.read(analysisProvider);
      if (analysisState.analysisId != null) {
        context.pushReplacement('/analysis/${analysisState.analysisId}/loading');
      } else {
        // startAnalysis swallows errors into state.errorMessage instead of
        // rethrowing — surface it so the click isn't silently lost.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              analysisState.errorMessage ??
                  'Failed to start analysis. Please try again.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start analysis: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    return LoadingOverlay(
      isLoading: _isSubmitting,
      message: 'Submitting payment terms',
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            // ── Top bar ─────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border(
                  bottom: BorderSide(color: AppColors.outline, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'FairTerms',
                        style: GoogleFonts.fraunces(
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: AppColors.ink,
                          letterSpacing: -0.02,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => context.go(AppConstants.routeDashboard),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back, size: 14, color: AppColors.inkFaint),
                          SizedBox(width: 6),
                          Text(
                            'Back to dashboard',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.inkFaint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Main content ─────────────────────────────────────────────────
            Expanded(
              child: isDesktop
                  ? _DesktopLayout(
                      formKey: _formKey,
                      buyerNameCtrl: _buyerNameCtrl,
                      buyerAddressCtrl: _buyerAddressCtrl,
                      paymentTermsDaysCtrl: _paymentTermsDaysCtrl,
                      orderValueCtrl: _orderValueCtrl,
                      paymentTermsOfferedCtrl: _paymentTermsOfferedCtrl,
                      smePaymentToSuppliersCtrl: _smePaymentToSuppliersCtrl,
                      interestRateCtrl: _interestRateCtrl,
                      additionalContextCtrl: _additionalContextCtrl,
                      selectedBuyerType: _selectedBuyerType,
                      onBuyerTypeChanged: (v) =>
                          setState(() => _selectedBuyerType = v),
                      onSubmit: _submit,
                    )
                  : _MobileLayout(
                      formKey: _formKey,
                      buyerNameCtrl: _buyerNameCtrl,
                      buyerAddressCtrl: _buyerAddressCtrl,
                      paymentTermsDaysCtrl: _paymentTermsDaysCtrl,
                      orderValueCtrl: _orderValueCtrl,
                      paymentTermsOfferedCtrl: _paymentTermsOfferedCtrl,
                      smePaymentToSuppliersCtrl: _smePaymentToSuppliersCtrl,
                      interestRateCtrl: _interestRateCtrl,
                      additionalContextCtrl: _additionalContextCtrl,
                      selectedBuyerType: _selectedBuyerType,
                      onBuyerTypeChanged: (v) =>
                          setState(() => _selectedBuyerType = v),
                      onSubmit: _submit,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Desktop 2-column layout ────────────────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController buyerNameCtrl;
  final TextEditingController buyerAddressCtrl;
  final TextEditingController paymentTermsDaysCtrl;
  final TextEditingController orderValueCtrl;
  final TextEditingController paymentTermsOfferedCtrl;
  final TextEditingController smePaymentToSuppliersCtrl;
  final TextEditingController interestRateCtrl;
  final TextEditingController additionalContextCtrl;
  final String? selectedBuyerType;
  final ValueChanged<String?> onBuyerTypeChanged;
  final VoidCallback onSubmit;

  const _DesktopLayout({
    required this.formKey,
    required this.buyerNameCtrl,
    required this.buyerAddressCtrl,
    required this.paymentTermsDaysCtrl,
    required this.orderValueCtrl,
    required this.paymentTermsOfferedCtrl,
    required this.smePaymentToSuppliersCtrl,
    required this.interestRateCtrl,
    required this.additionalContextCtrl,
    required this.selectedBuyerType,
    required this.onBuyerTypeChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Left sidebar ──────────────────────────────────────────────────
        Container(
          width: 320,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              right: BorderSide(color: AppColors.outline, width: 1),
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analyse a contract',
                  style: GoogleFonts.fraunces(
                    fontSize: 30,
                    fontWeight: FontWeight.w300,
                    color: AppColors.ink,
                    letterSpacing: -0.02,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Fill in the payment terms from your buyer\'s contract. We\'ll score fairness, benchmark against sector peers, and flag MSMED compliance risk.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.inkFaint,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 36),

                // Upload PDF box
                _UploadPdfPanel(),

                const SizedBox(height: 36),

                // Info chips
                _InfoChip(
                  icon: Icons.flash_on_outlined,
                  label: 'Results in ~30 seconds',
                ),
                const SizedBox(height: 10),
                _InfoChip(
                  icon: Icons.lock_outline,
                  label: 'Your data is encrypted',
                ),
                const SizedBox(height: 10),
                _InfoChip(
                  icon: Icons.gavel_outlined,
                  label: 'MSMED Act 2006 compliance check',
                ),
              ],
            ),
          ),
        ),

        // ── Right form area ───────────────────────────────────────────────
        Expanded(
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel('Buyer Information'),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Buyer / Company Name *',
                      hint: 'e.g., Reliance Industries Ltd.',
                      controller: buyerNameCtrl,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Buyer name is required';
                        if (v.trim().length < 3) return 'Enter at least 3 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedBuyerType,
                      dropdownColor: AppColors.surface,
                      decoration: const InputDecoration(
                        labelText: 'Buyer Type *',
                      ),
                      hint: Text(
                        'Select buyer type',
                        style: GoogleFonts.inter(color: AppColors.inkFaint),
                      ),
                      style: GoogleFonts.inter(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w500,
                      ),
                      items: AppConstants.buyerTypes
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(t),
                              ))
                          .toList(),
                      onChanged: onBuyerTypeChanged,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Buyer type is required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Buyer Address *',
                      hint: 'Full registered address of the buyer',
                      controller: buyerAddressCtrl,
                      maxLines: 2,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Buyer address is required'
                          : null,
                    ),
                    const SizedBox(height: 32),

                    _SectionLabel('Payment Terms'),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'Payment Terms Days *',
                            hint: 'e.g., 90',
                            controller: paymentTermsDaysCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            suffixText: 'days',
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              final n = int.tryParse(v);
                              if (n == null || n <= 0) return 'Enter valid days';
                              if (n > 365) return 'Max 365 days';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            label: 'Order Value (₹) *',
                            hint: 'e.g., 500000',
                            controller: orderValueCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            prefixText: '₹ ',
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              final n = int.tryParse(v.replaceAll(',', ''));
                              if (n == null || n <= 0) return 'Enter valid amount';
                              if (n > 1000000000) return 'Max ₹100 crore';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Payment Terms Offered to SME *',
                      hint:
                          'e.g., Net 90 days from invoice date, with 2% deduction for early payment',
                      controller: paymentTermsOfferedCtrl,
                      maxLines: 3,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Payment terms description is required'
                          : null,
                    ),
                    const SizedBox(height: 32),

                    _SectionLabel('Your Financial Context'),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'Your Payment to Suppliers (days) *',
                            hint: 'e.g., 30',
                            controller: smePaymentToSuppliersCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            suffixText: 'days',
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              final n = int.tryParse(v);
                              if (n == null || n < 0) return 'Enter valid days';
                              if (n > 365) return 'Max 365 days';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            label: 'Short-term Loan Interest Rate *',
                            hint: 'e.g., 12.5',
                            controller: interestRateCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            suffixText: '% p.a.',
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              final n = double.tryParse(v);
                              if (n == null || n < 0 || n > 100) {
                                return 'Enter a valid interest rate';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    _SectionLabel('Additional Context'),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Additional Notes (Optional)',
                      hint: 'Any other information relevant to the analysis...',
                      controller: additionalContextCtrl,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.ink,
                          foregroundColor: AppColors.background,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Analyse payment terms →',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Mobile single-column layout ────────────────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController buyerNameCtrl;
  final TextEditingController buyerAddressCtrl;
  final TextEditingController paymentTermsDaysCtrl;
  final TextEditingController orderValueCtrl;
  final TextEditingController paymentTermsOfferedCtrl;
  final TextEditingController smePaymentToSuppliersCtrl;
  final TextEditingController interestRateCtrl;
  final TextEditingController additionalContextCtrl;
  final String? selectedBuyerType;
  final ValueChanged<String?> onBuyerTypeChanged;
  final VoidCallback onSubmit;

  const _MobileLayout({
    required this.formKey,
    required this.buyerNameCtrl,
    required this.buyerAddressCtrl,
    required this.paymentTermsDaysCtrl,
    required this.orderValueCtrl,
    required this.paymentTermsOfferedCtrl,
    required this.smePaymentToSuppliersCtrl,
    required this.interestRateCtrl,
    required this.additionalContextCtrl,
    required this.selectedBuyerType,
    required this.onBuyerTypeChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardSection(
              title: 'Buyer Information',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    label: 'Buyer / Company Name *',
                    hint: 'e.g., Reliance Industries Ltd.',
                    controller: buyerNameCtrl,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Buyer name is required';
                      if (v.trim().length < 3) return 'Enter at least 3 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedBuyerType,
                    dropdownColor: AppColors.surface,
                    decoration: const InputDecoration(
                      labelText: 'Buyer Type *',
                    ),
                    hint: Text(
                      'Select buyer type',
                      style: GoogleFonts.inter(color: AppColors.inkFaint),
                    ),
                    style: GoogleFonts.inter(
                        color: AppColors.ink, fontWeight: FontWeight.w500),
                    items: AppConstants.buyerTypes
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t),
                            ))
                        .toList(),
                    onChanged: onBuyerTypeChanged,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Buyer type is required' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Buyer Address *',
                    hint: 'Full registered address of the buyer',
                    controller: buyerAddressCtrl,
                    maxLines: 2,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Buyer address is required'
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _CardSection(
              title: 'Payment Terms',
              child: Column(
                children: [
                  _buildTextField(
                    label: 'Payment Terms Days *',
                    hint: 'e.g., 90',
                    controller: paymentTermsDaysCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    suffixText: 'days',
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final n = int.tryParse(v);
                      if (n == null || n <= 0) return 'Enter valid days';
                      if (n > 365) return 'Max 365 days';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Order Value (₹) *',
                    hint: 'e.g., 500000',
                    controller: orderValueCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    prefixText: '₹ ',
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final n = int.tryParse(v.replaceAll(',', ''));
                      if (n == null || n <= 0) return 'Enter valid amount';
                      if (n > 1000000000) return 'Max ₹100 crore';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Payment Terms Offered to SME *',
                    hint: 'e.g., Net 90 days from invoice date',
                    controller: paymentTermsOfferedCtrl,
                    maxLines: 3,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Payment terms description is required'
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _CardSection(
              title: 'Your Financial Context',
              child: Column(
                children: [
                  _buildTextField(
                    label: 'Your Payment to Suppliers (days) *',
                    hint: 'e.g., 30',
                    controller: smePaymentToSuppliersCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    suffixText: 'days',
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final n = int.tryParse(v);
                      if (n == null || n < 0) return 'Enter valid days';
                      if (n > 365) return 'Max 365 days';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Short-term Loan Interest Rate *',
                    hint: 'e.g., 12.5',
                    controller: interestRateCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    suffixText: '% p.a.',
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final n = double.tryParse(v);
                      if (n == null || n < 0 || n > 100) {
                        return 'Enter a valid interest rate';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _CardSection(
              title: 'Additional Context',
              child: _buildTextField(
                label: 'Additional Notes (Optional)',
                hint: 'Any other information relevant to the analysis...',
                controller: additionalContextCtrl,
                maxLines: 4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Analyse payment terms'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────────

Widget _buildTextField({
  required String label,
  required String hint,
  required TextEditingController controller,
  TextInputType? keyboardType,
  List<TextInputFormatter>? inputFormatters,
  String? Function(String?)? validator,
  int maxLines = 1,
  String? prefixText,
  String? suffixText,
}) {
  return TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    inputFormatters: inputFormatters,
    validator: validator,
    maxLines: maxLines,
    style: GoogleFonts.inter(
      color: AppColors.ink,
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefixText,
      suffixText: suffixText,
      prefixStyle: GoogleFonts.inter(
        color: AppColors.inkMuted,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      suffixStyle: GoogleFonts.inter(
        color: AppColors.inkMuted,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),
  );
}

// Upload PDF panel in sidebar
class _UploadPdfPanel extends StatefulWidget {
  const _UploadPdfPanel();

  @override
  State<_UploadPdfPanel> createState() => _UploadPdfPanelState();
}

class _UploadPdfPanelState extends State<_UploadPdfPanel> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (mounted) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (mounted) setState(() => _isHovered = false);
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF upload coming soon')),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _isHovered
                ? AppColors.primary.withValues(alpha: 0.06)
                : AppColors.background,
            border: Border.all(
              color: _isHovered ? AppColors.primary : AppColors.outline,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.upload_file_outlined,
                    color: _isHovered ? AppColors.primary : AppColors.inkMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Start your analysis',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _isHovered ? AppColors.primary : AppColors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Upload your buyer\'s contract PDF and we\'ll extract payment terms automatically.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.inkFaint,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.outline.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Coming soon',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.inkMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Section label for desktop form
class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: GoogleFonts.fraunces(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: AppColors.ink,
            letterSpacing: -0.01,
          ),
        ),
        const SizedBox(height: 4),
        Container(height: 1, width: 32, color: AppColors.primary),
      ],
    );
  }
}

// Info chip for sidebar
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.inkFaint,
          ),
        ),
      ],
    );
  }
}

// Card section for mobile layout
class _CardSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _CardSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.outline, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.inkFaint,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
