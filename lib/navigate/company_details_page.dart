import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/company_model.dart';
import 'chat_screen.dart';

class CompanyDetailsPage extends StatefulWidget {
  final CompanyModel company;

  const CompanyDetailsPage({super.key, required this.company});

  @override
  State<CompanyDetailsPage> createState() => _CompanyDetailsPageState();
}

class _CompanyDetailsPageState extends State<CompanyDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isFollowing = false;
  String? _ownerName;
  String? _ownerEmail;
  String? _ownerPosition;

  @override
  void initState() {
    super.initState();
    _loadOwnerInfo();
    _checkFollowStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkFollowStatus();
  }

  void _loadOwnerInfo() async {
    try {
      final ownerDoc = await _firestore.collection('users').doc(widget.company.ownerId).get();
      if (ownerDoc.exists) {
        final ownerData = ownerDoc.data()!;
        setState(() {
          _ownerName = ownerData['name'];
          _ownerEmail = ownerData['email'];
        });
      }
      
      final memberDoc = await _firestore
          .collection('company_members')
          .doc('${widget.company.id}_${widget.company.ownerId}')
          .get();
      
      if (memberDoc.exists) {
        final memberData = memberDoc.data()!;
        setState(() {
          _ownerPosition = memberData['position']?.isNotEmpty == true 
              ? memberData['position'] 
              : 'Owner';
        });
      } else {
        setState(() {
          _ownerPosition = 'Owner';
        });
      }
    } catch (e) {
      setState(() {
        _ownerPosition = 'Owner';
      });
    }
  }

  void _checkFollowStatus() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final followQuery = await _firestore
          .collection('company_follows')
          .where('followerId', isEqualTo: currentUserId)
          .where('companyId', isEqualTo: widget.company.id)
          .get();

      setState(() {
        _isFollowing = followQuery.docs.isNotEmpty;
      });
    } catch (e) {
      // Handle error
    }
  }

  void _toggleFollow() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      if (_isFollowing) {
        final followQuery = await _firestore
            .collection('company_follows')
            .where('followerId', isEqualTo: currentUserId)
            .where('companyId', isEqualTo: widget.company.id)
            .get();

        for (var doc in followQuery.docs) {
          await doc.reference.delete();
        }

        if (mounted) {
          setState(() => _isFollowing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unfollowed company'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        await _firestore.collection('company_follows').add({
          'followerId': currentUserId,
          'companyId': widget.company.id,
          'createdAt': DateTime.now(),
        });

        if (mounted) {
          setState(() => _isFollowing = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Following company!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update follow status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _messageOwner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          otherUserId: widget.company.ownerId,
          otherUserName: widget.company.name,
          chatType: 'company',
          companyId: widget.company.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.deepPurple,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.company.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: StreamBuilder<DocumentSnapshot>(
                stream: _firestore.collection('companies').doc(widget.company.id).snapshots(),
                builder: (context, snapshot) {
                  String? photoUrl;
                  if (snapshot.hasData && snapshot.data!.data() != null) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    photoUrl = data['photoUrl'];
                  }
                  
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      photoUrl != null
                          ? Image.network(
                              photoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.deepPurple.withOpacity(0.8), Colors.purple.withOpacity(0.6)],
                                  ),
                                ),
                                child: const Center(child: Icon(Icons.business, size: 80, color: Colors.white)),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.deepPurple.withOpacity(0.8), Colors.purple.withOpacity(0.6)],
                                ),
                              ),
                              child: const Center(child: Icon(Icons.business, size: 80, color: Colors.white)),
                            ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.deepPurple.withOpacity(0.8),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
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
                              child: const Icon(Icons.info, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Company Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('Description', widget.company.description.isNotEmpty ? widget.company.description : 'No description available', Icons.description),
                        _buildInfoRow('Members', '${widget.company.memberIds.length}', Icons.group),
                        _buildInfoRow('Created', widget.company.createdAt.toString().split(' ')[0], Icons.calendar_today),
                        if (widget.company.address != null)
                          _buildInfoRow('Address', '${widget.company.address}, ${widget.company.city}, ${widget.company.province}', Icons.location_on),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_ownerName != null)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
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
                                child: const Icon(Icons.person_pin, color: Colors.white, size: 20),
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
                          const SizedBox(height: 16),
                          _buildInfoRow('Name', _ownerName!, Icons.person),
                          _buildInfoRow('Email', _ownerEmail ?? 'Not available', Icons.email),
                          _buildInfoRow('Position', _ownerPosition ?? 'Owner', Icons.work),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.shade700,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.location_on, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Location',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                            child: widget.company.latitude != null && widget.company.longitude != null
                                ? FlutterMap(
                                    options: MapOptions(
                                      initialCenter: LatLng(widget.company.latitude!, widget.company.longitude!),
                                      initialZoom: 15.0,
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName: 'com.example.app',
                                      ),
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            point: LatLng(widget.company.latitude!, widget.company.longitude!),
                                            child: const Icon(
                                              Icons.location_pin,
                                              color: Colors.red,
                                              size: 40,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                : Container(
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: Text(
                                        'Location not available',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _toggleFollow,
                          icon: Icon(
                            _isFollowing ? Icons.favorite : Icons.favorite_border,
                            color: Colors.white,
                          ),
                          label: Text(
                            _isFollowing ? 'Following' : 'Follow',
                            style: const TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isFollowing ? Colors.green : Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _messageOwner,
                          icon: const Icon(Icons.message, color: Colors.deepPurple),
                          label: const Text(
                            'Message',
                            style: TextStyle(color: Colors.deepPurple),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Colors.deepPurple),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
}