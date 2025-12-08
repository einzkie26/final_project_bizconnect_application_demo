import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/company_model.dart';

class CompanyController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> createCompany(String name, String description, String industry) async {
    final user = _auth.currentUser;
    if (user == null) return '';

    final company = CompanyModel(
      id: '',
      name: name,
      description: description,
      industry: industry,
      ownerId: user.uid,
      memberIds: [user.uid],
      createdAt: DateTime.now(),
    );

    final docRef = await _firestore.collection('companies').add(company.toMap());
    return docRef.id;
  }

  Stream<List<CompanyModel>> getUserCompanies() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('companies')
        .where('memberIds', arrayContains: user.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CompanyModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> inviteToCompany(String companyId, String companyName, String userId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final invitation = CompanyInvitation(
      id: '',
      companyId: companyId,
      companyName: companyName,
      inviterId: user.uid,
      inviteeId: userId,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('company_invitations').add(invitation.toMap());
  }

  Stream<List<CompanyInvitation>> getPendingInvitations() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('company_invitations')
        .where('inviteeId', isEqualTo: user.uid)
        .where('isAccepted', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CompanyInvitation.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> acceptInvitation(String invitationId, String companyId, String position, String idNumber) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final batch = _firestore.batch();

    // Mark invitation as accepted
    batch.update(
      _firestore.collection('company_invitations').doc(invitationId),
      {'isAccepted': true},
    );

    // Add user to company
    batch.update(
      _firestore.collection('companies').doc(companyId),
      {
        'memberIds': FieldValue.arrayUnion([user.uid])
      },
    );

    // Add user company membership
    batch.set(
      _firestore.collection('company_members').doc('${companyId}_${user.uid}'),
      {
        'companyId': companyId,
        'userId': user.uid,
        'position': position,
        'idNumber': idNumber,
        'joinedAt': DateTime.now(),
      },
    );

    await batch.commit();
  }

  Future<void> switchToCompanyMode(String companyId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'isCompanyMode': true,
      'activeCompanyId': companyId,
    });
  }

  Future<void> switchToPersonalMode() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'isCompanyMode': false,
      'activeCompanyId': null,
    });
  }

  Future<void> deleteCompany(String companyId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Get company info before deletion
    final companyDoc = await _firestore.collection('companies').doc(companyId).get();
    if (!companyDoc.exists) return;
    
    final companyData = companyDoc.data()!;
    final companyName = companyData['name'];
    final ownerId = companyData['ownerId'];

    final batch = _firestore.batch();

    // Mark company chats as unknown instead of deleting
    final chatsQuery = await _firestore
        .collection('chats')
        .where('type', isEqualTo: 'company')
        .where('participants', arrayContains: ownerId)
        .get();
    
    for (var chatDoc in chatsQuery.docs) {
      final chatData = chatDoc.data();
      if (chatData['companyName'] == companyName) {
        // Mark chat as unknown company
        batch.update(chatDoc.reference, {
          'companyName': 'Unknown Company',
          'isArchived': true,
          'deletedAt': DateTime.now(),
        });
      }
    }

    // Delete company members
    final membersQuery = await _firestore
        .collection('company_members')
        .where('companyId', isEqualTo: companyId)
        .get();
    
    for (var doc in membersQuery.docs) {
      batch.delete(doc.reference);
    }

    // Delete company document
    batch.delete(_firestore.collection('companies').doc(companyId));

    await batch.commit();
  }
}

final companyControllerProvider = Provider<CompanyController>((ref) {
  return CompanyController();
});