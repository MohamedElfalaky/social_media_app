import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/controllers/auth_controller.dart';
import 'package:social_media_app/controllers/posts_controller.dart';
import 'package:social_media_app/screens/create_post_screen.dart';
import 'package:social_media_app/screens/create_post_screen.dart';
import 'package:social_media_app/screens/login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          FirebaseAuth.instance.currentUser!.displayName ?? 'Unknown',
        ),
        centerTitle: false,
        actions: [
          Icon(Icons.notifications_none),
          SizedBox(width: 12),
          Icon(Icons.search),
          SizedBox(width: 12),
          InkWell(
            onTap: () async {
              AuthController().signOut().then((response) {
                if (response.success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(response.message ?? 'Sign out successful'),
                    ),
                  );

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) => LoginScreen(),
                    ),
                    (Route<dynamic> route) => false,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(response.message ?? 'Sign out failed'),
                    ),
                  );
                }
              });
            },
            child: Icon(Icons.logout),
          ),
          SizedBox(width: 12),
        ],
      ),
      body: FirebaseAuth.instance.currentUser!.emailVerified
          ? StreamBuilder(
              stream: PostsController().getPostsStream(),
              builder: (context, asyncSnapshot) {
                if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (asyncSnapshot.hasError) {
                  return Center(child: Text('Error: ${asyncSnapshot.error}'));
                } else if (asyncSnapshot.hasData &&
                    asyncSnapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No posts available. Tap the + button to create a new post!',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  );
                } else if (asyncSnapshot.hasData &&
                    asyncSnapshot.data!.docs.isNotEmpty) {
                  List<QueryDocumentSnapshot> postsDocs =
                      asyncSnapshot.data!.docs;
                  List<_Post> posts = postsDocs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return _Post(
                      username: data['publisherUserName'] ?? 'Unknown',
                      caption: data['postContent'] ?? '',
                      publisherUserId: data['publisherUserId'] ?? '',
                      postId: doc.id,

                      timestamp: data['createdAt'] != null
                          ? (data['createdAt'] as Timestamp)
                                .toDate()
                                .toLocal()
                                .toString()
                          : 'Unknown time',
                      likes: data['likes'] ?? 0,
                      comments: data['comments'] ?? 0,
                    );
                  }).toList();

                  return SafeArea(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: posts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        return _PostCard(post: post, theme: theme);
                      },
                    ),
                  );
                } else {
                  return Center(child: Text('Something went wrong!'));
                }
              },
            )
          : Center(
              child: Column(
                children: [
                  Text('Please verify your email address.'),
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.currentUser!
                          .sendEmailVerification();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Verification email sent. Please check your inbox.',
                          ),
                        ),
                      );
                    },
                    child: Text('Resend Verification Email'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.currentUser!.reload();
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('user updated')));
                    },
                    child: Text('Reload Verification Status'),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.theme});

  final _Post post;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Avatar + name + timestamp + menu
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Text(
                    post.username.substring(0, 1).toUpperCase(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.username, style: theme.textTheme.titleMedium),
                      Text(
                        post.timestamp,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(
                            0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (FirebaseAuth.instance.currentUser!.uid ==
                    post.publisherUserId)
                  IconButton(
                    onPressed: () {
                      PostsController().deletePost(postId: post.postId);
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Content image (placeholder if null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: Colors.grey.shade200,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.image,
                    size: 48,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Actions: like, comment, share, bookmark
            Row(
              children: [
                _ActionIcon(
                  icon: Icons.favorite_border,
                  label: post.likes.toString(),
                  onTap: () {},
                ),
                const SizedBox(width: 16),
                _ActionIcon(
                  icon: Icons.mode_comment_outlined,
                  label: post.comments.toString(),
                  onTap: () {},
                ),
                const SizedBox(width: 16),
                _ActionIcon(
                  icon: Icons.send_outlined,
                  label: 'Share',
                  onTap: () {},
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.bookmark_border),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Caption
            Text(post.caption, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: theme.iconTheme.color),
            const SizedBox(width: 6),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

// Simple UI model
class _Post {
  const _Post({
    required this.username,
    required this.caption,
    required this.timestamp,
    required this.likes,
    required this.comments,
    required this.publisherUserId,
    required this.postId,
  });

  final String username;
  final String caption;
  final String timestamp;
  final String publisherUserId;
  final int likes;
  final int comments;
  final String postId;
}
