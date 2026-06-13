import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/app_user.dart';
import 'follow_button.dart';
import 'user_avatar.dart';
import 'verified_badge.dart';

class UserTile extends StatelessWidget {
  const UserTile({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      '@${user.handle}',
      if (user.industry.isNotEmpty) user.industry,
    ].join(' · ');

    return ListTile(
      onTap: () => context.push('/u/${user.uid}'),
      leading: UserAvatar(photoUrl: user.photoUrl, name: user.displayName),
      title: Row(
        children: [
          Flexible(
            child: Text(user.displayName,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          if (user.verified)
            const Padding(
                padding: EdgeInsets.only(left: 4), child: VerifiedBadge(size: 14)),
        ],
      ),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: FollowButton(targetUid: user.uid, compact: true),
    );
  }
}
