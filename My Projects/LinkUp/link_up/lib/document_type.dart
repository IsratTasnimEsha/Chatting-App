import 'package:flutter/material.dart';

class DocumentType {
  final String type;
  final IconData icon;

  DocumentType(this.type, this.icon);
}

final Map<String, DocumentType> documentTypes = {
  'pdf': DocumentType('PDF Document', Icons.picture_as_pdf),
  'doc': DocumentType('Word Document', Icons.description),
  'docx': DocumentType('Word Document', Icons.description),
  'xls': DocumentType('Excel Spreadsheet', Icons.table_chart),
  'xlsx': DocumentType('Excel Spreadsheet', Icons.table_chart),
  'ppt': DocumentType('PowerPoint Presentation', Icons.slideshow),
  'pptx': DocumentType('PowerPoint Presentation', Icons.slideshow),
  'csv': DocumentType('CSV File', Icons.list_alt),
  'mp4': DocumentType('Video File', Icons.video_library),
  'avi': DocumentType('Video File', Icons.video_library),
  'mov': DocumentType('Video File', Icons.video_library),
  'png': DocumentType('Image File', Icons.image),
  'jpg': DocumentType('Image File', Icons.image),
  'jpeg': DocumentType('Image File', Icons.image),
  // Add more document types as needed
};