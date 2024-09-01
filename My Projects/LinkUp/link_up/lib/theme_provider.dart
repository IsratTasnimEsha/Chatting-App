import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  Color _color = Colors.blue; // Default color

  Color get color => _color;

  void setColor(Color color) {
    _color = color;
    notifyListeners(); // Notify all listeners about the color change
  }
}