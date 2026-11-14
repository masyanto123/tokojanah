import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../home/views/home_view.dart';
import 'history_view.dart';
import 'barcode_view.dart';
import 'profile_view.dart';
import '../controllers/main_navigation_controller.dart';

class MainNavigationView extends GetView<MainNavigationController> {
  const MainNavigationView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MainNavigationController());

    final List<Widget> pages = [
      const HistoryView(),
      const BarcodeView(),
      const ProfileView(),
    ];

    return Obx(
      () => PopScope(
        canPop: controller.isHomeActive.value,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && !controller.isHomeActive.value) {
            controller.showHome();
          }
        },
        child: Scaffold(
          body: controller.isHomeActive.value
              ? const HomeView()
              : IndexedStack(
                  index: controller.currentIndex.value,
                  children: pages,
                ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: controller.currentIndex.value,
              onTap: controller.changePage,
              selectedItemColor: controller.isHomeActive.value
                  ? const Color(0xFF9E9E9E)
                  : const Color(0xFFD49A5B),
              unselectedItemColor: const Color(0xFF9E9E9E),
              backgroundColor: Colors.white,
              elevation: 0,
              selectedLabelStyle: TextStyle(
                fontWeight: controller.isHomeActive.value
                    ? FontWeight.w500
                    : FontWeight.w600,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long_outlined),
                  activeIcon: Icon(Icons.receipt_long),
                  label: 'Riwayat',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.qr_code_scanner_outlined),
                  activeIcon: Icon(Icons.qr_code_scanner),
                  label: 'Barcode',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

