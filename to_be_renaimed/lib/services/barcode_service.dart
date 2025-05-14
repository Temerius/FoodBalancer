// lib/services/barcode_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:to_be_renaimed/services/api_service.dart';

class BarcodeService {
  final ApiService _apiService;

  BarcodeService({required ApiService apiService}) : _apiService = apiService;

  // Получение информации о продукте по штрих-коду от нашего API
  Future<Map<String, dynamic>?> fetchProductByBarcode(String barcode) async {
    try {
      print('\n===== FETCHING PRODUCT BY BARCODE =====');
      print('Barcode: $barcode');
      print('Sending request to: /api/barcode/?barcode=$barcode');

      // Вызываем наш API-эндпоинт
      final response = await _apiService.get('/api/barcode/?barcode=$barcode');

      print('\n===== SERVER RESPONSE RAW =====');
      print('Response type: ${response.runtimeType}');
      print('Response keys: ${response.keys.toList()}');
      print('Response contains product: ${response.containsKey('product')}');

      // Более детальный вывод содержимого ответа
      if (response.containsKey('barcode')) {
        print('Barcode in response: ${response['barcode']}');
      }

      if (response.containsKey('error')) {
        print('Error in response: ${response['error']}');
      }

      if (response.containsKey('warning')) {
        print('Warning in response: ${response['warning']}');
      }

      // Проверяем структуру ответа
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
      return null;
    }
  }

  // Преобразование данных продукта в формат для AddProductScreen
  Map<String, dynamic> formatProductData(Map<String, dynamic> productData) {
    Map<String, dynamic> formattedData = {};

    try {
      // Основные поля
      formattedData['name'] = productData['name'] ?? '';

      // Обработка информации о весе, извлекаем только число
      if (productData['weight'] != null && productData['weight'].toString().isNotEmpty) {
        formattedData['weight'] = _extractNumericValue(productData['weight']);
      }

      // Состав продукта
      if (productData['ingredients'] != null && productData['ingredients'].toString().isNotEmpty) {
        formattedData['ingredients'] = productData['ingredients'];
      }

      // Извлекаем числовые значения из строк для БЖУ и калорий
      formattedData['calories'] = _extractNumericValue(productData['calories']);
      formattedData['protein'] = _extractNumericValue(productData['protein']);
      formattedData['fat'] = _extractNumericValue(productData['fat']);
      formattedData['carbs'] = _extractNumericValue(productData['carbs']);

      // Обработка классификации
      if (productData.containsKey('classification') && productData['classification'] != null) {
        final classification = productData['classification'];

        // Определяем категорию на основе classification
        if (classification.containsKey('ingredient_type_id') &&
            classification['ingredient_type_id'] != null) {
          formattedData['ingredient_type_id'] = classification['ingredient_type_id'];
        }

        // Добавляем название типа, если есть
        if (classification.containsKey('ingredient_type_name')) {
          formattedData['category'] = classification['ingredient_type_name'];
        }

        // Аллергены
        if (classification.containsKey('allergen_ids')) {
          formattedData['allergen_ids'] = classification['allergen_ids'];
        }

        // Названия аллергенов
        if (classification.containsKey('allergen_names')) {
          formattedData['allergen_names'] = classification['allergen_names'];
        }
      }

      // Если есть информация о магазине, добавляем ее
      if (productData.containsKey('store')) {
        formattedData['store'] = productData['store'];
      }

      // URL изображения, если есть
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

  // Извлекает числовое значение из строки вида "40 г" или "250 ккал"
  int _extractNumericValue(dynamic value) {
    if (value == null || (value is String && value.isEmpty)) return 0;

    // Если value уже число, просто возвращаем его
    if (value is int) return value;
    if (value is double) return value.round();

    // Если value строка, извлекаем из нее число
    if (value is String) {
      // Регулярное выражение для поиска числа
      final RegExp regExp = RegExp(r'(\d+(?:[.,]\d+)?)');
      final match = regExp.firstMatch(value);

      if (match != null) {
        // Заменяем запятую на точку (для корректного парсинга)
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