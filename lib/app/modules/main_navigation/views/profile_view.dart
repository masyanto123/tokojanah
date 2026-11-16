import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/api_service.dart';
import '../controllers/main_navigation_controller.dart';

class ProfileView extends GetView<MainNavigationController> {
  const ProfileView({super.key});

  void _showStoreInfoDialog(BuildContext context) {
    final apiService = Get.find<ApiService>();
    final descCtrl = TextEditingController();
    final isLoading = true.obs;
    final isSaving = false.obs;

    apiService.getStoreInfo().then((res) {
      if (res.success && res.data != null) {
        descCtrl.text = res.data!['description']?.toString() ?? '';
      }
      isLoading.value = false;
    }).catchError((_) {
      isLoading.value = false;
    });

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.storefront_outlined, color: Color(0xFFD49A5B)),
            SizedBox(width: 8),
            Text(
              'Informasi Toko',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Obx(() {
          if (isLoading.value) {
            return const SizedBox(
              height: 120,
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFFD49A5B)),
              ),
            );
          }
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Deskripsi Toko',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C2C2E),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: descCtrl,
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Masukkan deskripsi toko Anda...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD49A5B)),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          );
        }),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF8C7E74))),
          ),
          Obx(
            () => ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD49A5B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: isSaving.value || isLoading.value
                  ? null
                  : () async {
                      isSaving.value = true;
                      final res = await apiService.saveStoreInfo(
                        description: descCtrl.text.trim(),
                      );
                      isSaving.value = false;
                      Get.back();
                      if (res.success) {
                        Get.snackbar(
                          'Berhasil',
                          res.message,
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.green.withOpacity(0.9),
                          colorText: Colors.white,
                        );
                      } else {
                        Get.snackbar(
                          'Gagal',
                          res.message,
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.redAccent.withOpacity(0.9),
                          colorText: Colors.white,
                        );
                      }
                    },
              child: isSaving.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Simpan'),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final apiService = Get.find<ApiService>();
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();

    final obscureOld = true.obs;
    final obscureNew = true.obs;
    final obscureConfirm = true.obs;
    final isSubmitting = false.obs;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Color(0xFFD49A5B)),
            SizedBox(width: 8),
            Text(
              'Ubah Kata Sandi',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(
                () => TextField(
                  controller: oldPassCtrl,
                  obscureText: obscureOld.value,
                  decoration: InputDecoration(
                    labelText: 'Kata Sandi Saat Ini',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureOld.value ? Icons.visibility_off : Icons.visibility,
                        size: 20,
                        color: Colors.grey,
                      ),
                      onPressed: () => obscureOld.toggle(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Obx(
                () => TextField(
                  controller: newPassCtrl,
                  obscureText: obscureNew.value,
                  decoration: InputDecoration(
                    labelText: 'Kata Sandi Baru (Min. 6 Karakter)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNew.value ? Icons.visibility_off : Icons.visibility,
                        size: 20,
                        color: Colors.grey,
                      ),
                      onPressed: () => obscureNew.toggle(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Obx(
                () => TextField(
                  controller: confirmPassCtrl,
                  obscureText: obscureConfirm.value,
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi Kata Sandi Baru',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm.value ? Icons.visibility_off : Icons.visibility,
                        size: 20,
                        color: Colors.grey,
                      ),
                      onPressed: () => obscureConfirm.toggle(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF8C7E74))),
          ),
          Obx(
            () => ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD49A5B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: isSubmitting.value
                  ? null
                  : () async {
                      final oldPass = oldPassCtrl.text;
                      final newPass = newPassCtrl.text;
                      final confirmPass = confirmPassCtrl.text;

                      if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
                        Get.snackbar(
                          'Peringatan',
                          'Semua kolom kata sandi wajib diisi!',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.orange.withOpacity(0.9),
                          colorText: Colors.white,
                        );
                        return;
                      }

                      if (newPass.length < 6) {
                        Get.snackbar(
                          'Peringatan',
                          'Kata sandi baru minimal harus 6 karakter!',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.orange.withOpacity(0.9),
                          colorText: Colors.white,
                        );
                        return;
                      }

                      if (newPass != confirmPass) {
                        Get.snackbar(
                          'Peringatan',
                          'Konfirmasi kata sandi baru tidak cocok!',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.orange.withOpacity(0.9),
                          colorText: Colors.white,
                        );
                        return;
                      }

                      isSubmitting.value = true;
                      final res = await apiService.changePassword(
                        oldPassword: oldPass,
                        newPassword: newPass,
                      );
                      isSubmitting.value = false;

                      if (res.success) {
                        Get.back();
                        Get.snackbar(
                          'Berhasil',
                          res.message,
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.green.withOpacity(0.9),
                          colorText: Colors.white,
                        );
                      } else {
                        Get.snackbar(
                          'Gagal',
                          res.message,
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.redAccent.withOpacity(0.9),
                          colorText: Colors.white,
                        );
                      }
                    },
              child: isSubmitting.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Simpan'),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpSupportDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Color(0xFFD49A5B)),
            SizedBox(width: 8),
            Text('Bantuan & Dukungan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aplikasi Kasir Warungku / Toko Janah',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            SizedBox(height: 8),
            Text(
              'Untuk bantuan teknis, kendala sistem, atau saran pengembangan aplikasi, silakan hubungi pengelola toko atau tim pengembang.',
              style: TextStyle(fontSize: 13, color: Color(0xFF6E6259)),
            ),
            SizedBox(height: 12),
            Text(
              'Versi Aplikasi: 1.0.0',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD49A5B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Get.back(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

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
              onTap: () => _showStoreInfoDialog(context),
            ),
            _buildProfileMenuItem(
              icon: Icons.lock_outline,
              title: 'Ubah Kata Sandi',
              onTap: () => _showChangePasswordDialog(context),
            ),
            _buildProfileMenuItem(
              icon: Icons.help_outline,
              title: 'Bantuan & Dukungan',
              onTap: () => _showHelpSupportDialog(context),
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
