import 'package:flutter/material.dart';
import '../config/theme.dart';

class LogoWidget extends StatelessWidget {
  final double size;
  final bool withText;

  const LogoWidget({
    Key? key,
    this.size = 80,
    this.withText = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              Icons.restaurant,
              color: Colors.white,
              size: size * 0.6,
            ),
          ),
        ),
        if (withText) ...[
          SizedBox(height: 16),
          Text(
            'CookHelper',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Ваш умный помощник на кухне',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}