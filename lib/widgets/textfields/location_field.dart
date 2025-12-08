import 'package:flutter/material.dart';
import '../../controllers/location_controller.dart';
import '../map_widget.dart';
import '../coordinate_picker.dart';
import 'package:latlong2/latlong.dart';

class LocationField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;

  const LocationField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.validator,
  });

  @override
  State<LocationField> createState() => _LocationFieldState();
}

class _LocationFieldState extends State<LocationField> {
  List<Map<String, dynamic>> _suggestions = [];
  bool _showSuggestions = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(25),
          ),
          child: TextFormField(
            controller: widget.controller,
            validator: widget.validator,
            onChanged: _onTextChanged,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: Icon(widget.icon, color: Colors.grey),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.map, color: Colors.deepPurple),
                    onPressed: () => _showMapDialog(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.gps_fixed, color: Colors.deepPurple),
                    onPressed: () => _showCoordinateDialog(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.my_location, color: Colors.deepPurple),
                    onPressed: () {
                      if (widget.controller.text.isEmpty) {
                        widget.controller.text = "Enter city name";
                      }
                      _searchLocation();
                    },
                  ),
                ],
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.deepPurple),
                  title: Text(suggestion['display_name'] ?? ''),
                  onTap: () => _selectLocation(suggestion),
                );
              },
            ),
          ),
      ],
    );
  }

  void _onTextChanged(String value) {
    if (value.length > 2) {
      _searchLocation();
    } else {
      setState(() {
        _showSuggestions = false;
        _suggestions = [];
      });
    }
  }

  void _searchLocation() async {
    final query = widget.controller.text.trim();
    if (query.isEmpty) {
      widget.controller.text = "Davao City, Philippines";
      return;
    }
    
    final results = await LocationController.searchLocation(query);
    final suggestions = results.map((location) => {
      'display_name': location.displayName,
      'lat': location.latitude,
      'lon': location.longitude,
    }).toList();
    setState(() {
      _suggestions = suggestions.take(5).toList();
      _showSuggestions = results.isNotEmpty;
    });
  }

  void _selectLocation(Map<String, dynamic> location) {
    widget.controller.text = location['display_name'] ?? '';
    setState(() {
      _showSuggestions = false;
      _suggestions = [];
    });
  }

  void _showMapDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.map, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text('Select Location'),
          ],
        ),
        content: SizedBox(
          width: 400,
          height: 450,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'If map tiles are blocked, offline mode will activate automatically',
                        style: TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: MapWidget(
                  onLocationSelected: (LatLng location) {
                    widget.controller.text = '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showCoordinateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.gps_fixed, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text('Enter Coordinates'),
          ],
        ),
        content: CoordinatePicker(
          onLocationSelected: (lat, lng) {
            widget.controller.text = '$lat, $lng';
            Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}