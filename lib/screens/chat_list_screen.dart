import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/screens/chat_screen.dart';
import 'package:flutter_application_1/theme/app_theme.dart';
import 'package:flutter_application_1/theme/chat_service.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _getTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final difference = now.difference(timestamp.toDate());

    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'just now';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Messages',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 32,
                    ),
                  ),
                  Text(
                    'Connect with other students',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTextColor
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(30.0),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Search conversation',
                    hintStyle: TextStyle(color: AppTheme.lightTextColor),
                    prefixIcon: Icon(Icons.search, color: AppTheme.lightTextColor),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                    isDense: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _chatService.getChatRooms(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading chats.'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'You have no messages yet.\nStart a conversation from a post.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.lightTextColor, fontSize: 16),
                      ),
                    );
                  }

                  // MODIFIED: Manually filter the documents in the app
                  final String currentUserId = _auth.currentUser!.uid;
                  final chatDocs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final List<dynamic> hiddenFor = data['hiddenFor'] ?? [];
                    // Only show chats that are NOT hidden for the current user
                    return !hiddenFor.contains(currentUserId);
                  }).toList();
                  
                  if (chatDocs.isEmpty) {
                    return const Center(
                      child: Text(
                        'You have no messages yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.lightTextColor, fontSize: 16),
                      ),
                    );
                  }
                  // --- END OF MODIFICATION ---

                  return ListView.builder(
                    itemCount: chatDocs.length,
                    itemBuilder: (context, index) {
                      final chatRoom = chatDocs[index];
                      final chatRoomData = chatRoom.data() as Map<String, dynamic>;
                      return _buildChatTile(chatRoomData, chatRoom.id);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTile(Map<String, dynamic> chatRoomData, String chatRoomId) {
    final List<dynamic> userIds = chatRoomData['userIds'];
    final String currentUserId = _auth.currentUser!.uid;
    final String otherUserId = userIds.firstWhere((id) => id != currentUserId);
    final String lastMessage = chatRoomData['lastMessage'] ?? '...';
    final Timestamp? lastTimestamp = chatRoomData['lastMessageTimestamp'];
    final String itemStatus = chatRoomData['itemStatus'] ?? 'Item';
    final String itemName = chatRoomData['itemName'] ?? '';
    final int unreadCount = chatRoomData['unreadCount_$currentUserId'] ?? 0;

    final bool isLost = itemStatus == 'Lost';
    final Color statusColor = isLost ? Colors.red.shade600 : Colors.green.shade600;

    return FutureBuilder<Map<String, dynamic>>(
      future: _chatService.getUserData(otherUserId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ListTile();
        }

        final userData = snapshot.data!;
        final String name = userData['name'];
        final String profileImageUrl = userData['profileImageUrl'];

        return Dismissible(
          key: Key(chatRoomId),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) {
            _chatService.hideChatForUser(chatRoomId);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Conversation hidden')),
            );
          },
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: ListTile(
            leading: CircleAvatar(
              radius: 25,
              backgroundImage: profileImageUrl.isNotEmpty 
                  ? NetworkImage(profileImageUrl) 
                  : null,
              child: profileImageUrl.isEmpty 
                  ? const Icon(Icons.person, color: AppTheme.primaryColor) 
                  : null,
            ),
            title: Text(
              name,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        itemStatus,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      itemName,
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.lightTextColor),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  lastMessage,
                  style: GoogleFonts.inter(
                    fontSize: 14, 
                    color: AppTheme.darkTextColor,
                    fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _getTimeAgo(lastTimestamp),
                  style: const TextStyle(color: AppTheme.lightTextColor, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Visibility(
                  visible: unreadCount > 0,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    chatRoomId: chatRoomId,
                    receiverUserId: otherUserId,
                    receiverName: name,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}