import 'package:flutter/material.dart';

class HomeCarousel extends StatelessWidget {
  final PageController controller;
  final int currentPage;
  final Function(int) onPageChanged;
  final List<Widget> items;

  const HomeCarousel({
    super.key,
    required this.controller,
    required this.currentPage,
    required this.onPageChanged,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 200,
          margin: const EdgeInsets.only(top: 15),
          child: PageView(
            controller: controller,
            onPageChanged: onPageChanged,
            children: items,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            items.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: currentPage == index ? 18 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: currentPage == index
                    ? const Color(0xFF1E3A8A)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// بطاقة الإجراءات الملونة داخل الكاروسيل
class ActionCarouselItem extends StatelessWidget {
  final String category, title, subtitle, actionText;
  final String? value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const ActionCarouselItem({
    super.key,
    required this.category,
    required this.title,
    required this.subtitle,
    this.value,
    required this.icon,
    required this.color,
    required this.actionText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [color.withOpacity(0.85), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8))
          ],
        ),
        child: Stack(
          children: [
            Positioned(
                left: -20,
                top: -20,
                child: Icon(icon,
                    size: 130, color: Colors.white.withOpacity(0.12))),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBadge(category),
                const SizedBox(height: 10),
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text(subtitle,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 11)),
                const Spacer(),
                if (value != null)
                  Text(value!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900)),
                const Spacer(),
                Text(actionText,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.white12, borderRadius: BorderRadius.circular(8)),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
    );
  }
}

// بطاقة مراقبة الموارد (CPU/RAM)
class ResourceCarouselItem extends StatelessWidget {
  final String category, label, percent;
  final IconData icon;
  final Color color;

  const ResourceCarouselItem({
    super.key,
    required this.category,
    required this.label,
    required this.percent,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    double val = double.parse(percent.replaceAll('%', '')) / 100;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(35),
        boxShadow: const [
          BoxShadow(
              color: Colors.black26, blurRadius: 15, offset: Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBadge(category),
          const Spacer(),
          Center(child: Icon(icon, color: color, size: 45)),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text(percent,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
                value: val,
                backgroundColor: Colors.white10,
                color: color,
                minHeight: 8),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.white12, borderRadius: BorderRadius.circular(8)),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
    );
  }
}
