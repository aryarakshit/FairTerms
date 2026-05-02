// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
/// Settings — Refined to match the main website's premium typography and style.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sme_profile.dart';
import '../providers/analysis_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../widgets/user_avatar.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _businessNameCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _revenueCtrl = TextEditingController();
  final _employeesCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  String _industry = 'Textiles';
  bool _emailReports = true;
  bool _leaderboardUpdates = true;
  int _selectedTabIndex = 0;
  SmeProfile? _loadedProfile;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = AuthService.instance.currentUserDisplayName;
    _emailCtrl.text = AuthService.instance.currentUserEmail;
    
    // Initial data sync
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadProfileData();
    });
  }

  Future<void> _loadProfileData() async {
    if (!mounted) return;
    
    // Trigger a fresh fetch from the provider
    final profile = await ref.refresh(myProfileProvider.future);
    
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (profile == null) return;
      _loadedProfile = profile;
      if (profile.photoUrl != null) {
        ref.read(profilePhotoProvider.notifier).syncFromServer(profile.photoUrl!);
      }

      final matchedIndustry = AppConstants.industries.firstWhere(
        (i) => i.toLowerCase() == profile.industry.toLowerCase(),
        orElse: () => _industry,
      );
      _businessNameCtrl.text = profile.businessName;
      _gstCtrl.text = profile.gstNumber ?? '';
      _phoneCtrl.text = profile.phoneNumber ?? '';
      _pincodeCtrl.text = profile.pincode;
      _revenueCtrl.text = profile.annualRevenueInr.toString();
      _employeesCtrl.text = profile.employeeCount.toString();
      _industry = matchedIndustry;
    });
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final profileId = ref.read(activeProfileIdProvider).valueOrNull;
      final profile = SmeProfile(
        profileId: profileId,
        businessName: _businessNameCtrl.text.trim(),
        ownerName: _nameCtrl.text.trim(),
        pincode: _pincodeCtrl.text.trim(),
        city: _loadedProfile?.city ?? '',
        state: _loadedProfile?.state ?? '',
        industry: _industry,
        annualRevenueInr:
            int.tryParse(_revenueCtrl.text.trim().replaceAll(',', '')) ?? 0,
        employeeCount: int.tryParse(_employeesCtrl.text.trim()) ?? 0,
        yearsInOperation: _loadedProfile?.yearsInOperation ?? 0,
        gstNumber: _gstCtrl.text.trim().isEmpty ? null : _gstCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      );
      final result = await ApiService.instance.createProfile(profile);
      final newId = result['profile_id'] as String?;
      if (newId != null && mounted) {
        ref.read(activeProfileIdProvider.notifier).setId(newId);
        _loadedProfile = profile.copyWith(profileId: newId);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile saved successfully'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _businessNameCtrl.dispose();
    _gstCtrl.dispose();
    _pincodeCtrl.dispose();
    _revenueCtrl.dispose();
    _employeesCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image != null && mounted) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          maxWidth: 400,
          maxHeight: 400,
          uiSettings: [
            WebUiSettings(
              context: context,
              presentStyle: WebPresentStyle.dialog,
              size: const CropperSize(width: 400, height: 400),
              viewwMode: WebViewMode.mode_1,
              initialAspectRatio: 1,
              dragMode: WebDragMode.move,
              customDialogBuilder: (cropper, initCropper, crop, rotate, scale) {
                return _CustomCropperDialog(
                  cropper: cropper,
                  initCropper: initCropper,
                  crop: crop,
                );
              },
            ),
          ],
        );

        if (croppedFile != null && mounted) {
          final bytes = await croppedFile.readAsBytes();
          await ref.read(profilePhotoProvider.notifier).updatePhoto(bytes);
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 960;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 24 : 40,
              vertical: isMobile ? 32 : 56,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top Bar (Matches Dashboard) ──────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
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
                    GestureDetector(
                      onTap: () => context.go(AppConstants.routeDashboard),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.outline, width: 1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back, size: 14, color: AppColors.inkMuted),
                            SizedBox(width: 8),
                            Text(
                              'Back to dashboard',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.inkMuted,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 56),

                // ── Hero Headline (Matches Dashboard) ────────────────────
                Text(
                  'Settings',
                  style: GoogleFonts.fraunces(
                    fontSize: 52,
                    fontWeight: FontWeight.w300,
                    color: AppColors.ink,
                    letterSpacing: -0.03,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Manage your profile, business details, and preferences.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.inkMuted,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 56),

                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 120),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (_loadedProfile == null)
                  _NoProfileView()
                else
                  _buildMainLayout(isMobile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainLayout(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          _buildSidebarTabs(true),
          const SizedBox(height: 40),
          _buildSelectedTabContent(),
          const SizedBox(height: 48),
          _buildStickyActionFooter(),
          const SizedBox(height: 100),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 220,
          child: _buildSidebarTabs(false),
        ),
        const SizedBox(width: 64),
        Expanded(
          child: Column(
            children: [
              _buildSelectedTabContent(),
              const SizedBox(height: 48),
              _buildStickyActionFooter(),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarTabs(bool horizontal) {
    final tabs = ['Profile', 'Business details', 'Notifications', 'Danger zone'];

    if (horizontal) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(tabs.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _TabPill(
                label: tabs[index],
                isActive: _selectedTabIndex == index,
                onTap: () => setState(() => _selectedTabIndex = index),
              ),
            );
          }),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(tabs.length, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: _TabPill(
            label: tabs[index],
            isActive: _selectedTabIndex == index,
            isDanger: index == 3,
            onTap: () => setState(() => _selectedTabIndex = index),
            isSidebar: true,
          ),
        );
      }),
    );
  }

  Widget _buildSelectedTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildProfileTab();
      case 1:
        return _buildBusinessTab();
      case 2:
        return _buildNotificationsTab();
      case 3:
        return _buildDangerTab();
      default:
        return const SizedBox();
    }
  }

  Widget _buildProfileTab() {
    final photoB64 = ref.watch(profilePhotoProvider);

    return _RefinedSettingsGroup(
      title: 'Profile',
      children: [
        _RefinedSettingsRow(
          label: 'Profile photo',
          desc: 'Updates your visual identity across the platform',
          child: Row(
            children: [
              UserAvatar(size: 64, fontSize: 24),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GhostButton(
                    'Change photo',
                    onTap: _pickImage,
                  ),
                  if (photoB64 != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: TextButton(
                        onPressed: () => ref.read(profilePhotoProvider.notifier).removePhoto(),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 30),
                        ),
                        child: const Text('Remove', style: TextStyle(fontSize: 12, fontFamily: 'Inter')),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        _RefinedSettingsRow(
          label: 'Display name',
          child: _RefinedTextField(controller: _nameCtrl),
        ),
        _RefinedSettingsRow(
          label: 'Email address',
          desc: 'Used for important account alerts',
          child: _RefinedTextField(
            controller: _emailCtrl,
            enabled: false,
          ),
        ),
        _RefinedSettingsRow(
          label: 'Phone number',
          isLast: true,
          child: _RefinedTextField(
            controller: _phoneCtrl,
            hint: '+91 00000 00000',
            keyboardType: TextInputType.phone,
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessTab() {
    return _RefinedSettingsGroup(
      title: 'Business details',
      tag: 'Verified',
      children: [
        _RefinedSettingsRow(
          label: 'Business name',
          child: _RefinedTextField(controller: _businessNameCtrl),
        ),
        _RefinedSettingsRow(
          label: 'GST identification',
          child: _RefinedTextField(controller: _gstCtrl),
        ),
        _RefinedSettingsRow(
          label: 'Industry vertical',
          child: _RefinedIndustryDropdown(
            value: _industry,
            items: AppConstants.industries,
            onChanged: (v) => setState(() => _industry = v!),
          ),
        ),
        _RefinedSettingsRow(
          label: 'Pincode',
          child: _RefinedTextField(controller: _pincodeCtrl),
        ),
        _RefinedSettingsRow(
          label: 'Annual revenue (₹)',
          child: _RefinedTextField(controller: _revenueCtrl),
        ),
        _RefinedSettingsRow(
          label: 'Team size',
          isLast: true,
          child: _RefinedTextField(controller: _employeesCtrl),
        ),
      ],
    );
  }

  Widget _buildNotificationsTab() {
    return _RefinedSettingsGroup(
      title: 'Notifications',
      children: [
        _RefinedSettingsRow(
          label: 'Email reports',
          desc: 'Receive comprehensive bias analysis after each scan',
          child: Align(
            alignment: Alignment.centerRight,
            child: _RefinedSwitch(
              value: _emailReports,
              onChanged: (v) => setState(() => _emailReports = v),
            ),
          ),
        ),
        _RefinedSettingsRow(
          label: 'Leaderboard updates',
          desc: 'Weekly fairness rankings for your industry and state',
          isLast: true,
          child: Align(
            alignment: Alignment.centerRight,
            child: _RefinedSwitch(
              value: _leaderboardUpdates,
              onChanged: (v) => setState(() => _leaderboardUpdates = v),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmClearAnalysisHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear analysis history?'),
        content: const Text(
          'This permanently deletes every past bias report on your account. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete all'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final removed = await ApiService.instance.clearAnalysisHistory();
      if (!mounted) return;
      ref.invalidate(analysisHistoryProvider);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            removed == 0
                ? 'No analyses to delete.'
                : 'Deleted $removed analysis report${removed == 1 ? '' : 's'}.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to clear history: $e')),
      );
    }
  }

  Widget _buildDangerTab() {
    return _RefinedSettingsGroup(
      title: 'Danger zone',
      isDanger: true,
      children: [
        _RefinedSettingsRow(
          label: 'Reset analysis history',
          desc: 'Permanently delete all your past bias reports',
          child: _GhostButton(
            'Clear data',
            onTap: _confirmClearAnalysisHistory,
            isDanger: true,
          ),
        ),
        _RefinedSettingsRow(
          label: 'Deactivate account',
          desc: 'Permanently remove your business profile',
          isLast: true,
          child: _GhostButton(
            'Deactivate',
            onTap: () {},
            isDanger: true,
          ),
        ),
        _RefinedSettingsRow(
          label: 'Log out',
          desc: 'Sign out of your session on this device',
          isLast: true,
          child: _GhostButton(
            'Sign out',
            onTap: () {
              ref.read(activeProfileIdProvider.notifier).clear();
              ref.read(guestModeProvider.notifier).state = false;
              ref.read(signInProvider.notifier).signOut();
              context.go(AppConstants.routeLogin);
            },
            isDanger: true,
          ),
        ),
      ],
    );
  }

  Widget _buildStickyActionFooter() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unsaved changes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your profile is the key to accurate fairness scores.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.inkMuted,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          _GhostButton(
            'Discard',
            onTap: () => context.pop(),
          ),
          const SizedBox(width: 16),
          _InkButton(
            _isSaving ? 'Saving...' : 'Save changes',
            onTap: _isSaving ? () {} : _saveProfile,
          ),
        ],
      ),
    );
  }
}

// ── Components ──────────────────────────────────────────────────────────

class _TabPill extends StatefulWidget {
  final String label;
  final bool isActive;
  final bool isDanger;
  final VoidCallback onTap;
  final bool isSidebar;

  const _TabPill({
    required this.label,
    required this.isActive,
    this.isDanger = false,
    required this.onTap,
    this.isSidebar = false,
  });

  @override
  State<_TabPill> createState() => _TabPillState();
}

class _TabPillState extends State<_TabPill> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.isSidebar ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isActive ? AppColors.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: widget.isActive
                  ? AppColors.ink
                  : (_isHovered ? AppColors.inkFaint : Colors.transparent),
              width: 1,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: widget.isActive
                  ? AppColors.background
                  : (widget.isDanger ? AppColors.error : AppColors.inkMuted),
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }
}

class _RefinedSettingsGroup extends StatelessWidget {
  final String title;
  final String? tag;
  final bool isDanger;
  final List<Widget> children;

  const _RefinedSettingsGroup({
    required this.title,
    this.tag,
    this.isDanger = false,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(
          color: isDanger ? AppColors.error.withValues(alpha: 0.3) : AppColors.outline,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Row(
              children: [
                Text(
                  title,
                  style: GoogleFonts.fraunces(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: isDanger ? AppColors.error : AppColors.ink,
                    letterSpacing: -0.01,
                  ),
                ),
                if (tag != null) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      tag!,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ]
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.outline),
          ...children,
        ],
      ),
    );
  }
}

class _RefinedSettingsRow extends StatelessWidget {
  final String label;
  final String? desc;
  final Widget child;
  final bool isLast;

  const _RefinedSettingsRow({
    required this.label,
    this.desc,
    required this.child,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.outline, width: 1)),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink, fontFamily: 'Inter'),
                ),
                if (desc != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    desc!,
                    style: const TextStyle(fontSize: 12, color: AppColors.inkFaint, fontFamily: 'Inter'),
                  ),
                ],
                const SizedBox(height: 16),
                child,
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink, fontFamily: 'Inter'),
                      ),
                      if (desc != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          desc!,
                          style: const TextStyle(fontSize: 12, color: AppColors.inkFaint, fontFamily: 'Inter'),
                        ),
                      ]
                    ],
                  ),
                ),
                const SizedBox(width: 48),
                SizedBox(width: 320, child: child),
              ],
            ),
    );
  }
}

class _RefinedTextField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final String? hint;
  final TextInputType? keyboardType;

  const _RefinedTextField({
    required this.controller,
    this.enabled = true,
    this.hint,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: TextStyle(
        fontSize: 13,
        color: enabled ? AppColors.ink : AppColors.inkFaint,
        fontFamily: 'Inter',
      ),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: enabled ? AppColors.background : AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.outline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.ink, width: 1),
        ),
      ),
    );
  }
}

class _RefinedIndustryDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _RefinedIndustryDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.outline, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.expand_more, size: 20, color: AppColors.ink),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          style: const TextStyle(fontSize: 13, color: AppColors.ink, fontFamily: 'Inter'),
          dropdownColor: AppColors.background,
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _RefinedSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _RefinedSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 44,
        height: 24,
        decoration: BoxDecoration(
          color: value ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(999),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.all(2),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

class _InkButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _InkButton(this.label, {required this.onTap});

  @override
  State<_InkButton> createState() => _InkButtonState();
}

class _InkButtonState extends State<_InkButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFF222222) : AppColors.ink,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.background, fontFamily: 'Inter'),
          ),
        ),
      ),
    );
  }
}

class _GhostButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDanger;

  const _GhostButton(this.label, {required this.onTap, this.isDanger = false});

  @override
  State<_GhostButton> createState() => _GhostButtonState();
}

class _GhostButtonState extends State<_GhostButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered ? (widget.isDanger ? AppColors.error.withValues(alpha: 0.1) : AppColors.ink.withValues(alpha: 0.05)) : Colors.transparent,
            border: Border.all(color: widget.isDanger ? AppColors.error.withValues(alpha: 0.3) : AppColors.outline, width: 1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: widget.isDanger ? AppColors.error : AppColors.ink,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }
}

class _NoProfileView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(56),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.outline, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(Icons.business_center_outlined, size: 48, color: AppColors.inkFaint),
            const SizedBox(height: 20),
            Text(
              'No profile found',
              style: GoogleFonts.fraunces(fontSize: 24, color: AppColors.ink, fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 10),
            const Text(
              'Complete your business profile to start analyzing contracts.',
              style: TextStyle(fontSize: 14, color: AppColors.inkMuted, fontFamily: 'Inter'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _InkButton('Complete Profile', onTap: () => context.go(AppConstants.routeProfile)),
          ],
        ),
      ),
    );
  }
}

class _CustomCropperDialog extends StatefulWidget {
  final Widget cropper;
  final Function() initCropper;
  final Future<String?> Function() crop;

  const _CustomCropperDialog({
    required this.cropper,
    required this.initCropper,
    required this.crop,
  });

  @override
  State<_CustomCropperDialog> createState() => _CustomCropperDialogState();
}

class _CustomCropperDialogState extends State<_CustomCropperDialog> {
  @override
  void initState() {
    super.initState();
    widget.initCropper();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: AppColors.background,
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Crop Profile Photo',
              style: GoogleFonts.fraunces(fontSize: 24, color: AppColors.ink),
            ),
            const SizedBox(height: 32),
            SizedBox(height: 400, child: widget.cropper),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _GhostButton('Cancel', onTap: () => Navigator.pop(context)),
                const SizedBox(width: 16),
                _InkButton('Confirm', onTap: () async {
                  final res = await widget.crop();
                  if (res != null) Navigator.pop(context, res);
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
