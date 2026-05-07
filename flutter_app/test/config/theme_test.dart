import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barfliz/config/theme.dart';

void main() {
  group('AppTheme', () {
    test('brand pink primary color is correct hex', () {
      expect(AppTheme.primaryColor, const Color(0xFFE91E63));
    });

    test('secondary color is a darker pink', () {
      expect(AppTheme.secondaryColor, const Color(0xFFC2185B));
    });

    test('error color is red', () {
      expect(AppTheme.errorColor, const Color(0xFFD32F2F));
    });

    test('success color is green', () {
      expect(AppTheme.successColor, const Color(0xFF4CAF50));
    });

    test('dark background is a dark navy', () {
      expect(AppTheme.darkBackgroundColor, const Color(0xFF0F1219));
    });

    group('lightTheme', () {
      test('is a valid ThemeData', () {
        expect(AppTheme.lightTheme, isA<ThemeData>());
      });

      test('uses Material 3', () {
        expect(AppTheme.lightTheme.useMaterial3, isTrue);
      });

      test('primary color matches brand pink', () {
        expect(AppTheme.lightTheme.colorScheme.primary, AppTheme.primaryColor);
      });

      test('brightness is light', () {
        expect(AppTheme.lightTheme.brightness, Brightness.light);
      });

      test('elevated button has brand pink background', () {
        final style = AppTheme.lightTheme.elevatedButtonTheme.style;
        expect(style, isNotNull);
        final bgColor = style!.backgroundColor?.resolve({});
        expect(bgColor, AppTheme.primaryColor);
      });

      test('error color is set in colorScheme', () {
        expect(AppTheme.lightTheme.colorScheme.error, AppTheme.errorColor);
      });
    });

    group('darkTheme', () {
      test('is a valid ThemeData', () {
        expect(AppTheme.darkTheme, isA<ThemeData>());
      });

      test('uses Material 3', () {
        expect(AppTheme.darkTheme.useMaterial3, isTrue);
      });

      test('brightness is dark', () {
        expect(AppTheme.darkTheme.brightness, Brightness.dark);
      });

      test('primary color matches brand pink', () {
        expect(AppTheme.darkTheme.colorScheme.primary, AppTheme.primaryColor);
      });

      test('scaffold background is dark navy', () {
        expect(
          AppTheme.darkTheme.scaffoldBackgroundColor,
          AppTheme.darkBackgroundColor,
        );
      });

      test('surface is dark surface color', () {
        expect(
          AppTheme.darkTheme.colorScheme.surface,
          AppTheme.darkSurfaceColor,
        );
      });
    });

    test('light and dark themes are distinct', () {
      expect(
        AppTheme.lightTheme.brightness,
        isNot(AppTheme.darkTheme.brightness),
      );
      expect(
        AppTheme.lightTheme.scaffoldBackgroundColor,
        isNot(AppTheme.darkTheme.scaffoldBackgroundColor),
      );
    });
  });
}
