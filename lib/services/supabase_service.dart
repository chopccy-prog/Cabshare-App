import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ride.dart';

class SupabaseService {
  final supabase = Supabase.instance.client;

  Future<List<Ride>> searchRides(String fromCity, String toCity, DateTime date) async {
    try {
      final response = await supabase
          .from('rides_search_view')
          .select()
          .eq('from_city', fromCity)
          .eq('to_city', toCity)
          .eq('depart_date', date.toIso8601String().split('T')[0])
          .order('depart_time');
      return response.map((json) => Ride.fromJson(json)).toList();
    } catch (e) {
      print('Search error: $e');
      return [];
    }
  }

  Future<List<Ride>> getPublishedRides() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];
    try {
      final response = await supabase
          .from('rides')
          .select()
          .eq('driver_id', user.id)
          .order('depart_date', ascending: false);
      return response.map((json) => Ride.fromJson(json)).toList();
    } catch (e) {
      print('Published rides error: $e');
      return [];
    }
  }

  Future<List<Ride>> getBookedRides() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];
    try {
      final response = await supabase
          .from('bookings')
          .select('*, ride_id(*)')
          .eq('rider_id', user.id)
          .order('created_at', ascending: false);
      return response.map((json) => Ride.fromJson(json['ride_id'])).toList();
    } catch (e) {
      print('Booked rides error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getInbox() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];
    try {
      final response = await supabase
          .from('messages')
          .select()
          .or('sender_id.eq.${user.id},recipient_id.eq.${user.id}')
          .order('ts', ascending: false);
      return response;
    } catch (e) {
      print('Inbox error: $e');
      return [];
    }
  }

  Future<void> bookRide(String rideId, int seats, String fromStop, String toStop) async {
    try {
      await supabase.rpc('app_book_ride', params: {
        'p_ride_id': rideId,
        'p_seats': seats,
        'p_from_stop': fromStop,
        'p_to_stop': toStop,
      });
    } catch (e) {
      print('Booking error: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
    }
  }
}