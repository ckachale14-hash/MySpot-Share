import 'package:cloud_firestore/cloud_firestore.dart';

class Business {
  const Business({
    required this.id,
    required this.ownerId,
    this.name = '',
    this.logoUrl = '',
    this.coverUrl = '',
    this.description = '',
    this.category = '',
    this.products = const [],
    this.services = const [],
    this.phone = '',
    this.email = '',
    this.whatsapp = '',
    this.address = '',
    this.website = '',
    this.verified = false,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.followerCount = 0,
    this.createdAt,
  });

  final String id;
  final String ownerId;
  final String name;
  final String logoUrl;
  final String coverUrl;
  final String description;
  final String category;
  final List<String> products;
  final List<String> services;
  final String phone;
  final String email;
  final String whatsapp;
  final String address;
  final String website;
  final bool verified;
  final num ratingAvg;
  final int ratingCount;
  final int followerCount;
  final DateTime? createdAt;

  factory Business.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const {};
    final contact = (m['contact'] as Map<String, dynamic>?) ?? const {};
    final links = (m['links'] as Map<String, dynamic>?) ?? const {};
    List<String> strList(dynamic v) => ((v ?? []) as List).map((e) => '$e').toList();
    return Business(
      id: doc.id,
      ownerId: (m['ownerId'] ?? '') as String,
      name: (m['name'] ?? '') as String,
      logoUrl: (m['logoUrl'] ?? '') as String,
      coverUrl: (m['coverUrl'] ?? '') as String,
      description: (m['description'] ?? '') as String,
      category: (m['category'] ?? '') as String,
      products: strList(m['products']),
      services: strList(m['services']),
      phone: (contact['phone'] ?? '') as String,
      email: (contact['email'] ?? '') as String,
      whatsapp: (contact['whatsapp'] ?? '') as String,
      address: (contact['address'] ?? '') as String,
      website: (links['website'] ?? '') as String,
      verified: (m['verified'] ?? false) as bool,
      ratingAvg: (m['ratingAvg'] ?? 0) as num,
      ratingCount: (m['ratingCount'] ?? 0) as int,
      followerCount: (m['followerCount'] ?? 0) as int,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class BusinessReview {
  const BusinessReview({
    required this.uid,
    this.authorName = '',
    this.authorPhotoUrl = '',
    this.rating = 0,
    this.text = '',
    this.createdAt,
  });

  final String uid;
  final String authorName;
  final String authorPhotoUrl;
  final num rating;
  final String text;
  final DateTime? createdAt;

  factory BusinessReview.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const {};
    final author = (m['author'] as Map<String, dynamic>?) ?? const {};
    return BusinessReview(
      uid: doc.id,
      authorName: (author['displayName'] ?? '') as String,
      authorPhotoUrl: (author['photoUrl'] ?? '') as String,
      rating: (m['rating'] ?? 0) as num,
      text: (m['text'] ?? '') as String,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
