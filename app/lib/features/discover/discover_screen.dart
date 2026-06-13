import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/entities/founder_journey.dart';
import '../../core/widgets/user_tile.dart';
import '../profile/user_providers.dart';
import 'discovery_providers.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final industry = ref.watch(appUserProvider).value?.industry ?? '';
    final pymk = ref.watch(peopleYouMayKnowProvider(industry)).value ?? const [];
    final newbies = ref.watch(newUsersProvider).value ?? const [];
    final tags = ref.watch(trendingProvider).value ?? const [];
    final journeys = ref.watch(recentJourneysProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: SearchBar(
              hintText: 'Search people by @handle',
              leading: const Icon(Icons.search),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
        ),
      ),
      body: _query.isNotEmpty
          ? _SearchResults(query: _query)
          : ListView(
              children: [
                _heading(t, 'People you may know'),
                _users(pymk),
                _heading(t, 'New entrepreneurs'),
                _users(newbies),
                _heading(t, 'Trending'),
                if (tags.isEmpty)
                  _empty('No trends yet.')
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        for (final tag in tags)
                          Chip(label: Text('#${tag.tag} · ${tag.postCount}')),
                      ],
                    ),
                  ),
                _heading(t, 'Founder journeys'),
                if (journeys.isEmpty)
                  _empty('No journeys shared yet.')
                else
                  for (final j in journeys)
                    ListTile(
                      leading: const Icon(Icons.auto_stories_outlined),
                      title: Text(j.title,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                          '${j.author.displayName} · ${journeyStageLabels[j.stage]}'),
                      onTap: () => context.push('/journey/${j.id}'),
                    ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _heading(ThemeData t, String s) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(s, style: t.textTheme.titleMedium),
      );

  Widget _empty(String s) =>
      Padding(padding: const EdgeInsets.all(16), child: Text(s));

  Widget _users(List<AppUser> users) => users.isEmpty
      ? _empty('Nothing here yet.')
      : Column(children: [for (final u in users) UserTile(user: u)]);
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.query});
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(searchPeopleProvider(query));
    return results.when(
      data: (users) => users.isEmpty
          ? const Center(
              child: Padding(
                  padding: EdgeInsets.all(32), child: Text('No people found')))
          : ListView(children: [for (final u in users) UserTile(user: u)]),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }
}
