import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CoordinatePicker extends StatefulWidget {
  final Function(double lat, double lng)? onLocationSelected;

  const CoordinatePicker({
    super.key,
    this.onLocationSelected,
  });

  @override
  State<CoordinatePicker> createState() => _CoordinatePickerState();
}

class _CoordinatePickerState extends State<CoordinatePicker> {
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(Icons.gps_fixed, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text(
                'Enter Coordinates',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _latController,
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    hintText: '7.0731',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _lngController,
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    hintText: '125.6128',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _setDavaoCity,
                  icon: const Icon(Icons.location_city),
                  label: const Text('Davao City'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _setManila,
                  icon: const Icon(Icons.location_city),
                  label: const Text('Manila'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectCoordinates,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Use These Coordinates'),
            ),
          ),
        ],
      ),
    );
  }

  void _setDavaoCity() {
    _latController.text = '7.0731';
    _lngController.text = '125.6128';
  }

  void _setManila() {
    _latController.text = '14.5995';
    _lngController.text = '120.9842';
  }

  void _selectCoordinates() {
    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);
    
    if (lat != null && lng != null) {
      if (lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
        widget.onLocationSelected?.call(lat, lng);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid coordinates. Latitude: -90 to 90, Longitude: -180 to 180'),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid numbers for both latitude and longitude'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }
}