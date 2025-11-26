import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CustomMarkerGenerator {
  static Future<BitmapDescriptor> createProfileMarker({
    required String initials,
    required Color statusColor,
    required Color backgroundColor,
    double size = 120,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..isAntiAlias = true;

    // Draw outer status ring
    paint.color = statusColor;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2,
      paint,
    );

    // Draw white ring
    paint.color = Colors.white;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      (size / 2) - 4,
      paint,
    );

    // Draw profile circle
    paint.color = backgroundColor;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      (size / 2) - 8,
      paint,
    );

    // Draw initials
    final textPainter = TextPainter(
      text: TextSpan(
        text: initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.35,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    final textOffset = Offset(
      (size - textPainter.width) / 2,
      (size - textPainter.height) / 2,
    );
    textPainter.paint(canvas, textOffset);

    // Convert to image
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }

  static Future<BitmapDescriptor> createCurrentUserMarker({
    required String initials,
    double size = 140,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..isAntiAlias = true;

    // Draw outer blue ring (current user indicator)
    paint.color = const Color(0xFF2196F3);
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2,
      paint,
    );

    // Draw white ring
    paint.color = Colors.white;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      (size / 2) - 6,
      paint,
    );

    // Draw profile circle with gradient effect
    final gradient = ui.Gradient.linear(
      Offset(0, 0),
      Offset(size, size),
      [const Color(0xFF1976D2), const Color(0xFF42A5F5)],
    );
    paint.shader = gradient;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      (size / 2) - 12,
      paint,
    );

    // Draw initials
    final textPainter = TextPainter(
      text: TextSpan(
        text: initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.3,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    final textOffset = Offset(
      (size - textPainter.width) / 2,
      (size - textPainter.height) / 2,
    );
    textPainter.paint(canvas, textOffset);

    // Convert to image
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return const Color(0xFF4CAF50); // Green
      case 'busy':
        return const Color(0xFFF44336); // Red
      case 'away':
        return const Color(0xFFFF9800); // Orange
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  static Color getProfileColor(String name) {
    // Generate a consistent color based on the name
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFFEC4899), // Pink
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF10B981), // Emerald
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFEF4444), // Red
      const Color(0xFF84CC16), // Lime
    ];
    
    final hash = name.hashCode;
    return colors[hash.abs() % colors.length];
  }
}
