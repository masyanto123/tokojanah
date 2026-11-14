import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/api_service.dart';
import '../controllers/main_navigation_controller.dart';

class ProfileView extends GetView<MainNavigationController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = Get.find<ApiService>();
    final navController = Get.find<MainNavigationController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E1E1E)),
          onPressed: navController.showHome,
        ),
        title: const Text(
          'Profil Saya',
          style: TextStyle(
            color: Color(0xFF1E1E1E),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Avatar Profil
            CircleAvatar(
              radius: 48,
              backgroundColor: const Color(0xFFE5B582).withOpacity(0.2),
              child: const Icon(
                Icons.person,
                size: 54,
                color: Color(0xFFD49A5B),
              ),
            ),
            const SizedBox(height: 16),
            Obx(() {
              final user = apiService.currentUser.value;
              return Column(
                children: [
                  Text(
                    user?['name']?.toString() ?? 'Kasir Toko Janah',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C2C2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?['email']?.toString() ?? '-',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 32),

            // Opsi Profil
            _buildProfileMenuItem(
              icon: Icons.storefront_outlined,
              title: 'Informasi Toko',
              onTap: () {},
            ),
            _buildProfileMenuItem(
              icon: Icons.lock_outline,
              title: 'Ubah Kata Sandi',
              onTap: () {},
            ),
            _buildProfileMenuItem(
              icon: Icons.help_outline,
              title: 'Bantuan & Dukungan',
              onTap: () {},
            ),
            const SizedBox(height: 16),
            _buildProfileMenuItem(
              icon: Icons.logout,
              title: 'Keluar',
              color: Colors.redAccent,
              onTap: () {
                Get.defaultDialog(
                  title: 'Konfirmasi Keluar',
                  middleText: 'Apakah Anda yakin ingin keluar dari akun?',
                  textConfirm: 'Keluar',
                  textCancel: 'Batal',
                  confirmTextColor: Colors.white,
                  buttonColor: Colors.redAccent,
                  onConfirm: () {
                    Get.back(); // close dialog
                    navController.logout();
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Icon(icon, color: color ?? const Color(0xFFD49A5B)),
        title: Text(
          title,
          style: TextStyle(
            color: color ?? const Color(0xFF2C2C2E),
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey.shade400,
          size: 20,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

