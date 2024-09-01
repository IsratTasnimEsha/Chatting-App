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

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _listenToMessages();
    _checkFriendStatus();
    _checkBlockStatus();
    _fetchUserColor(); // Fetch the color for other_email
  }

  void _fetchUserColor() {
    DatabaseReference colorRef = FirebaseDatabase.instance
        .ref('users/${widget.email}/chatColor/${widget.other_email}');

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

  void _listenToMessages() {
    final chatRef =
        _userRef.child('${widget.email}/chat/${widget.other_email}');

    chatRef.onChildAdded.listen((event) {
      final messageId = event.snapshot.key;
      final messageData = event.snapshot.value;

      setState(() {
        _messages.add({
          'id': messageId,
          'messages': messageData,
        });
        _scrollToBottom();
      });
    });

    chatRef.onChildChanged.listen((event) {
      final messageId = event.snapshot.key;
      final messageData = event.snapshot.value;

      setState(() {
        final index = _messages.indexWhere((msg) => msg['id'] == messageId);
        if (index != -1) {
          _messages[index] = {
            'id': messageId,
            'messages': messageData,
          };
        }
      });
    });

    chatRef.onChildRemoved.listen((event) {
      final messageId = event.snapshot.key;

      setState(() {
        _messages.removeWhere((msg) => msg['id'] == messageId);
      });
    });
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

    // Reference paths for both users
    final messageRef1 = _userRef
        .child('${widget.email}/chat/${widget.other_email}/$currentTime');
    final messageRef2 = _userRef
        .child('${widget.other_email}/chat/${widget.email}/$currentTime');

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
        final storageRef1 = _storage.ref().child(
            'users/${widget.email}/chat/${widget.other_email}/$currentTime/${widget.email}/image.png');
        final storageRef2 = _storage.ref().child(
            'users/${widget.other_email}/chat/${widget.email}/$currentTime/${widget.email}/image.png');

        // Upload image
        try {
          final uploadTask1 = storageRef1.putFile(File(image.path));
          final uploadTask2 = storageRef2.putFile(File(image.path));

          await Future.wait(
              [uploadTask1, uploadTask2]); // Wait for both uploads to complete

          // Save image messages in the database
          await messageRef1
              .set({'${widget.email}': '**##image*#@#*storage##**'});
          await messageRef2
              .set({'${widget.email}': '**##image*#@#*storage##**'});
        } catch (e) {
          // Handle upload errors
          print('Error uploading image: $e');
        }
      }
      setState(() {
        _selectedImages.clear(); // Clear selected images after sending
      });
    }

    if (_selectedDocument != null) {
      // Handle document message
      final storageRef1 = _storage.ref().child(
          'users/${widget.email}/chat/${widget.other_email}/$currentTime/${widget.email}/${_selectedDocument!.path.split('/').last}');
      final storageRef2 = _storage.ref().child(
          'users/${widget.other_email}/chat/${widget.email}/$currentTime/${widget.email}/${_selectedDocument!.path.split('/').last}');

      try {
        final uploadTask1 = storageRef1.putFile(_selectedDocument!);
        final uploadTask2 = storageRef2.putFile(_selectedDocument!);

        await Future.wait(
            [uploadTask1, uploadTask2]); // Wait for both uploads to complete

        // Save document message in the database
        await messageRef1
            .set({'${widget.email}': '**##document*#@#*storage##**'});
        await messageRef2
            .set({'${widget.email}': '**##document*#@#*storage##**'});
      } catch (e) {
        // Handle upload errors
        print('Error uploading document: $e');
      }
      setState(() {
        _selectedDocument = null; // Clear selected document after sending
      });
    }
  }

  Future<String> _getImageUrl(String firstValue, String secondValue) async {
    final storageRef = FirebaseStorage.instance.ref().child(
        'users/${widget.email}/chat/${widget.other_email}/$firstValue/$secondValue/image.png');
    return await storageRef.getDownloadURL();
  }

  Future<String> _getDocumentUrl(String firstValue, String secondValue) async {
    // Construct the storage reference to the directory
    final storageRef = FirebaseStorage.instance.ref().child(
        'users/${widget.email}/chat/${widget.other_email}/$firstValue/$secondValue');

    // List all files in the directory
    final ListResult result = await storageRef.listAll();

    // If there are any items in the directory, get the first item's download URL
    if (result.items.isNotEmpty) {
      final Reference firstFile = result.items.first;
      return await firstFile.getDownloadURL();
    } else {
      throw Exception('No document found in the specified directory');
    }
  }

  // Add this method to handle deletion
  Future<void> _deleteMessage(String messageId, bool deleteForEveryone) async {
    final messageRef1 =
        _userRef.child('${widget.email}/chat/${widget.other_email}/$messageId');
    final messageRef2 =
        _userRef.child('${widget.other_email}/chat/${widget.email}/$messageId');

    try {
      if (deleteForEveryone) {
        await messageRef1
            .set({'${widget.email}': '**##deleted*#@#*message##**'});
        await messageRef2
            .set({'${widget.email}': '**##deleted*#@#*message##**'});
      } else {
        await messageRef1.remove();
      }

      // Remove the image if it exists
      final storageRef1 = _storage.ref().child(
          'users/${widget.email}/chat/${widget.other_email}/$messageId/${widget.email}/image.png');
      final storageRef2 = _storage.ref().child(
          'users/${widget.other_email}/chat/${widget.email}/$messageId/${widget.email}/image.png');

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
        _messages.removeWhere((message) => message['id'] == messageId);
      });
    } catch (e) {
      print('Error deleting message: $e');
    }
  }

  void _editMessage(String messageId, String currentMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController _editController =
            TextEditingController(text: currentMessage);

        return AlertDialog(
          title: Text('Edit Message'),
          content: TextField(
            controller: _editController,
            decoration: InputDecoration(hintText: 'Edit your message'),
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
                final newMessage = _editController.text;
                if (newMessage.isNotEmpty) {
                  await _updateMessage(messageId, newMessage);
                  Navigator.pop(context); // Close the dialog
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _copyText(String messageId, String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message copied to clipboard')),
      );
    }).catchError((e) {
      print('Error copying text: $e');
    });
  }

  Future<void> _updateMessage(String messageId, String newMessage) async {
    final messageRef1 =
        _userRef.child('${widget.email}/chat/${widget.other_email}/$messageId');
    final messageRef2 =
        _userRef.child('${widget.other_email}/chat/${widget.email}/$messageId');

    try {
      await messageRef1.update({
        '${widget.email}': newMessage,
        'edited': true, // Indicate that the message has been edited
      });
      await messageRef2.update({
        '${widget.email}': newMessage,
        'edited': true,
      });
    } catch (e) {
      print('Error updating message: $e');
    }
  }

  void _showDeleteOptions(
      String messageId, String secondValue, String currentMessage) {
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
                    _copyText(messageId, currentMessage);
                  },
                ),
              if (isCurrentUser &&
                  currentMessage != '**##image*#@#*storage##**' &&
                  currentMessage !=
                      '**##document*#@#*storage##**') // Show 'Edit Message' option for the current user
                ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Edit Message'),
                  onTap: () {
                    Navigator.pop(context); // Close the bottom sheet
                    _editMessage(messageId, currentMessage);
                  },
                ),
              if (currentMessage != '**##deleted*#@#*message##**') ...[
                if (isCurrentUser) // Show 'Delete for you' and 'Delete for everyone' options for the current user
                  ListTile(
                    leading: Icon(Icons.delete),
                    title: Text('Delete for you'),
                    onTap: () {
                      Navigator.pop(context); // Close the bottom sheet
                      _deleteMessage(messageId, false);
                    },
                  ),
                if (isCurrentUser) // Show 'Delete for everyone' option for the current user
                  ListTile(
                    leading: Icon(Icons.delete_forever),
                    title: Text('Delete for everyone'),
                    onTap: () {
                      Navigator.pop(context); // Close the bottom sheet
                      _deleteMessage(messageId, true);
                    },
                  ),
                if (!isCurrentUser) // Show 'Delete for you' option for the other user
                  ListTile(
                    leading: Icon(Icons.delete),
                    title: Text('Delete for you'),
                    onTap: () {
                      Navigator.pop(context); // Close the bottom sheet
                      _deleteMessage(messageId, false);
                    },
                  ),
              ] else if (isCurrentUser) // Only 'Delete for you' option if the message is deleted
                ListTile(
                  leading: Icon(Icons.delete),
                  title: Text('Delete for you'),
                  onTap: () {
                    Navigator.pop(context); // Close the bottom sheet
                    _deleteMessage(messageId, false);
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
    final fileName = _decodeFileName(fileUrl);
    final documentType = getDocumentType(fileName);

    return GestureDetector(
      onTap: () {
        // Handle document tap (e.g., navigate to a document viewer or download)
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
                      : color_1, // Set the icon color
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    documentType.type,
                    style: TextStyle(
                      color: isCurrentUser
                          ? Colors.white
                          : color_1, // Set color based on isCurrentUser
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            // First column: Profile picture
            GestureDetector(
              onTap: () => _buildProfilePage(),
              // Call the function when the CircleAvatar is tapped
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
                  final messageId = message['id'];
                  final messageData =
                      message['messages'] as Map<dynamic, dynamic>?;

                  if (messageData == null) {
                    return SizedBox.shrink();
                  }

                  bool isCurrentUserMessage =
                      messageData.containsKey(widget.email);
                  bool isOtherUserMessage =
                      messageData.containsKey(widget.other_email);

                  final timeString =
                      DateTime.fromMillisecondsSinceEpoch(int.parse(messageId))
                          .toLocal()
                          .toString();

                  final firstValue = messageId;
                  final secondValue =
                      isOtherUserMessage ? widget.other_email : widget.email;
                  final thirdValue = messageData[secondValue] ?? '';
                  final isEdited = messageData.containsKey('edited') &&
                      messageData['edited'] == true;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 4.0, horizontal: 8.0),
                    child: GestureDetector(
                      onLongPress: () {
                        _showDeleteOptions(messageId, secondValue, thirdValue);
                      },
                      onTap: () {
                        setState(() {
                          _tappedCardIndex =
                              _tappedCardIndex == index ? null : index;
                        });
                        print('Tapped index: $_tappedCardIndex');
                      },
                      child: Row(
                        mainAxisAlignment: isCurrentUserMessage
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          if (!isCurrentUserMessage)
                            CircleAvatar(
                              backgroundImage: _profilePicUrl.isNotEmpty
                                  ? NetworkImage(_profilePicUrl)
                                  : null,
                            ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: isCurrentUserMessage
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                if (_tappedCardIndex == index)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Text(
                                      timeString,
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey),
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
                                              height: 100,
                                              width: 150,
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
                                else if (thirdValue ==
                                    '**##document*#@#*storage##**')
                                  FutureBuilder<String>(
                                    future: _getDocumentUrl(
                                        firstValue, secondValue),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return CircularProgressIndicator();
                                      } else if (snapshot.hasError) {
                                        return Text('Error loading document');
                                      } else if (snapshot.hasData) {
                                        return _buildDocumentWidget(
                                          snapshot.data!,
                                          secondValue == widget.email,
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
                                    color: isCurrentUserMessage
                                        ? color_1
                                        : Colors.white,
                                    elevation: 4,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                                0.5,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              thirdValue,
                                              style: TextStyle(
                                                color: isCurrentUserMessage
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                            if (isEdited)
                                              Align(
                                                alignment:
                                                    Alignment.bottomRight,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 4.0),
                                                  child: Text(
                                                    '(edited)',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontStyle:
                                                          FontStyle.italic,
                                                      color: secondValue ==
                                                              widget.email
                                                          ? Colors.white
                                                          : Colors.grey,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
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
