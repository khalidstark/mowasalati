import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tahadi/home.dart';

const _blue = Color(0xFF3563E9);
const _bg = Color(0xFFF2F4F8);
const _white = Colors.white;
const _border = Color(0xFFE5E9F0);
const _textDark = Color(0xFF1A1D26);
const _textMid = Color(0xFF6B7280);
const _textLight = Color(0xFF9CA3AF);
const _green = Color(0xFF10B981);
const _red = Color(0xFFEF4444);

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          Container(
            height: 280,
            decoration: const BoxDecoration(
              color: _blue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.route_rounded, size: 40, color: _white),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'أهلاً في مواصلاتي',
                    style: GoogleFonts.tajawal(fontSize: 26, fontWeight: FontWeight.bold, color: _white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'سجّل دخول أو اعمل حساب جديد',
                    style: GoogleFonts.tajawal(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 36),

                  _typeCard(
                    context: context,
                    icon: Icons.login_rounded,
                    title: 'تسجيل دخول',
                    subtitle: 'عندك حساب؟ ادخل هنا',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignInScreen())),
                  ),
                  const SizedBox(height: 14),

                  _typeCard(
                    context: context,
                    icon: Icons.person_add_rounded,
                    title: 'حساب جديد',
                    subtitle: 'سجّل حساب جديد',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateAccountScreen())),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 28, color: _blue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.tajawal(fontSize: 13, color: _textMid)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: _textLight),
          ],
        ),
      ),
    );
  }
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  String _email = '';
  String _password = '';
  bool _isLoading = false;

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final result = await _firestore.collection('users').where('email', isEqualTo: _email).get();
      if (!mounted) return;

      if (result.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('الإيميل مش موجود', style: GoogleFonts.tajawal()), backgroundColor: _red, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16)),
        );
        setState(() => _isLoading = false);
        return;
      }

      final userDoc = result.docs.first;
      if (userDoc['password'] != _password) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('الباسورد غلط', style: GoogleFonts.tajawal()), backgroundColor: _red, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16)),
        );
        setState(() => _isLoading = false);
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', userDoc.id);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LocationSwapperPage()));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حصلت مشكلة: $e', style: GoogleFonts.tajawal()), backgroundColor: _red, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          Container(
            height: 180,
            decoration: const BoxDecoration(
              color: _blue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: _white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Text(
                        'تسجيل الدخول',
                        style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold, color: _white),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('أهلاً بيك', style: GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.bold, color: _textDark)),
                            const SizedBox(height: 4),
                            Text('سجّل دخول بحسابك', style: GoogleFonts.tajawal(fontSize: 13, color: _textMid)),
                            const SizedBox(height: 28),

                            _field(label: 'الإيميل', icon: Icons.email_outlined, keyboard: TextInputType.emailAddress,
                              validator: (v) { if (v == null || v.isEmpty) return 'لازم تكتب الإيميل'; if (!v.contains('@')) return 'الإيميل مش صح'; return null; },
                              onChanged: (v) => _email = v),
                            const SizedBox(height: 18),

                            _field(label: 'الباسورد', icon: Icons.lock_outline_rounded, obscure: true,
                              validator: (v) => (v == null || v.isEmpty) ? 'لازم تكتب الباسورد' : null,
                              onChanged: (v) => _password = v),
                            const SizedBox(height: 30),

                            GestureDetector(
                              onTap: _isLoading ? null : _signIn,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: _isLoading ? _blue.withOpacity(0.5) : _blue,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: _isLoading
                                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: _white, strokeWidth: 2.5))
                                      : Text('سجّل دخول', style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.bold, color: _white)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            Center(
                              child: GestureDetector(
                                onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CreateAccountScreen())),
                                child: Text.rich(
                                  TextSpan(
                                    text: 'ما عندكش حساب؟ ',
                                    style: GoogleFonts.tajawal(fontSize: 13, color: _textMid),
                                    children: [
                                      TextSpan(text: 'سجّل حساب جديد', style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.bold, color: _blue)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboard,
    required String? Function(String?) validator,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.w600, color: _textMid)),
        const SizedBox(height: 6),
        TextFormField(
          obscureText: obscure,
          keyboardType: keyboard,
          validator: validator,
          onChanged: onChanged,
          style: GoogleFonts.tajawal(fontSize: 15, color: _textDark),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: _textLight, size: 20),
            filled: true,
            fillColor: const Color(0xFFF8F9FC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _blue, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _red, width: 1)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            isDense: true,
          ),
        ),
      ],
    );
  }
}

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  String _name = '';
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  bool _isLoading = false;
  bool _showSuccess = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final existing = await _firestore.collection('users').where('email', isEqualTo: _email).get();
      if (existing.docs.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('الإيميل ده متسجّل قبل كده', style: GoogleFonts.tajawal()), backgroundColor: _red, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16)),
        );
        setState(() => _isLoading = false);
        return;
      }

      final docRef = await _firestore.collection('users').add({
        'name': _name, 'email': _email, 'password': _password,
        'phone': '', 'type': 'rider', 'createdAt': FieldValue.serverTimestamp(),
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', docRef.id);

      setState(() => _showSuccess = true);
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LocationSwapperPage()));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حصلت مشكلة: $e', style: GoogleFonts.tajawal()), backgroundColor: _red, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSuccess) return _successScreen();

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          Container(
            height: 180,
            decoration: const BoxDecoration(
              color: _blue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: _white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Text(
                        'حساب جديد',
                        style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold, color: _white),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('اكتب بياناتك', style: GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.bold, color: _textDark)),
                            const SizedBox(height: 4),
                            Text('عشان نعملك حساب', style: GoogleFonts.tajawal(fontSize: 13, color: _textMid)),
                            const SizedBox(height: 28),

                            _field(label: 'الاسم بالكامل', icon: Icons.person_outline_rounded,
                              validator: (v) => (v == null || v.isEmpty) ? 'لازم تكتب اسمك' : null,
                              onChanged: (v) => _name = v),
                            const SizedBox(height: 18),

                            _field(label: 'الإيميل', icon: Icons.email_outlined, keyboard: TextInputType.emailAddress,
                              validator: (v) { if (v == null || v.isEmpty) return 'لازم تكتب الإيميل'; if (!v.contains('@')) return 'الإيميل مش صح'; return null; },
                              onChanged: (v) => _email = v),
                            const SizedBox(height: 18),

                            _field(label: 'الباسورد', icon: Icons.lock_outline_rounded, obscure: true,
                              validator: (v) { if (v == null || v.isEmpty) return 'لازم تكتب الباسورد'; if (v.length < 6) return 'الباسورد لازم 6 حروف على الأقل'; return null; },
                              onChanged: (v) => _password = v),
                            const SizedBox(height: 18),

                            _field(label: 'أكّد الباسورد', icon: Icons.lock_outline_rounded, obscure: true,
                              validator: (v) => v != _password ? 'الباسوردين مش زي بعض' : null,
                              onChanged: (v) => _confirmPassword = v),
                            const SizedBox(height: 30),

                            GestureDetector(
                              onTap: _isLoading ? null : _register,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: _isLoading ? _blue.withOpacity(0.5) : _blue,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: _isLoading
                                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: _white, strokeWidth: 2.5))
                                      : Text('سجّل الحساب', style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.bold, color: _white)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            Center(
                              child: GestureDetector(
                                onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SignInScreen())),
                                child: Text.rich(
                                  TextSpan(
                                    text: 'عندك حساب؟ ',
                                    style: GoogleFonts.tajawal(fontSize: 13, color: _textMid),
                                    children: [
                                      TextSpan(text: 'سجّل دخول', style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.bold, color: _blue)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboard,
    required String? Function(String?) validator,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.w600, color: _textMid)),
        const SizedBox(height: 6),
        TextFormField(
          obscureText: obscure,
          keyboardType: keyboard,
          validator: validator,
          onChanged: onChanged,
          style: GoogleFonts.tajawal(fontSize: 15, color: _textDark),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: _textLight, size: 20),
            filled: true,
            fillColor: const Color(0xFFF8F9FC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _blue, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _red, width: 1)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _successScreen() {
    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(color: _green.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, color: _green, size: 72),
            ),
            const SizedBox(height: 28),
            Text('الحساب اتعمل بنجاح!', style: GoogleFonts.tajawal(fontSize: 24, fontWeight: FontWeight.bold, color: _textDark)),
            const SizedBox(height: 8),
            Text(
              'اتسجّلت بنجاح',
              style: GoogleFonts.tajawal(fontSize: 15, color: _textMid),
            ),
          ],
        ),
      ),
    );
  }
}
