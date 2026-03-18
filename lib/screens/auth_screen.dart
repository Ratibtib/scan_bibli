import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _loading = false;
  String? _error;
  String? _success;

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    setState(() { _error = null; _success = null; });

    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Email et mot de passe requis.');
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = 'Minimum 6 caractères.');
      return;
    }
    if (!_isLogin && pass != confirm) {
      setState(() => _error = 'Les mots de passe ne correspondent pas.');
      return;
    }

    setState(() => _loading = true);

    String? err;
    if (_isLogin) {
      err = await AuthService.signIn(email, pass);
    } else {
      err = await AuthService.signUp(email, pass);
      if (err == null) {
        setState(() {
          _loading = false;
          _success = '✓ Compte créé ! Vérifiez votre email pour confirmer.';
        });
        return;
      }
    }

    setState(() {
      _loading = false;
      _error = err;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                const Text('📚', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 16),
                // Logo
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Ma ', style: AppTheme.display(size: 28)),
                    Text('Bibliothèque', style: AppTheme.display(size: 28, color: AppColors.acc)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'VOTRE COLLECTION PERSONNELLE',
                  style: AppTheme.mono(size: 10, color: AppColors.mut).copyWith(letterSpacing: 1.5),
                ),
                const SizedBox(height: 40),

                // Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.sur,
                    border: Border.all(color: AppColors.bdr),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 40, offset: Offset(0, 8))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Tabs
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: AppColors.bg,
                          border: Border.all(color: AppColors.bdr),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _buildTab('Connexion', _isLogin, () => setState(() { _isLogin = true; _error = null; _success = null; })),
                            const SizedBox(width: 3),
                            _buildTab('Inscription', !_isLogin, () => setState(() { _isLogin = false; _error = null; _success = null; })),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Fields
                      Text('ADRESSE EMAIL', style: AppTheme.mono(size: 10, color: AppColors.mut).copyWith(letterSpacing: 1)),
                      const SizedBox(height: 7),
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: AppTheme.ui(size: 14),
                        decoration: AppTheme.fieldDecoration('vous@email.com'),
                      ),
                      const SizedBox(height: 16),
                      Text('MOT DE PASSE', style: AppTheme.mono(size: 10, color: AppColors.mut).copyWith(letterSpacing: 1)),
                      const SizedBox(height: 7),
                      TextField(
                        controller: _passCtrl,
                        obscureText: true,
                        style: AppTheme.ui(size: 14),
                        decoration: AppTheme.fieldDecoration('••••••••'),
                      ),

                      if (!_isLogin) ...[
                        const SizedBox(height: 16),
                        Text('CONFIRMER', style: AppTheme.mono(size: 10, color: AppColors.mut).copyWith(letterSpacing: 1)),
                        const SizedBox(height: 7),
                        TextField(
                          controller: _confirmCtrl,
                          obscureText: true,
                          style: AppTheme.ui(size: 14),
                          decoration: AppTheme.fieldDecoration('••••••••'),
                        ),
                      ],

                      const SizedBox(height: 14),

                      // Error / Success
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Text(_error!, style: AppTheme.mono(size: 11, color: AppColors.dan)),
                        ),
                      if (_success != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Text(_success!, style: AppTheme.mono(size: 11, color: AppColors.grn)),
                        ),

                      // Submit
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.acc,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                          ),
                          child: _loading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(
                                  _isLogin ? 'Se connecter' : "S'inscrire",
                                  style: AppTheme.ui(size: 13, weight: FontWeight.w700, color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? AppColors.sur3 : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: active ? [const BoxShadow(color: Colors.black38, blurRadius: 4)] : null,
          ),
          child: Center(
            child: Text(
              label,
              style: AppTheme.ui(
                size: 12,
                weight: FontWeight.w600,
                color: active ? AppColors.txt : AppColors.mut,
              ).copyWith(letterSpacing: 0.5),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }
}
