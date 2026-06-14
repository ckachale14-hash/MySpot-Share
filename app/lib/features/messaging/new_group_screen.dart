import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/repositories.dart';
import '../../core/widgets/user_avatar.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/author_ref.dart';
import '../discover/discovery_providers.dart';
import '../profile/user_providers.dart';

/// Create a group conversation: name it, then pick at least two members.
class NewGroupScreen extends ConsumerStatefulWidget {
  const NewGroupScreen({super.key});

  @override
  ConsumerState<NewGroupScreen> createState() => _NewGroupScreenState();
}

class _NewGroupScreenState extends ConsumerState<NewGroupScreen> {
  final _title = TextEditingController();
  final _selected = <String, AppUser>{};
  String _query = '';
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _toggle(AppUser u) => setState(() {
        if (_selected.containsKey(u.uid)) {
          _selected.remove(u.uid);
        } else {
          _selected[u.uid] = u;
        }
      });

  Future<void> _create() async {
    final me = ref.read(currentAuthorRefProvider);
    final title = _title.text.trim();
    if (me == null || title.isEmpty || _selected.length < 2) return;
    setState(() => _busy = true);
    try {
      final others = _selected.values
          .map((u) => AuthorRef(
                uid: u.uid,
                handle: u.handle,
                displayName: u.displayName,
                photoUrl: u.photoUrl,
                verified: u.verified,
              ))
          .toList();
      final cid = await ref
          .read(conversationRepositoryProvider)
          .createGroup(me: me, others: others, title: title);
      if (mounted) context.pushReplacement('/chat/$cid');
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = ref.watch(currentAuthorRefProvider)?.uid;
    final canCreate =
        _title.text.trim().isNotEmpty && _selected.length >= 2 && !_busy;
    return Scaffold(
      appBar: AppBar(
        title: const Text('New group'),
        actions: [
          TextButton(
            onPressed: canCreate ? _create : null,
            child: _busy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Create'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _title,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Group name',
                prefixIcon: Icon(Icons.groups_outlined),
              ),
            ),
          ),
          if (_selected.isNotEmpty)
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final u in _selected.values)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InputChip(
                        avatar: UserAvatar(
                            photoUrl: u.photoUrl,
                            name: u.displayName,
                            radius: 12),
                        label: Text(u.displayName),
                        onDeleted: () => _toggle(u),
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchBar(
              hintText: 'Search people by @handle',
              leading: const Icon(Icons.search),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          Expanded(
            child: _query.isEmpty
                ? const Center(child: Text('Search to add members'))
                : ref.watch(searchPeopleProvider(_query)).when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('$e')),
                      data: (users) {
                        final people =
                            users.where((u) => u.uid != myUid).toList();
                        if (people.isEmpty) {
                          return const Center(child: Text('No people found'));
                        }
                        return ListView(
                          children: [
                            for (final u in people)
                              CheckboxListTile(
                                value: _selected.containsKey(u.uid),
                                onChanged: (_) => _toggle(u),
                                secondary: UserAvatar(
                                    photoUrl: u.photoUrl, name: u.displayName),
                                title: Text(u.displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                subtitle: Text('@${u.handle}'),
                              ),
                          ],
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
