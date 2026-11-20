import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../models/models.dart';
import 'demo_database.dart';

class AuthRepository {
  AuthRepository({
    required DemoDatabase demoDb,
    required SharedPreferences prefs,
  })  : _demoDb = demoDb,
        _prefs = prefs;

  final DemoDatabase _demoDb;
  final SharedPreferences _prefs;

  static const _kDemoCustomerKey = 'priscy_demo_customer_session_v1';
  static const _kDemoAdminKey = 'priscy_demo_admin_session_v1';

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<UserProfile?> getCurrentCustomer() async {
    if (AppConfig.isDemoMode) {
      final raw = _prefs.getString(_kDemoCustomerKey);
      if (raw == null) return null;
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    }

    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    final row = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    if (row == null) return null;
    return UserProfile.fromJson({...row, 'email': user.email});
  }

  Future<UserProfile?> getCurrentAdmin() async {
    if (AppConfig.isDemoMode) {
      final raw = _prefs.getString(_kDemoAdminKey);
      if (raw == null) return null;
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    }

    final profile = await getCurrentCustomer();
    if (profile != null && profile.isAdmin) return profile;
    return null;
  }

  Future<UserProfile> signInCustomer({
    required String email,
    required String password,
  }) async {
    if (AppConfig.isDemoMode) {
      final profile = UserProfile(
        id: 'demo-user-001',
        email: email.trim(),
        fullName: email.split('@').first.replaceAll('.', ' '),
        phone: '0244123456',
        role: AppRole.customer,
        createdAt: DateTime.now(),
      );
      await _prefs.setString(_kDemoCustomerKey, jsonEncode(profile.toJson()));
      return profile;
    }

    await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final profile = await getCurrentCustomer();
    if (profile == null) {
      throw StateError('Account profile not found.');
    }
    return profile;
  }

  Future<UserProfile> signUpCustomer({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async {
    if (AppConfig.isDemoMode) {
      final profile = UserProfile(
        id: _demoDb.nextId('usr'),
        email: email.trim(),
        fullName: fullName.trim(),
        phone: phone.trim(),
        role: AppRole.customer,
        createdAt: DateTime.now(),
      );
      await _prefs.setString(_kDemoCustomerKey, jsonEncode(profile.toJson()));
      return profile;
    }

    await _supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': fullName.trim(),
        'phone': phone.trim(),
      },
    );
    final current = await getCurrentCustomer();
    return current ??
        UserProfile(
          id: _supabase.auth.currentUser?.id ?? '',
          email: email.trim(),
          fullName: fullName.trim(),
          phone: phone.trim(),
          role: AppRole.customer,
        );
  }

  Future<void> requestPhoneOtp(String ghanaPhone) async {
    if (AppConfig.isDemoMode) return;
    await _supabase.auth.signInWithOtp(phone: ghanaPhone);
  }

  Future<UserProfile> verifyPhoneOtp({
    required String ghanaPhone,
    required String otpCode,
  }) async {
    if (AppConfig.isDemoMode) {
      final profile = UserProfile(
        id: 'demo-otp-user',
        fullName: 'Mobile Shopper',
        phone: ghanaPhone,
        role: AppRole.customer,
        createdAt: DateTime.now(),
      );
      await _prefs.setString(_kDemoCustomerKey, jsonEncode(profile.toJson()));
      return profile;
    }

    await _supabase.auth.verifyOTP(
      phone: ghanaPhone,
      token: otpCode,
      type: OtpType.sms,
    );
    final current = await getCurrentCustomer();
    if (current == null) {
      throw StateError('Could not load customer profile');
    }
    return current;
  }

  Future<UserProfile> signInAdmin({
    required String email,
    required String password,
  }) async {
    if (AppConfig.isDemoMode) {
      if (password.trim().length < 4) {
        throw StateError('Enter a valid password (demo: admin1234).');
      }
      final admin = UserProfile(
        id: 'demo-admin-priscilla',
        email: email.trim().isEmpty ? AppConfig.supportEmail : email.trim(),
        fullName: AppConfig.ownerName,
        phone: AppConfig.supportPhoneLocal,
        role: AppRole.admin,
        createdAt: DateTime(2026, 10, 30),
      );
      await _prefs.setString(_kDemoAdminKey, jsonEncode(admin.toJson()));
      return admin;
    }

    await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final admin = await getCurrentAdmin();
    if (admin == null || !admin.isAdmin) {
      await _supabase.auth.signOut();
      throw StateError(
        'Access denied: this account does not have the admin role.',
      );
    }
    return admin;
  }

  Future<void> signOutCustomer() async {
    if (AppConfig.isDemoMode) {
      await _prefs.remove(_kDemoCustomerKey);
      return;
    }
    await _supabase.auth.signOut();
  }

  Future<void> signOutAdmin() async {
    if (AppConfig.isDemoMode) {
      await _prefs.remove(_kDemoAdminKey);
      return;
    }
    await _supabase.auth.signOut();
  }

  Future<List<SavedAddress>> fetchSavedAddresses(String userId) async {
    if (AppConfig.isDemoMode) {
      return _demoDb.savedAddresses
          .where((a) => a.userId == userId)
          .toList();
    }

    final rows = await _supabase
        .from('saved_addresses')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return rows.map(SavedAddress.fromJson).toList();
  }

  Future<void> addSavedAddress(SavedAddress address) async {
    if (AppConfig.isDemoMode) {
      _demoDb.savedAddresses.insert(
        0,
        SavedAddress(
          id: _demoDb.nextId('addr'),
          userId: address.userId,
          label: address.label,
          recipientName: address.recipientName,
          phone: address.phone,
          region: address.region,
          city: address.city,
          address: address.address,
          landmark: address.landmark,
          isDefault: address.isDefault,
        ),
      );
      await _demoDb.saveAddresses();
      return;
    }

    await _supabase.from('saved_addresses').insert({
      'user_id': address.userId,
      'label': address.label,
      'recipient_name': address.recipientName,
      'phone': address.phone,
      'region': address.region,
      'city': address.city,
      'address': address.address,
      'landmark': address.landmark,
      'is_default': address.isDefault,
    });
  }

  Future<void> deleteSavedAddress(String addressId) async {
    if (AppConfig.isDemoMode) {
      _demoDb.savedAddresses.removeWhere((a) => a.id == addressId);
      await _demoDb.saveAddresses();
      return;
    }
    await _supabase.from('saved_addresses').delete().eq('id', addressId);
  }
}
