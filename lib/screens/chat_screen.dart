import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/models/post_model.dart';
import 'package:flutter_application_1/theme/app_theme.dart';
import 'package:flutter_application_1/theme/chat_service.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  final String receiverUserId;
  final String receiverName;

  const ChatScreen({
    super.key,
    required this.chatRoomId,
    required this.receiverUserId,
    required this.receiverName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();

  String _receiverProfileImageUrl = '';
  late String _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _firebaseAuth.currentUser!.uid;
    _loadReceiverData();
    _markAsRead();
  }
  
  void _markAsRead() {
    _chatService.markChatAsRead(widget.chatRoomId);
  }

  void _loadReceiverData() async {
    final userData = await _chatService.getUserData(widget.receiverUserId);
    if (mounted) {
      setState(() {
        _receiverProfileImageUrl = userData['profileImageUrl'];
      });
    }
  }

  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await _chatService.sendMessage(
        widget.chatRoomId,
        widget.receiverUserId,
        _messageController.text,
      );
      _messageController.clear();
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _onConfirmPressed(String userRole) async {
    try {
      await _chatService.submitConfirmation(widget.chatRoomId, userRole);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.receiverName,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [],
      ),
      body: Column(
        children: [
          _buildConfirmationBanner(),
          Expanded(
            child: _buildMessageList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }
  
  Widget _buildConfirmationBanner() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _chatService.getChatRoomStream(widget.chatRoomId),
      builder: (context, chatRoomSnapshot) {
        if (!chatRoomSnapshot.hasData) return const SizedBox.shrink();
        
        final chatRoomData = chatRoomSnapshot.data!.data() as Map<String, dynamic>;
        final String postId = chatRoomData['associatedPostId'] as String? ?? '';
        final String ownerId = chatRoomData['postOwnerId'] as String? ?? '';
        final String finderId = chatRoomData['postFinderId'] as String? ?? '';
        final String confirmationState = chatRoomData['confirmationState'] as String? ?? 'none';

        if (postId.isEmpty || ownerId.isEmpty || finderId.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return StreamBuilder<DocumentSnapshot>(
          stream: _chatService.getPostStream(postId),
          builder: (context, postSnapshot) {
            if (!postSnapshot.hasData) return const SizedBox.shrink();
            
            final post = PostModel.fromFirestore(postSnapshot.data!);
            
            if (post.status == 'recovered' || confirmationState == 'recovered') {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Colors.green.shade100,
                child: Text(
                  'Item successfully recovered!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }

            String userRole = '';
            if (_currentUserId == ownerId) {
              userRole = 'Owner';
            } else if (_currentUserId == finderId) {
              userRole = 'Finder';
            } else {
              return const SizedBox.shrink();
            }

            // MODIFIED: This container is styled to match your request
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12.0),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _buildConfirmationWidget(
                userRole: userRole,
                confirmationState: confirmationState,
              ),
            );
          },
        );
      },
    );
  }

  // MODIFIED: This helper widget contains your new text and UI
  Widget _buildConfirmationWidget({
    required String userRole,
    required String confirmationState,
  }) {
    // Custom button style for the "Confirm" button
    final ButtonStyle confirmButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: AppTheme.secondaryColor, // Bright yellow
      foregroundColor: AppTheme.primaryColor, // Dark blue text
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );

    // --- Case 1: I am the Finder ---
    if (userRole == 'Finder') {
      if (confirmationState == 'none') {
        // Show the Finder's confirmation button
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Is this the owner?',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
            ),
            ElevatedButton(
              onPressed: () => _onConfirmPressed('Finder'),
              style: confirmButtonStyle,
              child: const Text('Confirm'),
            )
          ],
        );
      } else {
        // 'finder_confirmed'
        return Center(
          child: Text(
            'Waiting for Owner to confirm...',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: AppTheme.primaryColor, fontStyle: FontStyle.italic),
          ),
        );
      }
    }
    // --- Case 2: I am the Owner ---
    else {
      if (confirmationState == 'none') {
        // Finder hasn't confirmed yet
        return Center(
          child: Text(
            'Waiting for Finder to confirm the return...',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: AppTheme.primaryColor, fontStyle: FontStyle.italic),
          ),
        );
      } else {
        // 'finder_confirmed', it is now my turn
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'I\'ve received my item.',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
            ),
            ElevatedButton(
              onPressed: () => _onConfirmPressed('Owner'),
              style: confirmButtonStyle,
              child: const Text('Confirm'),
            )
          ],
        );
      }
    }
  }


  Widget _buildMessageList() {
    return StreamBuilder(
      stream: _chatService.getMessages(widget.chatRoomId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No messages yet. Say hi!',
              style: TextStyle(color: AppTheme.lightTextColor, fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          itemCount: snapshot.data!.docs.length,
          padding: const EdgeInsets.all(10.0),
          itemBuilder: (context, index) {
            return _buildMessageItem(snapshot.data!.docs[index]);
          },
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    bool isCurrentUser = data['senderId'] == _currentUserId;

    var bubbleColor =
        isCurrentUser ? AppTheme.primaryColor : Colors.grey.shade200;
    var textColor = isCurrentUser ? Colors.white : AppTheme.darkTextColor;
    var rowAlignment =
        isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start;

    Widget bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Text(
        data['message'],
        style: GoogleFonts.poppins(fontSize: 16, color: textColor),
      ),
    );

    Widget avatar = CircleAvatar(
      radius: 15,
      backgroundImage: _receiverProfileImageUrl.isNotEmpty
          ? NetworkImage(_receiverProfileImageUrl)
          : null,
      child: _receiverProfileImageUrl.isEmpty
          ? const Icon(Icons.person, size: 15)
          : null,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: rowAlignment,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            avatar,
            const SizedBox(width: 8),
          ],
          
          Column(
            crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 4.0),
                child: Text(
                  isCurrentUser ? "You" : widget.receiverName,
                  style: TextStyle(
                    color: AppTheme.darkTextColor.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ),
              bubble,
            ],
          ),
          
          if (isCurrentUser)
            const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              obscureText: false,
              decoration: InputDecoration(
                hintText: 'Enter message...',
                fillColor: Colors.grey.shade100,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
              ),
            ),
          ),
          IconButton(
            onPressed: _sendMessage,
            icon: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}