import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/post_model.dart';
import 'package:flutter_application_1/screens/chat_screen.dart';
import 'package:flutter_application_1/screens/comment_screen.dart';
import 'package:flutter_application_1/services/post_service.dart';
import 'package:flutter_application_1/theme/app_theme.dart';
import 'package:flutter_application_1/theme/chat_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final PostService _postService = PostService();
  final ChatService _chatService = ChatService();

  PostCard({super.key, required this.post});

  String _getTimeAgo(Timestamp timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp.toDate());
    if (difference.inDays > 0) return '${difference.inDays} days ago';
    if (difference.inHours > 0) return '${difference.inHours} hours ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes} mins ago';
    return 'just now';
  }

  // MODIFIED: Added mounted checks
  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Delete Post'),
          content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () async { // Made this async
                await _postService.deletePost(post.id, post.imageUrl);
                
                if (!ctx.mounted) return; // Mounted check
                Navigator.of(ctx).pop();

                if (!context.mounted) return; // Mounted check
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post deleted successfully.')),
                );
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final bool isLost = post.itemStatus == 'Lost';
    final Color statusColor =
        isLost ? Colors.red.shade600 : Colors.green.shade600;

    const String placeholderProfileImage =
        'https://via.placeholder.com/150/141449/FBB313?text=B';
    const String placeholderItemImage =
        'https://via.placeholder.com/600x400/333333/FFFFFF?text=Item+Image';

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final bool canMessage = currentUserId != null && currentUserId != post.userId;
    final bool isLiked = post.likes.contains(currentUserId);
    final bool isOwner = currentUserId != null && currentUserId == post.userId;

    return Card(
      margin: const EdgeInsets.only(bottom: 10, left: 0, right: 0),
      elevation: 0,
      shape: const RoundedRectangleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(placeholderProfileImage),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 14, color: AppTheme.lightTextColor),
                          const SizedBox(width: 4),
                          Text(
                            _getTimeAgo(post.timestamp),
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.lightTextColor),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.location_on,
                              size: 14, color: AppTheme.lightTextColor),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              // MODIFIED: Changed to 'locationName'
                              post.locationName.split(',')[0],
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.lightTextColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    post.itemStatus,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (isOwner)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _showDeleteDialog(context),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              post.itemName,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              post.description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: Image.network(
                post.imageUrl.isEmpty ? placeholderItemImage : post.imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    color: Colors.grey.shade200,
                    child: const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.primaryColor)),
                  );
                },
                errorBuilder: (context, error, stackTrace) =>
                    Image.network(placeholderItemImage,
                        height: 200, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildActionButton(
                      context,
                      icon: isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : AppTheme.lightTextColor,
                      count: post.likes.length,
                      onTap: () {
                        _postService.toggleLike(post.id, post.likes);
                      },
                    ),
                    _buildActionButton(
                      context,
                      icon: Icons.comment_outlined,
                      color: AppTheme.lightTextColor,
                      count: post.commentCount,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CommentsScreen(postId: post.id),
                          ),
                        );
                      },
                    ),
                    _buildActionButton(
                      context,
                      icon: Icons.share_outlined,
                      color: AppTheme.lightTextColor,
                      count: 0,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Share feature not yet implemented.')),
                        );
                      },
                    ),
                  ],
                ),
                
                if (canMessage)
                  ElevatedButton(
                    onPressed: () async {
                      final String chatRoomId = await _chatService.getOrCreateChatRoom(
                        post.userId,
                        post.id,
                        post.itemName,
                        post.itemStatus,
                      );
                      
                      // MODIFIED: Added mounted check
                      if (!context.mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            chatRoomId: chatRoomId,
                            receiverUserId: post.userId,
                            receiverName: post.userName,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    child: const Text('Message', style: TextStyle(color: Colors.white, fontSize: 14)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required int count,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 4),
              Text(
                count.toString(),
                style: const TextStyle(fontSize: 14, color: AppTheme.lightTextColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}