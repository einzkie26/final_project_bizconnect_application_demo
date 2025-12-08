import 'package:flutter/material.dart';
import 'widgets/map_widget.dart';
import 'package:latlong2/latlong.dart';

class TestMapPage extends StatefulWidget {
  const TestMapPage({super.key});

  @override
  State<TestMapPage> createState() => _TestMapPageState();
}

class _TestMapPageState extends State<TestMapPage> {
  LatLng? selectedLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Test'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'OpenStreetMap Test',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: MapWidget(
                latitude: 7.0731,
                longitude: 125.6128,
                onLocationSelected: (location) {
                  setState(() {
                    selectedLocation = location;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            if (selectedLocation != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Selected: ${selectedLocation!.latitude.toStringAsFixed(4)}, ${selectedLocation!.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
          ],
        ),
      ),
    );
  }
}