import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../navigate/main_navigation.dart';

class CompanyInfoPage extends StatefulWidget {
  final String userId;
  final String phoneNumber;
  final String bio;
  
  const CompanyInfoPage({
    super.key,
    required this.userId,
    required this.phoneNumber,
    required this.bio,
  });

  @override
  State<CompanyInfoPage> createState() => _CompanyInfoPageState();
}

class _CompanyInfoPageState extends State<CompanyInfoPage> {
  final _companyController = TextEditingController();
  final _positionController = TextEditingController();
  bool _isWorkingAtCompany = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Information'),
        backgroundColor: const Color(0xFF6A5AE0),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you currently working?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('I am currently employed'),
                      value: _isWorkingAtCompany,
                      onChanged: (value) {
                        setState(() {
                          _isWorkingAtCompany = value;
                        });
                      },
                      activeThumbColor: const Color(0xFF6A5AE0),
                    ),
                    
                    if (_isWorkingAtCompany) ...[
                      const SizedBox(height: 20),
                      TextField(
                        controller: _companyController,
                        decoration: InputDecoration(
                          labelText: 'Company Name',
                          prefixIcon: const Icon(Icons.business),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: _positionController,
                        decoration: InputDecoration(
                          labelText: 'Position/Role',
                          prefixIcon: const Icon(Icons.work),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const Spacer(),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _continue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isLoading ? Colors.grey : const Color(0xFF6A5AE0),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Continue', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _continue() async {
    setState(() => _isLoading = true);
    
    try {
      final profileData = {
        'phoneNumber': widget.phoneNumber,
        'bio': widget.bio,
        'isWorkingAtCompany': _isWorkingAtCompany,
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_isWorkingAtCompany) {
        profileData['companyName'] = _companyController.text.trim();
        profileData['position'] = _positionController.text.trim();
        profileData['useCompanyName'] = false; // Default to showing personal name
      } else {
        profileData['useCompanyName'] = false;
      }

      // Update with timeout
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update(profileData)
          .timeout(const Duration(seconds: 10));

      // Profile is complete when we reach this point

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}