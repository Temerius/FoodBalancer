
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../repositories/data_repository.dart';
import '../../services/barcode_service.dart';
import '../refrigerator/add_product_screen.dart'; 

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
  late BarcodeService _barcodeService;
  DataRepository? _dataRepository;

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    _dataRepository = Provider.of<DataRepository>(context, listen: false);
    _barcodeService = BarcodeService(apiService: _dataRepository!.apiService);
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

      
      final String? barcodeData = barcode.rawValue;

      print('\n===== BARCODE DETECTED =====');
      print('Type: ${barcode.type}');
      print('Format: ${barcode.format}');
      print('Raw Value: $barcodeData');

      if (barcodeData != null) {
        
        controller.stop();
        setState(() {
          _scanStatus = 'Штрих-код распознан';
        });

        if (mounted) {
          
          _showScannedBarcodeDialog(barcodeData);
        }
      }
    }

    setState(() {
      _isProcessing = false;
    });
  }

  
  void _showScannedBarcodeDialog(String barcode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Штрих-код отсканирован'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Выберите действие для штрих-кода:'),
            const SizedBox(height: 16),
            Text(
              barcode,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              
              controller.start();
              setState(() {
                _scanStatus = 'Наведите камеру на штрих-код продукта';
              });
            },
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _scanStatus = 'Обработка штрих-кода...';
              });
              
              _processBarcodeWithOurAPI(barcode);
            },
            child: const Text('Обработать'),
          ),
        ],
      ),
    );
  }

  Future<void> _processBarcodeWithOurAPI(String barcode) async {
    try {
      setState(() {
        _isProcessing = true;
        _scanStatus = 'Поиск информации о продукте...';
      });

      print('\n===== PROCESSING BARCODE WITH OUR API =====');
      print('Sending barcode to server: $barcode');

      
      _showLoadingDialog('Запрос обрабатывается. Это может занять до 20 секунд...');

      
      final productData = await _barcodeService.fetchProductByBarcode(barcode);

      
      if (mounted) {
        Navigator.pop(context);
      }

      
      print('\n===== SERVER RESPONSE =====');
      if (productData != null) {
        print('Response received successfully!');
        print('Product name: ${productData['name'] ?? "Not available"}');
        print('Product weight: ${productData['weight'] ?? "Not available"}');
        print('Calories: ${productData['calories'] ?? "Not available"}');
        print('Protein: ${productData['protein'] ?? "Not available"}');
        print('Fat: ${productData['fat'] ?? "Not available"}');
        print('Carbs: ${productData['carbs'] ?? "Not available"}');

        
        if (productData.containsKey('classification')) {
          final classification = productData['classification'];
          print('Classification:');
          print('  - Type ID: ${classification['ingredient_type_id'] ?? "None"}');
          print('  - Type name: ${classification['ingredient_type_name'] ?? "None"}');
          print('  - Allergen IDs: ${classification['allergen_ids'] ?? "[]"}');
          print('  - Allergen names: ${classification['allergen_names'] ?? "[]"}');
        } else {
          print('No classification data available');
        }

        
        print('Store: ${productData['store'] ?? "Not available"}');

        setState(() {
          _scanStatus = 'Товар найден!';
        });

        
        await Future.delayed(const Duration(seconds: 1));

        
        final formattedData = _barcodeService.formatProductData(productData);
        formattedData['barcode'] = barcode;

        print('\n===== FORMATTED DATA =====');
        formattedData.forEach((key, value) {
          print('$key: $value');
        });

        
        _goToAddProductWithData({
          'scanned_data': formattedData,
          'barcode': barcode,
        });
      } else {
        print('No product data received from server');
        
        setState(() {
          _scanStatus = 'Продукт не найден';
        });
        _showBarcodeInfo(barcode);
      }
    } catch (e) {
      
      if (mounted) {
        Navigator.pop(context);
      }

      print('\n===== ERROR PROCESSING BARCODE =====');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stacktrace:');
      print(StackTrace.current);

      if (mounted) {
        setState(() {
          _scanStatus = 'Ошибка поиска продукта';
        });

        
        if (e.toString().contains('TimeoutException')) {
          _showTimeoutErrorDialog(barcode);
        } else {
          _showBarcodeInfo(barcode);
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          
          controller.start();
        });
      }
    }
  }

  
  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        );
      },
    );
  }

  
  void _showTimeoutErrorDialog(String barcode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Превышено время ожидания'),
          content: const Text(
              'Сервер не успел обработать запрос в отведенное время. '
                  'Это может быть вызвано повышенной нагрузкой или сложностью обработки данного штрих-кода.'
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showBarcodeInfo(barcode);
              },
              child: const Text('Понятно'),
            ),
          ],
        );
      },
    );
  }

  void _goToAddProductWithData(Map<String, dynamic> data) {
    if (mounted) {
      print('\n===== NAVIGATING TO ADD_PRODUCT_SCREEN =====');
      print('Data being passed: $data');

      
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddProductScreen(),
          settings: RouteSettings(
            arguments: data,
          ),
        ),
      );
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
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      
                      _processBarcodeWithOurAPI(barcode);
                    },
                    child: const Text('Повторить поиск'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddProductScreen(),
                          settings: RouteSettings(
                            arguments: {'barcode': barcode},
                          ),
                        ),
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
          
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),

          
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
            
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddProductScreen(),
              ),
            );
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