import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.bone,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: TextField(
            controller: _controller,
            autofocus: true,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 15,
              color: AppTheme.ink,
            ),
            decoration: InputDecoration(
              hintText: '¿Qué estás buscando?',
              hintStyle: GoogleFonts.spaceGrotesk(
                color: AppTheme.silver,
                fontSize: 15,
              ),
              prefixIcon: Icon(Icons.search_rounded,
                  color: AppTheme.silver, size: 20),
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ScannerScreen(),
                  ),
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.ink,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(
                  Icons.center_focus_strong_rounded,
                  color: AppTheme.bone,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RECIENTES',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ash,
                    letterSpacing: 2,
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: Text(
                    'LIMPIAR',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.silver,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRecentItem('Nike Air Jordan'),
            _buildRecentItem('Adidas Ozrah'),
            _buildRecentItem('Jordan 1'),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentItem(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.bone,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm / 2),
          ),
          child: Icon(Icons.history_rounded, color: AppTheme.silver, size: 18),
        ),
        title: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppTheme.ink,
          ),
        ),
        trailing: Icon(Icons.north_west_rounded,
            size: 16, color: AppTheme.silver),
        onTap: () {},
      ),
    );
  }
}