import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';

class FullScreenImagePage extends StatelessWidget {
  final List<XFile> images;
  final VoidCallback onSend;
  final VoidCallback onAddMore;

  FullScreenImagePage({
    required this.images,
    required this.onSend,
    required this.onAddMore,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preview'),
        actions: [
          IconButton(
            icon: Icon(Icons.add_photo_alternate),
            onPressed: onAddMore,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              itemCount: images.length,
              itemBuilder: (context, index) {
                return PhotoView(
                  imageProvider: FileImage(File(images[index].path)),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      onSend();
                      Navigator.pop(context); // Close full screen preview after sending
                    },
                    child: Text('Send'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class UserMessagePage extends StatefulWidget {
  final String email;
  final String other_email;

  UserMessagePage({required this.email, required this.other_email});

  @override
  _UserMessagePageState createState() => _UserMessagePageState();
}

class _UserMessagePageState extends State<UserMessagePage> {
  final DatabaseReference _userRef = FirebaseDatabase.instance.reference().child('users');
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<Map<String, dynamic>> _messages = []; // List to hold chat messages

  String _username = '';
  String _profilePicUrl = ''; // Initialize with an empty string
  List<XFile> _selectedImages = []; // Store selected images
  int? _tappedCardIndex;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _listenToMessages();
  }

  void _listenToMessages() {
    final chatRef = _userRef.child('${widget.email}/chat/${widget.other_email}');
    chatRef.onChildAdded.listen((event) {
      final Map<String, dynamic> messageData = {
        'id': event.snapshot.key,
        'messages': event.snapshot.value,
      };
      setState(() {
        _messages.add(messageData);
      });
    });
  }

  void _fetchUserData() async {
    final userRef = _userRef.child(widget.other_email);

    // Fetch username
    final nameSnapshot = await userRef.child('name').get();
    if (nameSnapshot.exists) {
      setState(() {
        _username = nameSnapshot.value as String;
      });
    }

    // Fetch profile picture URL
    final profilePicRef = _storage.ref().child('users/${widget.other_email}/profile_pic.png');
    try {
      final url = await profilePicRef.getDownloadURL();
      setState(() {
        _profilePicUrl = url;
      });
    } catch (e) {
      // Handle errors (e.g., file not found)
      setState(() {
        _profilePicUrl = ''; // Or some default value
      });
    }
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
                    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
                    Navigator.pop(context, pickedFile);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_album),
                  title: Text('Gallery'),
                  onTap: () async {
                    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
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

    // Reference paths for both users
    final messageRef1 = _userRef.child('${widget.email}/chat/${widget.other_email}/$currentTime');
    final messageRef2 = _userRef.child('${widget.other_email}/chat/${widget.email}/$currentTime');

    if (_messageController.text.isNotEmpty) {
      // Handle text message
      final message = _messageController.text;
      await messageRef1.set({'${widget.email}': message});
      await messageRef2.set({'${widget.email}': message});
      _messageController.clear();
    }

    if (_selectedImages.isNotEmpty) {
      // Handle image messages
      for (var image in _selectedImages) {
        final storageRef1 = _storage.ref().child('users/${widget.email}/chat/${widget.other_email}/$currentTime/${widget.email}.png');
        final storageRef2 = _storage.ref().child('users/${widget.other_email}/chat/${widget.email}/$currentTime/${widget.email}.png');

        // Upload image
        try {
          final uploadTask1 = storageRef1.putFile(File(image.path));
          final uploadTask2 = storageRef2.putFile(File(image.path));

          await Future.wait([uploadTask1, uploadTask2]); // Wait for both uploads to complete

          // Save image messages in the database
          await messageRef1.set({'${widget.email}': '**##firebase*@*storage##**'});
          await messageRef2.set({'${widget.email}': '**##firebase*@*storage##**'});
        } catch (e) {
          // Handle upload errors
          print('Error uploading image: $e');
        }
      }
      setState(() {
        _selectedImages.clear(); // Clear selected images after sending
      });
      Navigator.pop(context); // Close full screen preview
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: _profilePicUrl.isNotEmpty ? NetworkImage(_profilePicUrl) : null,
              child: _profilePicUrl.isEmpty ? Icon(Icons.person) : null,
            ),
            SizedBox(width: 10),
            Text(_username),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final messageId = message['id'];
                final messageData = message['messages'] as Map<dynamic, dynamic>?;

                if (messageData == null) {
                  return SizedBox.shrink();
                }

                bool isCurrentUserMessage = messageData.containsKey(widget.email);
                bool isOtherUserMessage = messageData.containsKey(widget.other_email);

                final timeString = DateTime.fromMillisecondsSinceEpoch(int.parse(messageId)).toLocal().toString();
                final messageContent = isCurrentUserMessage
                    ? messageData[widget.email] as String? ?? ''
                    : messageData[widget.other_email] as String? ?? '';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _tappedCardIndex = _tappedCardIndex == index ? null : index;
                      });
                      print('Tapped index: $_tappedCardIndex'); // Debugging statement
                    },
                    child: Row(
                      mainAxisAlignment: isCurrentUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        // Display image on the left of the white card if it's the other user's message
                        if (!isCurrentUserMessage)
                          CircleAvatar(
                            backgroundImage: _profilePicUrl.isNotEmpty ? NetworkImage(_profilePicUrl) : null,
                          ),
                        SizedBox(width: 8),
                        // Display the message card
                        Expanded(
                          child: Column(
                            crossAxisAlignment: isCurrentUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              // Display timeString for tapped white cards and green cards
                              if (_tappedCardIndex == index)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Text(
                                    timeString,
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ),
                              Card(
                                color: isCurrentUserMessage ? Colors.green : Colors.white,
                                elevation: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    messageContent,
                                    style: TextStyle(
                                      color: isCurrentUserMessage ? Colors.white : Colors.black,
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.camera_alt),
                  onPressed: () => _pickImage(),
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
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
    );
  }
}