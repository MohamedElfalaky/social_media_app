import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/controllers/auth_controller.dart';
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
          ? SafeArea(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _samplePosts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final post = _samplePosts[index];
                  return _PostCard(post: post, theme: theme);
                },
              ),
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
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_horiz),
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
  });

  final String username;
  final String caption;
  final String timestamp;
  final int likes;
  final int comments;
}

const List<_Post> _samplePosts = [
  _Post(
    username: 'Alice',
    caption: 'Sunny day at the beach ☀️',
    timestamp: '2h',
    likes: 128,
    comments: 14,
  ),
  _Post(
    username: 'Bob',
    caption: 'New year, new goals! 💪',
    timestamp: '5h',
    likes: 86,
    comments: 9,
  ),
  _Post(
    username: 'Charlie',
    caption: 'Coffee + code = ❤️',
    timestamp: '1d',
    likes: 203,
    comments: 32,
  ),
  _Post(
    username: 'Dina',
    caption: 'Hiking adventures this weekend 🥾',
    timestamp: '2d',
    likes: 54,
    comments: 5,
  ),
];
