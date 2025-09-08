import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ThemeSwitcher extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onThemeChanged;

  const ThemeSwitcher({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            // Theme Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: AppTheme.primaryColor,
                size: 28,
              ),
            ),

            const SizedBox(width: 20),

            // Theme Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Тема додатку',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isDarkMode ? 'Темна тема активна' : 'Світла тема активна',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            // Switch
            Switch(
              value: isDarkMode,
              onChanged: (value) => onThemeChanged(),
              activeColor: AppTheme.primaryColor,
              activeTrackColor: AppTheme.primaryColor.withOpacity(0.3),
              inactiveThumbColor: AppTheme.secondaryColor,
              inactiveTrackColor: AppTheme.secondaryColor.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }
}
