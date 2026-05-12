import 'package:flutter/material.dart';

class MobileConfig {
  // Device detection
  static const bool isMobile = true;
  static const bool isTablet = false;
  
  // Screen dimensions for mobile design
  static const double defaultPadding = 16.0;
  static const double cardMargin = 12.0;
  static const double borderRadius = 12.0;
  
  // Mobile-specific settings
  static const double maxContentWidth = 400.0;
  static const double minButtonHeight = 48.0;
  static const double maxButtonWidth = double.infinity;
  
  // Mobile navigation
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Curve animationCurve = Curves.easeInOut;
  
  // Mobile text sizes
  static const double headingFontSize = 20.0;
  static const double subheadingFontSize = 16.0;
  static const double bodyFontSize = 14.0;
  static const double captionFontSize = 12.0;
  
  // Mobile spacing
  static const double smallSpacing = 8.0;
  static const double mediumSpacing = 16.0;
  static const double largeSpacing = 24.0;
  
  // Mobile colors (can be customized)
  static const Color primaryColor = Color(0xFF1976D2);
  static const Color accentColor = Color(0xFF42A5F5);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  
  // Mobile breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  
  // Check if device is mobile
  static bool isMobileDevice(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width < mobileBreakpoint;
  }
  
  // Check if device is tablet
  static bool isTabletDevice(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width >= mobileBreakpoint && size.width < tabletBreakpoint;
  }
  
  // Get responsive font size
  static double getResponsiveFontSize(BuildContext context, double mobileSize) {
    if (isTabletDevice(context)) {
      return mobileSize * 1.2;
    }
    return mobileSize;
  }
  
  // Mobile input decoration
  static InputDecoration mobileInputDecoration({
    String? hintText,
    IconData? prefixIcon,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
      errorText: errorText,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: Color(0xFFE0E0E)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }
  
  // Mobile button style
  static ButtonStyle mobileButtonStyle({
    Color backgroundColor = primaryColor,
    Color textColor = Colors.white,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: textColor,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      minimumSize: const Size(double.infinity, minButtonHeight),
    );
  }
  
  // Mobile card decoration
  static BoxDecoration mobileCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          spreadRadius: 1,
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
