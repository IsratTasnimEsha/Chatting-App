import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

class FullScreenImagePage2 extends StatelessWidget {
  final String imageUrl;

  FullScreenImagePage2({required this.imageUrl});

  Future<void> _downloadImage() async {
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    String formattedTime = timestamp.toString();

    final taskId = await FlutterDownloader.enqueue(
      url: imageUrl,
      savedDir: '/storage/emulated/0/Download', // or use a different directory
      fileName: '${formattedTime}.png',
      showNotification: true,
      openFileFromNotification: true,
    );
    print('Download task id: $taskId');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context); // Go back when tapped
            },
            child: Center(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _downloadImage,
              child: Icon(Icons.download),
            ),
          ),
        ],
      ),
    );
  }
}

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
                      Navigator.pop(
                          context); // Close full screen preview after sending
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