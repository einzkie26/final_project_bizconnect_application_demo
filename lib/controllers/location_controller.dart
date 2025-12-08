import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/location_model.dart';

class LocationController {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';
  
  static Future<List<LocationModel>> searchLocation(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search?q=$query&format=json&limit=5'),
        headers: {'User-Agent': 'BizConnect/1.0'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => LocationModel.fromMap(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
  
  static Future<LocationModel?> getAddressFromCoordinates(
    double lat, 
    double lon
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/reverse?lat=$lat&lon=$lon&format=json'),
        headers: {'User-Agent': 'BizConnect/1.0'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return LocationModel.fromMap(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}