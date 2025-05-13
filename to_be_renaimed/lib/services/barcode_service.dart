// lib/services/barcode_service.dart
import 'package:to_be_renaimed/services/api_service.dart';

class BarcodeService {
  final ApiService _apiService;

  BarcodeService({required ApiService apiService}) : _apiService = apiService;

  // Отправка URL на сервер для скрэпинга
  Future<Map<String, dynamic>> scanProductUrl(String url) async {
    try {
      print('\n===== SENDING URL TO SERVER =====');
      print('URL: $url');

      final response = await _apiService.post('/api/scan-product/', {
        'barcode_url': url,
      });

      print('SERVER RESPONSE: $response');

      return response;
    } catch (e) {
      print('ERROR SCANNING PRODUCT: $e');
      throw Exception('Ошибка при сканировании товара: $e');
    }
  }

  // Поиск по штрих-коду (например, через OpenFoodFacts)
  Future<Map<String, dynamic>?> searchByBarcode(String barcode) async {
    try {
      print('\n===== SEARCHING BY BARCODE =====');
      print('Barcode: $barcode');

      // Здесь можно использовать OpenFoodFacts API
      // final url = 'https://world.openfoodfacts.org/api/v2/product/$barcode';
      // ... поиск товара

      // Пока возвращаем null
      return null;
    } catch (e) {
      print('ERROR SEARCHING BY BARCODE: $e');
      return null;
    }
  }
}