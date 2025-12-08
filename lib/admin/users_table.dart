import 'package:flutter/material.dart';

class UsersTablePage extends StatefulWidget {
  const UsersTablePage({super.key});

  @override
  State<UsersTablePage> createState() => _UsersTablePageState();
}

class _UsersTablePageState extends State<UsersTablePage> {
  final List<Map<String, dynamic>> _users = [
    {
      'id': 'U001',
      'name': 'John Doe',
      'email': 'john@example.com',
      'role': 'User',
      'status': 'Active',
      'joinDate': '2024-01-15',
    },
    {
      'id': 'U002',
      'name': 'Jane Smith',
      'email': 'jane@example.com',
      'role': 'Admin',
      'status': 'Active',
      'joinDate': '2024-01-10',
    },
    {
      'id': 'U003',
      'name': 'Bob Johnson',
      'email': 'bob@example.com',
      'role': 'User',
      'status': 'Inactive',
      'joinDate': '2024-01-05',
    },
  ];

  String _searchQuery = '';
  String _selectedRole = 'All';
  String _selectedStatus = 'All';

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _users.where((user) {
      final matchesSearch = user['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           user['email'].toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesRole = _selectedRole == 'All' || user['role'] == _selectedRole;
      final matchesStatus = _selectedStatus == 'All' || user['status'] == _selectedStatus;
      return matchesSearch && matchesRole && matchesStatus;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Users Management'),
        backgroundColor: const Color(0xFF0C1D67),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0C1D67),
              Color(0xFF8B2DD9),
              Color(0xFFF165C3),
            ],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon: const Icon(Icons.search, color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      hintStyle: const TextStyle(color: Colors.white70),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedRole,
                          dropdownColor: const Color(0xFF0C1D67),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Role',
                            labelStyle: const TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: ['All', 'Admin', 'User']
                              .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                              .toList(),
                          onChanged: (value) => setState(() => _selectedRole = value!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedStatus,
                          dropdownColor: const Color(0xFF0C1D67),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Status',
                            labelStyle: const TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: ['All', 'Active', 'Inactive']
                              .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                              .toList(),
                          onChanged: (value) => setState(() => _selectedStatus = value!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: Colors.white.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ExpansionTile(
                      title: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: Text(
                              user['name'][0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user['name'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  user['email'],
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: user['status'] == 'Active' ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user['status'],
                              style: TextStyle(
                                color: user['status'] == 'Active' ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Role: ${user['role']}', style: const TextStyle(color: Colors.white)),
                              Text('Join Date: ${user['joinDate']}', style: const TextStyle(color: Colors.white70)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Edit'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: user['status'] == 'Active' ? Colors.orange : Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text(user['status'] == 'Active' ? 'Deactivate' : 'Activate'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
