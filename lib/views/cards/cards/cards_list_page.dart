import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/shared/layouts/app_mini_footer.dart';
import '../../../controllers/cards/cards/cards_list_controller.dart';

// استيراد الوجتات المشتركة
import '../../widgets/shared/layouts/sub_page_header.dart';
import '../../widgets/widgetsCard/card_item_tile.dart';

class CardsListPage extends GetView<CardsListController> {
  const CardsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1220),
        body: Column(
          children: [
            // 1. الهيدر
            const PremiumHeader(
              title: "إدارة الكروت",
              subtitle: "مزامنة لحظية وبحث فائق السرعة لكافة اشتراكات الشبكة",
              showBackButton: true,
            ),
            
            // 2. منطقة البحث والفلترة
            _buildSearchAndFilterArea(),
            
            // 3. القائمة المحدثة مع دعم السحب للتحديث
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.refreshCards,
                color: const Color(0xFF3B82F6),
                backgroundColor: const Color(0xFF16213A),
                child: _buildCardsList(),
              ),
            ),
            
            // 4. الفوتر
            const AppMiniFooter(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(
                    children: [
                      Icon(Icons.circle, color: Color(0xFF0EA5E9), size: 14),
                      SizedBox(width: 5),
                      Text("جديدة", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), fontSize: 12)),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.circle, color: Colors.green, size: 14),
                      SizedBox(width: 5),
                      Text("نشطة", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), fontSize: 12)),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.circle, color: Colors.redAccent, size: 14),
                      SizedBox(width: 5),
                      Text("منتهية", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* ================= منطقة البحث والفلترة ================= */
  Widget _buildSearchAndFilterArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _searchField(),
              ),
              const SizedBox(width: 8),
              _refreshButton(),
              const SizedBox(width: 8),
              _addButton(),
            ],
          ),
          const SizedBox(height: 11),
          _buildFilterChips(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _searchField() {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: const Color(0xFF16213A),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), 
            blurRadius: 15, 
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Obx(() => TextField(
        controller: controller.searchCtrl,
        onChanged: controller.setSearch,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: "بحث سريع برقم الكرت أو الباقة...",
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF3B82F6)),
          suffixIcon: controller.searchQuery.value.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: Color(0xFF94A3B8), size: 20),
                  onPressed: controller.clearSearch,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        ),
      )),
    );
  }

  Widget _refreshButton() {
    return InkWell(
      onTap: controller.refreshCards,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 55,
        width: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF16213A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF243352)),
        ),
        child: const Icon(Icons.sync_rounded, color: Color(0xFF3B82F6), size: 24),
      ),
    );
  }

  Widget _addButton() { 
    return InkWell( 
      onTap: controller.goToAddSingleCard, 
      borderRadius: BorderRadius.circular(18),
      child: Container( 
        height: 55, 
        width: 55, 
        decoration: BoxDecoration( 
          gradient: const LinearGradient(colors: [Color(0xFF38BDF8), Color(0xFF0EA5E9)]), 
          borderRadius: BorderRadius.circular(18), 
          boxShadow: [ 
            BoxShadow( 
              color: const Color(0xFF0EA5E9).withOpacity(0.3), 
              blurRadius: 10, 
              offset: const Offset(0, 4), 
            ) 
          ], 
        ), 
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30), 
      ), 
    ); 
  }

  Widget _buildFilterChips() {
    final items = ["الكل", "جديدة", "نشطة", "منتهية"];
    
    return Obx(() => Row(
      children: items.map((f) {
        final active = controller.filter.value == f;
        final count = controller.cardCounts[f]?.value ?? 0;
        
        return Expanded(
          child: GestureDetector(
            onTap: () => controller.setFilter(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 7),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? const Color(0xFF3B82F6) : const Color(0xFF16213A),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: active ? const Color(0xFF60A5FA) : const Color(0xFF243352)),
                boxShadow: active
                    ? [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                    : null,
              ),
              child: Text(
                "$f\n($count)",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: active ? Colors.white : const Color(0xFF94A3B8), 
                  fontWeight: FontWeight.w900, 
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      }).toList(),
    ));
  }

  /* ================= عرض قائمة الكروت ================= */
  Widget _buildCardsList() {
    return Obx(() {
      // 1. حالة التحميل
      if (controller.isLoading.value) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF3B82F6)),
              SizedBox(height: 14),
              Text("جاري مزامنة الكروت مع الراوتر...", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
            ],
          ),
        );
      }

      // 2. حالة القائمة فارغة
      if (controller.filteredCards.isEmpty) {
        return _emptyState();
      }

      // 3. بناء القائمة المفلترة
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        itemCount: controller.filteredCards.length,
        itemBuilder: (context, i) {
          final card = controller.filteredCards[i];

          return CardItemTile(
            username: card.username,
            package: card.profile,
            status: card.status,
            onTap: () => controller.goToCardDetails(card),
            onAnalyticsTap: () => controller.goToCardSessions(card),
          );
        },
      );
    });
  }

  Widget _emptyState() {
    final hasSearch = controller.searchQuery.value.isNotEmpty;
    final isTotalEmpty = controller.allCards.isEmpty;

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                hasSearch ? Icons.search_off_rounded : Icons.credit_card_off_rounded,
                size: 64,
                color: const Color(0xFF334155),
              ),
              const SizedBox(height: 14),
              Text(
                hasSearch
                    ? "لم يتم العثور على نتائج مطابقة لـ \"${controller.searchQuery.value}\""
                    : (isTotalEmpty ? "لا توجد كروت مسجلة في الراوتر حالياً" : "لا توجد كروت في هذا التصنيف"),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              if (hasSearch)
                ElevatedButton.icon(
                  onPressed: controller.clearSearch,
                  icon: const Icon(Icons.clear_all_rounded, size: 18),
                  label: const Text("مسح البحث"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: const Color(0xFF60A5FA),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                )
              else if (isTotalEmpty)
                ElevatedButton.icon(
                  onPressed: controller.goToAddSingleCard,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text("إضافة كرت الآن"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
