import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import '../models/book.dart';
import '../services/auth_service.dart';
import '../services/book_service.dart';
import 'scanner_screen.dart';
import 'library_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;
  List<Book> books = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    final user = AuthService.currentUser;
    if (user == null) return;
    setState(() => _loading = true);
    try {
      final data = await BookService.loadBooks(user.id);
      setState(() {
        books = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showToast('Erreur chargement');
    }
  }

  void addBook(Book book) {
    setState(() {
      final idx = books.indexWhere((b) => b.id == book.id);
      if (idx != -1) {
        books[idx] = book;
      } else {
        books.insert(0, book);
      }
    });
  }

  void updateBook(Book book) {
    setState(() {
      final idx = books.indexWhere((b) => b.id == book.id);
      if (idx != -1) books[idx] = book;
    });
  }

  void removeBook(String id) {
    setState(() {
      books.removeWhere((b) => b.id == id);
    });
  }

  void _showToast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: AppTheme.mono(size: 12, color: AppColors.txt)),
        backgroundColor: AppColors.sur3,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        margin: const EdgeInsets.only(bottom: 80, left: 40, right: 40),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void switchToLibrary() {
    setState(() => _tabIndex = 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.sur,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📚 ', style: TextStyle(fontSize: 18)),
              Text('Ma ', style: AppTheme.display(size: 20)),
              Text('Bibliothèque', style: AppTheme.display(size: 20, color: AppColors.acc)),
            ],
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.acc3,
              border: Border.all(color: AppColors.acc.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${books.length} livre${books.length > 1 ? 's' : ''}',
              style: AppTheme.mono(size: 10, color: AppColors.acc),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 18, color: AppColors.mut),
            onPressed: () async {
              await AuthService.signOut();
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          ScannerScreen(homeState: this),
          LibraryScreen(homeState: this),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.sur,
          border: Border(top: BorderSide(color: AppColors.bdr)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                _navBtn(0, Icons.qr_code_scanner, 'Scanner'),
                _navBtn(1, Icons.library_books, 'Biblio'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navBtn(int index, IconData icon, String label) {
    final active = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _tabIndex = index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (active)
              Container(
                width: 40,
                height: 2,
                decoration: BoxDecoration(
                  color: AppColors.acc,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            const SizedBox(height: 8),
            Icon(
              icon,
              size: 22,
              color: active ? AppColors.acc : AppColors.mut,
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: AppTheme.mono(
                size: 9,
                weight: FontWeight.w600,
                color: active ? AppColors.acc : AppColors.mut,
              ).copyWith(letterSpacing: 0.6),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
