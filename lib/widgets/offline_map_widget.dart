import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class OfflineMapWidget extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final Function(LatLng)? onLocationSelected;

  const OfflineMapWidget({
    super.key,
    this.latitude,
    this.longitude,
    this.onLocationSelected,
  });

  @override
  State<OfflineMapWidget> createState() => _OfflineMapWidgetState();
}

class _OfflineMapWidgetState extends State<OfflineMapWidget> {
  LatLng? _selectedLocation;
  Offset? _selectedOffset;

  @override
  void initState() {
    super.initState();
    if (widget.latitude != null && widget.longitude != null) {
      _selectedLocation = LatLng(widget.latitude!, widget.longitude!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.grey.shade100,
      ),
      child: Stack(
        children: [
          // Grid background to simulate map
          CustomPaint(
            size: const Size(double.infinity, 300),
            painter: GridPainter(),
          ),
          // Tap detector
          GestureDetector(
            onTapDown: (details) {
              if (widget.onLocationSelected != null) {
                setState(() {
                  _selectedOffset = details.localPosition;
                  // Convert tap position to approximate coordinates
                  final lat = 7.0731 + (150 - details.localPosition.dy) * 0.001;
                  final lng = 125.6128 + (details.localPosition.dx - 200) * 0.001;
                  _selectedLocation = LatLng(lat, lng);
                });
                widget.onLocationSelected!(_selectedLocation!);
              }
            },
            child: Container(
              width: double.infinity,
              height: 300,
              color: Colors.transparent,
            ),
          ),
          // Selected location marker
          if (_selectedOffset != null)
            Positioned(
              left: _selectedOffset!.dx - 20,
              top: _selectedOffset!.dy - 40,
              child: const Icon(
                Icons.location_pin,
                color: Colors.red,
                size: 40,
              ),
            ),
          // Info overlay
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Offline Map Mode',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Tap to select location',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          // Coordinates display
          if (_selectedLocation != null)
            Positioned(
              bottom: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Lat: ${_selectedLocation!.latitude.toStringAsFixed(4)}\nLng: ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    // Draw grid lines
    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Draw some "roads" to make it look more map-like
    final roadPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 3;

    canvas.drawLine(
      Offset(size.width * 0.2, 0),
      Offset(size.width * 0.2, size.height),
      roadPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.3),
      Offset(size.width, size.height * 0.3),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, 0),
      Offset(size.width * 0.7, size.height),
      roadPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.7),
      Offset(size.width, size.height * 0.7),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}