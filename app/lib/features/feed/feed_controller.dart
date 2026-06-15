import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/repositories.dart';
import '../../domain/entities/post.dart';

const Object _unset = Object();

/// Immutable state for the paginated For-You feed.
class FeedState {
  const FeedState({
    this.posts = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<Post> posts;
  final bool isLoading; // first page loading
  final bool isLoadingMore; // appending a page
  final bool hasMore;
  final Object? error;

  FeedState copyWith({
    List<Post>? posts,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error = _unset,
  }) =>
      FeedState(
        posts: posts ?? this.posts,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        error: identical(error, _unset) ? this.error : error,
      );
}

/// Cursor-paginated For-You feed: a first page on load/refresh, then more pages
/// appended as the user scrolls. Pull-to-refresh resets to page one.
class FeedController extends StateNotifier<FeedState> {
  FeedController(this._ref) : super(const FeedState()) {
    refresh();
  }

  final Ref _ref;
  static const _pageSize = 12;
  DocumentSnapshot? _cursor;

  Future<void> refresh() async {
    _cursor = null;
    state = const FeedState(isLoading: true);
    try {
      final page = await _ref
          .read(postRepositoryProvider)
          .fetchForYou(limit: _pageSize);
      _cursor = page.cursor;
      state = FeedState(
        posts: page.posts,
        isLoading: false,
        hasMore: page.posts.length == _pageSize,
      );
    } catch (e) {
      state = FeedState(isLoading: false, hasMore: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final page = await _ref
          .read(postRepositoryProvider)
          .fetchForYou(startAfter: _cursor, limit: _pageSize);
      _cursor = page.cursor ?? _cursor;
      state = state.copyWith(
        posts: [...state.posts, ...page.posts],
        isLoadingMore: false,
        hasMore: page.posts.length == _pageSize,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false, hasMore: false);
    }
  }
}

final feedControllerProvider =
    StateNotifierProvider.autoDispose<FeedController, FeedState>(
  FeedController.new,
);
