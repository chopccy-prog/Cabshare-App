// lib/services/profile_repo.dart
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Tables expected (you already have these or similar):
/// - profiles:      user_id (pk/uuid), full_name text, phone text, email text, kyc_status text
/// - vehicles:      id bigserial, owner_id uuid, plate text, model text, color text?
/// - kyc_documents: id bigserial, user_id uuid, doc_type text, storage_path text, status text, created_at timestamptz default now()
///
/// Storage bucket expected:
/// - kyc (public=false)
class ProfileRepo {
  final _supabase = sb.Supabase.instance.client;

  String? get _uid => _supabase.auth.currentUser?.id;

  Future<Map<String, dynamic>?> getMyProfile() async {
    final uid = _uid;
    if (uid == null) return null;
    final rows = await _supabase
        .from('profiles')
        .select()
        .eq('user_id', uid)
        .limit(1);
    if (rows.isEmpty) return null;
    return rows.first as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> upsertMyProfile({
    String? fullName,
    String? phone,
    String? email,
    String? kycStatus,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not signed in');
    final payload = <String, dynamic>{
      'user_id': uid,
      if (fullName != null) 'full_name': fullName,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (kycStatus != null) 'kyc_status': kycStatus,
    };
    final res = await _supabase.from('profiles').upsert(payload).select().limit(1);
    return (res as List).first as Map<String, dynamic>;
  }

  // ---------------- Vehicles ----------------
  Future<List<Map<String, dynamic>>> myVehicles() async {
    final uid = _uid;
    if (uid == null) return [];
    final rows = await _supabase
        .from('vehicles')
        .select()
        .eq('owner_id', uid)
        .order('id', ascending: false);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> addVehicle({
    required String plate,
    required String model,
    String? color,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not signed in');
    final rows = await _supabase.from('vehicles').insert({
      'owner_id': uid,
      'plate': plate,
      'model': model,
      if (color != null && color.isNotEmpty) 'color': color,
    }).select();
    return (rows as List).first as Map<String, dynamic>;
  }

  Future<void> deleteVehicle(int id) async {
    await _supabase.from('vehicles').delete().eq('id', id);
  }

  // ---------------- KYC Documents ----------------
  /// Upload bytes to storage (bucket `kyc`) and create a row in `kyc_documents`.
  /// Returns the DB row.
  Future<Map<String, dynamic>> uploadKycDocument({
    required String docType, // e.g. 'id_proof','driver_license','vehicle_rc'
    required Uint8List bytes,
    required String filename, // with extension
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not signed in');
    final path = '$uid/$docType/$filename';
    await _supabase.storage.from('kyc').uploadBinary(path, bytes, fileOptions: const sb.FileOptions(upsert: true));
    final rows = await _supabase.from('kyc_documents').insert({
      'user_id': uid,
      'doc_type': docType,
      'storage_path': path,
      'status': 'pending',
    }).select();
    return (rows as List).first as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> myKycDocs() async {
    final uid = _uid;
    if (uid == null) return [];
    final rows = await _supabase
        .from('kyc_documents')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false);
    return (rows as List).cast<Map<String, dynamic>>();
  }
}
