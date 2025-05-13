// lib/screens/refrigerator/barcode_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({Key? key}) : super(key: key);

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  bool _hasPermission = false;
  String _scanStatus = 'Наведите камеру на штрих-код продукта';
  bool _isProcessing = false;
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isDenied) {
      final result = await Permission.camera.request();
      setState(() {
        _hasPermission = result.isGranted;
      });
    } else {
      setState(() {
        _hasPermission = status.isGranted;
      });
    }
  }

  Future<void> _toggleFlash() async {
    await controller.toggleTorch();
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    final List<Barcode> barcodes = capture.barcodes;

    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first;

      // Получаем данные штрих-кода
      final String? barcodeData = barcode.rawValue;

      print('\n===== BARCODE DETECTED =====');
      print('Type: ${barcode.type}');
      print('Format: ${barcode.format}');
      print('Raw Value: $barcodeData');

      if (barcodeData != null) {
        // Проверяем, содержит ли штрих-код URL
        if (barcodeData.startsWith('http://') || barcodeData.startsWith('https://')) {
          print('DETECTED URL: $barcodeData');
          setState(() {
            _scanStatus = 'Найден URL: $barcodeData';
          });

          // Здесь позже отправим URL на сервер
          await _processBarcode(barcodeData);

        } else {
          // Обычный штрих-код (EAN, UPC и т.д.)
          print('DETECTED BARCODE: $barcodeData');
          setState(() {
            _scanStatus = 'Штрих-код: $barcodeData';
          });

          // Здесь позже можно будет использовать API для поиска по штрих-коду
          await _processBarcodeDigits(barcodeData);
        }
      }
    }

    // Ждем 2 секунды перед следующим сканированием
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isProcessing = false;
    });
  }

  Future<void> _processBarcode(String url) async {
    print('\n===== PROCESSING URL =====');
    print('URL: $url');

    // TODO: Отправить URL на сервер для скрэпинга
    // Пока просто симулируем обработку
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _scanStatus = 'Обрабатываем данные...';
    });

    // Симуляция получения данных
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      // Симулируем получение данных и переход к добавлению
      Navigator.pushReplacementNamed(
        context,
        '/refrigerator/add-product',
        arguments: {
          'scanned_data': {
            'name': 'Молоко 3.2%',
            'calories': 58,
            'protein': 2.9,
            'fat': 3.2,
            'carbs': 4.7,
            'category': 'Молочные продукты',
          }
        },
      );
    }
  }

  Future<Map<String, dynamic>?> _searchOpenFoodFacts(String barcode) async {
    try {
      final url = 'https://world.openfoodfacts.org/api/v2/product/$barcode';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 1 && data['product'] != null) {
          final product = data['product'];

          // Извлекаем нужные данные
          final String name = product['product_name'] ?? product['generic_name'] ?? '';
          final String? brand = product['brands'];

          // Пищевая ценность (на 100г)
          final nutriments = product['nutriments'] ?? {};

          // Формируем структурированные данные
          return {
            'name': brand != null ? '$brand $name' : name,
            'calories': nutriments['energy-kcal_100g']?.toInt() ?? 0,
            'protein': nutriments['proteins_100g']?.toDouble() ?? 0.0,
            'fat': nutriments['fat_100g']?.toDouble() ?? 0.0,
            'carbs': nutriments['carbohydrates_100g']?.toDouble() ?? 0.0,
            'category': _extractCategory(product),
            'image_url': product['image_url'],
            'barcode': barcode,
          };
        }
      }

      return null;
    } catch (e) {
      print('ERROR in _searchOpenFoodFacts: $e');
      return null;
    }
  }

  String _extractCategory(Map<String, dynamic> product) {
    // Попробуем получить категорию из различных полей
    if (product['categories'] != null && product['categories'].isNotEmpty) {
      final categories = product['categories'].split(',');

      // Преобразуем некоторые категории на русский
      for (var category in categories) {
        category = category.trim().toLowerCase();

        if (category.contains('dairy') || category.contains('milk')) {
          return 'Молочные продукты';
        }
        if (category.contains('vegetable') || category.contains('produce')) {
          return 'Овощи';
        }
        if (category.contains('fruit')) {
          return 'Фрукты';
        }
        if (category.contains('meat')) {
          return 'Мясо';
        }
        if (category.contains('beverage') || category.contains('drink')) {
          return 'Напитки';
        }
        if (category.contains('cereal') || category.contains('grain')) {
          return 'Крупы';
        }
      }
    }

    return 'Разное';
  }

  Future<void> _processBarcodeDigits(String barcode) async {
    print('\n===== PROCESSING BARCODE DIGITS =====');
    print('Barcode: $barcode');

    setState(() {
      _scanStatus = 'Поиск товара...';
    });

    try {
      // Ищем товар через OpenFoodFacts API
      final productInfo = await _searchOpenFoodFacts(barcode);

      if (productInfo != null && mounted) {
        setState(() {
          _scanStatus = 'Товар найден!';
        });

        // Ждем немного, чтобы пользователь увидел сообщение
        await Future.delayed(const Duration(seconds: 1));

        // Переходим к форме добавления с найденными данными
        Navigator.pushReplacementNamed(
          context,
          '/refrigerator/add-product',
          arguments: {
            'scanned_data': productInfo,
            'barcode': barcode,
          },
        );
      } else if (mounted) {
        setState(() {
          _scanStatus = 'Товар не найден';
        });

        // Показываем информацию о том, что товар не найден
        _showBarcodeInfo(barcode);
      }
    } catch (e) {
      print('ERROR SEARCHING PRODUCT: $e');
      if (mounted) {
        setState(() {
          _scanStatus = 'Ошибка поиска';
        });
        _showBarcodeInfo(barcode);
      }
    }
  }

  void _showBarcodeInfo(String barcode) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Штрих-код отсканирован',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              barcode,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Здесь можно добавить поиск по штрих-коду
                    },
                    child: const Text('Поиск товара'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(
                        context,
                        '/refrigerator/add-product',
                        arguments: {'barcode': barcode},
                      );
                    },
                    child: const Text('Добавить вручную'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Сканирование штрих-кода'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Требуется разрешение на использование камеры'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Сканирование штрих-кода'),
        actions: [
          IconButton(
            icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleFlash,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Камера
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),

          // Оверлей с рамкой сканирования
          Center(
            child: Container(
              width: 300,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // Статус сканирования
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _scanStatus,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Индикатор загрузки
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: OutlinedButton.icon(
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/refrigerator/add-product');
          },
          icon: const Icon(Icons.edit),
          label: const Text('Ввести вручную'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}