import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../models/book.dart';
import '../services/auth_service.dart';
import '../services/book_service.dart';
import '../widgets/cover_image.dart';
import 'home_screen.dart';

class BookDetailScreen extends StatefulWidget {
  final Book book;
  final HomeScreenState homeState;

  const BookDetailScreen({super.key, required this.book, required this.homeState});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late String _status;
  String? _newCoverBase64;
  bool _saving = false;

  late TextEditingController _titleCtrl;
  late TextEditingController _authorsCtrl;
  late TextEditingController _publisherCtrl;
  late TextEditingController _yearCtrl;
  late TextEditingController _pagesCtrl;
  late TextEditingController _isbnCtrl;
  late TextEditingController _catsCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _rg1Ctrl;
  late TextEditingController _rg2Ctrl;
  late TextEditingController _collectionCtrl;
  late TextEditingController _genreCtrl;
  late TextEditingController _deweyCtrl;
  late TextEditingController _titreOrigCtrl;
  late TextEditingController _lieuCtrl;
  late TextEditingController _rolesCtrl;

  @override
  void initState() {
    super.initState();
    final b = widget.book;
    _status = b.status;
    _titleCtrl = TextEditingController(text: b.title);
    _authorsCtrl = TextEditingController(text: b.authors);
    _publisherCtrl = TextEditingController(text: b.publisher ?? '');
    _yearCtrl = TextEditingController(text: b.year ?? '');
    _pagesCtrl = TextEditingController(text: b.pages ?? '');
    _isbnCtrl = TextEditingController(text: b.isbn ?? '');
    _catsCtrl = TextEditingController(text: b.categories ?? '');
    _descCtrl = TextEditingController(text: b.description ?? '');
    _rg1Ctrl = TextEditingController(text: b.rangement1 ?? '');
    _rg2Ctrl = TextEditingController(text: b.rangement2 ?? '');
    _collectionCtrl = TextEditingController(text: b.collection ?? '');
    _genreCtrl = TextEditingController(text: b.genre ?? '');
    _deweyCtrl = TextEditingController(text: b.dewey ?? '');
    _titreOrigCtrl = TextEditingController(text: b.titreOriginal ?? '');
    _lieuCtrl = TextEditingController(text: b.lieu ?? '');
    _rolesCtrl = TextEditingController(text: b.roles ?? '');
  }

  @override
  void dispose() {
    for (final c in [_titleCtrl, _authorsCtrl, _publisherCtrl, _yearCtrl, _pagesCtrl,
      _isbnCtrl, _catsCtrl, _descCtrl, _rg1Ctrl, _rg2Ctrl, _collectionCtrl,
      _genreCtrl, _deweyCtrl, _titreOrigCtrl, _lieuCtrl, _rolesCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.camera, maxWidth: 600, imageQuality: 85);
    if (xfile == null) return;
    final bytes = await xfile.readAsBytes();
    final b64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    setState(() => _newCoverBase64 = b64);
    _showToast('Couverture mise à jour');
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    final b = widget.book;
    b.title = _titleCtrl.text.trim().isNotEmpty ? _titleCtrl.text.trim() : b.title;
    b.authors = _authorsCtrl.text.trim().isNotEmpty ? _authorsCtrl.text.trim() : b.authors;
    b.publisher = _publisherCtrl.text.trim();
    b.year = _yearCtrl.text.trim();
    b.pages = _pagesCtrl.text.trim();
    b.isbn = _isbnCtrl.text.trim().isNotEmpty ? _isbnCtrl.text.trim() : b.isbn;
    b.categories = _catsCtrl.text.trim();
    b.description = _descCtrl.text.trim();
    b.rangement1 = _rg1Ctrl.text.trim().isEmpty ? null : _rg1Ctrl.text.trim();
    b.rangement2 = _rg2Ctrl.text.trim().isEmpty ? null : _rg2Ctrl.text.trim();
    b.collection = _collectionCtrl.text.trim().isEmpty ? null : _collectionCtrl.text.trim();
    b.genre = _genreCtrl.text.trim().isEmpty ? null : _genreCtrl.text.trim();
    b.dewey = _deweyCtrl.text.trim().isEmpty ? null : _deweyCtrl.text.trim();
    b.titreOriginal = _titreOrigCtrl.text.trim().isEmpty ? null : _titreOrigCtrl.text.trim();
    b.lieu = _lieuCtrl.text.trim().isEmpty ? null : _lieuCtrl.text.trim();
    b.roles = _rolesCtrl.text.trim().isEmpty ? null : _rolesCtrl.text.trim();
    b.status = _status;
    if (_newCoverBase64 != null) b.cover = _newCoverBase64;

    final user = AuthService.currentUser;
    if (user == null) {
      setState(() => _saving = false);
      return;
    }

    final saved = await BookService.saveBook(b, user.id);
    setState(() => _saving = false);

    if (saved != null) {
      widget.homeState.updateBook(saved);
      _showToast('✅ Modifications enregistrées');
      if (mounted) Navigator.pop(context);
    } else {
      _showToast('Erreur sauvegarde');
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.sur,
        title: Text('Supprimer ce livre ?', style: AppTheme.display(size: 18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler', style: AppTheme.ui(color: AppColors.mut)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Supprimer', style: AppTheme.ui(color: AppColors.dan, weight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final user = AuthService.currentUser;
    if (user == null || widget.book.id == null) return;

    await BookService.deleteBook(widget.book.id!, user.id);
    widget.homeState.removeBook(widget.book.id!);
    _showToast('Livre supprimé');
    if (mounted) Navigator.pop(context);
  }

  void _showToast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: AppTheme.mono(size: 12, color: AppColors.txt)),
        backgroundColor: AppColors.sur3,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        margin: const EdgeInsets.only(bottom: 20, left: 40, right: 40),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return '—';
    }
  }

  Widget _coverWidget() {
    final url = _newCoverBase64 ?? widget.book.cover;
    return CoverImage(
      coverUrl: url,
      width: 110,
      height: 110 * 18 / 11,
      placeholderFontSize: 40,
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.book;
    final hasCover = b.cover != null && b.cover!.isNotEmpty || _newCoverBase64 != null;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            backgroundColor: AppColors.sur,
            surfaceTintColor: Colors.transparent,
            pinned: true,
            leading: IconButton(
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.bdr),
                ),
                child: const Icon(Icons.chevron_left, color: AppColors.txt, size: 18),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('FICHE DU LIVRE', style: AppTheme.mono(size: 11, color: AppColors.mut).copyWith(letterSpacing: 1)),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.acc,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    elevation: 2,
                  ),
                  child: _saving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Enregistrer', style: AppTheme.ui(size: 12, weight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),

          // Hero
          SliverToBoxAdapter(
            child: Container(
              height: 260,
              child: Stack(
                children: [
                  // Blurred background
                  if (hasCover)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.sur2,
                        ),
                        child: Opacity(
                          opacity: 0.35,
                          child: _coverWidget(),
                        ),
                      ),
                    ),
                  if (!hasCover)
                    Positioned.fill(child: Container(color: AppColors.sur2)),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        // Cover
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 110,
                              height: 110 * 18 / 11,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white10),
                                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 32, offset: Offset(0, 8))],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _coverWidget(),
                            ),
                            Positioned(
                              bottom: -8,
                              right: -8,
                              child: GestureDetector(
                                onTap: _pickPhoto,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: AppColors.acc,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.bg, width: 2),
                                    boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8)],
                                  ),
                                  child: const Icon(Icons.camera_alt, size: 13, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        // Info
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.title,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.display(size: 22, weight: FontWeight.w600, color: Colors.white).copyWith(
                                  shadows: [const Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 2))],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                b.authors,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.ui(size: 13, color: AppColors.acc.withOpacity(0.9)),
                              ),
                              const SizedBox(height: 12),
                              // Status row
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: Book.statusOrder.map((s) {
                                  final active = _status == s;
                                  return GestureDetector(
                                    onTap: () => setState(() => _status = s),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: active ? _statusBgColor(s) : Colors.transparent,
                                        border: Border.all(color: active ? _statusColor(s) : AppColors.bdr2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        Book.statusLabels[s]!,
                                        style: AppTheme.ui(
                                          size: 9,
                                          weight: FontWeight.w700,
                                          color: active ? _statusColor(s) : AppColors.mut,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Body
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Informations
                _sectionTitle('Informations'),
                _fieldLabel('Titre'),
                _field(_titleCtrl, 'Titre du livre'),
                _fieldLabel('Auteur(s)'),
                _field(_authorsCtrl, 'Prénom Nom'),
                _fieldLabel('Éditeur'),
                _field(_publisherCtrl, 'Éditeur'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _fieldLabel('Année'),
                      _field(_yearCtrl, '2024', mono: true, keyboard: TextInputType.number),
                    ])),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _fieldLabel('Pages'),
                      _field(_pagesCtrl, '320', mono: true, keyboard: TextInputType.number),
                    ])),
                  ],
                ),
                const SizedBox(height: 22),

                // Référence
                _sectionTitle('Référence'),
                _fieldLabel('ISBN'),
                _field(_isbnCtrl, '9782…', mono: true, keyboard: TextInputType.number),
                _fieldLabel('Genres / Catégories (Rameau)'),
                _field(_catsCtrl, 'Roman, Philosophie…'),
                _fieldLabel('Collection'),
                _field(_collectionCtrl, 'Folio, Pléiade…'),
                const SizedBox(height: 22),

                // Données BNF
                _sectionTitle('Données BNF'),
                Row(
                  children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _fieldLabel('Genre / Forme'),
                      _field(_genreCtrl, 'Roman, Essai…'),
                    ])),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _fieldLabel('Indice Dewey'),
                      _field(_deweyCtrl, '843.914…', mono: true),
                    ])),
                  ],
                ),
                _fieldLabel('Titre original'),
                _field(_titreOrigCtrl, "Titre en langue d'origine"),
                _fieldLabel('Lieu géographique'),
                _field(_lieuCtrl, 'France, Japon…'),
                _fieldLabel('Contributeurs & rôles'),
                _field(_rolesCtrl, 'Prénom Nom (Traducteur)…'),
                const SizedBox(height: 22),

                // Rangement
                _sectionTitle('Rangement'),
                Row(
                  children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _fieldLabel('Rangement 1'),
                      _field(_rg1Ctrl, 'ex: Étagère A', mono: true),
                    ])),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _fieldLabel('Rangement 2'),
                      _field(_rg2Ctrl, 'ex: Boite 3', mono: true),
                    ])),
                  ],
                ),
                const SizedBox(height: 22),

                // Résumé
                _sectionTitle('Résumé'),
                TextField(
                  controller: _descCtrl,
                  maxLines: 5,
                  style: AppTheme.ui(size: 13).copyWith(height: 1.6),
                  decoration: AppTheme.fieldDecoration('Résumé du livre…'),
                ),
                const SizedBox(height: 20),

                // Dates
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.sur,
                    border: Border.all(color: AppColors.bdr),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Ajouté le    ${_fmtDate(b.cr)}\nModifié le  ${_fmtDate(b.up)}',
                    style: AppTheme.mono(size: 10, color: AppColors.mut).copyWith(height: 2),
                  ),
                ),
                const SizedBox(height: 20),

                // Delete button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.dan),
                    label: Text('Supprimer ce livre', style: AppTheme.ui(size: 13, weight: FontWeight.w600, color: AppColors.dan)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.dan.withOpacity(0.25)),
                      backgroundColor: AppColors.dan.withOpacity(0.05),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.bdr)),
        ),
        child: Text(
          label.toUpperCase(),
          style: AppTheme.mono(size: 10, color: AppColors.mut).copyWith(letterSpacing: 1),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        label.toUpperCase(),
        style: AppTheme.mono(size: 10, color: AppColors.mut).copyWith(letterSpacing: 0.8),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, {bool mono = false, TextInputType? keyboard}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      style: mono ? AppTheme.mono(size: 13, color: AppColors.txt) : AppTheme.ui(size: 13),
      decoration: AppTheme.fieldDecoration(hint),
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
