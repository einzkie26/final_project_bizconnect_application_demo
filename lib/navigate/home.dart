import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/company_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/profile_controller.dart';
import 'chat_screen.dart';
import 'company_details_page.dart';
import 'dart:async';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  static final Set<String> _usersSeenWelcome = <String>{};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Set<String> followedCompanies = <String>{};
  Set<String> memberCompanies = <String>{};
  String _selectedIndustryFilter = 'All';
  bool _showWelcome = true;
  Timer? _welcomeTimer;
  
  final List<String> _industryFilters = [
    'All',
    'Technology',
    'Healthcare',
    'Finance',
    'Education',
    'Retail',
    'Manufacturing',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _setupFollowStream();
    _checkWelcomeVisibility();
  }

  void _checkWelcomeVisibility() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;
    
    if (!_usersSeenWelcome.contains(currentUserId)) {
      _welcomeTimer = Timer(const Duration(seconds: 15), () {
        if (mounted) {
          _usersSeenWelcome.add(currentUserId);
          setState(() {
            _showWelcome = false;
          });
        }
      });
    } else {
      setState(() {
        _showWelcome = false;
      });
    }
  }

  @override
  void dispose() {
    _welcomeTimer?.cancel();
    super.dispose();
  }

  void _setupFollowStream() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    _firestore
        .collection('company_follows')
        .where('followerId', isEqualTo: currentUserId)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          followedCompanies = snapshot.docs.map((doc) => doc.data()['companyId'] as String).toSet();
        });
      }
    });
    
    _firestore
        .collection('company_members')
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          memberCompanies = snapshot.docs.map((doc) => doc.data()['companyId'] as String).toSet();
        });
      }
    });
  }

  void _toggleFollow(String companyId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to follow companies')),
      );
      return;
    }

    try {
      if (followedCompanies.contains(companyId)) {
        final followQuery = await _firestore
            .collection('company_follows')
            .where('followerId', isEqualTo: currentUserId)
            .where('companyId', isEqualTo: companyId)
            .get();

        for (var doc in followQuery.docs) {
          await doc.reference.delete();
        }

        setState(() => followedCompanies.remove(companyId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unfollowed company')),
        );
      } else {
        await _firestore.collection('company_follows').add({
          'followerId': currentUserId,
          'companyId': companyId,
          'createdAt': DateTime.now(),
        });

        setState(() => followedCompanies.add(companyId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Following company!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _showCompanyDetails(CompanyModel company) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompanyDetailsPage(company: company),
      ),
    );
  }
  
  void _messageCompany(String ownerId, String companyName, String companyId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          otherUserId: ownerId,
          otherUserName: companyName,
          chatType: 'company',
          companyId: companyId,
        ),
      ),
    );
  }
  


  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(profileControllerProvider);
    final currentUser = _auth.currentUser;
    
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }
    
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get(),
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
        
        return _buildHomeScreen(userProfile, currentUser);
      },
    );
  }
  
  Widget _buildProfileIncompleteScreen() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return const Scaffold();
    
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final hasPhone = userData['phoneNumber']?.toString().isNotEmpty == true;
        final hasBio = userData['bio']?.toString().isNotEmpty == true;
        final hasProfilePic = userData['profilePicUrl']?.toString().isNotEmpty == true;
        final progress = (hasPhone ? 0.33 : 0.0) + (hasBio ? 0.33 : 0.0) + (hasProfilePic ? 0.34 : 0.0);
        
        return Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 80,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Complete Your Profile',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: 200,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Progress', style: TextStyle(fontSize: 14, color: Colors.grey)),
                            Text('${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                        ),
                        const SizedBox(height: 16),
                        Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  hasPhone ? Icons.check_circle : Icons.radio_button_unchecked,
                                  color: hasPhone ? Colors.green : Colors.grey,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                const Text('Phone Number', style: TextStyle(fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  hasBio ? Icons.check_circle : Icons.radio_button_unchecked,
                                  color: hasBio ? Colors.green : Colors.grey,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                const Text('Bio', style: TextStyle(fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  hasProfilePic ? Icons.check_circle : Icons.radio_button_unchecked,
                                  color: hasProfilePic ? Colors.green : Colors.grey,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                const Text('Profile Picture', style: TextStyle(fontSize: 14)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  const Text(
                    'Complete these fields to explore companies and chat with others.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: const Text(
                      'Complete Profile',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildHomeScreen(userProfile, User? currentUser) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Row(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: Image.asset(
                            'assets/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Bizconnect',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (currentUser != null && _showWelcome) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Welcome, ${userProfile?.name.split(' ').first ?? 'User'}!',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.deepPurple.withOpacity(0.1),
                            ),
                            child: ClipOval(
                              child: userProfile?.profilePicUrl != null
                                  ? Image.network(
                                      userProfile!.profilePicUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Center(
                                        child: Text(
                                          userProfile.name.isNotEmpty ? userProfile.name[0].toUpperCase() : 'U',
                                          style: const TextStyle(
                                            color: Colors.deepPurple,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        userProfile?.name.isNotEmpty == true ? userProfile!.name[0].toUpperCase() : 'U',
                                        style: const TextStyle(
                                          color: Colors.deepPurple,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              const SizedBox(height: 8),
                const Text(
                  'Discover New Companies & Connections',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  softWrap: true,
                ),
              
              const SizedBox(height: 20),
              
              // New Companies Section
              Row(
                children: [
                  const Icon(Icons.new_releases, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'New Companies',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Last 7 days',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              SizedBox(
                height: 120,
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('companies')
                      .where('createdAt', isGreaterThan: DateTime.now().subtract(const Duration(days: 7)))
                      .limit(20)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (snapshot.hasError || !snapshot.hasData) {
                      return const Center(
                        child: Text('No companies found', style: TextStyle(color: Colors.grey)),
                      );
                    }
                    
                    final companies = snapshot.data!.docs
                        .map((doc) => CompanyModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                        .where((company) => 
                          company.ownerId != currentUser?.uid &&
                          !followedCompanies.contains(company.id) &&
                          !memberCompanies.contains(company.id)
                        )
                        .toList();
                    
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: companies.length,
                      itemBuilder: (context, index) {
                        final company = companies[index];
                        return GestureDetector(
                          onTap: () => _showCompanyDetails(company),
                          child: Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 12),
                            child: Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Stack(
                                      children: [
                                        FutureBuilder<DocumentSnapshot>(
                                          future: _firestore.collection('companies').doc(company.id).get(),
                                          builder: (context, snapshot) {
                                            String? photoUrl;
                                            if (snapshot.hasData && snapshot.data!.data() != null) {
                                              final data = snapshot.data!.data() as Map<String, dynamic>;
                                              photoUrl = data['photoUrl'];
                                            }
                                            return Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: Colors.deepPurple.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: photoUrl != null
                                                  ? ClipRRect(
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: Image.network(
                                                        photoUrl,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (_, __, ___) => const Icon(Icons.business, color: Colors.deepPurple, size: 20),
                                                      ),
                                                    )
                                                  : const Icon(Icons.business, color: Colors.deepPurple, size: 20),
                                            );
                                          },
                                        ),
                                        Positioned(
                                          top: -6,
                                          right: -6,
                                          child: GestureDetector(
                                            onTap: () => _toggleFollow(company.id),
                                            child: Icon(
                                              followedCompanies.contains(company.id) ? Icons.favorite : Icons.favorite_border,
                                              color: followedCompanies.contains(company.id) ? Colors.red : Colors.grey,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      company.name,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                    Text(
                                      company.industry,
                                      style: const TextStyle(
                                        fontSize: 8,
                                        color: Colors.deepPurple,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                    Text(
                                      '${company.memberIds.length} members',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: Colors.grey,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 20),
              
              Row(
                children: [
                  const Text(
                    'Available Companies',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      // Navigate to search page
                    },
                    child: const Text(
                      'See All',
                      style: TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Industry Filter
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _industryFilters.length,
                  itemBuilder: (context, index) {
                    final filter = _industryFilters[index];
                    final isSelected = _selectedIndustryFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedIndustryFilter = filter;
                          });
                        },
                        backgroundColor: Colors.grey[100],
                        selectedColor: Colors.deepPurple,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 12,
                        ),
                        checkmarkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? Colors.deepPurple : Colors.transparent,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              
              StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('companies').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Center(
                      child: Text('No companies found', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    );
                  }
                  
                  final companies = snapshot.data!.docs
                      .map((doc) => CompanyModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                      .where((company) => 
                        company.ownerId != currentUser?.uid &&
                        !followedCompanies.contains(company.id) &&
                        !memberCompanies.contains(company.id)
                      )
                      .toList();
                  
                  final filteredCompanies = _selectedIndustryFilter == 'All' 
                      ? companies 
                      : companies.where((company) => company.industry == _selectedIndustryFilter).toList();
                  
                  if (companies.isEmpty) {
                    return const Center(
                      child: Text(
                        'No companies found',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredCompanies.length,
                    itemBuilder: (context, index) {
                        final company = filteredCompanies[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => _showCompanyDetails(company),
                            child: Row(
                              children: [
                                FutureBuilder<DocumentSnapshot>(
                                  future: _firestore.collection('companies').doc(company.id).get(),
                                  builder: (context, snapshot) {
                                    String? photoUrl;
                                    if (snapshot.hasData && snapshot.data!.data() != null) {
                                      final data = snapshot.data!.data() as Map<String, dynamic>;
                                      photoUrl = data['photoUrl'];
                                    }
                                    return Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurple.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: photoUrl != null
                                          ? ClipOval(
                                              child: Image.network(
                                                photoUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => const Icon(Icons.business, color: Colors.deepPurple, size: 24),
                                              ),
                                            )
                                          : const Icon(Icons.business, color: Colors.deepPurple, size: 24),
                                    );
                                  },
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FutureBuilder<DocumentSnapshot>(
                                    future: _firestore.collection('users').doc(company.ownerId).get(),
                                    builder: (context, snapshot) {
                                      String ownerName;
                                      if (snapshot.hasData && snapshot.data!.data() != null) {
                                        final data = snapshot.data!.data() as Map<String, dynamic>?;
                                        ownerName = data?['name'] ?? 'Unknown';
                                      } else {
                                        ownerName = 'Loading...';
                                      }
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            company.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            company.industry,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.deepPurple,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            'by $ownerName',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _toggleFollow(company.id),
                                  icon: Icon(
                                    followedCompanies.contains(company.id) ? Icons.favorite : Icons.favorite_border,
                                    color: followedCompanies.contains(company.id) ? Colors.red : Colors.grey,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                  );
                },
              ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}