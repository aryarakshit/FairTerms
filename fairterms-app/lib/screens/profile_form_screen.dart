/// Profile form — cream brutalist 3-step SME profile wizard.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/profile_provider.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../widgets/loading_overlay.dart';

class ProfileFormScreen extends ConsumerStatefulWidget {
  const ProfileFormScreen({super.key});

  @override
  ConsumerState<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends ConsumerState<ProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _businessNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _yearsCtrl = TextEditingController();

  final _pincodeCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  final _revenueCtrl = TextEditingController();
  final _employeeCtrl = TextEditingController();

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _gstCtrl.dispose();
    _phoneCtrl.dispose();
    _yearsCtrl.dispose();
    _pincodeCtrl.dispose();
    _cityCtrl.dispose();
    _revenueCtrl.dispose();
    _employeeCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleNext() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final notifier = ref.read(profileFormProvider.notifier);
    final state = ref.read(profileFormProvider);

    if (state.currentStep < 2) {
      notifier.nextStep();
    } else {
      final profileId = await notifier.submitProfile();
      if (!mounted) return;

      final updatedState = ref.read(profileFormProvider);
      if (updatedState.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(updatedState.errorMessage!)),
        );
      } else if (profileId != null) {
        ref.read(activeProfileIdProvider.notifier).setId(profileId!);
        context.push(AppConstants.routePaymentTerms);
      }
    }
  }

  void _syncControllersToState() {
    final notifier = ref.read(profileFormProvider.notifier);

    notifier.updateField('businessName', _businessNameCtrl.text);
    notifier.updateField('ownerName', _ownerNameCtrl.text);
    notifier.updateField('gstNumber', _gstCtrl.text);
    notifier.updateField('phoneNumber', _phoneCtrl.text);
    notifier.updateField('yearsInOperation', _yearsCtrl.text);
    notifier.updateField('pincode', _pincodeCtrl.text);
    notifier.updateField('city', _cityCtrl.text);
    notifier.updateField('annualRevenueInr', _revenueCtrl.text);
    notifier.updateField('employeeCount', _employeeCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileFormProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    final formContent = Column(
      children: [
        _StepIndicator(
          currentStep: state.currentStep,
          totalSteps: 3,
        ),
        Expanded(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.05, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey<int>(state.currentStep),
                  child: _buildStep(state.currentStep, state),
                ),
              ),
            ),
          ),
        ),
        _BottomNav(
          currentStep: state.currentStep,
          totalSteps: 3,
          onBack: () {
            _syncControllersToState();
            ref.read(profileFormProvider.notifier).previousStep();
          },
          onNext: () {
            _syncControllersToState();
            _handleNext();
          },
        ),
      ],
    );

    return LoadingOverlay(
      isLoading: state.isSubmitting,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                              'Set up SME Profile',
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
                              'Tell us about your business. We use this data to calculate accurate benchmarking comparisons against peers in your regional sector.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.inkFaint,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 36),
                            const _InfoChip(
                              icon: Icons.timer_outlined,
                              label: 'Takes less than 2 minutes',
                            ),
                            const SizedBox(height: 10),
                            const _InfoChip(
                              icon: Icons.lock_outline,
                              label: 'Your data is encrypted',
                            ),
                            const SizedBox(height: 10),
                            const _InfoChip(
                              icon: Icons.bar_chart_outlined,
                              label: 'Used strictly for peer analysis',
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Spacer(),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 680),
                            child: formContent,
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: formContent,
                    ),
                    const Spacer(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildStep(int step, ProfileFormState state) {
    switch (step) {
      case 0:
        return _Step1(
          businessNameCtrl: _businessNameCtrl,
          ownerNameCtrl: _ownerNameCtrl,
          gstCtrl: _gstCtrl,
          phoneCtrl: _phoneCtrl,
          yearsCtrl: _yearsCtrl,
        );
      case 1:
        return _Step2(
          pincodeCtrl: _pincodeCtrl,
          cityCtrl: _cityCtrl,
          selectedState: state.state,
          onStateChanged: (value) => ref
              .read(profileFormProvider.notifier)
              .updateField('state', value ?? ''),
        );
      case 2:
        return _Step3(
          revenueCtrl: _revenueCtrl,
          employeeCtrl: _employeeCtrl,
          selectedIndustry: state.industry,
          onIndustryChanged: (value) => ref
              .read(profileFormProvider.notifier)
              .updateField('industry', value ?? ''),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _Step1 extends StatelessWidget {
  final TextEditingController businessNameCtrl;
  final TextEditingController ownerNameCtrl;
  final TextEditingController gstCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController yearsCtrl;

  const _Step1({
    required this.businessNameCtrl,
    required this.ownerNameCtrl,
    required this.gstCtrl,
    required this.phoneCtrl,
    required this.yearsCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return _BrutalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Business Information',
            subtitle: 'Tell us about your business',
          ),
          const SizedBox(height: 24),
          _FormField(
            label: 'Business Name *',
            hint: 'e.g., Sharma Textiles Pvt. Ltd.',
            controller: businessNameCtrl,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Business name is required'
                : null,
          ),
          const SizedBox(height: 16),
          _FormField(
            label: 'Owner / Director Name *',
            hint: 'e.g., Rajesh Sharma',
            controller: ownerNameCtrl,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Owner name is required'
                : null,
          ),
          const SizedBox(height: 16),
          _FormField(
            label: 'Phone Number',
            hint: '+91 00000 00000',
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _FormField(
            label: 'GST Number',
            hint: 'e.g., 22AAAAA0000A1Z5',
            controller: gstCtrl,
            textCapitalization: TextCapitalization.characters,
            maxLength: 15,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              final pattern = RegExp(
                  r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
              if (!pattern.hasMatch(v.trim())) {
                return 'Enter a valid 15-character GST number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _FormField(
            label: 'Years in Operation *',
            hint: 'e.g., 5',
            controller: yearsCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              final n = int.tryParse(v);
              if (n == null || n < 0 || n > 200) {
                return 'Enter a valid number of years';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}

class _Step2 extends StatelessWidget {
  final TextEditingController pincodeCtrl;
  final TextEditingController cityCtrl;
  final String? selectedState;
  final ValueChanged<String?> onStateChanged;

  const _Step2({
    required this.pincodeCtrl,
    required this.cityCtrl,
    required this.selectedState,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _BrutalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Location Details',
            subtitle: 'Your registered business location',
          ),
          const SizedBox(height: 24),
          _FormField(
            label: 'Pincode *',
            hint: 'e.g., 400001',
            controller: pincodeCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 6,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Pincode is required';
              if (v.length != 6) return 'Enter a valid 6-digit pincode';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _FormField(
            label: 'City *',
            hint: 'e.g., Mumbai',
            controller: cityCtrl,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'City is required' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: selectedState,
            dropdownColor: AppColors.surface,
            decoration: const InputDecoration(labelText: 'State / UT *'),
            hint: Text('Select state',
                style: GoogleFonts.inter(color: AppColors.inkFaint)),
            style: GoogleFonts.inter(
                color: AppColors.ink, fontWeight: FontWeight.w600),
            items: AppConstants.indianStates
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: onStateChanged,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Please select your state' : null,
          ),
        ],
      ),
    );
  }
}

class _Step3 extends StatelessWidget {
  final TextEditingController revenueCtrl;
  final TextEditingController employeeCtrl;
  final String? selectedIndustry;
  final ValueChanged<String?> onIndustryChanged;

  const _Step3({
    required this.revenueCtrl,
    required this.employeeCtrl,
    required this.selectedIndustry,
    required this.onIndustryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _BrutalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Financial Details',
            subtitle: 'Helps us compare with similar businesses',
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            initialValue: selectedIndustry,
            dropdownColor: AppColors.surface,
            decoration:
                const InputDecoration(labelText: 'Industry Sector *'),
            hint: Text('Select industry',
                style: GoogleFonts.inter(color: AppColors.inkFaint)),
            style: GoogleFonts.inter(
                color: AppColors.ink, fontWeight: FontWeight.w600),
            items: AppConstants.industries
                .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                .toList(),
            onChanged: onIndustryChanged,
            validator: (v) => (v == null || v.isEmpty)
                ? 'Please select your industry'
                : null,
          ),
          const SizedBox(height: 16),
          _FormField(
            label: 'Annual Revenue (₹) *',
            hint: 'e.g., 5000000',
            controller: revenueCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            prefixText: '₹ ',
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Annual revenue is required';
              }
              final n = int.tryParse(v);
              if (n == null || n <= 0) return 'Enter a valid amount';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _FormField(
            label: 'Number of Employees *',
            hint: 'e.g., 25',
            controller: employeeCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Employee count is required';
              }
              final n = int.tryParse(v);
              if (n == null || n <= 0) return 'Enter a valid count';
              return null;
            },
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outline, width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined,
                    size: 22, color: AppColors.ink),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Revenue figures are used purely for localized AI peer comparison and are heavily anonymized.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
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

class _BrutalCard extends StatelessWidget {
  final Widget child;

  const _BrutalCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline, width: 1),
      ),
      padding: const EdgeInsets.all(24),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.fraunces(
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: AppColors.ink,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.inkMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;
  final int? maxLength;
  final String? prefixText;

  const _FormField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
    this.maxLength,
    this.prefixText,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      textCapitalization: textCapitalization,
      maxLength: maxLength,
      style: GoogleFonts.inter(
        color: AppColors.ink,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        prefixStyle: GoogleFonts.inter(
          color: AppColors.inkMuted,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        counterText: '',
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepIndicator({
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.outline, width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(totalSteps, (index) {
              final isActive = index <= currentStep;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                              color: AppColors.outline, width: 1),
                        ),
                      ),
                    ),
                    if (index < totalSteps - 1) const SizedBox(width: 6),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${currentStep + 1} of $totalSteps',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.inkMuted,
                  letterSpacing: 0.2,
                ),
              ),
              Text(
                _stepName(currentStep),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.inkFaint,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _stepName(int step) {
    switch (step) {
      case 0:
        return 'Business Info';
      case 1:
        return 'Location';
      case 2:
        return 'Financials';
      default:
        return '';
    }
  }
}

class _BottomNav extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _BottomNav({
    required this.currentStep,
    required this.totalSteps,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.outline, width: 1),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  child: const Text('Back'),
                ),
              ),
            if (currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: onNext,
                child: Text(currentStep < totalSteps - 1
                    ? 'Next'
                    : 'Create profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
