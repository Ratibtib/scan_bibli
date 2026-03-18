import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme.dart';
import '../models/book.dart';

class ScanResultSheet extends StatefulWidget {
  final Book book;
  final List<Book> existingBooks;
  final Future<void> Function(Book) onConfirm;

  const ScanResultSheet({
    super.key,
    required this.book,
    required this.existingBooks,
    required this.onConfirm,
  });

  @override
  State<ScanResultSheet> createState() => _ScanResultSheetState();
}

class _ScanResultSheetState extends State<ScanResultSheet> {
  late String _status;
  late TextEditingController _titleCtrl;
  late TextEditingController _authorCtrl;
  late TextEditingController _rg1Ctrl;
  late TextEditingController _rg2Ctrl;
  bool _descExpanded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _status = 'alire';
    final notFound = widget.book.title == 'Titre non trouvé';
    _titleCtrl = TextEditingController(text: notFound ? '' : widget.book.title);
    _authorCtrl = TextEditingController(text: notFound ? '' : widget.book.authors);
    _rg1Ctrl = TextEditingController();
    _rg2Ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _rg1Ctrl.dispose();
    _rg2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_saving) return;
    setState(() => _saving = true);

    final book = widget.book;
    if (_titleCtrl.text.trim().isNotEmpty) book.title = _titleCtrl.text.trim();
    if (_authorCtrl.text.trim().isNotEmpty) book.authors = _authorCtrl.text.trim();
    book.status = _status;
    book.rangement1 = _rg1Ctrl.text.trim().isEmpty ? null : _rg1Ctrl.text.trim();
    book.rangement2 = _rg2Ctrl.text.trim().isEmpty ? null : _rg2Ctrl.text.trim();

    await widget.onConfirm(book);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.book;
    final notFound = b.title == 'Titre non trouvé';
    final meta = b.metaLine;
    final hasCover = b.cover != null && b.cover!.isNotEmpty;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: AppColors.sur,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(top: BorderSide(color: AppColors.bdr)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 14),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.bdr2,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title label
                  Text(
                    notFound ? 'ISBN ${b.isbn} — complétez les infos' : '📚 Livre trouvé',
                    style: AppTheme.mono(size: 10, color: AppColors.mut).copyWith(letterSpacing: 1),
                  ),
                  const SizedBox(height: 16),

                  // Book row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cover
                      Container(
                        width: 72,
                        height: 72 * 18 / 11,
                        decoration: BoxDecoration(
                          color: AppColors.sur2,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.bdr),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: hasCover
                            ? CachedNetworkImage(
                                imageUrl: b.cover!,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => const Center(child: Text('📕', style: TextStyle(fontSize: 28))),
                              )
                            : const Center(child: Text('📕', style: TextStyle(fontSize: 28))),
                      ),
                      const SizedBox(width: 16),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Editable title
                            TextField(
                              controller: _titleCtrl,
                              style: AppTheme.display(size: 18, weight: FontWeight.w600),
                              decoration: const InputDecoration(
                                hintText: 'Titre…',
                                hintStyle: TextStyle(color: AppColors.mut, fontStyle: FontStyle.italic),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              maxLines: 2,
                            ),
                            const Divider(color: AppColors.bdr, height: 10),
                            // Editable author
                            TextField(
                              controller: _authorCtrl,
                              style: AppTheme.ui(size: 12, weight: FontWeight.w500, color: AppColors.acc),
                              decoration: const InputDecoration(
                                hintText: 'Auteur…',
                                hintStyle: TextStyle(color: AppColors.mut),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            if (meta.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(meta, style: AppTheme.mono(size: 10, color: AppColors.mut)),
                            ],
                            if (b.collection != null && b.collection!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text('Coll. ${b.collection}', style: AppTheme.mono(size: 10, color: AppColors.mut)),
                            ],
                            if (b.isbn != null) ...[
                              const SizedBox(height: 2),
                              Text('ISBN ${b.isbn}', style: AppTheme.mono(size: 10, color: AppColors.mut)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Categories
                  if (b.categories != null && b.categories!.isNotEmpty) ...[
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: b.categories!.split(',').map((g) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.acc.withOpacity(0.08),
                            border: Border.all(color: AppColors.acc.withOpacity(0.2)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            g.trim(),
                            style: AppTheme.ui(size: 10, weight: FontWeight.w600, color: AppColors.acc),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Description
                  if (b.description != null && b.description!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.only(top: 12),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: AppColors.bdr)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedCrossFade(
                            firstChild: Text(
                              b.description!,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.ui(size: 12, color: AppColors.txt2).copyWith(height: 1.7),
                            ),
                            secondChild: Text(
                              b.description!,
                              style: AppTheme.ui(size: 12, color: AppColors.txt2).copyWith(height: 1.7),
                            ),
                            crossFadeState: _descExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 300),
                          ),
                          if (b.description!.length > 180)
                            GestureDetector(
                              onTap: () => setState(() => _descExpanded = !_descExpanded),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  _descExpanded ? 'réduire ↑' : 'lire la suite ↓',
                                  style: AppTheme.ui(size: 11, weight: FontWeight.w600, color: AppColors.acc),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Divider
                  Container(height: 1, color: AppColors.bdr, margin: const EdgeInsets.only(bottom: 16)),

                  // Status picker
                  Row(
                    children: Book.statusOrder.map((s) {
                      final active = _status == s;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: s != 'prete' ? 6 : 0),
                          child: GestureDetector(
                            onTap: () => setState(() => _status = s),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: active ? _statusBgColor(s) : Colors.transparent,
                                border: Border.all(color: active ? _statusColor(s) : AppColors.bdr2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  Book.statusLabels[s]!,
                                  style: AppTheme.ui(
                                    size: 10,
                                    weight: FontWeight.w700,
                                    color: active ? _statusColor(s) : AppColors.mut,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Rangement
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('RANGEMENT 1', style: AppTheme.mono(size: 10, color: AppColors.mut).copyWith(letterSpacing: 0.5)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _rg1Ctrl,
                              style: AppTheme.ui(size: 13),
                              decoration: AppTheme.fieldDecoration('Étagère A…'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('RANGEMENT 2', style: AppTheme.mono(size: 10, color: AppColors.mut).copyWith(letterSpacing: 0.5)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _rg2Ctrl,
                              style: AppTheme.ui(size: 13),
                              decoration: AppTheme.fieldDecoration('Boite 3…'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.mut,
                            side: const BorderSide(color: AppColors.bdr2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text('Ignorer', style: AppTheme.ui(size: 13, color: AppColors.mut)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _confirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.acc,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 4,
                          ),
                          child: _saving
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text('Ajouter à ma biblio', style: AppTheme.ui(size: 13, weight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'alire': return AppColors.blu;
      case 'encours': return AppColors.amber;
      case 'lu': return AppColors.grn;
      case 'prete': return AppColors.red;
      default: return AppColors.blu;
    }
  }

  Color _statusBgColor(String s) {
    switch (s) {
      case 'alire': return AppColors.blu2;
      case 'encours': return const Color(0x1FD4845A);
      case 'lu': return AppColors.grn2;
      case 'prete': return AppColors.red2;
      default: return AppColors.blu2;
    }
  }
}
