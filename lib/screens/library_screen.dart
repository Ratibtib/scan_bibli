import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../models/book.dart';
import 'home_screen.dart';
import 'book_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  final HomeScreenState homeState;
  const LibraryScreen({super.key, required this.homeState});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _filter = 'all';
  String _rg1Filter = 'all';
  String _rg2Filter = 'all';
  final _searchCtrl = TextEditingController();

  List<Book> get books => widget.homeState.books;

  List<Book> get _filteredBooks {
    final q = _searchCtrl.text.toLowerCase();
    return books.where((b) {
      final matchSearch = q.isEmpty ||
          b.title.toLowerCase().contains(q) ||
          b.authors.toLowerCase().contains(q) ||
          (b.isbn ?? '').contains(q);
      final matchStatus = _filter == 'all' || b.status == _filter;
      final matchRg1 = _rg1Filter == 'all' || b.rangement1 == _rg1Filter;
      final matchRg2 = _rg2Filter == 'all' || b.rangement2 == _rg2Filter;
      return matchSearch && matchStatus && matchRg1 && matchRg2;
    }).toList();
  }

  Set<String> get _rg1Values => books.map((b) => b.rangement1).where((v) => v != null && v.isNotEmpty).cast<String>().toSet();
  Set<String> get _rg2Values => books.map((b) => b.rangement2).where((v) => v != null && v.isNotEmpty).cast<String>().toSet();

  int _countStatus(String status) => books.where((b) => b.status == status).length;

  void _openDetail(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookDetailScreen(
          book: book,
          homeState: widget.homeState,
        ),
      ),
    );
  }

  Future<void> _exportCsv() async {
    if (books.isEmpty) {
      _showToast('Aucune donnée');
      return;
    }
    final rows = <List<String>>[
      ['ISBN', 'Titre', 'Titre original', 'Auteur', 'Contributeurs', 'Éditeur', 'Collection', 'Année', 'Pages', 'Genre', 'Lieu', 'Dewey', 'Catégories Rameau', 'Statut', 'Rangement 1', 'Rangement 2'],
      ...books.map((b) => [
        b.isbn ?? '', b.title, b.titreOriginal ?? '', b.authors, b.roles ?? '',
        b.publisher ?? '', b.collection ?? '', b.year ?? '', b.pages ?? '',
        b.genre ?? '', b.lieu ?? '', b.dewey ?? '', b.categories ?? '',
        b.status, b.rangement1 ?? '', b.rangement2 ?? '',
      ]),
    ];
    final csv = rows.map((r) => r.map((c) => '"${c.replaceAll('"', '""')}"').join(',')).join('\n');
    final bytes = utf8.encode('\uFEFF$csv');
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final dir = Directory.systemTemp;
    final file = File('${dir.path}/bibliotheque_$date.csv');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: 'Export bibliothèque');
    _showToast('CSV exporté');
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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredBooks;

    return Column(
      children: [
        // Stats bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              _statChip('all', 'Tous', books.length, AppColors.txt),
              _statChip('alire', 'À lire', _countStatus('alire'), AppColors.blu),
              _statChip('encours', 'En cours', _countStatus('encours'), AppColors.amber),
              _statChip('lu', 'Lus', _countStatus('lu'), AppColors.grn),
              _statChip('prete', 'Prêtés', _countStatus('prete'), AppColors.red),
            ],
          ),
        ),

        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: TextField(
            controller: _searchCtrl,
            style: AppTheme.ui(size: 13),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Titre, auteur, ISBN…',
              hintStyle: AppTheme.ui(size: 13, color: AppColors.mut2),
              prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.mut),
              filled: true,
              fillColor: AppColors.sur,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.bdr),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.bdr),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.acc),
              ),
            ),
          ),
        ),

        // Rangement filter chips
        if (_rg1Values.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildRgChips(1, _rg1Values.toList()..sort(), _rg1Filter, (v) => setState(() => _rg1Filter = v)),
        ],
        if (_rg2Values.isNotEmpty) ...[
          const SizedBox(height: 6),
          _buildRgChips(2, _rg2Values.toList()..sort(), _rg2Filter, (v) => setState(() => _rg2Filter = v)),
        ],
        const SizedBox(height: 8),

        // Book list
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(books.isEmpty ? '📚' : '🔍', style: const TextStyle(fontSize: 48)),
                      const SizedBox(height: 14),
                      Text(
                        books.isEmpty ? 'Aucun livre enregistré' : 'Aucun résultat',
                        style: AppTheme.display(size: 18, color: AppColors.mut).copyWith(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  itemCount: filtered.length + 1, // +1 for export button
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    if (i == filtered.length) {
                      // Export button
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: OutlinedButton.icon(
                          onPressed: _exportCsv,
                          icon: const Icon(Icons.download, size: 16),
                          label: Text('Exporter en CSV', style: AppTheme.ui(size: 12, weight: FontWeight.w500, color: AppColors.mut)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.mut,
                            side: const BorderSide(color: AppColors.bdr),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      );
                    }
                    return _bookCard(filtered[i]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _statChip(String filter, String label, int count, Color numColor) {
    final active = _filter == filter;
    return GestureDetector(
      onTap: () => setState(() => _filter = filter),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.acc3 : AppColors.sur,
          border: Border.all(color: active ? AppColors.acc : AppColors.bdr),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              '$count',
              style: AppTheme.ui(
                size: 14,
                weight: FontWeight.w700,
                color: active ? AppColors.acc : numColor,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: AppTheme.mono(
                size: 11,
                color: active ? AppColors.acc : AppColors.mut,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRgChips(int n, List<String> values, String current, void Function(String) onSelect) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text('📦 R$n ', style: AppTheme.mono(size: 10, color: AppColors.mut)),
          const SizedBox(width: 4),
          _rgChip('Tous', 'all', current, onSelect),
          ...values.map((v) => _rgChip(v, v, current, onSelect)),
        ],
      ),
    );
  }

  Widget _rgChip(String label, String value, String current, void Function(String) onSelect) {
    final active = current == value;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.acc3 : AppColors.sur,
          border: Border.all(color: active ? AppColors.acc : AppColors.bdr),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTheme.mono(size: 11, color: active ? AppColors.acc : AppColors.mut),
        ),
      ),
    );
  }

  Widget _bookCard(Book b) {
    final hasCover = b.cover != null && b.cover!.isNotEmpty;
    return GestureDetector(
      onTap: () => _openDetail(b),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.sur,
          border: Border.all(color: AppColors.bdr),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Cover
            Container(
              width: 54,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.sur2,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.bdr),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasCover
                  ? CachedNetworkImage(
                      imageUrl: b.cover!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Center(child: Text('📕', style: TextStyle(fontSize: 22))),
                    )
                  : const Center(child: Text('📕', style: TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.display(size: 14, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    b.authors,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.ui(size: 11, color: AppColors.acc),
                  ),
                  if (b.metaLine.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(b.metaLine, style: AppTheme.mono(size: 10, color: AppColors.mut), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                  if (b.rangementLine.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(b.rangementLine, style: AppTheme.mono(size: 10, color: AppColors.mut2)),
                  ],
                  const SizedBox(height: 6),
                  _statusBadge(b.status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: _statusBgColor(status),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        Book.statusLabels[status] ?? '',
        style: AppTheme.mono(size: 9, weight: FontWeight.w700, color: _statusTextColor(status)).copyWith(letterSpacing: 0.5),
      ),
    );
  }

  Color _statusBgColor(String s) {
    switch (s) {
      case 'alire': return const Color(0x2E6B9FD4);
      case 'encours': return const Color(0x2ED4845A);
      case 'lu': return const Color(0x2E5AAD7E);
      case 'prete': return const Color(0x2EC96B4A);
      default: return AppColors.sur2;
    }
  }

  Color _statusTextColor(String s) {
    switch (s) {
      case 'alire': return const Color(0xFFA8C8EF);
      case 'encours': return const Color(0xFFEFB88A);
      case 'lu': return const Color(0xFF8AEFC0);
      case 'prete': return const Color(0xFFEFA07A);
      default: return AppColors.mut;
    }
  }
}
