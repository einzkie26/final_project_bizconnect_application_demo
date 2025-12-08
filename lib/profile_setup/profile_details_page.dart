import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'company_info_page.dart';

class ProfileDetailsPage extends StatefulWidget {
  final String userId;
  
  const ProfileDetailsPage({super.key, required this.userId});

  @override
  State<ProfileDetailsPage> createState() => _ProfileDetailsPageState();
}

class _ProfileDetailsPageState extends State<ProfileDetailsPage> {
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  Uint8List? _profileImageBytes;
  bool _isUploading = false;
  bool _hasError = false;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Setup'),
        backgroundColor: const Color(0xFF6A5AE0),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Complete Your Profile',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            
            GestureDetector(
              onTap: _selectProfilePicture,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: _profileImageBytes != null ? Colors.green[100] : Colors.grey[300],
                    backgroundImage: _profileImageBytes != null ? MemoryImage(_profileImageBytes!) : null,
                    child: _profileImageBytes == null ? const Icon(
                      Icons.add_a_photo,
                      size: 40,
                      color: Colors.grey,
                    ) : null,
                  ),
                  if (_profileImageBytes == null)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Text('*', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _profileImageBytes != null ? 'Profile picture selected' : 'Tap to add profile picture *',
              style: TextStyle(color: _profileImageBytes != null ? Colors.green : Colors.red),
            ),
            
            const SizedBox(height: 30),
            
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number *',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                errorText: _phoneController.text.isEmpty ? 'Required' : null,
              ),
              keyboardType: TextInputType.phone,
              onChanged: (value) => setState(() {}),
            ),
            
            const SizedBox(height: 20),
            
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Bio *',
                prefixIcon: const Icon(Icons.info),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                hintText: 'Tell us about yourself...',
                errorText: _bioController.text.isEmpty ? 'Required' : null,
              ),
              onChanged: (value) => setState(() {}),
            ),
            
            const Spacer(),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canContinue() && !_isUploading ? _continue : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canContinue() && !_isUploading ? const Color(0xFF6A5AE0) : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isUploading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Continue', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canContinue() {
    return _profileImageBytes != null && 
           _phoneController.text.isNotEmpty && 
           _bioController.text.isNotEmpty;
  }

  Future<void> _selectProfilePicture() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _profileImageBytes = bytes;
      });
    }
  }

  Future<void> _continue() async {
    if (!_canContinue()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
      return;
    }
    
    setState(() {
      _isUploading = true;
      _hasError = false;
    });
    
    try {
      // Upload profile picture
      String? profilePicUrl;
      if (_profileImageBytes != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_pictures')
            .child('${widget.userId}.jpg');
        await ref.putData(_profileImageBytes!);
        profilePicUrl = await ref.getDownloadURL();
      }
      
      // Update user document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'phoneNumber': _phoneController.text.trim(),
        'bio': _bioController.text.trim(),
        'profilePicUrl': profilePicUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CompanyInfoPage(
              userId: widget.userId,
              phoneNumber: _phoneController.text,
              bio: _bioController.text,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _hasError = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }
}