import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart'; // for Firebase Realtime Database
import 'package:provider/provider.dart'; // Import provider
import 'theme_provider.dart'; // Import your ThemeProvider

class ColorModePage extends StatefulWidget {
  final String email, text;

  const ColorModePage({Key? key, required this.email, required this.text}) : super(key: key);

  @override
  _ColorModePageState createState() => _ColorModePageState();
}

class _ColorModePageState extends State<ColorModePage> {
  final List<Color> colors = [
    ...Colors.primaries,
    ...Colors.accents,
  ];

  Color? _selectedColor;

  @override
  void initState() {
    super.initState();
    _fetchColor(); // Fetch the color when the page initializes
  }

  void _fetchColor() async {
    final databaseReference = FirebaseDatabase.instance.ref();
    final colorSnapshot = await databaseReference.child('users/${widget.email}/appColor').get();

    if (colorSnapshot.exists) {
      String colorValue = colorSnapshot.value.toString();
      try {
        Color fetchedColor = _getColorFromHex(colorValue);
        setState(() {
          // Find and set the fetched color as selected
          _selectedColor = colors.firstWhere(
                (color) => color.value == fetchedColor.value,
            orElse: () => Colors.transparent, // Default value if not found
          );
        });
      } catch (e) {
        print("Error parsing color: $e");
      }
    }
  }

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor"; // Add alpha if not provided
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  void _saveColor(Color color) async {
    final databaseReference = FirebaseDatabase.instance.ref();
    String colorValue = color.value.toRadixString(16).padLeft(8, '0'); // Convert color to hex string with alpha
    databaseReference.child('users/${widget.email}/appColor').set(colorValue);

    Provider.of<ThemeProvider>(context, listen: false).setColor(color);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.text),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5, // Number of circles per row
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: colors.length,
          itemBuilder: (context, index) {
            final color = colors[index];
            final isSelected = color == _selectedColor; // Check if the color is selected

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = color; // Update the selected color
                  _saveColor(color); // Save the selected color
                });
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: color,
                    radius: 24,
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 28,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
