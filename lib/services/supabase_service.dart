import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ride.dart';

class SupabaseService {
  final supabase = Supabase.instance.client;

  Future<List<Ride>> searchRides(String fromCity, String toCity, DateTime date) async {
    return await supabase
        .from('rides_search_view')
        .select()
        .eq('from_city', fromCity)
        .eq('to_city', toCity)
        .eq('depart_date', date.toIso8601String().split('T')[0])
        .order('depart_time')
        .map((json) => Ride.fromJson(json));
  }

  Future<List<Ride>> getPublishedRides() async {
    final userId = supabase.auth.currentUser?.id;
    return userId == null ? [] : await supabase
        .from('rides')
        .select()
        .eq('driver_id', userId)
        .order('depart_date', ascending: false)
        .map((json) => Ride.fromJson(json));
  }

  Future<List<Ride>> getBookedRides() async {
    final userId = supabase.auth.currentUser?.id;
    return userId == null ? [] : await supabase
        .from('bookings')
        .select('*, ride_id(*)')
        .eq('rider_id', userId)
        .order('created_at', ascending: false)
        .map((json) => Ride.fromJson(json['ride_id']));
  }

  Future<List<Map<String, dynamic>>> getInbox() async {
    final userId = supabase.auth.currentUser?.id;
    return userId == null ? [] : await supabase
        .from('messages')
        .select()
        .or('sender_id.eq.$userId,recipient_id.eq.$userId')
        .order('ts', ascending: false);
  }

  Future<void> bookRide(String rideId, int seats, String fromStop, String toStop) async {
    await supabase.rpc('app_book_ride', params: {
      'p_ride_id': rideId,
      'p_seats': seats,
      'p_from_stop': fromStop,
      'p_to_stop': toStop,
    });
    final userId = supabase.auth.currentUser?.id;
    final ride = await supabase.from('rides').select().eq('id', rideId).single();
    final driverId = ride['driver_id'];
    await supabase.from('conversations').insert({
      'members': [userId, driverId],
      'title': 'Ride $rideId Chat',
      'created_at': DateTime.now().toIso8601String(),
    });
    await supabase.from('messages').insert({
      'conversation_id': rideId, // Use rideId as temp conv ID
      'sender_id': userId,
      'text': 'Ride booked! Details: ${ride['depart_date']} ${ride['depart_time']}',
      'ts': DateTime.now().toIso8601String(),
      'recipient_id': driverId,
    });
  }

  Future<void> signOut() async => await supabase.auth.signOut();
}