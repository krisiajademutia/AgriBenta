import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for rootBundle

class LocationService {
  static Map<String, dynamic>? _fullData;

  static Future<void> loadData() async {
    if (_fullData != null) return;
    try {
      final String response =
          await rootBundle.loadString('assets/ph_locations.json');
      _fullData = json.decode(response);
    } catch (e) {
      debugPrint("Error loading location data: $e");
    }
  }

  static List<String> getRegions() {
    if (_fullData == null) return [];
    return _fullData!.keys.toList();
  }

  static List<String> getProvinces(String region) {
    if (_fullData == null || !_fullData!.containsKey(region)) return [];
    try {
      Map<String, dynamic> list = _fullData![region]['province_list'];
      return list.keys.toList();
    } catch (e) {
      return [];
    }
  }

  static List<String> getCities(String region, String province) {
    if (_fullData == null) return [];
    try {
      Map<String, dynamic> list =
          _fullData![region]['province_list'][province]['municipality_list'];
      return list.keys.toList();
    } catch (e) {
      return [];
    }
  }

  static List<String> getBarangays(
      String region, String province, String city) {
    if (_fullData == null) return [];
    try {
      List<dynamic> list = _fullData![region]['province_list'][province]
          ['municipality_list'][city]['barangay_list'];
      return list.map((e) => e.toString()).toList();
    } catch (e) {
      return [];
    }
  }
}
