import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminCompaniesPage extends StatefulWidget {
  const AdminCompaniesPage({super.key});

  @override
  State<AdminCompaniesPage> createState() => _AdminCompaniesPageState();
}

class _AdminCompaniesPageState extends State<AdminCompaniesPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Management'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search companies...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('companies').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                var companies = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toLowerCase();
                  return name.contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  itemCount: companies.length,
                  itemBuilder: (context, index) {
                    final company = companies[index].data() as Map<String, dynamic>;
                    final companyId = companies[index].id;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: company['logoUrl'] != null 
                            ? NetworkImage(company['logoUrl']) 
                            : null,
                          child: company['logoUrl'] == null 
                            ? const Icon(Icons.business) 
                            : null,
                        ),
                        title: Text(company['name'] ?? 'No Name'),
                        subtitle: Text(company['industry'] ?? 'No Industry'),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'view', child: Text('View Details')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete Company')),
                          ],
                          onSelected: (value) {
                            if (value == 'view') _viewCompanyDetails(companyId, company);
                            if (value == 'delete') _deleteCompany(companyId, company['name']);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _viewCompanyDetails(String companyId, Map<String, dynamic> company) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(company['name'] ?? 'Company Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Industry: ${company['industry'] ?? 'N/A'}'),
              Text('Description: ${company['description'] ?? 'N/A'}'),
              Text('Location: ${company['location'] ?? 'N/A'}'),
              Text('Website: ${company['website'] ?? 'N/A'}'),
              Text('Company ID: $companyId'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _deleteCompany(String companyId, String? companyName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Company'),
        content: Text('Are you sure you want to delete ${companyName ?? 'this company'}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('companies').doc(companyId).delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Company deleted successfully')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
