import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:link_up/view_friend_profile.dart';
import 'package:link_up/view_profile.dart';
import 'package:flutter/services.dart';
import 'document_type.dart';
import 'document_viewer.dart';
import 'full_screen_image.dart';
import 'package:intl/intl.dart';

Color color_1 = Colors.blue;

class UserMessagePage extends StatefulWidget {
  final String email;
  final String other_email;

  UserMessagePage({required this.email, required this.other_email});

  @override
  _UserMessagePageState createState() => _UserMessagePageState();
}

class _UserMessagePageState extends State<UserMessagePage> {
  final DatabaseReference _userRef =
  FirebaseDatabase.instance.reference().child('users');
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<Map<String, dynamic>> _messages = []; // List to hold chat messages
  final ScrollController _scrollController =
  ScrollController(); // Scroll controller for ListView

  String _username = '';
  String _status = '';
  String _profilePicUrl = ''; // Initialize with an empty string
  List<XFile> _selectedImages = []; // Store selected images
  int? _tappedCardIndex;
  bool _isFriend = false;
  bool _isBlock = false;
  bool isEdited = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _listenToMessages();
    _seenMessages();
    _checkFriendStatus();
    _checkBlockStatus();
    _fetchUserColor(); // Fetch the color for other_email
  }

  void _listenToMessages() {
    final String currentUserEmail = widget.email;
    final String otherUserEmail = widget.other_email;

    final chatRef = FirebaseDatabase.instance.ref()
        .child('users')
        .child(otherUserEmail)
        .child('chat')
        .child(currentUserEmail);

    // Listen for new messages
    chatRef.onChildAdded.listen((event) async {
      final messageKey = event.snapshot.key; // This will be the push() key
      final chatRef1 = chatRef.child('$messageKey');

      try {
        final snapshot = await chatRef1.once();
        final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;

        if (data != null) {
          String senderId = '';
          String? content;
          bool isEdited = false;
          String? sentTime;
          String status = 'Sent';
          String? deliveredTime;
          String? seenTime;

          if (data.containsKey('content')) {
            // Flat structure
            content = data['content'] as String?;
            isEdited = data['edited'] ?? false;
            sentTime = data['sentTime'] as String?;
            status = data['status'] ?? 'Sent';
            deliveredTime = data['deliveredTime'] as String?;
            seenTime = data['seenTime'] as String?;

          } else {
            // Nested structure
            for (var key in data.keys) {
              if (key != 'content' && key != 'edited' && key != 'sentTime' && key != 'status'
                  && key != 'seenTime' && key != 'deliveredTime') {
                senderId = key;
                content = data[key]?['content'] as String?;
                isEdited = data[key]?['edited'] ?? false;
                sentTime = data[key]?['sentTime'] as String?;
                status = data[key]?['status'] ?? 'Sent';
                deliveredTime = data[key]?['deliveredTime'] as String?;
                seenTime = data[key]?['seenTime'] as String?;
              }
            }
          }

          setState(() {
            _messages.add({
              'message_key': messageKey,
              'sender_id': senderId,
              'content': content ?? '',
              'edited': isEdited,
              'sentTime': sentTime ?? '',
              'status': status,
              'deliveredTime': deliveredTime ?? '',
              'seenTime': seenTime ?? '',
            });
            _scrollToBottom();
          });
        } else {
          print('No snapshot value exists for message key: $messageKey');
        }
      } catch (e) {
        print('Error retrieving new message content: $e');
      }
    });

    // Listen for message updates
    chatRef.onChildChanged.listen((event) async {
      final messageKey = event.snapshot.key; // The push() key of the message
      final chatRef1 = chatRef.child('$messageKey'); // Reference to the updated message

      try {
        // Fetch the updated data
        final snapshot = await chatRef1.once();
        final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;

        if (data != null) {

          String senderId = '';
          String? content;
          bool isEdited = false;
          String? sentTime;
          String status = 'Sent';
          String? deliveredTime;
          String? seenTime;

          if (data.containsKey('content')) {
            // Flat structure
            content = data['content'] as String?;
            isEdited = data['edited'] ?? false;
            sentTime = data['sentTime'] as String?;
            status = data['status'] ?? 'Sent';
            deliveredTime = data['deliveredTime'] as String?;
            seenTime = data['seenTime'] as String?;

          } else {
            // Nested structure
            for (var key in data.keys) {
              if (key != 'content' && key != 'edited' && key != 'sentTime' &&
                  key != 'status' && key != 'seenTime') {
                senderId = key;
                content = data[key]?['content'] as String?;
                isEdited = data[key]?['edited'] ?? false;
                sentTime = data[key]?['sentTime'] as String?;
                status = data[key]?['status'] ?? 'Sent';
                deliveredTime = data[key]?['deliveredTime'] as String?;
                seenTime = data[key]?['seenTime'] as String?;
              }
            }
          }

          final nowTime = DateFormat('yyyy-MM-dd H:m:s').format(DateTime.now());

          // Update the message in the _messages list
          setState(() {
            final index = _messages.indexWhere((msg) => msg['message_key'] == messageKey);

            if (index != -1) {
              // Replace the old message with the updated one
              _messages[index] = {
                'message_key': messageKey,
                'sender_id': senderId,
                'content': content ?? '',
                'edited': isEdited,
                'sentTime': sentTime ?? '',
                'status': status,
                'deliveredTime': deliveredTime ?? '',
                'seenTime': seenTime ?? '',
              };
            } else {
              print('Updated message not found in the list');
            }
          });

          // Check if status is "Delivered" or "Sent" and update to "Seen"
          if (status == 'Delivered' || status == 'Sent') {
            final messageRef = chatRef1.child(senderId);

            // Update the message status to "Seen" and add seenTime
            await messageRef.update({
              'status': 'Seen',
              'seenTime': nowTime,
            });

            // Update on both sides (sender and receiver)
            final otherUserRef = FirebaseDatabase.instance.ref('users/$currentUserEmail/chat/$otherUserEmail/$messageKey/$senderId');
            await otherUserRef.update({
              'status': 'Seen',
              'seenTime': nowTime,
            });

            print('Updated message status to "Seen" and added seenTime.');
          }

          if (status == 'Sent') {
            final messageRef = chatRef1.child(senderId);

            // Update the message status to "Seen" and add seenTime
            await messageRef.update({
              'status': 'Seen',
              'deliveredTime': nowTime,
              'seenTime': nowTime,
            });

            // Update on both sides (sender and receiver)
            final otherUserRef = FirebaseDatabase.instance.ref('users/$currentUserEmail/chat/$otherUserEmail/$messageKey/$senderId');
            await otherUserRef.update({
              'status': 'Seen',
              'deliveredTime': nowTime,
              'seenTime': nowTime,
            });

            print('Updated message status to "Seen" and added seenTime.');
          }

        } else {
          print('No data exists for updated message ID: $messageKey');
        }
      } catch (e) {
        print('Error updating message content: $e');
      }
    });
  }

  void _seenMessages() async {
    final String currentUserEmail = widget.email;
    final String otherUserEmail = widget.other_email;
    final DatabaseReference chatRef = FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(otherUserEmail)
        .child('chat')
        .child(currentUserEmail);

    try {
      // Fetch all messages in the chat reference
      final DataSnapshot snapshot = await chatRef.get();

      if (snapshot.exists) {
        final Map<dynamic, dynamic> messages = snapshot.value as Map<dynamic, dynamic>;

        print('\n=== Checking Messages for Seen Update ===');
        for (final messageId in messages.keys) {
          final messageRef = FirebaseDatabase.instance.ref('users/$otherUserEmail/chat/$currentUserEmail/$messageId');

          final snapshot = await messageRef.once();
          final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;

          if (data != null) {
            final senderId = data.keys.first;

            if (senderId == widget.other_email) {
              final nowTime = DateFormat('yyyy-MM-dd H:m:s').format(DateTime.now());

              // Update both sides of the chat to mark the message as 'Seen'
              await messageRef.child(senderId).update({
                'seenTime': nowTime,
                'status': 'Seen',
              });

              await FirebaseDatabase.instance.ref('users/$currentUserEmail/chat/$otherUserEmail/$messageId/$senderId')
                  .update({
                'seenTime': nowTime,
                'status': 'Seen',
              });

              print('Updated seenTime and status to "Seen" for senderId: $senderId.');
            }
          }
        }
      } else {
        print('No messages found for the chat.');
      }
    } catch (error) {
      print('Error updating message statuses: $error');
    }
  }

  void _fetchUserColor() {
    DatabaseReference colorRef =
    FirebaseDatabase.instance.ref('users/${widget.email}/appColor/');

    colorRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null) {
        setState(() {
          color_1 = _getColorFromHex(data.toString()) as Color;
        });
      }
    });
  }

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor"; // Add alpha if not provided
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  Future<void> _checkFriendStatus() async {
    bool check = await _friendCheck(widget.other_email);
    setState(() {
      _isFriend = check;
    });
  }

  Future<void> _checkBlockStatus() async {
    bool check = await _blockCheck(widget.email);
    setState(() {
      _isBlock = check;
    });
  }

  Future<bool> _friendCheck(String otherEmail) async {
    final userRef = _userRef.child('${widget.email}/friend');

    try {
      final friendsSnapshot = await userRef.get();
      if (friendsSnapshot.exists) {
        final friendsList =
        Map<dynamic, dynamic>.from(friendsSnapshot.value as Map);
        return friendsList.containsValue(otherEmail);
      }
    } catch (e) {
      print('Error checking friends list: $e');
    }

    return false;
  }

  Future<bool> _blockCheck(String otherEmail) async {
    final userRef1 = _userRef.child('${widget.email}/blocked');

    try {
      final blockSnapshot = await userRef1.get();
      if (blockSnapshot.exists) {
        final blockList =
        Map<dynamic, dynamic>.from(blockSnapshot.value as Map);
        return blockList.containsValue(otherEmail);
      }
    } catch (e) {
      print('Error checking friends list: $e');
    }

    final userRef2 = _userRef.child('${widget.email}/blockedBy');

    try {
      final blockSnapshot = await userRef2.get();
      if (blockSnapshot.exists) {
        final blockList =
        Map<dynamic, dynamic>.from(blockSnapshot.value as Map);
        return blockList.containsValue(otherEmail);
      }
    } catch (e) {
      print('Error checking friends list: $e');
    }

    return false;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose(); // Dispose the scroll controller
    super.dispose();
  }


  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _fetchUserData() {
    final userRef = _userRef.child(widget.other_email);

    // Listen for changes to the username
    userRef.child('name').onValue.listen((event) {
      final snapshot = event.snapshot;
      if (snapshot.exists) {
        setState(() {
          _username = snapshot.value as String;
        });
      }
    });

    userRef.child('activeStatus').onValue.listen((event) {
      final snapshot = event.snapshot;
      if (snapshot.exists) {
        setState(() {
          _status = snapshot.value as String;
        });
      }
    });

    // Fetch and listen for profile picture URL
    final profilePicRef =
    _storage.ref().child('users/${widget.other_email}/profile_pic.png');
    profilePicRef.getDownloadURL().then((url) {
      setState(() {
        _profilePicUrl = url;
      });
    }).catchError((e) {
      setState(() {
        _profilePicUrl = ''; // Handle error by setting a default value
      });
    });
  }

  Future<void> _pickImage({bool multiple = false}) async {
    if (multiple) {
      final List<XFile>? images = await _picker.pickMultiImage();
      if (images != null) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } else {
      final XFile? image = await showModalBottomSheet<XFile>(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.camera_alt),
                  title: Text('Camera'),
                  onTap: () async {
                    final pickedFile =
                    await _picker.pickImage(source: ImageSource.camera);
                    Navigator.pop(context, pickedFile);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_album),
                  title: Text('Gallery'),
                  onTap: () async {
                    final pickedFile =
                    await _picker.pickImage(source: ImageSource.gallery);
                    Navigator.pop(context, pickedFile);
                  },
                ),
              ],
            ),
          );
        },
      );

      if (image != null) {
        setState(() {
          _selectedImages = [image];
        });
        _showFullScreenImage();
      }
    }
  }

  void _showFullScreenImage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImagePage(
          images: _selectedImages,
          onSend: _sendMessage,
          onAddMore: () {
            Navigator.pop(context); // Close full screen preview
            _pickImage(multiple: true); // Open gallery for more images
          },
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    String currentTime = DateTime.now().millisecondsSinceEpoch.toString();
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(currentTime)).toLocal();

    final DateFormat formatter = DateFormat('yyyy-MM-dd H:m:s');
    final String timeString = formatter.format(dateTime);

    // Reference paths for both users
    final chatRef1 = _userRef.child('${widget.email}/chat/${widget.other_email}');
    final chatRef2 = _userRef.child('${widget.other_email}/chat/${widget.email}');

    if (_messageController.text.isNotEmpty) {
      // Handle text message
      final message = _messageController.text;
      final newMessageKey = chatRef1.push().key; // Generate unique message key

      final messageData = {
        'content': message,
        'sentTime': timeString,
        'status': 'Sent',
      };

      await chatRef1.child('$newMessageKey/${widget.email}').update(messageData);
      await chatRef2.child('$newMessageKey/${widget.email}').update(messageData);

      _messageController.clear();
    }

    if (_selectedImages.isNotEmpty) {
      // Handle image messages
      for (var image in _selectedImages) {
        final messageKey = chatRef1.push().key;

        // Storage references for both users
        final storageRef1 = _storage.ref().child(
            'users/${widget.email}/chat/${widget.other_email}/$messageKey/${widget.email}/content/${image.path.split('/').last}');
        final storageRef2 = _storage.ref().child(
            'users/${widget.other_email}/chat/${widget.email}/$messageKey/${widget.email}/content/${image.path.split('/').last}');

        try {
          // Upload images
          final uploadTask1 = storageRef1.putFile(File(image.path));
          final uploadTask2 = storageRef2.putFile(File(image.path));

          await Future.wait([uploadTask1, uploadTask2]); // Wait for both uploads

          // Save image message in the database
          final imageMessageData = {
            'content': '**##image*#@#*storage##**',
            'sentTime': timeString,
            'status': 'Sent',
          };

          await chatRef1.child('$messageKey/${widget.email}').update(imageMessageData);
          await chatRef2.child('$messageKey/${widget.email}').update(imageMessageData);

        } catch (e) {
          print('Error uploading image: $e');
        }
      }

      setState(() {
        _selectedImages.clear(); // Clear selected images after sending
      });
    }

    if (_selectedDocument != null) {
      final messageKey = chatRef1.push().key;

      final fileName = _selectedDocument!.path.split('/').last;

      final storageRef1 = _storage.ref().child(
          'users/${widget.email}/chat/${widget.other_email}/$messageKey/${widget.email}/content/$fileName');
      final storageRef2 = _storage.ref().child(
          'users/${widget.other_email}/chat/${widget.email}/$messageKey/${widget.email}/content/$fileName');

      try {
        // Upload document
        final uploadTask1 = storageRef1.putFile(_selectedDocument!);
        final uploadTask2 = storageRef2.putFile(_selectedDocument!);

        await Future.wait([uploadTask1, uploadTask2]); // Wait for both uploads

        // Save document message in the database
        final documentMessageData = {
          'content': '**##document*#@#*storage##**',
          'sentTime': timeString,
          'status': 'Sent',
        };

        await chatRef1.child('$messageKey/${widget.email}').update(documentMessageData);
        await chatRef2.child('$messageKey/${widget.email}').update(documentMessageData);

      } catch (e) {
        print('Error uploading document: $e');
      }

      setState(() {
        _selectedDocument = null; // Clear the selected document after sending
      });
    }
  }


  Future<String> _getImageUrl(String firstValue, String secondValue) async {
    // Reference to the directory containing the image
    final storageRef = FirebaseStorage.instance.ref().child(
        'users/${widget.email}/chat/${widget.other_email}/$firstValue/$secondValue/content/');

    // List all items in the 'content' folder to get the image name
    final listResult = await storageRef.listAll();

    if (listResult.items.isNotEmpty) {
      // Assuming there is only one image, get the first item
      final imageRef = listResult.items.first;

      // Return the download URL for the image
      return await imageRef.getDownloadURL();
    } else {
      throw Exception("No images found in the content folder");
    }
  }

  Future<String> _getDocumentUrl(String firstValue, String secondValue) async {
    // Reference to the directory containing the document
    final storageRef = FirebaseStorage.instance.ref().child(
        'users/${widget.email}/chat/${widget.other_email}/$firstValue/$secondValue/content/');

    // List all items in the 'content' folder to get the document name
    final listResult = await storageRef.listAll();

    if (listResult.items.isNotEmpty) {
      // Assuming there is only one document, get the first item
      final documentRef = listResult.items.first;

      // Return the download URL for the document
      return await documentRef.getDownloadURL();
    } else {
      throw Exception("No documents found in the content folder");
    }
  }

  // Add this method to handle deletion
  Future<void> _deleteMessage(String messageKey, bool deleteForEveryone) async {
    final messageRef1 = _userRef.child(
        '${widget.email}/chat/${widget.other_email}/$messageKey/${widget.email}');
    final messageRef2 = _userRef.child(
        '${widget.other_email}/chat/${widget.email}/$messageKey/${widget.email}');

    try {
      if (deleteForEveryone) {
        await messageRef1.set({'content': '**##deleted*#@#*message##**'});
        await messageRef2.set({'content': '**##deleted*#@#*message##**'});
      } else {
        await messageRef1.remove();
      }

      // Remove the image if it exists
      final storageRef1 = _storage.ref().child(
          'users/${widget.email}/chat/${widget.other_email}/$messageKey/${widget.email}/content/image.png');
      final storageRef2 = _storage.ref().child(
          'users/${widget.other_email}/chat/${widget.email}/$messageKey/${widget.email}/content/image.png');

      if (deleteForEveryone) {
        await Future.wait([
          storageRef1.delete(),
          storageRef2.delete(),
        ]);
      } else {
        await storageRef1.delete();
      }

      // Update local state
      setState(() {
        _messages.removeWhere((message) => message['id'] == messageKey);
      });
    } catch (e) {
      print('Error deleting message: $e');
    }
  }

  void _copyText(String messageKey, String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message copied to clipboard')),
      );
    }).catchError((e) {
      print('Error copying text: $e');
    });
  }

  void _editMessage(String messageKey, String currentMessage) {
    final TextEditingController _editController =
    TextEditingController(text: currentMessage);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Message'),
          content: TextField(
            controller: _editController,
            decoration: InputDecoration(hintText: 'Edit your message'),
            autofocus: true, // Automatically focus on the TextField
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final newMessage = _editController.text
                    .trim(); // Remove leading/trailing whitespace
                if (newMessage.isNotEmpty) {
                  try {
                    await _updateMessage(messageKey, newMessage);
                    Navigator.pop(context); // Close the dialog
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update message: $e')),
                    );
                  }
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    ).whenComplete(
            () => _editController.dispose()); // Dispose of the controller
  }

  Future<void> _updateMessage(String messageKey, String newMessage) async {
    final messageRef1 = _userRef.child(
        '${widget.email}/chat/${widget.other_email}/$messageKey/${widget.email}');
    final messageRef2 = _userRef.child(
        '${widget.other_email}/chat/${widget.email}/$messageKey/${widget.email}');

    try {
      await messageRef1.update({
        'content': newMessage,
        'edited': true, // Indicate that the message has been edited
      });
      await messageRef2.update({
        'content': newMessage,
        'edited': true,
      });
    } catch (e) {
      print('Error updating message: $e');
      throw e; // Re-throw the error to handle it in the calling method
    }
  }

  void _showDeleteOptions(
      String messageKey, String secondValue, String currentMessage, String messageValue,
      String sentTime, String deliveredTime, String seenTime) {
    final isCurrentUser = widget.email == secondValue;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (currentMessage != '**##image*#@#*storage##**' &&
                  currentMessage != '**##document*#@#*storage##**')
                ListTile(
                  leading: Icon(Icons.copy),
                  title: Text('Copy Text'),
                  onTap: () {
                    Navigator.pop(context); // Close the bottom sheet
                    _copyText(messageKey, currentMessage);
                  },
                ),
              if (isCurrentUser &&
                  currentMessage != '**##image*#@#*storage##**' &&
                  currentMessage !=
                      '**##document*#@#*storage##**') // Show 'Edit Message' option for the current user
                ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Edit'),
                  onTap: () {
                    Navigator.pop(context); // Close the bottom sheet
                    _editMessage(
                        messageKey, currentMessage); // Call the edit function
                  },
                ),

              if (currentMessage != '**##deleted*#@#*message##**') ...[
                if (isCurrentUser) // Show 'Delete for you' and 'Delete for everyone' options for the current user
                  ListTile(
                    leading: Icon(Icons.delete),
                    title: Text('Delete for you'),
                    onTap: () {
                      Navigator.pop(context); // Close the bottom sheet
                      _deleteMessage(messageKey, false);
                    },
                  ),
                if (isCurrentUser) // Show 'Delete for everyone' option for the current user
                  ListTile(
                    leading: Icon(Icons.delete_forever),
                    title: Text('Delete for everyone'),
                    onTap: () {
                      Navigator.pop(context); // Close the bottom sheet
                      _deleteMessage(messageKey, true);
                    },
                  ),
                if (!isCurrentUser) // Show 'Delete for you' option for the other user
                  ListTile(
                    leading: Icon(Icons.delete),
                    title: Text('Delete for you'),
                    onTap: () {
                      Navigator.pop(context); // Close the bottom sheet
                      _deleteMessage(messageKey, false);
                    },
                  ),
              ] else if (isCurrentUser) // Only 'Delete for you' option if the message is deleted
                ListTile(
                  leading: Icon(Icons.delete),
                  title: Text('Delete for you'),
                  onTap: () {
                    Navigator.pop(context); // Close the bottom sheet
                    _deleteMessage(messageKey, false);
                  },
                ),
              ListTile(
                leading: Icon(Icons.info),
                title: Text('Details'),
                onTap: () {
                  Navigator.pop(context); // Close the bottom sheet
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), // Rounded corners
                        ),
                        title: Row(
                          children: [
                            SizedBox(width: 8),
                            Text('Message Details'),
                          ],
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.message),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Content:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 32),
                              child: Text(messageValue),
                            ),
                            SizedBox(height: 16), // Spacing
                            Row(
                              children: [
                                Icon(Icons.access_time),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Sent:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 32),
                              child: Text(formatTime(sentTime) ?? 'Unknown'),
                            ),

                            if (deliveredTime != null && deliveredTime.isNotEmpty) ...[
                              SizedBox(height: 16), // Spacing for `Seen` time if it exists
                              Row(
                                children: [
                                  Icon(Icons.visibility,),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Delivered:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 32),
                                child: Text(formatTime(deliveredTime!)),
                              ),
                            ],

                            if (seenTime != null && seenTime.isNotEmpty) ...[
                              SizedBox(height: 16), // Spacing for `Seen` time if it exists
                              Row(
                                children: [
                                  Icon(Icons.visibility,),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Seen:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 32),
                                child: Text(formatTime(seenTime!)),
                              ),
                            ],
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context); // Close the dialog
                            },
                            child: Text('Close'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfilePage() {
    if (_isFriend) {
      return ViewFriendProfilePage(
        email: widget.other_email,
        other_email: widget.email,
      );
    } else if (_isBlock) {
      // Do nothing or show a message
      return Container(); // or a placeholder widget
    } else {
      return ViewProfilePage(
        email: widget.other_email,
        other_email: widget.email,
      );
    }
  }

  File? _selectedDocument; // Variable to store the selected document

  void _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx'],
    );

    if (result != null) {
      setState(() {
        _selectedDocument =
            File(result.files.single.path!); // Store the selected document
      });
    }
  }

  String _decodeFileName(String url) {
    // Extract the file name from the URL
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;
    return pathSegments.isNotEmpty ? pathSegments.last : 'Unknown Document';
  }

  Widget _buildDocumentWidget(String fileUrl, bool isCurrentUser) {
    // Extract the file name from the URL
    final fullPath = _decodeFileName(fileUrl);
    final fileName = fullPath.split('/').last;
    final documentType = getDocumentType(fileName);

    return GestureDetector(
      onTap: () {
        // Handle document tap (e.g., navigate to a document viewer or download)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DocumentViewerPage(
              documentUrl: fileUrl, // Pass the document URL here
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          height: 60,
          width: 150,
          decoration: BoxDecoration(
            color: isCurrentUser ? color_1 : Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: Colors.grey, width: 1),
          ),
          child: Container(
            padding:
            const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  documentType.icon,
                  color: isCurrentUser
                      ? Colors.white
                      : Colors.black, // Set the icon color
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fileName, // Display only the file name
                    style: TextStyle(
                      fontSize: 14,
                      color: isCurrentUser
                          ? Colors.white
                          : Colors.black, // Set color based on isCurrentUser
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  DocumentType getDocumentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return documentTypes[extension] ??
        DocumentType('Unknown Document', Icons.insert_drive_file);
  }

  Color _getMessageColor(String status, bool isCurrentUserMessage) {
    if (status == 'Sent') {
      return isCurrentUserMessage ? color_1.withOpacity(0.0) : Colors.white;
    } else if (status == 'Delivered') {
      return isCurrentUserMessage ? color_1.withOpacity(0.5) : Colors.white; // 50% opacity for 'Delivered'
    } else if (status == 'Seen') {
      return isCurrentUserMessage ? color_1 : Colors.white; // Full color for 'Seen'
    } else {
      return Colors.white; // Default color
    }
  }

  String formatTime(String sentTime) {
    try {
      // Parse the input string to a DateTime object
      DateTime dateTime = DateFormat("yyyy-MM-dd H:m:s").parse(sentTime);
      DateTime now = DateTime.now();

      if (DateFormat("yyyy-MM-dd").format(dateTime) == DateFormat("yyyy-MM-dd").format(now)) {
        // If the date is the same as today, show only the time
        return DateFormat("hh:mm:ss a").format(dateTime);
      } else if (dateTime.year == now.year) {
        // If the year is the same, exclude the year
        return DateFormat("MMM dd hh:mm:ss a").format(dateTime);
      } else {
        // Otherwise, show the full date and time
        return DateFormat("MMM dd, yyyy hh:mm:ss a").format(dateTime);
      }
    } catch (e) {
      // Handle parsing error if input is invalid
      print("Error formatting date: $e");
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            // First column: Profile picture
            GestureDetector(
              onTap: () {
                final profilePage = _buildProfilePage();
                if (profilePage != null) {
                  // Check if _buildProfilePage returns a valid widget
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => profilePage),
                  );
                }
              },
              child: CircleAvatar(
                backgroundImage: _profilePicUrl.isNotEmpty
                    ? NetworkImage(_profilePicUrl)
                    : null,
                child: _profilePicUrl.isEmpty ? Icon(Icons.person) : null,
              ),
            ),
            SizedBox(width: 10),
            // Second column: Username and status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _username,
                    style: TextStyle(fontWeight: FontWeight.normal),
                  ),
                  SizedBox(height: 2), // Space between username and status
                  Text(
                    _status,
                    style: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 12,
                        color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final messageKey = message['message_key'];
                  final senderId = message['sender_id'];
                  final content = message['content'];
                  final sentTime = message['sentTime'];
                  final isEdited = message['edited'];
                  final status = message['status'];
                  final deliveredTime = message['deliveredTime'];
                  final seenTime = message['seenTime'];

                  String formattedTime = formatTime(sentTime);

                  // Check for null content
                  if (content == null) {
                    return const SizedBox.shrink(); // Return an empty widget if content is null
                  }

                  bool isCurrentUserMessage = widget.email == senderId;
                  bool isOtherUserMessage = widget.other_email == senderId;

                  final firstValue = messageKey;
                  final secondValue =
                  isOtherUserMessage ? widget.other_email : widget.email;
                  final thirdValue = content;

                  String messageValue = ''; // Initialize as an empty string (or any other default value)
                  if (content == '**##image*#@#*storage##**') {
                    messageValue = 'Image'; // If the content is the image marker, set messageValue to "Image"
                  }
                  else if (content == '**##document*#@#*storage##**') {
                    messageValue = 'Document'; // If the content is the document marker, set messageValue to "Document"
                  }
                  else {
                    messageValue = content; // Otherwise, just keep the original content
                  }


                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 4.0, horizontal: 8.0),
                    child: GestureDetector(
                      onLongPress: () {
                        _showDeleteOptions(messageKey, secondValue, thirdValue, messageValue,
                            sentTime, deliveredTime, seenTime);
                      },
                      onTap: () {
                        setState(() {
                          _tappedCardIndex =
                          _tappedCardIndex == index ? null : index;
                        });
                      },
                      child: Row(
                        mainAxisAlignment: isCurrentUserMessage
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          if (!isCurrentUserMessage)
                            GestureDetector(
                              onTap: () {
                                final Widget profilePage =
                                _buildProfilePage();
                                if (profilePage is Widget) {
                                  // Ensure that it returns a valid widget
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => profilePage),
                                  );
                                }
                              },
                              child: CircleAvatar(
                                backgroundImage: _profilePicUrl.isNotEmpty
                                    ? NetworkImage(_profilePicUrl)
                                    : null,
                                child: _profilePicUrl.isEmpty
                                    ? Icon(Icons.person)
                                    : null,
                              ),
                            ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: isCurrentUserMessage
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                if (_tappedCardIndex == index) // Show status at the bottom
                                  Align(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        formattedTime,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (thirdValue == '**##image*#@#*storage##**')
                                  FutureBuilder<String>(
                                    future:
                                    _getImageUrl(firstValue, secondValue),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return CircularProgressIndicator();
                                      } else if (snapshot.hasError) {
                                        return Text('Error loading image');
                                      } else if (snapshot.hasData) {
                                        //return Text(firstValue.toString() + "--" + secondValue.toString());
                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    FullScreenImagePage2(
                                                      imageUrl: snapshot.data!,
                                                    ),
                                              ),
                                            );
                                          },
                                          child: ClipRRect(
                                            borderRadius:
                                            BorderRadius.circular(12.0),
                                            child: Container(
                                              height: 120,
                                              width: 200,
                                              decoration: BoxDecoration(
                                                color: Colors.black,
                                                borderRadius:
                                                BorderRadius.circular(12.0),
                                                border: Border.all(
                                                    color: Colors.grey,
                                                    width: 1),
                                              ),
                                              child: Image.network(
                                                snapshot.data!,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        );
                                      } else {
                                        return SizedBox.shrink();
                                      }
                                    },
                                  )
                                else if (thirdValue == '**##document*#@#*storage##**')
                                  FutureBuilder<String>(
                                    future: _getDocumentUrl(firstValue, secondValue),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return CircularProgressIndicator();
                                      } else if (snapshot.hasError) {
                                        return Text('Error loading document');
                                      } else if (snapshot.hasData) {
                                        // Build document display widget with fixed width of 200
                                        return Container(
                                          width: 200,
                                          height: 50,// Set width to 200
                                          child: _buildDocumentWidget(
                                            snapshot.data!,
                                            secondValue == widget.email, // Check if the sender is the current user
                                          ),
                                        );
                                      } else {
                                        return SizedBox.shrink();
                                      }
                                    },
                                  )
                                else if (thirdValue ==
                                      '**##deleted*#@#*message##**')
                                    Card(
                                      color: Colors.transparent,
                                      elevation: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          'This message was deleted',
                                          style: TextStyle(
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    Card(
                                      color: _getMessageColor(status, isCurrentUserMessage),
                                      elevation: 4,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context).size.width * 0.5,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                thirdValue,
                                                style: TextStyle(
                                                  color: isCurrentUserMessage ? Colors.white : Colors.black,
                                                ),
                                              ),
                                              if (isEdited)
                                                Align(
                                                  alignment: Alignment.bottomRight,
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(0.0),
                                                    child: Text(
                                                      isEdited ? '(edited)' : '', // Display `(edited)` or keep empty space
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontStyle: FontStyle.italic,
                                                        color: secondValue ==
                                                            widget.email ? Colors.white : Colors.grey,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                if (_tappedCardIndex == index) // Show status at the bottom
                                  if (isCurrentUserMessage)
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
                              ],
                            ),
                          ),
                          if (isCurrentUserMessage) SizedBox(width: 8),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_selectedDocument != null)
              Padding(
                padding:
                const EdgeInsets.symmetric(vertical: 4.0, horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedDocument!.path.split('/').last,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _selectedDocument =
                          null; // Remove the selected document
                        });
                      },
                    ),
                  ],
                ),
              ),
            if (_isFriend) // Show the bottom navigation bar only if the user is a friend
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.attach_file), // Document icon
                      onPressed: () =>
                          _pickDocument(), // Pick document when icon is pressed
                    ),
                    IconButton(
                      icon: Icon(Icons.camera_alt),
                      onPressed: () => _pickImage(),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        cursorColor: Colors.black, // Set the cursor color here
                        decoration: InputDecoration(
                          hintText: 'Type a message',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(
                              width: 2.0,
                              color: Colors.grey,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(
                              width: 1.0,
                              color: Colors.grey,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(
                              width: 1.0,
                              color: color_1,
                            ),
                          ),
                          hintStyle: TextStyle(
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}