/// Profile state providers for FairTerms.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sme_profile.dart';
import '../services/api_service.dart';

/// State for the multi-step profile creation form.
class ProfileFormState {
  final int currentStep;
  final String businessName;
  final String ownerName;
  final String gstNumber;
  final String yearsInOperation;
  final String pincode;
  final String city;
  final String? state;
  final String? industry;
  final String annualRevenueInr;
  final String employeeCount;
  final String phoneNumber;
  final bool isSubmitting;
  final String? errorMessage;
  final String? savedProfileId;

  const ProfileFormState({
    this.currentStep = 0,
    this.businessName = '',
    this.ownerName = '',
    this.gstNumber = '',
    this.yearsInOperation = '',
    this.pincode = '',
    this.city = '',
    this.state,
    this.industry,
    this.annualRevenueInr = '',
    this.employeeCount = '',
    this.phoneNumber = '',
    this.isSubmitting = false,
    this.errorMessage,
    this.savedProfileId,
  });

  /// Creates a copy of this state with updated fields.
  ProfileFormState copyWith({
    int? currentStep,
    String? businessName,
    String? ownerName,
    String? gstNumber,
    String? yearsInOperation,
    String? pincode,
    String? city,
    String? state,
    String? industry,
    String? annualRevenueInr,
    String? employeeCount,
    String? phoneNumber,
    bool? isSubmitting,
    String? errorMessage,
    String? savedProfileId,
  }) {
    return ProfileFormState(
      currentStep: currentStep ?? this.currentStep,
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      gstNumber: gstNumber ?? this.gstNumber,
      yearsInOperation: yearsInOperation ?? this.yearsInOperation,
      pincode: pincode ?? this.pincode,
      city: city ?? this.city,
      state: state ?? this.state,
      industry: industry ?? this.industry,
      annualRevenueInr: annualRevenueInr ?? this.annualRevenueInr,
      employeeCount: employeeCount ?? this.employeeCount,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      savedProfileId: savedProfileId ?? this.savedProfileId,
    );
  }
}

/// Manages the profile creation wizard state.
class ProfileFormNotifier extends StateNotifier<ProfileFormState> {
  ProfileFormNotifier() : super(const ProfileFormState());

  /// Advances to the next step.
  void nextStep() {
    if (state.currentStep < 2) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  /// Goes back to the previous step.
  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  /// Updates a field value by field name.
  void updateField(String field, String value) {
    switch (field) {
      case 'businessName':
        state = state.copyWith(businessName: value);
      case 'ownerName':
        state = state.copyWith(ownerName: value);
      case 'gstNumber':
        state = state.copyWith(gstNumber: value);
      case 'yearsInOperation':
        state = state.copyWith(yearsInOperation: value);
      case 'pincode':
        state = state.copyWith(pincode: value);
      case 'city':
        state = state.copyWith(city: value);
      case 'state':
        state = state.copyWith(state: value);
      case 'industry':
        state = state.copyWith(industry: value);
      case 'annualRevenueInr':
        state = state.copyWith(annualRevenueInr: value);
      case 'employeeCount':
        state = state.copyWith(employeeCount: value);
      case 'phoneNumber':
        state = state.copyWith(phoneNumber: value);
    }
  }

  /// Submits the profile form to the API.
  ///
  /// Returns the profile ID on success.
  Future<String?> submitProfile() async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final profile = SmeProfile(
        businessName: state.businessName.trim(),
        ownerName: state.ownerName.trim(),
        pincode: state.pincode.trim(),
        city: state.city.trim(),
        state: state.state ?? '',
        industry: state.industry ?? '',
        annualRevenueInr: int.tryParse(
                state.annualRevenueInr.replaceAll(',', '')) ??
            0,
        employeeCount: int.tryParse(state.employeeCount) ?? 0,
        yearsInOperation: int.tryParse(state.yearsInOperation) ?? 0,
        gstNumber:
            state.gstNumber.trim().isEmpty ? null : state.gstNumber.trim(),
        phoneNumber:
            state.phoneNumber.trim().isEmpty ? null : state.phoneNumber.trim(),
      );

      final result = await ApiService.instance.createProfile(profile);
      final profileId = result['profile_id'] as String?;

      state = state.copyWith(
        isSubmitting: false,
        savedProfileId: profileId,
      );

      return profileId;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Resets the form to initial state.
  void reset() {
    state = const ProfileFormState();
  }
}

/// Provider for [ProfileFormNotifier].
final profileFormProvider =
    StateNotifierProvider<ProfileFormNotifier, ProfileFormState>(
  (_) => ProfileFormNotifier(),
);

/// Persists the active profile ID to SharedPreferences so it survives page refreshes.
class ActiveProfileIdNotifier extends StateNotifier<AsyncValue<String?>> {
  static const _prefKey = 'active_profile_id';

  ActiveProfileIdNotifier() : super(const AsyncValue.loading()) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) state = AsyncValue.data(prefs.getString(_prefKey));
    } catch (_) {
      if (mounted) state = const AsyncValue.data(null);
    }
  }

  void setId(String id) {
    state = AsyncValue.data(id);
    SharedPreferences.getInstance().then((p) => p.setString(_prefKey, id));
  }

  void clear() {
    state = const AsyncValue.data(null);
    SharedPreferences.getInstance().then((p) => p.remove(_prefKey));
  }
}

/// Provider that holds the current active profile ID (persisted across page refreshes).
final activeProfileIdProvider =
    StateNotifierProvider<ActiveProfileIdNotifier, AsyncValue<String?>>(
  (_) => ActiveProfileIdNotifier(),
);

/// Provider that fetches a profile by ID.
final profileByIdProvider =
    FutureProvider.family<SmeProfile, String>((ref, profileId) async {
  return ApiService.instance.getProfile(profileId);
});

/// Provider for the profile photo (base64 encoded bytes).
final profilePhotoProvider =
    StateNotifierProvider<ProfilePhotoNotifier, String?>((ref) {
  return ProfilePhotoNotifier();
});

class ProfilePhotoNotifier extends StateNotifier<String?> {
  ProfilePhotoNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('profile_photo_b64');
      if (saved != null && mounted) {
        state = saved;
      }
    } catch (e) {
      // SharedPreferences might fail in some environments
    }
  }

    void syncFromServer(String b64) {
    if (state != b64) {
      state = b64;
      // Also save locally so it's available on next refresh before server load
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('profile_photo_b64', b64);
      });
    }
  }
  Future<void> updatePhoto(Uint8List bytes) async {
    try {
      final b64 = base64Encode(bytes);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_photo_b64', b64);
      if (mounted) {
        state = b64;
      }
    } catch (e) {
      // Handle or log error
    }
  }

  Future<void> removePhoto() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('profile_photo_b64');
      if (mounted) {
        state = null;
      }
    } catch (e) {
      // Handle or log error
    }
  }
}
