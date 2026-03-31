import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:tahadi/travelmap.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Design tokens ──
const _blue = Color(0xFF3563E9);
const _blueDark = Color(0xFF2A4FBF);
const _bg = Color(0xFFF2F4F8);
const _white = Colors.white;
const _border = Color(0xFFE5E9F0);
const _textDark = Color(0xFF1A1D26);
const _textMid = Color(0xFF6B7280);
const _textLight = Color(0xFF9CA3AF);
const _green = Color(0xFF10B981);
const _orange = Color(0xFFF59E0B);
const _red = Color(0xFFEF4444);

BoxShadow get _cardShadow => BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 20,
      offset: const Offset(0, 8),
    );


// ── Dashed line painter ──
class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.5;
    const dw = 5.0, ds = 3.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, size.height / 2), Offset(x + dw, size.height / 2), paint);
      x += dw + ds;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


// ════════════════════════════════════════════════════════════
//  Home — Location Swapper Page
// ════════════════════════════════════════════════════════════

class LocationSwapperPage extends StatefulWidget {
  @override
  _LocationSwapperPageState createState() => _LocationSwapperPageState();
}

class _LocationSwapperPageState extends State<LocationSwapperPage>
    with SingleTickerProviderStateMixin {
  final List<String> egyptGovernorates = [
    'القاهرة', 'الإسكندرية', 'الجيزة', 'الدقهلية', 'البحر الأحمر',
    'البحيرة', 'الفيوم', 'الغربية', 'الإسماعيلية', 'المنوفية',
    'المنيا', 'القليوبية', 'الوادي الجديد', 'السويس', 'أسوان',
    'أسيوط', 'بني سويف', 'بورسعيد', 'دمياط', 'الشرقية',
    'جنوب سيناء', 'كفر الشيخ', 'مطروح', 'الأقصر', 'قنا',
    'شمال سيناء', 'سوهاج'
  ];

  String fromCity = '';
  String fromGovernorate = '';
  String toCity = '';
  String toGovernorate = '';

  final fromCityController = TextEditingController();
  final toCityController = TextEditingController();

  List<dynamic> _routes = [];
  String _bestOption = '';
  String _fromLocation = '';
  String _toLocation = '';
  bool _isSearching = false;
  String _userName = '';

  late AnimationController _swapController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _swapController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId != null) {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && mounted) {
        setState(() => _userName = doc.data()?['name'] ?? '');
      }
    }
  }

  @override
  void dispose() {
    _swapController.dispose();
    fromCityController.dispose();
    toCityController.dispose();
    super.dispose();
  }

  // ── API ──
  Future<Map<String, dynamic>> fetchTravelRoutes(String from, String to) async {
    final apiKey = 'YOUR_GEMINI_API_KEY';
    final endpoint =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey';

    final prompt = '''
أريد ملف JSON يحتوي على 3 طرق دقيقة للسفر من "$from" إلى "$to" داخل مصر.

لكل طريقة، يجب أن توضح:
- وسيلة المواصلات (ميكروباص، قطار، حافلة، Uber، الخ).
- من أين تبدأ الوسيلة بالضبط (مثلاً: "موقف سنورس").
- متى تنطلق (ساعة الانطلاق بدقة، مثال: "10:45 صباحًا").
- كم تستغرق (مدة الرحلة).
- كم تكلفة كل جزء.
- إذا كان الطريق يحتوي على مراحل (مثلاً ميكروباص + قطار)، اذكر كل مرحلة بالتفصيل.
- عدد التحويلات.
- نصائح، وهل هناك زحام يؤثر على المدة.

أرجو أن يكون الرد عبارة عن JSON خام فقط، بدون علامات Markdown أو \`\`\`.

صيغة الإخراج:

{
 "from": "$from",
 "to": "$to",
 "routes": [
  {
   "method": "ميكروباص + قطار",
   "details": "من موقف سنورس إلى محطة قطار الفيوم، ثم القطار إلى المنصورة.",
   "duration": "3 ساعات",
   "price": "95 جنيه",
   "transfers": "2",
   "tips": "تأكد من الوصول للموقف قبل الموعد بـ 10 دقائق",
   "timeline": [
     {
       "step": "ميكروباص من موقف سنورس إلى الفيوم",
       "start_time": "10:10 صباحًا",
       "duration": "20 دقيقة"
     },
     {
       "step": "قطار من الفيوم إلى المنصورة",
       "start_time": "10:45 صباحًا",
       "duration": "2.5 ساعة"
     }
   ]
  }
 ],
 "best_option": "القطار لأن مواعيده دقيقة وتكلفته مناسبة"
}
''';

    try {
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "contents": [
                {
                  "parts": [
                    {"text": prompt}
                  ]
                }
              ]
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final rawText = decoded['candidates'][0]['content']['parts'][0]['text'];
        final cleanJson =
            rawText.replaceAll("```json", "").replaceAll("```", "").trim();
        return jsonDecode(cleanJson);
      } else {
        throw Exception("فشل الاتصال: ${response.statusCode}");
      }
    } on http.ClientException {
      throw Exception('مشكلة في الاتصال بالإنترنت');
    } on TimeoutException {
      throw Exception('الطلب استغرق وقت طويل');
    } on FormatException {
      throw Exception('مشكلة في تحليل البيانات');
    } catch (e) {
      throw Exception('حدث خطأ: $e');
    }
  }

  Future<String> saveSelectedRoute(Map<String, dynamic> route) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId == null) throw Exception('لازم تسجل دخول الأول');
    final docRef =
        await _firestore.collection('users').doc(userId).collection('roads').add({
      ...route,
      'from': _fromLocation,
      'to': _toLocation,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'planned',
    });
    return docRef.id;
  }

  void swapLocations() {
    _swapController.forward(from: 0);
    setState(() {
      final tc = fromCity, tg = fromGovernorate;
      fromCity = toCity;
      fromGovernorate = toGovernorate;
      toCity = tc;
      toGovernorate = tg;
      fromCityController.text = fromCity;
      toCityController.text = toCity;
    });
  }

  void _performSearch() async {
    if (fromCity.isEmpty || fromGovernorate.isEmpty || toCity.isEmpty || toGovernorate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('املا كل الخانات الأول!', style: GoogleFonts.tajawal()),
          backgroundColor: _red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    setState(() => _isSearching = true);
    try {
      final result = await fetchTravelRoutes('$fromCity, $fromGovernorate', '$toCity, $toGovernorate');
      setState(() {
        _routes = result['routes'];
        _bestOption = result['best_option'] ?? '';
        _fromLocation = result['from'];
        _toLocation = result['to'];
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e', style: GoogleFonts.tajawal()),
          backgroundColor: _red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  IconData _getTransportIcon(String method) {
    if (method.contains('قطار')) return Icons.train_rounded;
    if (method.contains('حافلة') || method.contains('أتوبيس')) return Icons.directions_bus_rounded;
    if (method.contains('ميكروباص')) return Icons.airport_shuttle_rounded;
    if (method.contains('Uber') || method.contains('تاكسي')) return Icons.local_taxi_rounded;
    return Icons.directions_rounded;
  }

  // ── Build ──
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // ── Blue curved header bg ──
          Container(
            height: 260,
            decoration: const BoxDecoration(
              color: _blue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),

          // ── Content ──
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _headerRow(),
                    const SizedBox(height: 24),
                    Text(
                      'عايز تروح فين؟',
                      style: GoogleFonts.tajawal(
                        fontSize: 26, fontWeight: FontWeight.bold, color: _white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'دوّر على أحسن طريق وأرخص سعر',
                      style: GoogleFonts.tajawal(fontSize: 14, color: Colors.white70),
                    ),
                    const SizedBox(height: 20),

                    // ── Form card ──
                    _formCard(),

                    const SizedBox(height: 16),

                    // ── Ramadan banner ──
                    _ramadanBanner(),

                    const SizedBox(height: 24),

                    // ── Loading ──
                    if (_isSearching) _loadingWidget(),

                    // ── Results ──
                    if (_routes.isNotEmpty && !_isSearching) ...[
                      _resultsHeader(),
                      const SizedBox(height: 14),
                      ..._routes.asMap().entries.map((e) => _routeCard(e.value, e.key)),
                      if (_bestOption.isNotEmpty) _bestBanner(),
                    ],
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header row (date + icon) ──
  Widget _headerRow() {
    final now = DateTime.now();
    final months = [
      '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    final dateStr = '${now.day} ${months[now.month]} ${now.year}';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateStr, style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.w600, color: _white)),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 14, color: Colors.white70),
                const SizedBox(width: 4),
                Text('مصر', style: GoogleFonts.tajawal(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.route_rounded, size: 22, color: _white),
        ),
      ],
    );
  }

  // ── White form card ──
  Widget _formCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [_cardShadow],
      ),
      child: Column(
        children: [
          // From
          _inputSection(
            label: 'هتتحرك منين؟',
            hint: 'اكتب اسم المنطقة',
            icon: Icons.trip_origin_rounded,
            controller: fromCityController,
            onChanged: (v) => setState(() => fromCity = v),
            govValue: fromGovernorate,
            onGovChanged: (v) => setState(() => fromGovernorate = v ?? ''),
          ),

          const SizedBox(height: 12),

          // Swap divider
          Row(
            children: [
              const Expanded(child: Divider(color: _border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: RotationTransition(
                  turns: Tween(begin: 0.0, end: 0.5).animate(
                    CurvedAnimation(parent: _swapController, curve: Curves.easeInOut),
                  ),
                  child: GestureDetector(
                    onTap: swapLocations,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _blue.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.swap_vert_rounded, size: 20, color: _blue),
                    ),
                  ),
                ),
              ),
              const Expanded(child: Divider(color: _border)),
            ],
          ),

          const SizedBox(height: 12),

          // To
          _inputSection(
            label: 'رايح فين؟',
            hint: 'اكتب اسم المنطقة',
            icon: Icons.place_rounded,
            controller: toCityController,
            onChanged: (v) => setState(() => toCity = v),
            govValue: toGovernorate,
            onGovChanged: (v) => setState(() => toGovernorate = v ?? ''),
          ),

          const SizedBox(height: 24),

          // Search button
          GestureDetector(
            onTap: _isSearching ? null : _performSearch,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _blue,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_rounded, color: _white, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'دوّر على المواصلات',
                    style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.bold, color: _white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputSection({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    required String govValue,
    required ValueChanged<String?> onGovChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: _blue),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.w600, color: _textMid)),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          style: GoogleFonts.tajawal(fontSize: 15, fontWeight: FontWeight.w600, color: _textDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.tajawal(color: _textLight, fontWeight: FontWeight.normal),
            filled: true,
            fillColor: const Color(0xFFF8F9FC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _blue, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: govValue.isEmpty ? null : govValue,
          onChanged: onGovChanged,
          style: GoogleFonts.tajawal(fontSize: 14, color: _textDark),
          dropdownColor: _white,
          borderRadius: BorderRadius.circular(12),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _blue, size: 20),
          decoration: InputDecoration(
            hintText: 'اختار المحافظة',
            hintStyle: GoogleFonts.tajawal(color: _textLight, fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF8F9FC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _blue, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            isDense: true,
          ),
          items: egyptGovernorates
              .map((g) => DropdownMenuItem(value: g, child: Text(g)))
              .toList(),
        ),
      ],
    );
  }

  // ── Ramadan banner ──
  Widget _ramadanBanner() {
    return GestureDetector(
      onTap: _showRamadanGreeting,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A0533), Color(0xFF2D1B69)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2D1B69).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFD4A017).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.nightlight_round,
                color: Color(0xFFD4A017),
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'اضغط هنا حالا',
                style: GoogleFonts.tajawal(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFD4A017),
                ),
              ),
            ),
            Icon(
              Icons.mosque_rounded,
              color: const Color(0xFFD4A017).withOpacity(0.5),
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  void _showRamadanGreeting() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D001A), Color(0xFF1A0533), Color(0xFF2D1B69)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4A017).withOpacity(0.2),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Crescent moon
              const Text('🌙', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 24),
              // رمضان كريم
              Text(
                'رمضان كريم',
                style: GoogleFonts.tajawal(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFD4A017),
                ),
              ),
              const SizedBox(height: 12),
              // Personalized name
              if (_userName.isNotEmpty)
                Text(
                  'يا $_userName',
                  style: GoogleFonts.tajawal(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              const SizedBox(height: 20),
              // Mosque icon
              Icon(
                Icons.mosque_rounded,
                color: const Color(0xFFD4A017).withOpacity(0.4),
                size: 40,
              ),
              const SizedBox(height: 16),
              // From Khalid
              Text(
                'from Khalid',
                style: GoogleFonts.tajawal(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFD4A017),
                ),
              ),
              const SizedBox(height: 24),
              // Close button
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFD4A017),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: const Color(0xFFD4A017).withOpacity(0.3),
                    ),
                  ),
                ),
                child: Text(
                  'إغلاق',
                  style: GoogleFonts.tajawal(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Loading ──
  Widget _loadingWidget() {
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Center(
        child: Column(
          children: [
            const SizedBox(width: 48, height: 48, child: CircularProgressIndicator(color: _blue, strokeWidth: 3.5)),
            const SizedBox(height: 16),
            Text('بندوّر على أحسن طرق...', style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark)),
            const SizedBox(height: 4),
            Text('ثواني كده', style: GoogleFonts.tajawal(fontSize: 13, color: _textMid)),
          ],
        ),
      ),
    );
  }

  // ── Results header ──
  Widget _resultsHeader() {
    return Row(
      children: [
        Text('الطرق المتاحة', style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)),
        const Spacer(),
        Text('${_routes.length} طرق', style: GoogleFonts.tajawal(fontSize: 13, color: _textMid)),
      ],
    );
  }

  void _openDetails(dynamic route) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RouteDetailsPage(
          route: route,
          fromLabel: '$fromCity, $fromGovernorate',
          toLabel: '$toCity, $toGovernorate',
          onSelect: () => saveSelectedRoute(route),
        ),
      ),
    );
  }

  // ── Route card — commuter-line style ──
  Widget _routeCard(dynamic route, int index) {
    final icon = _getTransportIcon(route['method']);
    return GestureDetector(
      onTap: () => _openDetails(route),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                children: [
                  // ── Governorate labels ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(fromGovernorate, style: GoogleFonts.tajawal(fontSize: 12, color: _textMid)),
                      Text(toGovernorate, style: GoogleFonts.tajawal(fontSize: 12, color: _textMid)),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // ── Method name — prominent ──
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: _blue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        route['method'],
                        style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.bold, color: _blue),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── City names row ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          fromCity.isNotEmpty ? fromCity : fromGovernorate,
                          style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Flexible(
                        child: Text(
                          toCity.isNotEmpty ? toCity : toGovernorate,
                          style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ── Dashed line with icon ──
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: _blue, shape: BoxShape.circle)),
                      Expanded(child: SizedBox(height: 2, child: CustomPaint(painter: _DashedLinePainter()))),
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: _blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: _white, width: 3),
                          boxShadow: [BoxShadow(color: _blue.withOpacity(0.2), blurRadius: 8)],
                        ),
                        child: Icon(icon, size: 18, color: _white),
                      ),
                      Expanded(child: SizedBox(height: 2, child: CustomPaint(painter: _DashedLinePainter()))),
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: _blue, shape: BoxShape.circle)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ── Duration / transfers row ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(route['duration'], style: GoogleFonts.tajawal(fontSize: 12, color: _textMid)),
                      Text('${route['transfers']} تحويلات', style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.w600, color: _blue)),
                      Text(route['duration'], style: GoogleFonts.tajawal(fontSize: 12, color: _textMid)),
                    ],
                  ),
                ],
              ),
            ),

            // Divider
            const Divider(height: 1, color: _border),

            // ── Footer: route number + price ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('طريق ${index + 1}', style: GoogleFonts.tajawal(fontSize: 13, color: _textMid)),
                  Text(route['price'], style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.bold, color: _blue)),
                ],
              ),
            ),

            // ── "عرض التفاصيل" button ──
            GestureDetector(
              onTap: () => _openDetails(route),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  color: _blue,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('عرض التفاصيل', style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.bold, color: _white)),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Best option banner ──
  Widget _bestBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _green.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _green.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _green.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.star_rounded, color: _green, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('نصيحتنا ليك', style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.bold, color: _green)),
                const SizedBox(height: 2),
                Text(_bestOption, style: GoogleFonts.tajawal(fontSize: 13, color: _textMid)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ════════════════════════════════════════════════════════════
//  Route Details Page
// ════════════════════════════════════════════════════════════

class RouteDetailsPage extends StatelessWidget {
  final Map<String, dynamic> route;
  final String fromLabel;
  final String toLabel;
  final Future<String?> Function() onSelect;

  const RouteDetailsPage({
    required this.route,
    required this.fromLabel,
    required this.toLabel,
    required this.onSelect,
  });

  IconData _getTransportIcon(String method) {
    if (method.contains('قطار')) return Icons.train_rounded;
    if (method.contains('حافلة') || method.contains('أتوبيس')) return Icons.directions_bus_rounded;
    if (method.contains('ميكروباص')) return Icons.airport_shuttle_rounded;
    if (method.contains('Uber') || method.contains('تاكسي')) return Icons.local_taxi_rounded;
    return Icons.directions_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final timeline = route['timeline'] as List<dynamic>?;
    final icon = _getTransportIcon(route['method']);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('تفاصيل الرحلة', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: _textDark)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.map_rounded, color: _blue),
            onPressed: () async {
              final routeId = await onSelect();
              if (routeId != null) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => TravelMapPage(routeId: routeId)));
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Route summary card ──
                  _summaryCard(icon),
                  const SizedBox(height: 20),

                  // ── Stats row ──
                  Row(
                    children: [
                      _statChip(Icons.schedule_rounded, route['duration'], 'المدة', _blue),
                      const SizedBox(width: 10),
                      _statChip(Icons.payments_rounded, route['price'], 'التكلفة', _green),
                      const SizedBox(width: 10),
                      _statChip(Icons.sync_alt_rounded, '${route['transfers']}', 'تحويلات', _orange),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Details ──
                  _sectionTitle('تفاصيل الرحلة', Icons.info_outline_rounded),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Text(route['details'], style: GoogleFonts.tajawal(fontSize: 14, height: 1.7, color: _textMid), textAlign: TextAlign.right),
                  ),
                  const SizedBox(height: 24),

                  // ── Timeline ──
                  if (timeline != null && timeline.isNotEmpty) ...[
                    _sectionTitle('خطوات الرحلة', Icons.timeline_rounded),
                    const SizedBox(height: 14),
                    ...timeline.asMap().entries.map((e) => _timelineStep(e.value, e.key, e.key == timeline.length - 1)),
                  ],
                  const SizedBox(height: 24),

                  // ── Tips ──
                  if (route['tips'] != null && route['tips'].toString().isNotEmpty) ...[
                    _sectionTitle('نصيحة', Icons.lightbulb_outline_rounded),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _orange.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _orange.withOpacity(0.15)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb_outline_rounded, color: _orange, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(route['tips'], style: GoogleFonts.tajawal(fontSize: 13, color: _textMid, height: 1.5), textAlign: TextAlign.right),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ),

          // ── Bottom button ──
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: _white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
            ),
            child: GestureDetector(
              onTap: () async {
                final routeId = await onSelect();
                if (routeId != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تمام! اتحفظ الطريق', style: GoogleFonts.tajawal()),
                      backgroundColor: _green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                  Navigator.pop(context);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _blue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text('امشي بالطريق ده', style: GoogleFonts.tajawal(fontSize: 17, fontWeight: FontWeight.bold, color: _white)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Summary card ──
  Widget _summaryCard(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(fromLabel, style: GoogleFonts.tajawal(fontSize: 11, color: _textMid), overflow: TextOverflow.ellipsis)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: _blue.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                child: Text(route['method'], style: GoogleFonts.tajawal(fontSize: 10, fontWeight: FontWeight.bold, color: _blue)),
              ),
              Flexible(child: Text(toLabel, style: GoogleFonts.tajawal(fontSize: 11, color: _textMid), overflow: TextOverflow.ellipsis, textAlign: TextAlign.end)),
            ],
          ),
          const SizedBox(height: 14),
          // Station row
          Row(
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: _blue, shape: BoxShape.circle)),
              Expanded(child: SizedBox(height: 2, child: CustomPaint(painter: _DashedLinePainter()))),
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: _blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: _white, width: 3),
                ),
                child: Icon(icon, size: 18, color: _white),
              ),
              Expanded(child: SizedBox(height: 2, child: CustomPaint(painter: _DashedLinePainter()))),
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: _blue, shape: BoxShape.circle)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(route['duration'], style: GoogleFonts.tajawal(fontSize: 12, color: _textMid)),
              Text('${route['transfers']} تحويلات', style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.w600, color: _blue)),
              Text(route['price'], style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.bold, color: _blue)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.bold, color: _textDark), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.tajawal(fontSize: 11, color: _textMid)),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _blue, size: 20),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark)),
      ],
    );
  }

  // ── Timeline step ──
  Widget _timelineStep(dynamic step, int index, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicator
          Column(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: _blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: _white, width: 2),
                  boxShadow: [BoxShadow(color: _blue.withOpacity(0.2), blurRadius: 6)],
                ),
                child: Icon(_getTransportIcon(step['step'] ?? ''), size: 16, color: _white),
              ),
              if (!isLast)
                Container(
                  width: 2, height: 40,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: _blue.withOpacity(0.15),
                ),
            ],
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step['step'], style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.w600, color: _textDark)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _miniTag(Icons.access_time_rounded, step['start_time']),
                      const SizedBox(width: 8),
                      _miniTag(Icons.timer_rounded, step['duration']),
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

  Widget _miniTag(IconData icon, String val) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: _blue.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _blue),
          const SizedBox(width: 4),
          Text(val, style: GoogleFonts.tajawal(fontSize: 11, color: _textMid)),
        ],
      ),
    );
  }
}
