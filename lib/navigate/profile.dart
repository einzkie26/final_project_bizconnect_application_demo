import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/profile_controller.dart';
import '../controllers/user_controller.dart';
import '../models/company_model.dart';
import '../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'create_company_page.dart';
import 'company_details_page.dart';
import 'user_details_page.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';


class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _isEditingBio = false;
  final _bioController = TextEditingController();
  List<CompanyModel> _userCompanies = [];
  String? _selectedCompanyId;
  bool _isPersonalMode = true;
  DateTime? _lastInviteTime;
  
  @override
  void initState() {
    super.initState();
    _setupStreams();
  }
  
  void _setupStreams() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    FirebaseFirestore.instance
        .collection('companies')
        .where('memberIds', arrayContains: user.uid)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _userCompanies = snapshot.docs
              .map((doc) => CompanyModel.fromMap(doc.data(), doc.id))
              .toList();
        });
      }
    });
    
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((userDoc) {
      if (mounted && userDoc.exists) {
        final userData = userDoc.data()!;
        final isCompanyMode = userData['isCompanyMode'] ?? false;
        final activeCompanyId = userData['activeCompanyId'];
        
        setState(() {
          _isPersonalMode = _userCompanies.isEmpty || !isCompanyMode;
          _selectedCompanyId = activeCompanyId;
          
          if (_userCompanies.isNotEmpty && activeCompanyId == null && isCompanyMode) {
            _isPersonalMode = true;
          }
        });
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(profileControllerProvider);
    
    if (userProfile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: _userCompanies.isNotEmpty ? () => _toggleMode(!_isPersonalMode) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _isPersonalMode
                          ? [
                              Colors.deepPurple.withOpacity(0.8),
                              Colors.purple.withOpacity(0.6),
                            ]
                          : [
                              Colors.pink.withOpacity(0.7),
                              Colors.pink[300]!.withOpacity(0.5),
                            ],
                    ),
                  ),
                  child: Column(
                    children: [
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 16),
                          child: Text(
                            'Profile',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _isPersonalMode ? Colors.deepPurple : Colors.pink[200],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Row(
                                key: ValueKey(_isPersonalMode),
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isPersonalMode ? Icons.person : Icons.business,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _isPersonalMode ? 'Personal' : 'Company',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Profile picture
                    _buildProfilePicture(),
                    
                    const SizedBox(height: 16),
                    // Display name
                    Text(
                      _getDisplayName(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getDisplayDetails(),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Company selection section
                    if (!_isPersonalMode) _buildCompanySection(),
                    
                    // Bio section
                    _buildBioSection(userProfile),
                    
                    const SizedBox(height: 16),
                    
                    // Contact information
                    _buildContactSection(userProfile),
                    
                    const SizedBox(height: 16),
                    
                    // Collaborations section
                    if (_isPersonalMode) _buildCollaborationsSection(),
                    
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _userCompanies.length >= 3 ? _showUpgradeDialog : _showAddCompanyDialog,
        backgroundColor: _userCompanies.length >= 3 ? Colors.grey : Colors.deepPurple,
        child: Icon(
          _userCompanies.length >= 3 ? Icons.lock : Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
  
  Widget _buildCompanySection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Company Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (value) {
                  switch (value) {
                    case 'add':
                      _userCompanies.length >= 3 ? _showUpgradeDialog() : _showAddCompanyDialog();
                      break;
                    case 'invite':
                      _showInviteDialog();
                      break;
                    case 'remove':
                      _showRemoveCompanyDialog();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'add',
                    child: Row(
                      children: [
                        Icon(_userCompanies.length >= 3 ? Icons.lock : Icons.add, color: _userCompanies.length >= 3 ? Colors.grey : Colors.deepPurple),
                        const SizedBox(width: 8),
                        Text(_userCompanies.length >= 3 ? 'Upgrade Required' : 'Add Company'),
                      ],
                    ),
                  ),
                  if (_selectedCompanyId != null) ...[
                    const PopupMenuItem(
                      value: 'invite',
                      child: Row(
                        children: [
                          Icon(Icons.person_add, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Invite Member'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'remove',
                      child: FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('companies').doc(_selectedCompanyId).get(),
                        builder: (context, snapshot) {
                          final isOwner = snapshot.data?.data() != null && 
                                         (snapshot.data!.data() as Map<String, dynamic>)['ownerId'] == FirebaseAuth.instance.currentUser?.uid;
                          return Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              const SizedBox(width: 8),
                              Text(isOwner ? 'Remove Company' : 'Leave Company'),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_userCompanies.isNotEmpty) ...[
            DropdownButtonFormField<String>(
              initialValue: _userCompanies.any((c) => c.id == _selectedCompanyId) ? _selectedCompanyId : null,
              decoration: const InputDecoration(
                labelText: 'Select Company',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              items: _userCompanies.map((company) {
                return DropdownMenuItem(
                  value: company.id,
                  child: Text(company.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCompanyId = value;
                });
                _updateActiveCompany(value);
              },
            ),
            const SizedBox(height: 16),
          ],
          
          if (_selectedCompanyId != null) _buildCompanyDetailsForm(),
        ],
      ),
    );
  }
  
  Widget _buildCompanyDetailsForm() {
    return FutureBuilder<List<DocumentSnapshot>>(
      future: Future.wait([
        FirebaseFirestore.instance.collection('companies').doc(_selectedCompanyId).get(),
        FirebaseFirestore.instance.collection('company_members').doc('${_selectedCompanyId}_${FirebaseAuth.instance.currentUser?.uid}').get(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        
        final companyDoc = snapshot.data![0];
        final memberDoc = snapshot.data![1];
        final companyData = companyDoc.data() as Map<String, dynamic>?;
        final memberData = memberDoc.data() as Map<String, dynamic>?;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company Information Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.withOpacity(0.1), Colors.purple.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.deepPurple.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.business, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Company Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Company Name', companyData?['name'] ?? 'N/A', Icons.business_center),
                  _buildInfoRow('Description', companyData?['description'] ?? 'No description', Icons.description),
                  _buildInfoRow('Address', companyData?['address'] ?? 'No address set', Icons.location_on),
                  if (companyData?['latitude'] != null && companyData?['longitude'] != null)
                    Container(
                      height: 200,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(companyData!['latitude'], companyData['longitude']),
                            initialZoom: 15.0,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(companyData['latitude'], companyData['longitude']),
                                  child: const Icon(Icons.location_on, color: Colors.red, size: 30),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  _buildInfoRow('Created', companyData?['createdAt']?.toDate().toString().split(' ')[0] ?? 'N/A', Icons.calendar_today),
                  _buildInfoRow('Total Members', '${companyData?['memberIds']?.length ?? 0}', Icons.group),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Owner Information Section
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(companyData?['ownerId']).get(),
              builder: (context, ownerSnapshot) {
                if (!ownerSnapshot.hasData) return const SizedBox();
                final ownerData = ownerSnapshot.data?.data() as Map<String, dynamic>?;
                
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepPurple.withOpacity(0.08), Colors.purple.withOpacity(0.03)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.deepPurple.withOpacity(0.15)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.shade600,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.person_pin, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Company Owner',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow('Owner Name', ownerData?['name'] ?? 'Not available', Icons.person),
                      _buildInfoRow('Owner Email', ownerData?['email'] ?? 'Not available', Icons.email),
                      _buildInfoRow('Owner Phone', ownerData?['phoneNumber'] ?? 'Not available', Icons.phone),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            
            // Your Role Information Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.withOpacity(0.06), Colors.purple.withOpacity(0.02)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.deepPurple.withOpacity(0.12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade700,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.badge, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Your Role & Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Position', memberData?['position']?.isNotEmpty == true ? memberData!['position'] : (companyData?['ownerId'] == FirebaseAuth.instance.currentUser?.uid ? 'Owner' : 'Collaborator'), Icons.work),
                  _buildInfoRow('ID Number', memberData?['idNumber']?.isNotEmpty == true ? memberData!['idNumber'] : (companyData?['ownerId'] == FirebaseAuth.instance.currentUser?.uid ? 'Owner ID' : 'Not assigned'), Icons.badge),
                  _buildInfoRow('Joined Date', memberData?['joinedAt']?.toDate().toString().split(' ')[0] ?? companyData?['createdAt']?.toDate().toString().split(' ')[0] ?? 'N/A', Icons.calendar_today),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Company Members Section (Only for owners)
            if (companyData?['ownerId'] == FirebaseAuth.instance.currentUser?.uid)
              _buildMembersManagementSection(),
          ],
        );
      },
    );
  }
  
  Widget _buildMembersManagementSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.withOpacity(0.12), Colors.purple.withOpacity(0.06)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade800,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.manage_accounts, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Manage Members',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('company_members')
                .where('companyId', isEqualTo: _selectedCompanyId)
                .get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              
              final members = snapshot.data!.docs;
              if (members.isEmpty) {
                return const Text('No members yet', style: TextStyle(color: Colors.grey));
              }
              
              return Column(
                children: members.map((memberDoc) {
                  final memberData = memberDoc.data() as Map<String, dynamic>;
                  final userId = memberData['userId'];
                  
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData) return const SizedBox();
                      final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.deepPurple.withOpacity(0.1)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurple.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userData?['name'] ?? 'Unknown',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    userData?['email'] ?? 'No email',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      memberData['position']?.isNotEmpty == true ? memberData['position'] : 'Collaborator',
                                      style: TextStyle(color: Colors.deepPurple.shade700, fontSize: 11, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    onPressed: () => _editMember(userId, memberData),
                                    icon: const Icon(Icons.edit, color: Colors.deepPurple, size: 18),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (userId != FirebaseAuth.instance.currentUser?.uid)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      onPressed: () => _kickMember(userId, userData?['name'] ?? 'User'),
                                      icon: const Icon(Icons.remove_circle, color: Colors.red, size: 18),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
  
  void _editMember(String userId, Map<String, dynamic> memberData) {
    final positionController = TextEditingController(text: memberData['position'] ?? '');
    final idController = TextEditingController(text: memberData['idNumber'] ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Member Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: positionController,
              decoration: const InputDecoration(
                labelText: 'Position',
                prefixIcon: Icon(Icons.work),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: idController,
              decoration: const InputDecoration(
                labelText: 'ID Number',
                prefixIcon: Icon(Icons.badge),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _updateMemberDetails(userId, positionController.text, idController.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _updateMemberDetails(String userId, String position, String idNumber) async {
    try {
      await FirebaseFirestore.instance
          .collection('company_members')
          .doc('${_selectedCompanyId}_$userId')
          .update({
        'position': position,
        'idNumber': idNumber,
      });
      
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member details updated'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update member'), backgroundColor: Colors.red),
      );
    }
  }
  
  void _kickMember(String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove $userName from the company?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _removeMemberFromCompany(userId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _removeMemberFromCompany(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('company_members')
          .doc('${_selectedCompanyId}_$userId')
          .delete();
      
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(_selectedCompanyId!)
          .update({
        'memberIds': FieldValue.arrayRemove([userId])
      });
      
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member removed successfully'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to remove member'), backgroundColor: Colors.red),
      );
    }
  }
  
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBioSection(userProfile) {
    // Check if profile is incomplete
    final hasPhone = userProfile.phoneNumber?.isNotEmpty == true;
    final hasBio = userProfile.bio?.isNotEmpty == true;
    final hasProfilePic = userProfile.profilePicUrl?.isNotEmpty == true;
    
    if (!hasPhone || !hasBio || !hasProfilePic) {
      return _buildProfileSetupForm(userProfile, hasPhone, hasBio, hasProfilePic);
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _isEditingBio
              ? Column(
                  children: [
                    TextField(
                      controller: _bioController,
                      maxLines: 3,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Tell us about yourself...',
                        helperText: 'Maximum 500 characters',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => setState(() => _isEditingBio = false),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _saveBio,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                          child: const Text('Save', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                )
              : GestureDetector(
                  onTap: () {
                    setState(() {
                      _isEditingBio = true;
                      _bioController.text = userProfile.bio ?? '';
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      userProfile.bio ?? 'Tap to add bio...',
                      style: TextStyle(
                        fontSize: 14,
                        color: userProfile.bio != null ? Colors.grey[700] : Colors.grey[400],
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _showConnectionsList('connections'),
                  child: FutureBuilder<int>(
                    future: _getConnectionsCount(),
                    builder: (context, snapshot) {
                      return Column(
                        children: [
                          Text(
                            '${snapshot.data ?? 0}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          Text(
                            'Connections',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showConnectionsList('following'),
                  child: FutureBuilder<int>(
                    future: _getFollowingCount(),
                    builder: (context, snapshot) {
                      return Column(
                        children: [
                          Text(
                            '${snapshot.data ?? 0}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          Text(
                            'Following',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showConnectionsList('followers'),
                  child: FutureBuilder<int>(
                    future: _getFollowersCount(),
                    builder: (context, snapshot) {
                      return Column(
                        children: [
                          Text(
                            '${snapshot.data ?? 0}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          Text(
                            'Followers',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildContactSection(userProfile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildContactItem(Icons.email, userProfile.email),
          const SizedBox(height: 12),
          _buildContactItem(Icons.phone, userProfile.phoneNumber ?? 'No phone number'),
          const SizedBox(height: 12),
          _buildContactItem(Icons.location_on, userProfile.location ?? 'No location set'),
        ],
      ),
    );
  }
  
  Widget _buildContactItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.deepPurple),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }
  
  String _getDisplayName() {
    if (_isPersonalMode) {
      final userProfile = ref.read(profileControllerProvider);
      return userProfile?.name ?? 'User';
    } else {
      final selectedCompany = _userCompanies.firstWhere(
        (c) => c.id == _selectedCompanyId,
        orElse: () => CompanyModel(
          id: '',
          name: 'No Company Selected',
          description: '',
          industry: '',
          ownerId: '',
          memberIds: [],
          createdAt: DateTime.now(),
        ),
      );
      return selectedCompany.name;
    }
  }
  
  String _getDisplayDetails() {
    if (_isPersonalMode) {
      final userProfile = ref.read(profileControllerProvider);
      return userProfile?.email ?? '';
    } else {
      return 'Company Profile';
    }
  }
  
  void _toggleMode(bool isPersonal) async {
    if (!isPersonal && _userCompanies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create a company first to switch to company mode'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await ref.read(userControllerProvider).toggleCompanyMode(
          user.uid,
          !isPersonal,
          isPersonal ? null : _selectedCompanyId,
        );
        
        if (mounted) {
          setState(() => _isPersonalMode = isPersonal);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to switch mode'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  Future<void> _updateActiveCompany(String? companyId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await ref.read(userControllerProvider).toggleCompanyMode(
        user.uid,
        !_isPersonalMode,
        companyId,
      );
    }
  }
  

  
  void _showAddCompanyDialog() async {
    if (_userCompanies.length >= 3) {
      _showUpgradeDialog();
      return;
    }
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateCompanyPage(),
      ),
    );
    
    // Data auto-refreshes via stream
  }
  
  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.deepPurple),
            const SizedBox(width: 8),
            const Text('Upgrade Required'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Company Limit Reached (${_userCompanies.length}/3)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('You\'ve reached the maximum number of companies for your current plan.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.withOpacity(0.1), Colors.purple.withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepPurple.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.deepPurple, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Premium Plan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('• Unlimited companies'),
                  const Text('• Advanced member management'),
                  const Text('• Priority support'),
                  const Text('• Analytics dashboard'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSubscriptionOptions();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            child: const Text('Upgrade Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  void _showSubscriptionOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Your Plan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPlanCard('Monthly Premium', '\$9.99/month', 'Best for growing businesses'),
            const SizedBox(height: 12),
            _buildPlanCard('Yearly Premium', '\$99.99/year', 'Save 17% - Most popular', isPopular: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPlanCard(String title, String price, String description, {bool isPopular = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPopular 
            ? [Colors.deepPurple.withOpacity(0.15), Colors.purple.withOpacity(0.08)]
            : [Colors.grey.withOpacity(0.05), Colors.grey.withOpacity(0.02)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPopular ? Colors.deepPurple : Colors.grey.withOpacity(0.3),
          width: isPopular ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isPopular ? Colors.deepPurple : Colors.black87,
                ),
              ),
              if (isPopular)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'POPULAR',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            price,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isPopular ? Colors.deepPurple : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _processPurchase(title);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isPopular ? Colors.deepPurple : Colors.grey[600],
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: Text(
                'Select Plan',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _processPurchase(String planName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.deepPurple),
            const SizedBox(height: 16),
            Text('Processing $planName purchase...'),
          ],
        ),
      ),
    );
    
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$planName activated! You can now create unlimited companies.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }
  

  

  
  void _showInviteDialog() {
    if (_lastInviteTime != null) {
      final cooldownEnd = _lastInviteTime!.add(const Duration(seconds: 20));
      if (DateTime.now().isBefore(cooldownEnd)) {
        final remaining = cooldownEnd.difference(DateTime.now()).inSeconds;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please wait ${remaining}s before sending another invite'), backgroundColor: Colors.orange),
        );
        return;
      }
    }
    
    final emailController = TextEditingController();
    bool isLoading = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Invite to Company'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'User Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'User will be added as collaborator if they don\'t provide position and ID.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              if (isLoading) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                final email = emailController.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter an email'), backgroundColor: Colors.orange),
                  );
                  return;
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid email'), backgroundColor: Colors.orange),
                  );
                  return;
                }
                setState(() => isLoading = true);
                final exists = await _checkEmailExists(email);
                if (!exists) {
                  setState(() => isLoading = false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Email not found'), backgroundColor: Colors.red),
                    );
                  }
                  return;
                }
                await _sendInvitation(email);
                _lastInviteTime = DateTime.now();
                setState(() => isLoading = false);
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Send Invite', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<bool> _checkEmailExists(String email) async {
    try {
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));
      return userQuery.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> _sendInvitation(String email) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _selectedCompanyId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid session'), backgroundColor: Colors.red),
        );
      }
      return;
    }
    
    try {
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));
      
      if (userQuery.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not found'), backgroundColor: Colors.red),
          );
        }
        return;
      }
      
      final targetUserId = userQuery.docs.first.id;
      final targetUserName = userQuery.docs.first.data()['name'] ?? 'User';
      
      final companyDoc = await FirebaseFirestore.instance
          .collection('companies')
          .doc(_selectedCompanyId!)
          .get()
          .timeout(const Duration(seconds: 10));
      
      if (!companyDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Company not found'), backgroundColor: Colors.red),
          );
        }
        return;
      }
      
      final companyName = companyDoc.data()!['name'];
      
      await _sendCollaborationMessage(targetUserId, targetUserName, companyName);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation sent!'), backgroundColor: Colors.green),
        );
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request timeout. Check connection'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  Future<void> _sendCollaborationMessage(String targetUserId, String targetUserName, String companyName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final participants = [user.uid, targetUserId]..sort();
    final chatId = participants.join('_');
    
    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'participants': participants,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': 'Collaboration invitation for $companyName',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'type': 'company',
      'companyName': companyName,
    }, SetOptions(merge: true)).timeout(const Duration(seconds: 10));
    
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'chatId': chatId,
      'senderId': user.uid,
      'text': 'You have been invited to collaborate with $companyName. Do you accept this collaboration?',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'messageType': 'collaboration_invite',
      'companyId': _selectedCompanyId,
      'companyName': companyName,
    }).timeout(const Duration(seconds: 10));
    
    await FirebaseFirestore.instance.collection('messages').add({
      'senderId': user.uid,
      'receiverId': targetUserId,
      'message': 'Company invitation: $_selectedCompanyId',
      'type': 'collaboration_invite',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    }).timeout(const Duration(seconds: 10));
  }
  
  void _showRemoveCompanyDialog() async {
    if (_selectedCompanyId == null) return;
    
    // Check if user is owner to show appropriate message
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final companyDoc = await FirebaseFirestore.instance
        .collection('companies')
        .doc(_selectedCompanyId!)
        .get();
    
    if (!companyDoc.exists) return;
    
    final companyData = companyDoc.data()!;
    final isOwner = companyData['ownerId'] == user.uid;
    final companyName = companyData['name'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isOwner ? 'Delete Company' : 'Leave Company'),
        content: Text(
          isOwner 
            ? 'Are you sure you want to delete "$companyName"? This will permanently delete the company and remove all members. This action cannot be undone.'
            : 'Are you sure you want to leave "$companyName"? You will no longer have access to this company.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _removeCompany();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              isOwner ? 'Delete' : 'Leave',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _removeCompany() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _selectedCompanyId == null) return;
    
    try {
      // Get company data to check if user is owner
      final companyDoc = await FirebaseFirestore.instance
          .collection('companies')
          .doc(_selectedCompanyId!)
          .get();
      
      if (!companyDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company not found'), backgroundColor: Colors.red),
        );
        return;
      }
      
      final companyData = companyDoc.data()!;
      final isOwner = companyData['ownerId'] == user.uid;
      
      if (isOwner) {
        // If owner, delete the entire company
        await _deleteCompany();
      } else {
        // If member, just leave the company
        await _leaveCompany();
      }
      
    } catch (e) {
      print('Error removing company: $e'); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove company: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _deleteCompany() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _selectedCompanyId == null) return;
    
    try {
      // First verify ownership again
      final companyDoc = await FirebaseFirestore.instance
          .collection('companies')
          .doc(_selectedCompanyId!)
          .get();
      
      if (!companyDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company not found'), backgroundColor: Colors.red),
        );
        return;
      }
      
      final companyData = companyDoc.data()!;
      if (companyData['ownerId'] != user.uid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Only the company owner can delete the company'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Delete all company members
      final membersQuery = await FirebaseFirestore.instance
          .collection('company_members')
          .where('companyId', isEqualTo: _selectedCompanyId)
          .get();
      
      for (var doc in membersQuery.docs) {
        await doc.reference.delete();
      }
      
      // Delete company follows
      final followsQuery = await FirebaseFirestore.instance
          .collection('company_follows')
          .where('companyId', isEqualTo: _selectedCompanyId)
          .get();
      
      for (var doc in followsQuery.docs) {
        await doc.reference.delete();
      }
      
      // Delete the company document
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(_selectedCompanyId!)
          .delete();
      
      // Reset to personal mode
      setState(() {
        _selectedCompanyId = null;
        _isPersonalMode = true;
      });
      
      await ref.read(userControllerProvider).toggleCompanyMode(
        user.uid,
        false,
        null,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Company deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete company: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _leaveCompany() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _selectedCompanyId == null) return;
    
    try {
      // Remove user from company members
      await FirebaseFirestore.instance
          .collection('company_members')
          .doc('${_selectedCompanyId}_${user.uid}')
          .delete();
      
      // Remove user from company memberIds array
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(_selectedCompanyId!)
          .update({
        'memberIds': FieldValue.arrayRemove([user.uid])
      });
      
      // Reset to personal mode
      setState(() {
        _selectedCompanyId = null;
        _isPersonalMode = true;
      });
      
      await ref.read(userControllerProvider).toggleCompanyMode(
        user.uid,
        false,
        null,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Left company successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to leave company: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Widget _buildProfileSetupForm(userProfile, bool hasPhone, bool hasBio, bool hasProfilePic) {
    final phoneController = TextEditingController(text: userProfile.phoneNumber ?? '');
    final bioController = TextEditingController(text: userProfile.bio ?? '');
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning, color: Colors.orange),
              const SizedBox(width: 8),
              const Text(
                'Complete Your Profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!hasPhone) ...[
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.number,
              maxLength: 12,
              decoration: const InputDecoration(
                labelText: 'Phone Number (12 digits)',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
                hintText: '639123456789',
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (!hasBio) ...[
            TextField(
              controller: bioController,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Bio (max 500 characters)',
                prefixIcon: Icon(Icons.info),
                border: OutlineInputBorder(),
                hintText: 'Tell us about yourself...',
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (!hasProfilePic) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.camera_alt, color: Colors.grey),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Profile picture required - Upload from profile section',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          ElevatedButton(
            onPressed: () => _saveProfileInfo(phoneController.text, bioController.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Save Profile', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _saveProfileInfo(String phone, String bio) async {
    if (phone.isNotEmpty && (phone.length != 12 || !RegExp(r'^[0-9]+$').hasMatch(phone))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number must be exactly 12 digits'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (bio.length > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bio must be 500 characters or less'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'phoneNumber': phone.trim(),
          'bio': bio.trim(),
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update profile'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _saveBio() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'bio': _bioController.text.trim()});
        
        setState(() => _isEditingBio = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bio updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update bio'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Widget _buildCollaborationsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Collaborations',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('company_members')
                .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                .get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              
              final allMemberships = snapshot.data!.docs;
              final collabs = allMemberships.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['position']?.isNotEmpty == true && data['idNumber']?.isNotEmpty == true;
              }).toList();
              
              if (collabs.isEmpty) {
                return const Text(
                  'No collaborations yet',
                  style: TextStyle(color: Colors.grey),
                );
              }
              
              return Column(
                children: collabs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('companies')
                        .doc(data['companyId'])
                        .get(),
                    builder: (context, companySnapshot) {
                      if (!companySnapshot.hasData) return const SizedBox();
                      
                      final companyData = companySnapshot.data!.data() as Map<String, dynamic>?;
                      if (companyData == null) return const SizedBox();
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.business, color: Colors.blue),
                          title: Text(companyData['name']),
                          subtitle: Text('Position: ${data['position']}'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            if (companyData['ownerId'] == FirebaseAuth.instance.currentUser?.uid) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('This is your own company'), backgroundColor: Colors.orange),
                              );
                              return;
                            }
                            _showCompanyProfile(data['companyId']);
                          },
                        ),
                      );
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
  

  
  void _showCompanyProfile(String companyId) async {
    try {
      final companyDoc = await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .get();
      
      if (!companyDoc.exists) return;
      
      final companyData = companyDoc.data()!;
      final company = CompanyModel.fromMap(companyData, companyId);
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CompanyDetailsPage(company: company),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load company details'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _joinAsCollaborator(String companyId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      await FirebaseFirestore.instance
          .collection('company_members')
          .doc('${companyId}_${user.uid}')
          .set({
        'companyId': companyId,
        'userId': user.uid,
        'position': '',
        'buildingNo': '',
        'idNumber': '',
        'joinedAt': DateTime.now(),
      });
      
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .update({
        'memberIds': FieldValue.arrayUnion([user.uid])
      });
      
      setState(() {});
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Joined as collaborator successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to join as collaborator'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  

  
  Future<List<DocumentSnapshot>> _filterChatsWithReceivedMessages(List<QueryDocumentSnapshot> chats, String userId) async {
    final filtered = <DocumentSnapshot>[];
    for (var chat in chats) {
      final messages = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chat.id)
          .collection('messages')
          .limit(10)
          .get();
      
      final hasReceivedMessage = messages.docs.any((msg) => msg.data()['senderId'] != userId);
      if (hasReceivedMessage) {
        filtered.add(chat);
      }
    }
    return filtered;
  }
  
  Future<int> _getConnectionsCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;
    
    try {
      final chats = await FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: user.uid)
          .get();
      
      final filtered = await _filterChatsWithReceivedMessages(chats.docs, user.uid);
      return filtered.length;
    } catch (e) {
      return 0;
    }
  }
  
  Future<int> _getFollowingCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;
    
    try {
      final companyFollows = await FirebaseFirestore.instance
          .collection('company_follows')
          .where('followerId', isEqualTo: user.uid)
          .get();
      
      final userFollows = await FirebaseFirestore.instance
          .collection('follows')
          .where('followerId', isEqualTo: user.uid)
          .get();
      
      return companyFollows.docs.length + userFollows.docs.length;
    } catch (e) {
      return 0;
    }
  }
  
  Future<int> _getFollowersCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;
    
    try {
      int totalFollowers = 0;
      
      // Count followers of user's companies
      for (var company in _userCompanies) {
        final followers = await FirebaseFirestore.instance
            .collection('company_follows')
            .where('companyId', isEqualTo: company.id)
            .get();
        totalFollowers += followers.docs.length;
      }
      
      return totalFollowers;
    } catch (e) {
      return 0;
    }
  }
  
  void _showConnectionsList(String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      type == 'connections' ? 'Connections' : 
                      type == 'following' ? 'Following' : 'Followers',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildConnectionsContent(type, scrollController),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildConnectionsContent(String type, ScrollController scrollController) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Please log in'));
    
    if (type == 'connections') {
      return FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: user.uid)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          return FutureBuilder<List<DocumentSnapshot>>(
            future: _filterChatsWithReceivedMessages(snapshot.data!.docs, user.uid),
            builder: (context, filteredSnapshot) {
              if (!filteredSnapshot.hasData) return const Center(child: CircularProgressIndicator());
              
              final chats = filteredSnapshot.data!;
              if (chats.isEmpty) {
                return const Center(child: Text('No connections yet'));
              }
              
              return ListView.builder(
                controller: scrollController,
                itemCount: chats.length,
                itemBuilder: (context, index) {
                  final chatData = chats[index].data() as Map<String, dynamic>;
                  final participants = List<String>.from(chatData['participants'] ?? []);
                  final otherUserId = participants.firstWhere((id) => id != user.uid, orElse: () => '');
                  final chatType = chatData['type'] ?? 'personal';
              
              if (chatType == 'company') {
                final companyId = chatData['companyId'];
                if (companyId == null) return const SizedBox();
                return FutureBuilder<List<dynamic>>(
                  future: Future.wait([
                    FirebaseFirestore.instance.collection('companies').doc(companyId).get().timeout(const Duration(seconds: 5)),
                    FirebaseFirestore.instance.collection('users').doc(otherUserId).get().timeout(const Duration(seconds: 5)),
                  ]).catchError((e) => []),
                  builder: (context, futureSnapshot) {
                    if (!futureSnapshot.hasData || futureSnapshot.data!.isEmpty) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          child: const Icon(Icons.business, color: Colors.blue),
                        ),
                        title: const Text('Company Chat'),
                        subtitle: const Text('Loading...'),
                      );
                    }
                    final companyData = futureSnapshot.data![0].data() as Map<String, dynamic>?;
                    final senderData = futureSnapshot.data![1].data() as Map<String, dynamic>?;
                    if (companyData == null) return const SizedBox();
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        child: const Icon(Icons.business, color: Colors.blue),
                      ),
                      title: Text(companyData['name']),
                      subtitle: Text('From: ${senderData?['name'] ?? 'Unknown'}'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        if (companyData['ownerId'] == user.uid) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('This is your own company'), backgroundColor: Colors.orange),
                          );
                          return;
                        }
                        _showCompanyProfile(companyId);
                      },
                    );
                  },
                );
              } else {
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) return const SizedBox();
                    final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                    if (userData == null) return const SizedBox();
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.deepPurple,
                        child: Text(
                          userData['name']?.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(userData['name'] ?? 'User'),
                      subtitle: const Text('Personal Chat'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        if (otherUserId == user.uid) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('This is your own profile'), backgroundColor: Colors.orange),
                          );
                          return;
                        }
                        final userModel = UserModel.fromMap(userData, otherUserId);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserDetailsPage(user: userModel),
                          ),
                        );
                      },
                    );
                  },
                );
              }
                },
              );
            },
          );
        },
      );
    } else if (type == 'following') {
      return FutureBuilder<List<QuerySnapshot>>(
        future: Future.wait([
          FirebaseFirestore.instance
              .collection('company_follows')
              .where('followerId', isEqualTo: user.uid)
              .get(),
          FirebaseFirestore.instance
              .collection('follows')
              .where('followerId', isEqualTo: user.uid)
              .get(),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final companyFollows = snapshot.data![0].docs;
          final userFollows = snapshot.data![1].docs;
          
          if (companyFollows.isEmpty && userFollows.isEmpty) {
            return const Center(child: Text('Not following anyone'));
          }
          
          return ListView(
            controller: scrollController,
            children: [
              if (companyFollows.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Companies (${companyFollows.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                ...companyFollows.map((doc) {
                  final followData = doc.data() as Map<String, dynamic>;
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('companies')
                        .doc(followData['companyId'])
                        .get(),
                    builder: (context, companySnapshot) {
                      if (!companySnapshot.hasData) return const SizedBox();
                      final companyData = companySnapshot.data!.data() as Map<String, dynamic>?;
                      if (companyData == null) return const SizedBox();
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          child: const Icon(Icons.business, color: Colors.blue),
                        ),
                        title: Text(companyData['name']),
                        subtitle: Text(companyData['industry'] ?? 'Company'),
                        trailing: TextButton(
                          onPressed: () async {
                            await doc.reference.delete();
                            if (mounted) setState(() {});
                          },
                          child: const Text('Unfollow', style: TextStyle(color: Colors.red)),
                        ),
                        onTap: () {
                          if (companyData['ownerId'] == user.uid) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('This is your own company'), backgroundColor: Colors.orange),
                            );
                            return;
                          }
                          _showCompanyProfile(followData['companyId']);
                        },
                      );
                    },
                  );
                }),
              ],
              if (userFollows.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('People (${userFollows.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                ...userFollows.map((doc) {
                  final followData = doc.data() as Map<String, dynamic>;
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(followData['followingId'])
                        .get(),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData) return const SizedBox();
                      final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                      if (userData == null) return const SizedBox();
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.deepPurple,
                          child: Text(
                            userData['name']?.substring(0, 1).toUpperCase() ?? 'U',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(userData['name'] ?? 'User'),
                        subtitle: Text(userData['email'] ?? ''),
                        trailing: TextButton(
                          onPressed: () async {
                            await doc.reference.delete();
                            if (mounted) setState(() {});
                          },
                          child: const Text('Unfollow', style: TextStyle(color: Colors.red)),
                        ),
                        onTap: () {
                          if (followData['followingId'] == user.uid) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('This is your own profile'), backgroundColor: Colors.orange),
                            );
                            return;
                          }
                          final userModel = UserModel.fromMap(userData, followData['followingId']);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserDetailsPage(user: userModel),
                            ),
                          );
                        },
                      );
                    },
                  );
                }),
              ],
            ],
          );
        },
      );
    } else { // followers
      return FutureBuilder<List<QuerySnapshot>>(
        future: Future.wait(_userCompanies.map((company) => 
          FirebaseFirestore.instance
              .collection('company_follows')
              .where('companyId', isEqualTo: company.id)
              .get()
        ).toList()),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final allFollowers = <Map<String, dynamic>>[];
          for (int i = 0; i < snapshot.data!.length; i++) {
            final followers = snapshot.data![i].docs;
            for (var follower in followers) {
              final data = follower.data() as Map<String, dynamic>;
              data['companyName'] = _userCompanies[i].name;
              allFollowers.add(data);
            }
          }
          
          if (allFollowers.isEmpty) {
            return const Center(child: Text('No followers yet'));
          }
          
          return ListView.builder(
            controller: scrollController,
            itemCount: allFollowers.length,
            itemBuilder: (context, index) {
              final followerData = allFollowers[index];
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(followerData['followerId'])
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) return const SizedBox();
                  
                  final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                  if (userData == null) return const SizedBox();
                  
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(userData['name'] ?? 'Unknown'),
                    subtitle: Text('Following: ${followerData['companyName']}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      if (followerData['followerId'] == user.uid) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('This is your own profile'), backgroundColor: Colors.orange),
                        );
                        return;
                      }
                      final userModel = UserModel.fromMap(userData, followerData['followerId']);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserDetailsPage(user: userModel),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      );
    }
  }
  
  Widget _buildProfilePicture() {
    if (_isPersonalMode) {
      final userProfile = ref.read(profileControllerProvider);
      final photoUrl = userProfile?.profilePicUrl;
      
      return Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: ClipOval(
              child: photoUrl != null
                  ? Image.network(photoUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 50, color: Colors.deepPurple))
                  : const Icon(Icons.person, size: 50, color: Colors.deepPurple),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _uploadPersonalPhoto,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    }
    
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('companies')
          .doc(_selectedCompanyId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: const CircularProgressIndicator(),
          );
        }
        
        final companyData = snapshot.data!.data() as Map<String, dynamic>?;
        final photoUrl = companyData?['photoUrl'];
        final isOwner = companyData?['ownerId'] == FirebaseAuth.instance.currentUser?.uid;
        
        return Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: ClipOval(
                child: photoUrl != null
                    ? Image.network(photoUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.business, size: 50, color: Colors.deepPurple))
                    : const Icon(Icons.business, size: 50, color: Colors.deepPurple),
              ),
            ),
            if (isOwner)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _uploadCompanyPhoto,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
  
  void _uploadPersonalPhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) return;
    
    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload'),
        body: {'key': '493f13fa424a0c9fca4c01f64cdb0b0f', 'image': base64Image},
      );
      
      final data = json.decode(response.body);
      final photoUrl = data['data']['url'];
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'profilePicUrl': photoUrl});
      
      setState(() {});
    } catch (e) {
      print('Upload error: $e');
    }
  }
  
  void _uploadCompanyPhoto() async {
    if (_selectedCompanyId == null) return;
    
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) return;
    
    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload'),
        body: {'key': '493f13fa424a0c9fca4c01f64cdb0b0f', 'image': base64Image},
      );
      
      final data = json.decode(response.body);
      final photoUrl = data['data']['url'];
      
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(_selectedCompanyId)
          .update({'photoUrl': photoUrl});
      
      setState(() {});
    } catch (e) {
      print('Upload error: $e');
    }
  }
  
  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }
}