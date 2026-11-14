import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../main_navigation/controllers/main_navigation_controller.dart';
import '../controllers/home_controller.dart';

class InfoStockView extends GetView<HomeController> {
  const InfoStockView({super.key});

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

  void _showEditProductDialog(BuildContext context, Map<String, dynamic> product) {
    final id = (product['id'] as num?)?.toInt() ?? 0;
    final nameCtrl = TextEditingController(text: product['name']?.toString() ?? '');
    final catCtrl = TextEditingController(text: product['category']?.toString() ?? 'Umum');
    final barcodeCtrl = TextEditingController(text: product['barcode']?.toString() ?? '');
    final buyCtrl = TextEditingController(text: product['buy_price']?.toString() ?? '0');
    final sellCtrl = TextEditingController(text: product['sell_price']?.toString() ?? '0');
    final stockCtrl = TextEditingController(text: product['stock']?.toString() ?? '0');

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.edit_outlined, color: Color(0xFFD49A5B)),
            const SizedBox(width: 8),
            const Text('Edit Produk'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Produk'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: catCtrl,
                decoration: const InputDecoration(labelText: 'Kategori'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: barcodeCtrl,
                decoration: const InputDecoration(labelText: 'Barcode (Opsional)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: buyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Harga Beli (Rp)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: sellCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Harga Jual (Rp)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: stockCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Jumlah Stok'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
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
              onPressed: controller.isSubmitting.value
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      final sell = num.tryParse(sellCtrl.text.trim()) ?? 0;
                      if (name.isEmpty || sell <= 0) {
                        Get.snackbar('Warning', 'Nama dan harga jual wajib diisi.');
                        return;
                      }
                      Get.back();
                      await controller.updateProduct(
                        id: id,
                        name: name,
                        barcode: barcodeCtrl.text.trim().isEmpty ? null : barcodeCtrl.text.trim(),
                        category: catCtrl.text.trim().isEmpty ? 'Umum' : catCtrl.text.trim(),
                        buyPrice: num.tryParse(buyCtrl.text.trim()) ?? 0,
                        sellPrice: sell,
                        stock: int.tryParse(stockCtrl.text.trim()) ?? 0,
                      );
                    },
              child: controller.isSubmitting.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Simpan Perubahan'),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteProduct(BuildContext context, Map<String, dynamic> product) {
    final id = (product['id'] as num?)?.toInt() ?? 0;
    final name = product['name']?.toString() ?? 'Produk';

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Hapus Produk?'),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus "$name"? Produk yang dihapus tidak dapat dikembalikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Get.back();
              controller.deleteProduct(id, name);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeController = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController());

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E1E1E)),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Info Stock',
          style: TextStyle(
            color: Color(0xFF1E1E1E),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Scan Barcode',
            icon: const Icon(Icons.qr_code_scanner, color: Color(0xFFD49A5B)),
            onPressed: () {
              Get.back();
              if (Get.isRegistered<MainNavigationController>()) {
                Get.find<MainNavigationController>().openBarcodeScanner();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar & Filter Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Color(0xFF8C7E74), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: homeController.searchController,
                            onSubmitted: homeController.onSearchSubmitted,
                            decoration: const InputDecoration(
                              hintText: 'Cari nama, kategori, atau barcode...',
                              hintStyle: TextStyle(fontSize: 13, color: Color(0xFF8C7E74)),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        if (homeController.searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              homeController.searchController.clear();
                              homeController.fetchProducts();
                            },
                            child: const Icon(Icons.clear, size: 18, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    Get.back();
                    if (Get.isRegistered<MainNavigationController>()) {
                      Get.find<MainNavigationController>().openBarcodeScanner();
                    }
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Scan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD49A5B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Total Items Info Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(
                  () => Text(
                    'Total ${homeController.products.length} Produk Terdaftar',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => homeController.fetchProducts(
                    search: homeController.searchController.text.trim(),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.refresh, size: 16, color: Color(0xFFD49A5B)),
                      SizedBox(width: 4),
                      Text(
                        'Refresh',
                        style: TextStyle(
                          color: Color(0xFFD49A5B),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Products List
          Expanded(
            child: Obx(() {
              if (homeController.isLoadingProducts.value && homeController.products.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (homeController.errorMessage.value != null && homeController.products.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          homeController.errorMessage.value!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => homeController.fetchProducts(),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (homeController.products.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () => homeController.fetchProducts(
                    search: homeController.searchController.text.trim(),
                  ),
                  child: ListView(
                    children: const [
                      SizedBox(height: 160),
                      Center(
                        child: Text(
                          'Belum ada data produk.',
                          style: TextStyle(color: Color(0xFF8E8E93)),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => homeController.fetchProducts(
                  search: homeController.searchController.text.trim(),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: homeController.products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final p = homeController.products[index];
                    final stock = (p['stock'] as num?)?.toInt() ?? 0;
                    final hasBarcode = (p['barcode'] != null && p['barcode'].toString().isNotEmpty);

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p['name']?.toString() ?? '-',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFF2B2118),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Kategori: ${p['category'] ?? 'Umum'}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                    if (hasBarcode) ...[
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.qr_code_2,
                                            size: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${p['barcode']}',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: stock > 0
                                      ? const Color(0xFFDCE6DF)
                                      : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Stok: $stock',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                    color: stock > 0
                                        ? const Color(0xFF2E5A3E)
                                        : Colors.red.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Harga Jual',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    _formatRupiah(p['sell_price']),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFFD49A5B),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  // Tombol Edit Barang
                                  OutlinedButton.icon(
                                    onPressed: () => _showEditProductDialog(context, p),
                                    icon: const Icon(Icons.edit_outlined, size: 16),
                                    label: const Text('Edit'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFD49A5B),
                                      side: const BorderSide(color: Color(0xFFD49A5B)),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Tombol Hapus Barang
                                  OutlinedButton.icon(
                                    onPressed: () => _confirmDeleteProduct(context, p),
                                    icon: const Icon(Icons.delete_outline, size: 16),
                                    label: const Text('Hapus'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.redAccent,
                                      side: const BorderSide(color: Colors.redAccent),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

