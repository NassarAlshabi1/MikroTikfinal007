import 'package:flutter/material.dart';

class AppScaffoldLayout extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final String footerText;
  final Widget body;

  /// الزر العائم
  final Widget? floatingActionButton;

  const AppScaffoldLayout({
    super.key,
    required this.title,
    required this.footerText,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffECEFF4),

        /// الزر العائم
        floatingActionButton: floatingActionButton,

        body: Column(
          children: [

            /// HEADER
            _header(context),

            /// BODY
            Expanded(child: body),

            /// FOOTER
            _footer(),
          ],
        ),
      ),
    );
  }

  /* ================= HEADER ================= */

  Widget _header(BuildContext context) {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff1E3C72), Color(0xff3A6EA5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x441E3C72),
            blurRadius: 18,
            offset: Offset(0, 6),
          )
        ],
      ),
      child: SafeArea(
        child: Stack(
          children: [

            /// زر الرجوع
            Positioned(
              right: 10,
              top: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),

            /// العنوان
            Center(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),

            /// الأزرار الإضافية
            if (actions != null)
              Positioned(
                left: 10,
                top: 10,
                child: Row(
                  children: actions!,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /* ================= FOOTER ================= */

  Widget _footer() {
    return Container(
      height: 58,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xff162447),
            Color(0xff1F4068),
          ],
        ),
      ),
      child: Center(
        child: Text(
          footerText,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}