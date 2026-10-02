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
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // 1. الهيدر
            const PremiumHeader(
              title: "إدارة الكروت",
              subtitle: "عرض وتحرير كافة اشتراكات الشبكة",
              showBackButton: true,
            ),
            
            // 2. منطقة البحث والفلترة (مربوطة الآن بالمتحكم تفاعلياً)
            _buildSearchAndFilterArea(),
            
            // 3. القائمة المحدثة
            Expanded(child: _buildCardsList()),
            
            // 4. الفوتر
           const AppMiniFooter(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(
                    children: [
                      Icon(Icons.circle,color: Colors.blue,size: 15,),
                      SizedBox(width: 5,),
                      Text("جديدة",style: TextStyle(fontWeight: FontWeight.bold,color: Colors.blueGrey),),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.circle,color: Colors.green,size: 15,),
                      SizedBox(width: 5,),
                      Text("نشطة",style: TextStyle(fontWeight: FontWeight.bold,color: Colors.blueGrey),),
                    ],
                  ),
                 Row(
                    children: [
                      Icon(Icons.circle,color: Colors.red,size: 15,),
                      SizedBox(width: 5,),
                      Text("منتهية",style: TextStyle(fontWeight: FontWeight.bold,color: Colors.blueGrey),),
                    ],
                  ),
                ],
              )
              ),
          ],
        ),
      ),
    );
  }

  /* ================= منطقة البحث والفلترة ================= */
  Widget _buildSearchAndFilterArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _searchField(),
              ),
              const SizedBox(width: 12),
              _addButton(),
            ],
          ),
          const SizedBox(height: 15),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), 
            blurRadius: 15, 
            offset: const Offset(0, 5)
          )
        ],
      ),
      child: TextField(
        // ربط التغيير مباشرة بدالة البحث في المتحكم
        onChanged: (v) => controller.setSearch(v),
        decoration: const InputDecoration(
          hintText: "بحث برقم الكرت أو الباقة...",
          hintStyle: TextStyle(fontSize: 13, color: Colors.blueGrey),
          prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF1E3A8A)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

Widget _addButton() { 
    return InkWell( 
      onTap: controller.goToAddSingleCard, 
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
      // مسحنا mainAxisAlignment لأن Expanded سيتكفل بتعبئة الصف بالكامل
      children: items.map((f) {
        final active = controller.filter.value == f;
        
        return Expanded( // 👈 تم التغليف بـ Expanded هنا
          child: GestureDetector(
            onTap: () => controller.setFilter(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4), // مسافة خفيفة بين الأزرار
              padding: const EdgeInsets.symmetric(vertical: 6), // حشوة من الأعلى والأسفل فقط
              alignment: Alignment.center, // 👈 مهم جداً لتوسيط النص داخل المساحة الممتدة
              decoration: BoxDecoration(
                color: active ? const Color(0xFF1E3A8A) : Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: active ? Colors.transparent : Colors.blueGrey.shade50),
              ),
              child: Text(
                "$f\n${controller.cardCounts[f]?.value}",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: active ? Colors.white : Colors.blueGrey, 
                  fontWeight: FontWeight.w900, 
                  fontSize: 12 // يمكنك تكبير الخط إلى 13 إذا أردت
                ),
                maxLines: 2, // لمنع النص من النزول لسطر جديد في الشاشات الصغيرة جداً
                overflow: TextOverflow.ellipsis, // وضع نقاط إذا كان النص أكبر من الشاشة (نادر الحدوث هنا)
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
      // 1. حالة التحميل من المتحكم
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A)));
      }

      // 2. حالة القائمة فارغة (سواء كانت فارغة أصلاً أو بسبب البحث)
      if (controller.filteredCards.isEmpty) {
        return _emptyState();
      }

      // 3. بناء القائمة المفلترة
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 5, 20, 20),
        physics: const BouncingScrollPhysics(),
        itemCount: controller.filteredCards.length,
        itemBuilder: (context, i) {
          final card = controller.filteredCards[i];

          return CardItemTile(
            username: card.username,
            package: card.profile, // يستخدم الـ extension الموجود في ملف المتحكم
            status: card.status,
            // التنقل عبر المتحكم مباشرة
            onTap: () => controller.goToCardDetails(card),
            onAnalyticsTap: () => controller.goToCardSessions(card),
          );
        },
      );
    });
  }

  Widget _emptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.search_off_rounded, size: 60, color: Colors.blueGrey.shade100),
        const SizedBox(height: 10),
        const Text(
          "لم يتم العثور على نتائج", 
          style: TextStyle(color: Colors.blueGrey, fontSize: 13)
        ),
      ],
    );
  }

}