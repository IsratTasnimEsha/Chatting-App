import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentViewerPage extends StatelessWidget {
  final String documentUrl;

  const DocumentViewerPage({Key? key, required this.documentUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Document Viewer")),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            // Code to open or download the document
            await launch(documentUrl);
          },
          child: Text("Open Document"),
        ),
      ),
    );
  }
}
