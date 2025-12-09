import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CreateCompanyPage extends StatefulWidget {
  const CreateCompanyPage({super.key});

  @override
  State<CreateCompanyPage> createState() => _CreateCompanyPageState();
}

class _CreateCompanyPageState extends State<CreateCompanyPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;
  
  final _nameController = TextEditingController();
  final _customIndustryController = TextEditingController();
  final _customPositionController = TextEditingController();
  final _idController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? _selectedIndustry;
  String? _selectedPosition;
  LatLng? _selectedLocation;
  final MapController _mapController = MapController();
  final LatLng _philippinesCenter = const LatLng(12.8797, 121.7740);
  
  final List<String> _industries = [
    'Technology', 'Healthcare', 'Finance', 'Education', 'Retail',
    'Manufacturing', 'Construction', 'Transportation', 'Food & Beverage',
    'Entertainment', 'Real Estate', 'Agriculture', 'Tourism', 'Other'
  ];
  
  final List<String> _positions = [
    'CEO', 'Manager', 'Director', 'Supervisor', 'Team Lead',
    'Owner', 'Founder', 'President', 'Vice President', 'Other'
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }
    
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildProfileIncompleteScreen();
        }
        
        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final hasPhone = userData['phoneNumber']?.toString().isNotEmpty == true;
        final hasBio = userData['bio']?.toString().isNotEmpty == true;
        final hasProfilePic = userData['profilePicUrl']?.toString().isNotEmpty == true;
        
        if (!hasPhone || !hasBio || !hasProfilePic) {
          return _buildProfileIncompleteScreen();
        }
        
        return _buildCreateCompanyScreen();
      },
    );
  }
  
  Widget _buildProfileIncompleteScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Company'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 80, color: Colors.orange),
              const SizedBox(height: 24),
              const Text(
                'Complete Your Profile First',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
              ),
              const SizedBox(height: 16),
              const Text(
                'You need to complete your profile with phone number, bio, and profile picture before you can create a company.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Go Back to Profile', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildCreateCompanyScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Company'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildStepIndicator(0, 'Basic Info'),
                    _buildStepConnector(),
                    _buildStepIndicator(1, 'Location'),
                    _buildStepConnector(),
                    _buildStepIndicator(2, 'Details'),
                  ],
                ),
              ),
              
              Expanded(
                child: IndexedStack(
                  index: _currentPage,
                  children: [
                    _buildBasicInfoPage(),
                    _buildLocationPage(),
                    _buildDetailsPage(),
                  ],
                ),
              ),
              
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentPage > 0)
                      ElevatedButton(
                        onPressed: () => setState(() => _currentPage--),
                        child: const Text('Previous'),
                      )
                    else
                      const SizedBox(),
                    
                    ElevatedButton(
                      onPressed: () {
                        if (_currentPage >= 2) {
                          _createCompany();
                        } else {
                          setState(() {
                            _currentPage++;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                      child: Text(
                        _currentPage == 2 ? 'Create Company' : 'Next',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = step <= _currentPage;
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isActive ? Colors.deepPurple : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${step + 1}',
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? Colors.deepPurple : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector() {
    return Container(
      height: 2,
      width: 40,
      color: Colors.grey[300],
      margin: const EdgeInsets.only(bottom: 20),
    );
  }

  Widget _buildBasicInfoPage() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Basic Company Information', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Company Name *',
              prefixIcon: Icon(Icons.business),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            initialValue: _selectedIndustry,
            decoration: const InputDecoration(
              labelText: 'Industry *',
              prefixIcon: Icon(Icons.category),
              border: OutlineInputBorder(),
            ),
            items: _industries.map((industry) => DropdownMenuItem(
              value: industry,
              child: Text(industry),
            )).toList(),
            onChanged: (value) => setState(() => _selectedIndustry = value),
          ),
          
          if (_selectedIndustry == 'Other') ...[
            const SizedBox(height: 16),
            TextField(
              controller: _customIndustryController,
              decoration: const InputDecoration(
                labelText: 'Specify Industry *',
                prefixIcon: Icon(Icons.edit),
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            initialValue: _selectedPosition,
            decoration: const InputDecoration(
              labelText: 'Your Position *',
              prefixIcon: Icon(Icons.work),
              border: OutlineInputBorder(),
            ),
            items: _positions.map((position) => DropdownMenuItem(
              value: position,
              child: Text(position),
            )).toList(),
            onChanged: (value) => setState(() => _selectedPosition = value),
          ),
          
          if (_selectedPosition == 'Other') ...[
            const SizedBox(height: 16),
            TextField(
              controller: _customPositionController,
              decoration: const InputDecoration(
                labelText: 'Specify Position *',
                prefixIcon: Icon(Icons.edit),
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          
          TextField(
            controller: _idController,
            decoration: const InputDecoration(
              labelText: 'Your ID Number *',
              prefixIcon: Icon(Icons.badge),
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPage() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Company Location', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          
          TextField(
            controller: _addressController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Complete Address *',
              prefixIcon: Icon(Icons.location_on),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _philippinesCenter,
                initialZoom: 6.0,
                onTap: (tapPosition, point) {
                  setState(() {
                    _selectedLocation = point;
                  });
                  _getAddressFromCoordinates(point);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                if (_selectedLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selectedLocation!,
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap on the map to pin your exact location',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsPage() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Company Details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _generateDescription,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Auto-Generate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _descriptionController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Company Description *',
              prefixIcon: Icon(Icons.description),
              border: OutlineInputBorder(),
              hintText: 'Describe your company...',
            ),
          ),
        ],
      ),
    );
  }
  
  void _generateDescription() {
    final industry = _selectedIndustry == 'Other' ? _customIndustryController.text : _selectedIndustry;
    
    String description = 'Welcome to ${_nameController.text}, ';
    
    if (industry != null && industry.isNotEmpty) {
      description += 'a leading company in the $industry industry. ';
    }
    
    description += 'Located in the Philippines, we are committed to delivering exceptional services and building strong partnerships with our clients.';
    
    setState(() {
      _descriptionController.text = description;
    });
  }

  Future<void> _createCompany() async {
    if (!_validateCurrentPage()) return;
    
    setState(() => _isLoading = true);
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError('Please log in to create a company');
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      final industry = _selectedIndustry == 'Other' ? _customIndustryController.text : _selectedIndustry!;
      
      final companyData = {
        'name': _nameController.text.trim(),
        'industry': industry.trim(),
        'description': _descriptionController.text.trim(),
        'ownerId': user.uid,
        'memberIds': [user.uid],
        'createdAt': DateTime.now(),
        'address': _addressController.text.trim(),
        'latitude': _selectedLocation?.latitude,
        'longitude': _selectedLocation?.longitude,
      };
      
      final companyRef = await FirebaseFirestore.instance.collection('companies').add(companyData);
      
      final position = _selectedPosition == 'Other' ? _customPositionController.text : _selectedPosition!;
      await FirebaseFirestore.instance
          .collection('company_members')
          .doc('${companyRef.id}_${user.uid}')
          .set({
        'companyId': companyRef.id,
        'userId': user.uid,
        'position': position,
        'buildingNo': '',
        'idNumber': _idController.text.trim(),
        'joinedAt': DateTime.now(),
      });
      
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company created successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
      
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Error: ${e.toString()}');
      }
    }
  }

  Future<void> _getAddressFromCoordinates(LatLng point) async {
    try {
      final url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}&zoom=18&addressdetails=1';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['display_name'] ?? 'Address not found';
        
        setState(() {
          _addressController.text = address;
        });
      }
    } catch (e) {
      setState(() {
        _addressController.text = 'Unable to get address';
      });
    }
  }

  bool _validateCurrentPage() {
    switch (_currentPage) {
      case 0:
        if (_nameController.text.trim().isEmpty) {
          _showError('Company name is required');
          return false;
        }
        if (_selectedIndustry == null) {
          _showError('Please select an industry');
          return false;
        }
        if (_selectedIndustry == 'Other' && _customIndustryController.text.trim().isEmpty) {
          _showError('Please specify the industry');
          return false;
        }
        if (_selectedPosition == null) {
          _showError('Please select your position');
          return false;
        }
        if (_selectedPosition == 'Other' && _customPositionController.text.trim().isEmpty) {
          _showError('Please specify your position');
          return false;
        }
        if (_idController.text.trim().isEmpty) {
          _showError('ID number is required');
          return false;
        }
        break;
      case 1:
        if (_addressController.text.trim().isEmpty) {
          _showError('Address is required');
          return false;
        }
        break;
      case 2:
        if (_descriptionController.text.trim().isEmpty) {
          _showError('Company description is required');
          return false;
        }
        break;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _customIndustryController.dispose();
    _customPositionController.dispose();
    _idController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}