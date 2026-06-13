import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/business.dart';
import 'rating_stars.dart';
import 'user_avatar.dart';
import 'verified_badge.dart';

class BusinessCard extends StatelessWidget {
  const BusinessCard({super.key, required this.business});

  final Business business;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: ListTile(
        onTap: () => context.push('/b/${business.id}'),
        leading: UserAvatar(photoUrl: business.logoUrl, name: business.name),
        title: Row(children: [
          Flexible(
              child: Text(business.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
          if (business.verified)
            const Padding(
                padding: EdgeInsets.only(left: 4), child: VerifiedBadge(size: 14)),
        ]),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (business.category.isNotEmpty) Text(business.category),
            RatingStars(
                rating: business.ratingAvg, count: business.ratingCount, size: 14),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
