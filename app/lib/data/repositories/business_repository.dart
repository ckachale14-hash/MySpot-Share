import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/author_ref.dart';
import '../../domain/entities/business.dart';

/// Business directory: profiles, category browse, and reviews. Ratings are
/// aggregated by the onReviewWrite Cloud Function.
class BusinessRepository {
  BusinessRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('businesses');

  Stream<List<Business>> watchByCategory(String? category, {int limit = 50}) {
    Query<Map<String, dynamic>> q = _col;
    if (category != null && category.isNotEmpty) {
      q = q.where('category', isEqualTo: category);
    }
    return q
        .orderBy('ratingAvg', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(Business.fromDoc).toList());
  }

  Stream<Business?> watchBusiness(String id) => _col
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? Business.fromDoc(d) : null);

  Stream<List<Business>> watchMine(String uid) => _col
      .where('ownerId', isEqualTo: uid)
      .limit(20)
      .snapshots()
      .map((s) {
    final list = s.docs.map(Business.fromDoc).toList()
      ..sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    return list;
  });

  Map<String, dynamic> _payload({
    required String name,
    required String category,
    required String description,
    required String logoUrl,
    required List<String> products,
    required List<String> services,
    required String phone,
    required String email,
    required String whatsapp,
    required String address,
    required String website,
  }) =>
      {
        'name': name,
        'category': category,
        'description': description,
        if (logoUrl.isNotEmpty) 'logoUrl': logoUrl,
        'products': products,
        'services': services,
        'contact': {
          'phone': phone,
          'email': email,
          'whatsapp': whatsapp,
          'address': address,
        },
        'links': {'website': website},
      };

  Future<String> create({
    required String ownerId,
    required String name,
    required String category,
    required String description,
    String logoUrl = '',
    List<String> products = const [],
    List<String> services = const [],
    String phone = '',
    String email = '',
    String whatsapp = '',
    String address = '',
    String website = '',
  }) async {
    final ref = await _col.add({
      'ownerId': ownerId,
      ..._payload(
        name: name,
        category: category,
        description: description,
        logoUrl: logoUrl,
        products: products,
        services: services,
        phone: phone,
        email: email,
        whatsapp: whatsapp,
        address: address,
        website: website,
      ),
      'verified': false,
      'ratingAvg': 0,
      'ratingCount': 0,
      'ratingSum': 0,
      'followerCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> update(
    String id, {
    required String name,
    required String category,
    required String description,
    String logoUrl = '',
    List<String> products = const [],
    List<String> services = const [],
    String phone = '',
    String email = '',
    String whatsapp = '',
    String address = '',
    String website = '',
  }) =>
      _col.doc(id).update(_payload(
            name: name,
            category: category,
            description: description,
            logoUrl: logoUrl,
            products: products,
            services: services,
            phone: phone,
            email: email,
            whatsapp: whatsapp,
            address: address,
            website: website,
          ));

  Stream<List<BusinessReview>> watchReviews(String id) => _col
      .doc(id)
      .collection('reviews')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map(BusinessReview.fromDoc).toList());

  Future<void> submitReview(
    String businessId,
    AuthorRef author,
    num rating,
    String text,
  ) =>
      _col.doc(businessId).collection('reviews').doc(author.uid).set({
        'rating': rating,
        'text': text,
        'author': author.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
}
