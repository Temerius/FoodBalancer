
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:to_be_renaimed/services/api_service.dart';

class BarcodeService {
  final ApiService _apiService;

  BarcodeService({required ApiService apiService}) : _apiService = apiService;

  
  Future<Map<String, dynamic>?> fetchProductByBarcode(String barcode) async {
    try {
      print('\n===== FETCHING PRODUCT BY BARCODE =====');
      print('Barcode: $barcode');
      print('Sending request to: /api/barcode/?barcode=$barcode');
      print('Using extended timeout for barcode processing...');

      
      final response = await _apiService.getWithExtendedTimeout(
        '/api/barcode/?barcode=$barcode',
        timeout: const Duration(seconds: 60),
      );

      print('\n===== SERVER RESPONSE RAW =====');
      print('Response type: ${response.runtimeType}');
      print('Response keys: ${response.keys.toList()}');
      print('Response contains product: ${response.containsKey('product')}');

      
      if (response.containsKey('barcode')) {
        print('Barcode in response: ${response['barcode']}');
      }

      if (response.containsKey('error')) {
        print('Error in response: ${response['error']}');
      }

      if (response.containsKey('warning')) {
        print('Warning in response: ${response['warning']}');
      }

      
      if (response.containsKey('product')) {
        print('Product data exists in response');
        return response['product'];
      }

      print('Product data not found in response');
      return null;
    } catch (e) {
      print('\n===== ERROR FETCHING PRODUCT =====');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');

      
      if (e is TimeoutException || e.toString().contains('TimeoutException')) {
        print('SERVER IS PROCESSING REQUEST LONGER THAN EXPECTED');

        
        
      }

      return null;
    }
  }

  
  Map<String, dynamic> formatProductData(Map<String, dynamic> productData) {
    Map<String, dynamic> formattedData = {};

    try {
      
      formattedData['name'] = productData['name'] ?? '';

      
      if (productData['weight'] != null && productData['weight'].toString().isNotEmpty) {
        formattedData['weight'] = _extractNumericValue(productData['weight']);
      }

      
      if (productData['ingredients'] != null && productData['ingredients'].toString().isNotEmpty) {
        formattedData['ingredients'] = productData['ingredients'];
      }

      
      formattedData['calories'] = _extractNumericValue(productData['calories']);
      formattedData['protein'] = _extractNumericValue(productData['protein']);
      formattedData['fat'] = _extractNumericValue(productData['fat']);
      formattedData['carbs'] = _extractNumericValue(productData['carbs']);

      
      if (productData.containsKey('classification') && productData['classification'] != null) {
        final classification = productData['classification'];

        
        if (classification.containsKey('ingredient_type_id') &&
            classification['ingredient_type_id'] != null) {
          formattedData['ingredient_type_id'] = classification['ingredient_type_id'];
        }

        
        if (classification.containsKey('ingredient_type_name')) {
          formattedData['category'] = classification['ingredient_type_name'];
        }

        
        if (classification.containsKey('allergen_ids')) {
          formattedData['allergen_ids'] = classification['allergen_ids'];
        }

        
        if (classification.containsKey('allergen_names')) {
          formattedData['allergen_names'] = classification['allergen_names'];
        }
      }

      
      if (productData.containsKey('store')) {
        formattedData['store'] = productData['store'];
      }

      
      if (productData.containsKey('image_url') && productData['image_url'] != null) {
        formattedData['image_url'] = productData['image_url'];
      }

      print('FORMATTED DATA: $formattedData');
      return formattedData;
    } catch (e) {
      print('ERROR FORMATTING PRODUCT DATA: $e');
      return formattedData;
    }
  }

  
  int _extractNumericValue(dynamic value) {
    if (value == null || (value is String && value.isEmpty)) return 0;

    
    if (value is int) return value;
    if (value is double) return value.round();

    
    if (value is String) {
      
      final RegExp regExp = RegExp(r'(\d+(?:[.,]\d+)?)');
      final match = regExp.firstMatch(value);

      if (match != null) {
        
        String numberStr = match.group(1)!.replaceAll(',', '.');
        try {
          return double.parse(numberStr).round();
        } catch (e) {
          print('Error parsing numeric value: $e');
        }
      }
    }

    return 0;
  }
}