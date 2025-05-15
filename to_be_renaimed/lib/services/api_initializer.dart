
import 'package:flutter/material.dart';
import 'api_test_service.dart';

class AppInitializer {
  static bool _testsRun = false;

  static Future<void> runApiTests(BuildContext context) async {
    if (_testsRun) return; 

    _testsRun = true;

    
    final apiTestService = ApiTestService(baseUrl: 'http://192.168.151.120:8000');

    
    final logs = await apiTestService.runAllTests();

    
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('API Test Results'),
          content: Container(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                Color textColor = Colors.black;

                if (log.contains('===')) {
                  textColor = Colors.blue;
                } else if (log.contains('✅')) {
                  textColor = Colors.green;
                } else if (log.contains('❌')) {
                  textColor = Colors.red;
                }

                return Text(
                  log,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        ),
      );
    }
  }
}