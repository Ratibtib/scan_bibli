import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme.dart';
import '../models/book.dart';
import '../services/isbn_service.dart';
import '../services/auth_service.dart';
import '../services/book_service.dart';
import 'home_screen.dart';
import 'scan_result_sheet.dart';

class ScannerScreen extends StatefulWidget {
  final HomeScreenState homeState;
  const ScannerScreen({super.key, required this.homeState});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  int _mode = 0; // 0 = camera, 1 = manual
  bool _cameraActive = false;
  bool _loading = false;
  String _loadingText = 'Recherche…';
  String? _lastScannedIsbn;
  bool _modalOpen = false;

  MobileScannerController? _scannerController;
  final _isbnCtrl = TextEditingController();

  void _startCamera() {
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      formats: [BarcodeFormat.ean13, BarcodeFormat.ean8, BarcodeFormat.upcA, BarcodeFormat.upcE],
    );
    setState(() => _cameraActive = true);
  }

  void _stopCamera() {
    _scannerController?.dispose();
    _scannerController = null;
    setState(() {
      _cameraActive = false;
      _lastScannedIsbn = null;
    });
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_modalOpen || _loading) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final isbn = barcode.rawValue!;
    if (isbn == _lastScannedIsbn) return;

    HapticFeedback.mediumImpact();
    _lastScannedIsbn = isbn;
    _lookupIsbn(isbn);
  }

  Future<void> _lookupIsbn(String raw) async {
    final isbn = IsbnService.normalizeIsbn(raw);
    if (isbn.length < 10) {
      _showToast('Code invalide : $raw');
      return;
    }

    setState(() {
      _loading = true;
      _loadingText = 'Recherche…';
    });

    final book = await IsbnService.lookup(isbn, onProgress: (msg) {
      if (mounted) setState(() => _loadingText = msg);
    });

    setState(() => _loading = false);

    if (!mounted) return;
    _showScanResult(book);
  }

  void _doManualSearch() {
    final v = _isbnCtrl.text.trim();
    if (v.isEmpty) return;
    _lastScannedIsbn = null;
    _lookupIsbn(v);
  }

  void _showScanResult(Book book) {
    _modalOpen = true;
    _scannerController?.stop();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ScanResultSheet(
        book: book,
        existingBooks: widget.homeState.books,
        onConfirm: (confirmedBook) async {
          final user = AuthService.currentUser;
          if (user == null) return;

          final existing = widget.homeState.books.firstWhere(
            (b) => b.isbn == confirmedBook.isbn,
            orElse: () => Book(),
          );

          if (existing.id != null) {
            confirmedBook.id = existing.id;
          }

          final saved = await BookService.saveBook(confirmedBook, user.id);
          if (saved != null) {
            widget.homeState.addBook(saved);
            _showToast('📚 ${_shorten(saved.title)} ajouté !');
          }
        },
      ),
    ).whenComplete(() {
      _modalOpen = false;
      _lastScannedIsbn = null;
      if (_cameraActive) {
        _scannerController?.start();
      }
      _isbnCtrl.clear();
    });
  }

  String _shorten(String s) => s.length > 22 ? '${s.substring(0, 20)}…' : s;

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
    _scannerController?.dispose();
    _isbnCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Mode bar
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.sur2,
              border: Border.all(color: AppColors.bdr),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _modeBtn(0, Icons.qr_code_scanner, 'Caméra'),
                const SizedBox(width: 3),
                _modeBtn(1, Icons.search, 'ISBN manuel'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Camera mode
          if (_mode == 0) ...[
            // Camera frame
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.bdr),
              ),
              clipBehavior: Clip.antiAlias,
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: _cameraActive && _scannerController != null
                    ? Stack(
                        children: [
                          MobileScanner(
                            controller: _scannerController!,
                            onDetect: _onBarcodeDetected,
                          ),
                          // Scan overlay
                          Center(
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.6,
                              height: 80,
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.acc, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          // Bottom gradient
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 80,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Container(
                        color: AppColors.sur2,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('📸', style: TextStyle(fontSize: 44)),
                            const SizedBox(height: 12),
                            Text(
                              'Pointez vers le code-barres',
                              style: AppTheme.ui(size: 12, color: AppColors.mut),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 14),

            // Scan button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_cameraActive) {
                    _stopCamera();
                  } else {
                    _startCamera();
                  }
                },
                icon: Icon(_cameraActive ? Icons.stop : Icons.play_arrow, size: 18),
                label: Text(
                  _cameraActive ? 'Arrêter' : 'Démarrer le scan',
                  style: AppTheme.ui(size: 13, weight: FontWeight.w700, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cameraActive ? AppColors.dan : AppColors.acc,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
              ),
            ),

            // Scan indicator
            if (_cameraActive) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
                decoration: BoxDecoration(
                  color: AppColors.acc3,
                  border: Border.all(color: AppColors.acc.withOpacity(0.15)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _PulsingDot(),
                    const SizedBox(width: 10),
                    Text(
                      _lastScannedIsbn != null ? 'Vu : $_lastScannedIsbn' : 'Scanner actif…',
                      style: AppTheme.mono(size: 12, color: AppColors.acc),
                    ),
                  ],
                ),
              ),
            ],
          ],

          // Manual mode
          if (_mode == 1) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.sur,
                border: Border.all(color: AppColors.bdr),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NUMÉRO ISBN',
                    style: AppTheme.mono(size: 10, color: AppColors.mut).copyWith(letterSpacing: 1),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _isbnCtrl,
                    keyboardType: TextInputType.number,
                    style: AppTheme.mono(size: 15, color: AppColors.txt),
                    decoration: AppTheme.fieldDecoration('9782070368228'),
                    onSubmitted: (_) => _doManualSearch(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _doManualSearch,
                      icon: const Icon(Icons.search, size: 16),
                      label: Text('Rechercher', style: AppTheme.ui(size: 13, weight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.txt,
                        side: const BorderSide(color: AppColors.bdr2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Loading indicator
          if (_loading) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(color: AppColors.mut, strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(_loadingText, style: AppTheme.mono(size: 12, color: AppColors.mut)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _modeBtn(int mode, IconData icon, String label) {
    final active = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_cameraActive) _stopCamera();
          setState(() => _mode = mode);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.sur3 : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: active ? [const BoxShadow(color: Colors.black38, blurRadius: 4)] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: active ? AppColors.txt : AppColors.mut),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: AppTheme.ui(
                  size: 11,
                  weight: FontWeight.w600,
                  color: active ? AppColors.txt : AppColors.mut,
                ).copyWith(letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: 0.3 + _ctrl.value * 0.7,
        child: Transform.scale(
          scale: 0.7 + _ctrl.value * 0.3,
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.acc,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
