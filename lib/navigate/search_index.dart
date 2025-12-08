import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'chat_screen.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _selectedFilter = 'All';
  bool _isSearching = false;
  List<UserModel> _searchResults = [];
  List<Map<String, dynamic>>? _companyResults = [];
  Set<String> _followingUsers = {};

  final List<String> _filters = [
    'All',
    'Companies',
    'Entrepreneurs',
    'Investors',
    'Startups',
  ];

  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final currentUserId = _auth.currentUser?.uid;
      
      // Search users
      final userQuery = await _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: '${query}z')
          .limit(10)
          .get();

      // Search companies
      final companyQuery = await _firestore
          .collection('companies')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: '${query}z')
          .limit(10)
          .get();

      final userResults = userQuery.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .where((user) => user.id != currentUserId)
          .toList();

      final companyResults = companyQuery.docs
          .map((doc) => {
            'type': 'company',
            'id': doc.id,
            'name': doc.data()['name'],
            'description': doc.data()['description'],
            'industry': doc.data()['industry'],
            'ownerId': doc.data()['ownerId'],
            'memberIds': doc.data()['memberIds'],
          })
          .toList();

      setState(() {
        _searchResults = userResults;
        _companyResults = companyResults;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _companyResults = [];
      });
    }
  }

  List<String> _recentSearches = [
    
  ];
  
  void _addToRecentSearches(String query) {
    if (query.isNotEmpty && !_recentSearches.contains(query)) {
      setState(() {
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 10) {
          _recentSearches = _recentSearches.take(10).toList();
        }
      });
    }
  }
  
  void _clearRecentSearches() {
    setState(() {
      _recentSearches.clear();
    });
  }

  void _followUser(String userId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to follow users')),
      );
      return;
    }
    
    if (currentUserId == userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot follow yourself')),
      );
      return;
    }
    
    try {
      // Check if already following
      final existingFollow = await _firestore
          .collection('follows')
          .where('followerId', isEqualTo: currentUserId)
          .where('followingId', isEqualTo: userId)
          .get();
      
      if (existingFollow.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Already following this user')),
        );
        return;
      }
      
      await _firestore.collection('follows').add({
        'followerId': currentUserId,
        'followingId': userId,
        'createdAt': DateTime.now(),
      });
      
      setState(() {
        _followingUsers.add(userId);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Following! You can now chat with them.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to follow: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _messageUser(String userId, String userName) async {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          otherUserId: userId,
          otherUserName: userName,
          chatType: 'personal',
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _companyResults = [];
    _loadFollowingUsers();
  }
  
  Future<void> _loadFollowingUsers() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;
    
    try {
      final followQuery = await _firestore
          .collection('follows')
          .where('followerId', isEqualTo: currentUserId)
          .get();
      
      setState(() {
        _followingUsers = followQuery.docs
            .map((doc) => doc.data()['followingId'] as String)
            .toSet();
      });
    } catch (e) {
      // Handle silently
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserModel> get _filteredResults {
    if (_selectedFilter == 'All') {
      return _searchResults;
    }
    return _searchResults.where((user) {
      switch (_selectedFilter) {
        case 'Companies':
          return user.isWorkingAtCompany && user.companyName != null;
        case 'Entrepreneurs':
          return !user.isWorkingAtCompany;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Search',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isSearching ? Colors.deepPurple : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        _performSearch(value);
                      },
                      onSubmitted: (value) {
                        _addToRecentSearches(value);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search companies, people, or startups...',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.deepPurple,
                        ),
                        suffixIcon: _isSearching
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _performSearch('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      itemBuilder: (context, index) {
                        final filter = _filters[index];
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(filter),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedFilter = filter;
                              });
                            },
                            backgroundColor: Colors.grey[100],
                            selectedColor: Colors.deepPurple,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
                ],
              ),
            ),
            
            Expanded(
              child: _isSearching
                  ? _buildSearchResults()
                  : _buildRecentSearches(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final results = _filteredResults;
    
    if (results.isEmpty && (_companyResults?.isEmpty ?? true)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length + (_companyResults?.length ?? 0),
      itemBuilder: (context, index) {
        if (index < results.length) {
          return _buildSearchResultCard(results[index]);
        } else {
          final companyIndex = index - results.length;
          if (_companyResults != null && companyIndex < _companyResults!.length) {
            return _buildCompanyResultCard(_companyResults![companyIndex]);
          }
          return const SizedBox();
        }
      },
    );
  }

  void _showUserProfile(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
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
                      user.name,
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
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Header Section
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
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.deepPurple.withOpacity(0.8), Colors.purple.withOpacity(0.6)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 32),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  Text(user.email, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                                  if (user.location != null)
                                    Text(user.location!, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // About Section
                      if (user.bio != null)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.withOpacity(0.2)),
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
                                    child: const Icon(Icons.info, color: Colors.white, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(user.bio!, style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      
                      // Contact Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.contact_mail, color: Colors.white, size: 18),
                                ),
                                const SizedBox(width: 12),
                                const Text('Contact Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.email, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Email: ${user.email}',
                                    style: const TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (user.phoneNumber != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.phone, size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Phone: ${user.phoneNumber}',
                                      style: const TextStyle(fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (user.location != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Location: ${user.location}',
                                      style: const TextStyle(fontSize: 14),
                                      softWrap: true,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Action Buttons
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.green.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _followUser(user.id),
                                icon: Icon(
                                  _followingUsers.contains(user.id) ? Icons.check : Icons.person_add,
                                  size: 18,
                                ),
                                label: Text(_followingUsers.contains(user.id) ? 'Following' : 'Follow'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _followingUsers.contains(user.id) ? Colors.green : Colors.deepPurple,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _messageUser(user.id, user.name),
                                icon: const Icon(Icons.message, size: 18),
                                label: const Text('Message'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      FutureBuilder<QuerySnapshot>(
                        future: _firestore.collection('company_members').where('userId', isEqualTo: user.id).get(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox();
                          final memberships = snapshot.data!.docs;
                          if (memberships.isEmpty) return const Text('No company collaborations');
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Collaborations (${memberships.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              ...memberships.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                return FutureBuilder<DocumentSnapshot>(
                                  future: _firestore.collection('companies').doc(data['companyId']).get(),
                                  builder: (context, companySnapshot) {
                                    if (!companySnapshot.hasData) return const SizedBox();
                                    final companyData = companySnapshot.data!.data() as Map<String, dynamic>?;
                                    if (companyData == null) return const SizedBox();
                                    
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.business, color: Colors.deepPurple),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(companyData['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                                Text('Position: ${data['position'] ?? 'Member'}', style: TextStyle(color: Colors.grey[600])),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              }),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showCompanyProfile(Map<String, dynamic> company) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
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
                      company['name'],
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
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.business, color: Colors.deepPurple, size: 40),
                      ),
                      const SizedBox(height: 16),
                      Text(company['name'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      Text(company['industry'], style: TextStyle(fontSize: 16, color: Colors.deepPurple)),
                      const SizedBox(height: 16),
                      Text('About', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(company['description'] ?? 'No description available'),
                      const SizedBox(height: 16),
                      FutureBuilder<DocumentSnapshot>(
                        future: _firestore.collection('users').doc(company['ownerId']).get(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox();
                          final ownerData = snapshot.data!.data() as Map<String, dynamic>?;
                          if (ownerData == null) return const SizedBox();
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Owner', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.person, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(ownerData['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          Text(ownerData['email'] ?? 'No email', style: TextStyle(color: Colors.grey[600])),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<QuerySnapshot>(
                        future: _firestore.collection('company_members').where('companyId', isEqualTo: company['id']).get(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox();
                          final members = snapshot.data!.docs;
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Members (${members.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              ...members.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                return FutureBuilder<DocumentSnapshot>(
                                  future: _firestore.collection('users').doc(data['userId']).get(),
                                  builder: (context, userSnapshot) {
                                    if (!userSnapshot.hasData) return const SizedBox();
                                    final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                                    if (userData == null) return const SizedBox();
                                    
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.person, color: Colors.deepPurple),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(userData['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                Text('Position: ${data['position'] ?? 'Member'}', style: TextStyle(color: Colors.grey[600])),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              }),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultCard(UserModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple.withOpacity(0.8),
                  Colors.purple.withOpacity(0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      flex: 3,
                      child: Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          user.isWorkingAtCompany ? 'Company' : 'Entrepreneur',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user.bio ?? user.email,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        user.location ?? 'No location',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => _showUserProfile(user),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: Size.zero,
                      ),
                      child: const Text('View', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Searches',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: _recentSearches.isNotEmpty ? _clearRecentSearches : null,
                child: Text(
                  'Clear All',
                  style: TextStyle(
                    color: _recentSearches.isNotEmpty ? Colors.deepPurple : Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(
            _recentSearches.length,
            (index) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.history,
                  color: Colors.grey[600],
                ),
                title: Text(
                  _recentSearches[index],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                trailing: Icon(
                  Icons.north_west,
                  color: Colors.grey[400],
                  size: 20,
                ),
                onTap: () {
                  _searchController.text = _recentSearches[index];
                  _performSearch(_recentSearches[index]);
                },
                onLongPress: () {
                  setState(() {
                    _recentSearches.removeAt(index);
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Popular Categories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildCategoryChip('Technology', Icons.computer),
              _buildCategoryChip('Finance', Icons.account_balance),
              _buildCategoryChip('Healthcare', Icons.local_hospital),
              _buildCategoryChip('E-commerce', Icons.shopping_cart),
              _buildCategoryChip('Education', Icons.school),
              _buildCategoryChip('Energy', Icons.bolt),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyResultCard(Map<String, dynamic> company) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.business, color: Colors.deepPurple, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      flex: 3,
                      child: Text(
                        company['name'],
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          company['industry'],
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.blue),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  company['description'] ?? 'No description',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.group, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${(company['memberIds'] as List?)?.length ?? 0} members',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => _showCompanyProfile(company),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: Size.zero,
                      ),
                      child: const Text('View', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, IconData icon) {
    return InkWell(
      onTap: () {
        _searchController.text = label;
        _performSearch(label);
        _addToRecentSearches(label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: Colors.deepPurple,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
