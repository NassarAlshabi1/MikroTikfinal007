import 'package:flutter/material.dart';
import 'package:mikronet/app/theme/app_theme.dart';

class HomeHeader extends StatelessWidget {
  final Animation<double> pulseAnimation;
  final VoidCallback onLogout;

  const HomeHeader({
    super.key,
    required this.pulseAnimation,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 44, left: 20, right: 20, bottom: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.headerTop, AppColors.headerBottom],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "مركز التحكم الذكي",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x1A4ADE80),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: pulseAnimation,
                      child: const Icon(Icons.circle,
                          color: Colors.greenAccent, size: 8),
                    ),
                    const SizedBox(width: 6),
                    const Text("ميكروتك: متصل الآن",
                        style: TextStyle(
                            color: Color(0xFFE8EEF9), fontSize: 10.5)),
                  ],
                ),
              ),
            ],
          ),
          ),
          IconButton(
            onPressed: onLogout,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: const Color(0x1AE8EEF9),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.power_settings_new_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
