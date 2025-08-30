import 'package:shared_preferences/shared_preferences.dart';

class ProfileData {
  final String name;
  final String phone;
  final String carNumber;

  const ProfileData({
    required this.name,
    required this.phone,
    required this.carNumber,
  });

  ProfileData copyWith({String? name, String? phone, String? carNumber}) {
    return ProfileData(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      carNumber: carNumber ?? this.carNumber,
    );
  }
}

class ProfileStore {
  static const _kName = 'profile.name';
  static const _kPhone = 'profile.phone';
  static const _kCarNo = 'profile.carNumber';

  static Future<ProfileData> load() async {
    final sp = await SharedPreferences.getInstance();
    return ProfileData(
      name: sp.getString(_kName) ?? '',
      phone: sp.getString(_kPhone) ?? '',
      carNumber: sp.getString(_kCarNo) ?? '',
    );
  }

  static Future<void> save(ProfileData data) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kName, data.name);
    await sp.setString(_kPhone, data.phone);
    await sp.setString(_kCarNo, data.carNumber);
  }

  static Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kName);
    await sp.remove(_kPhone);
    await sp.remove(_kCarNo);
  }
}
