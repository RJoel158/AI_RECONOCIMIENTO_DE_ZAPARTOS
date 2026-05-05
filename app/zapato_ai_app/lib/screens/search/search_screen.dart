import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../scanner/scanner_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: "What are you looking for?",
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ScannerScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Recent Search",
                  style: AppTheme.lightTheme.textTheme.displayLarge?.copyWith(
                    fontSize: 22,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    "CLEAR ALL", 
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildRecentItem("Nike Air Jordan"),
            _buildRecentItem("Adidas Ozrah"),
            _buildRecentItem("Jordan 1"),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentItem(String label) {
    return ListTile(
      leading: const Icon(Icons.history, color: Colors.grey),
      title: Text(label, style: const TextStyle(fontSize: 16)),
      trailing: const Icon(Icons.close, size: 20, color: Colors.grey),
      onTap: () {},
    );
  }
}