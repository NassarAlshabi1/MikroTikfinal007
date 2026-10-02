import 'package:flutter/material.dart';

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
      height: 150,
      padding: const EdgeInsets.only(top: 45, left: 20, right: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("مركز التحكم الذكي",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              Row(
                children: [
                  FadeTransition(
                      opacity: pulseAnimation,
                      child: const Icon(Icons.circle,
                          color: Colors.greenAccent, size: 10)),
                  const SizedBox(width: 8),
                  const Text("ميكروتك: متصل الآن",
                      style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: onLogout,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.power_settings_new_rounded,
                  color: Colors.white, size: 20),
            ),
          )
        ],
      ),
    );
  }
}
