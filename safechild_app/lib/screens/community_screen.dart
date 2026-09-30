import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_screen.dart';
import '../services/localization_service.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';

// Data model for a community post
class CommunityPost {
  final String id;
  final String userName;
  final String userPhoto;
  final String content;
  final DateTime createdAt;
  int likes;
  bool isLiked;
  List<CommunityComment> comments;

  CommunityPost({
    required this.id,
    required this.userName,
    required this.userPhoto,
    required this.content,
    required this.createdAt,
    this.likes = 0,
    this.isLiked = false,
    this.comments = const [],
  });
}

// Data model for a post comment
class CommunityComment {
  final String userName;
  final String userPhoto;
  final String content;
  final DateTime createdAt;
  int likes;
  bool isLiked;

  CommunityComment({
    required this.userName,
    required this.userPhoto,
    required this.content,
    required this.createdAt,
    this.likes = 0,
    this.isLiked = false,
  });
}

// Community feed state (local simulation, no backend yet)
final communityProvider =
    StateNotifierProvider<CommunityNotifier, List<CommunityPost>>((ref) {
      return CommunityNotifier();
    });

class CommunityNotifier extends StateNotifier<List<CommunityPost>> {
  CommunityNotifier()
    : super([
        CommunityPost(
          id: '1',
          userName: 'John Smith',
          userPhoto: 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
          content:
              'Heightened awareness near the primary school this morning. '
              'Let\'s all stay vigilant!',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          likes: 12,
          comments: [
            CommunityComment(
              userName: 'Marie D.',
              userPhoto:
                  'https://cdn-icons-png.flaticon.com/512/4140/4140047.png',
              content:
                  'Thanks for the heads up, I will let the parents group know.',
              createdAt: DateTime.now().subtract(const Duration(hours: 1)),
            ),
          ],
        ),
      ]);

  void addPost(String userName, String content) {
    state = [
      CommunityPost(
        id: DateTime.now().toString(),
        userName: userName,
        userPhoto: 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
        content: content,
        createdAt: DateTime.now(),
      ),
      ...state,
    ];
  }

  void toggleLike(String postId) {
    state = [
      for (final post in state)
        if (post.id == postId)
          CommunityPost(
            id: post.id,
            userName: post.userName,
            userPhoto: post.userPhoto,
            content: post.content,
            createdAt: post.createdAt,
            likes: post.isLiked ? post.likes - 1 : post.likes + 1,
            isLiked: !post.isLiked,
            comments: post.comments,
          )
        else
          post,
    ];
  }

  void addComment(String postId, String userName, String content) {
    state = [
      for (final post in state)
        if (post.id == postId)
          CommunityPost(
            id: post.id,
            userName: post.userName,
            userPhoto: post.userPhoto,
            content: post.content,
            createdAt: post.createdAt,
            likes: post.likes,
            isLiked: post.isLiked,
            comments: [
              ...post.comments,
              CommunityComment(
                userName: userName,
                userPhoto:
                    'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
                content: content,
                createdAt: DateTime.now(),
              ),
            ],
          )
        else
          post,
    ];
  }
}

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  void _showNewPostSheet(
    BuildContext context,
    WidgetRef ref,
    String userName,
    AppTranslations tr,
  ) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tr.translate('new_post'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: tr.translate('post_hint'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                fillColor: Theme.of(context).colorScheme.surfaceContainer,
                filled: true,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  ref
                      .read(communityProvider.notifier)
                      .addPost(userName, controller.text);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(tr.translate('publish')),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showCommentsSheet(
    BuildContext context,
    WidgetRef ref,
    CommunityPost post,
    String currentUserName,
    AppTranslations tr,
  ) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setInternalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                tr.translate('comments').toUpperCase(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(height: 30),
              Expanded(
                child: ListView.builder(
                  itemCount: post.comments.length,
                  itemBuilder: (context, index) {
                    final comment = post.comments[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(comment.userPhoto),
                            radius: 15,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainer,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        comment.userName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        comment.content,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 8,
                                    top: 4,
                                  ),
                                  child: Text(
                                    tr.translate('like'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          hintText: tr.translate('comment_hint'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: Icon(
                        Icons.send,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () {
                        if (controller.text.isNotEmpty) {
                          ref
                              .read(communityProvider.notifier)
                              .addComment(
                                post.id,
                                currentUserName,
                                controller.text,
                              );
                          controller.clear();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(communityProvider);
    final user = ref.watch(authProvider).value;
    final tr = AppTranslations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.translate('community_title')),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: context.colors.surfaceMuted,
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tr.translate('community_info'),
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return FadeSlideIn(
                  // Stagger the first screenful so the feed reads as
                  // arriving in sequence rather than snapping in at once.
                  delay: index < 6 ? AppMotion.stagger * index : Duration.zero,
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: NetworkImage(post.userPhoto),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post.userName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    tr.translate('time_ago'),
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            post.content,
                            style: const TextStyle(fontSize: 14, height: 1.4),
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          Row(
                            children: [
                              TextButton.icon(
                                onPressed: () => ref
                                    .read(communityProvider.notifier)
                                    .toggleLike(post.id),
                                icon: Icon(
                                  post.isLiked
                                      ? Icons.thumb_up
                                      : Icons.thumb_up_alt_outlined,
                                  size: 20,
                                  color: post.isLiked
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                ),
                                label: Text(
                                  "${post.likes}",
                                  style: TextStyle(
                                    color: post.isLiked
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              TextButton.icon(
                                onPressed: () => _showCommentsSheet(
                                  context,
                                  ref,
                                  post,
                                  user?.name ?? "User",
                                  tr,
                                ),
                                icon: Icon(
                                  Icons.chat_bubble_outline,
                                  size: 20,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                                label: Text(
                                  "${post.comments.length} ${tr.translate('comments')}",
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            _showNewPostSheet(context, ref, user?.name ?? "User", tr),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(
          Icons.add_comment,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }
}
