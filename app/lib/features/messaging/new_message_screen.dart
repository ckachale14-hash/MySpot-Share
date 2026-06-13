import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/repositories.dart';
import '../../core/widgets/user_avatar.dart';
import '../../core/widgets/verified_badge.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/author_ref.dart';
import '../discover/discovery_providers.dart';
import '../profile/user_providers.dart';

class NewMessageScreen extends ConsumerStatefulWidget {
  const NewMessageScreen({super.key});

  @override
  ConsumerState<NewMessageScreen> createState() => _NewMessageScreenState();
}

class _NewMessageScreenState extends ConsumerState<NewMessageScreen> {
  String _query = '';

  Future<void> _start(AppUser user) async {
    final me = ref.read(currentAuthorRefProvider);
    if (me == null) return;
    final other = AuthorRef(
      uid: user.uid,
      handle: user.handle,
      displayName: user.displayName,
      photoUrl: user.photoUrl,
      verified: user.verified,
    );
    final cid =
        await ref.read(conversationRepositoryProvider).getOrCreateDirect(me, other);
    if (mounted) context.pushReplacement('/chat/$cid');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New message'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: SearchBar(
              autoFocus: true,
              hintText: 'Search people by @handle',
              leading: const Icon(Icons.search),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
        ),
      ),
      body: _query.isEmpty
          ? const Center(child: Text('Search for someone to message'))
          : ref.watch(searchPeopleProvider(_query)).when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (users) => users.isEmpty
                    ? const Center(child: Text('No people found'))
                    : ListView(
                        children: [
                          for (final u in users)
                            ListTile(
                              onTap: () => _start(u),
                              leading: UserAvatar(
                                  photoUrl: u.photoUrl, name: u.displayName),
                              title: Row(children: [
                                Flexible(
                                    child: Text(u.displayName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis)),
                                if (u.verified)
                                  const Padding(
                                      padding: EdgeInsets.only(left: 4),
                                      child: VerifiedBadge(size: 14)),
                              ]),
                              subtitle: Text('@${u.handle}'),
                            ),
                        ],
                      ),
              ),
    );
  }
}
