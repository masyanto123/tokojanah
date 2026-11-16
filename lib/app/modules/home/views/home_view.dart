import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  String _formatRupiah(dynamic value) {
    final num amount = num.tryParse(value?.toString() ?? '0') ?? 0;
    final str = amount.round().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return 'Rp ${buffer.toString()}';
  }

  void _showInfoStockSheet(BuildContext context) {
    controller.fetchProducts(search: controller.searchController.text.trim());
    Get.toNamed(Routes.INFO_STOCK);
  }

  void _executeSearch(BuildContext context, HomeController homeController) {
    final query = homeController.searchController.text.trim();
    homeController.onSearchSubmitted(query);
    _showInfoStockSheet(context);
  }

  void _showHitungBarangSheet(BuildContext context) {
    controller.fetchProducts();
    Get.toNamed(Routes.HITUNG_BARANG);
  }

  @override
  Widget build(BuildContext context) {
    final homeController = Get.put(HomeController());

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Discover',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2B2118),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),

              // Search Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: homeController.searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _executeSearch(context, homeController),
                        decoration: const InputDecoration(
                          hintText: 'Cari produk di Info Produk...',
                          hintStyle: TextStyle(
                            color: Color(0xFF8C7E74),
                            fontSize: 13.5,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _executeSearch(context, homeController),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD49A5B),
                          borderRadius: BorderRadius.circular(21),
                        ),
                        child: const Icon(
                          Icons.search,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),

              // Recent Searches
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pencarian Terakhir',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2B2118),
                    ),
                  ),
                  GestureDetector(
                    onTap: homeController.clearRecentSearches,
                    child: const Text(
                      'Hapus Semua',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8C7E74),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Obx(
                () => Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: homeController.recentSearches.map((item) {
                    return GestureDetector(
                      onTap: () {
                        homeController.searchController.text = item;
                        _executeSearch(context, homeController);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAE5E2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4A3D33),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 28),

              // Trending Categories
              const Text(
                'Trending Categories',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2B2118),
                ),
              ),
              const SizedBox(height: 14),

              Obx(
                () => GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.78,
                  children: [
                    _CategoryCard(
                      boxColor: const Color(0xFFDCE6DF),
                      title: 'Info Stock',
                      subtitle: '${homeController.products.length} produk',
                      onTap: () => _showInfoStockSheet(context),
                    ),
                    _CategoryCard(
                      boxColor: const Color(0xFFF5DFDF),
                      title: 'Hitung Barang',
                      subtitle: 'Kasir & checkout',
                      onTap: () => _showHitungBarangSheet(context),
                    ),
                    _CategoryCard(
                      boxColor: const Color(0xFFFCE8D5),
                      title: 'Coming Soon',
                      subtitle: 'Segera hadir',
                      onTap: () {
                        Get.snackbar(
                          'Coming Soon',
                          'Fitur ini akan segera hadir!',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                    ),
                    _CategoryCard(
                      boxColor: const Color(0xFFDEDAD7),
                      title: 'Coming Soon',
                      subtitle: 'Segera hadir',
                      onTap: () {
                        Get.snackbar(
                          'Coming Soon',
                          'Fitur ini akan segera hadir!',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Color boxColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.boxColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: boxColor,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2B2118),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF8C7E74),
                ),
              ),
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }
}
