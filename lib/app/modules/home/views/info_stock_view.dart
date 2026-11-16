import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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

  void _showAddProductDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final barcodeCtrl = TextEditingController();
    final buyCtrl = TextEditingController(text: '0');
    final sellCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '10');
    String selectedCat = controller.categories.isNotEmpty
        ? controller.categories.first
        : 'Sembako & Bahan Pokok';

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.add_box_outlined, color: Color(0xFFD49A5B)),
                SizedBox(width: 8),
                Text('Tambah Produk Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama Produk *',
                      hintText: 'Contoh: Beras Ramos 5kg',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Kategori Produk:',
                    style: TextStyle(fontSize: 12, color: Color(0xFF8C7E74), fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: controller.categories.contains(selectedCat) ? selectedCat : controller.categories.first,
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: controller.categories.map((c) {
                      return DropdownMenuItem<String>(
                        value: c,
                        child: Text(c, style: const TextStyle(fontSize: 13.5)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedCat = val);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: barcodeCtrl,
                    decoration: InputDecoration(
                      labelText: 'Barcode (Opsional)',
                      hintText: 'Scan atau ketik barcode',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner, color: Color(0xFFD49A5B)),
                        tooltip: 'Scan Barcode dari Kamera',
                        onPressed: () async {
                          final scanned = await showDialog<String>(
                            context: context,
                            builder: (_) => const _QuickScannerDialog(),
                          );
                          if (scanned != null && scanned.isNotEmpty) {
                            barcodeCtrl.text = scanned;
                          }
                        },
                      ),
                    ),
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
                    decoration: const InputDecoration(labelText: 'Harga Jual (Rp) *'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: stockCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Jumlah Stok Awal'),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          await controller.addProduct(
                            name: name,
                            barcode: barcodeCtrl.text.trim().isEmpty ? null : barcodeCtrl.text.trim(),
                            category: selectedCat,
                            buyPrice: num.tryParse(buyCtrl.text.trim()) ?? 0,
                            sellPrice: sell,
                            stock: int.tryParse(stockCtrl.text.trim()) ?? 0,
                          );
                        },
                  child: const Text('Simpan Produk'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditProductDialog(BuildContext context, Map<String, dynamic> product) {
    final id = (product['id'] as num?)?.toInt() ?? 0;
    final nameCtrl = TextEditingController(text: product['name']?.toString() ?? '');
    final barcodeCtrl = TextEditingController(text: product['barcode']?.toString() ?? '');
    final buyCtrl = TextEditingController(text: product['buy_price']?.toString() ?? '0');
    final sellCtrl = TextEditingController(text: product['sell_price']?.toString() ?? '0');
    final stockCtrl = TextEditingController(text: product['stock']?.toString() ?? '0');

    String currentCat = product['category']?.toString().trim() ?? 'Lainnya';
    if (currentCat.isEmpty) currentCat = 'Lainnya';
    if (!controller.categories.contains(currentCat)) {
      controller.categories.add(currentCat);
    }
    String selectedCat = currentCat;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.edit_outlined, color: Color(0xFFD49A5B)),
                SizedBox(width: 8),
                Text('Edit Produk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nama Produk'),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Kategori:',
                    style: TextStyle(fontSize: 12, color: Color(0xFF8C7E74), fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: controller.categories.contains(selectedCat)
                        ? selectedCat
                        : controller.categories.first,
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: controller.categories.map((c) {
                      return DropdownMenuItem<String>(
                        value: c,
                        child: Text(c, style: const TextStyle(fontSize: 13.5)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedCat = val);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: barcodeCtrl,
                    decoration: InputDecoration(
                      labelText: 'Barcode (Opsional)',
                      hintText: 'Scan atau ketik barcode',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner, color: Color(0xFFD49A5B)),
                        tooltip: 'Scan Barcode dari Kamera',
                        onPressed: () async {
                          final scanned = await showDialog<String>(
                            context: context,
                            builder: (_) => const _QuickScannerDialog(),
                          );
                          if (scanned != null && scanned.isNotEmpty) {
                            barcodeCtrl.text = scanned;
                          }
                        },
                      ),
                    ),
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
                            category: selectedCat,
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
          );
        },
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
          'Apakah Anda yakin ingin menghapus "$name"? Produk ini akan dihapus dari daftar stok.',
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

  void _showManageCategoriesDialog(BuildContext context) {
    final newCatCtrl = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.category_outlined, color: Color(0xFFD49A5B)),
            SizedBox(width: 8),
            Text('Kelola Kategori', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Form Tambah Kategori
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: newCatCtrl,
                      decoration: InputDecoration(
                        hintText: 'Nama Kategori Baru...',
                        hintStyle: const TextStyle(fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD49A5B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onPressed: () async {
                      final name = newCatCtrl.text.trim();
                      if (name.isNotEmpty) {
                        final ok = await controller.addCategory(name);
                        if (ok) newCatCtrl.clear();
                      }
                    },
                    child: const Text('Tambah'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Daftar Kategori:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF8C7E74)),
                ),
              ),
              const SizedBox(height: 8),
              // List Kategori
              Flexible(
                child: Obx(
                  () => ListView.separated(
                    shrinkWrap: true,
                    itemCount: controller.categories.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final cat = controller.categories[index];
                      final catData = controller.categoryList.firstWhereOrNull((c) => c['name'] == cat);
                      final catId = (catData?['id'] as num?)?.toInt();

                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                        leading: const Icon(Icons.label_outline, size: 18, color: Color(0xFFD49A5B)),
                        title: Text(cat, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                        trailing: catId != null
                            ? IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                tooltip: 'Hapus Kategori',
                                onPressed: () {
                                  Get.defaultDialog(
                                    title: 'Hapus Kategori?',
                                    middleText: 'Kategori "$cat" akan dihapus. Produk dalam kategori ini akan dialihkan ke "Lainnya".',
                                    textConfirm: 'Hapus',
                                    textCancel: 'Batal',
                                    confirmTextColor: Colors.white,
                                    buttonColor: Colors.redAccent,
                                    onConfirm: () {
                                      Get.back();
                                      controller.deleteCategory(catId, cat);
                                    },
                                  );
                                },
                              )
                            : null,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Tutup', style: TextStyle(color: Color(0xFF8C7E74))),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Map<String, dynamic> p) {
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
            tooltip: 'Tambah Produk Manual',
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFFD49A5B)),
            onPressed: () => _showAddProductDialog(context),
          ),
          IconButton(
            tooltip: 'Kelola Kategori',
            icon: const Icon(Icons.category_outlined, color: Color(0xFFD49A5B)),
            onPressed: () => _showManageCategoriesDialog(context),
          ),
          IconButton(
            tooltip: 'Scan Barcode',
            icon: const Icon(Icons.qr_code_scanner, color: Color(0xFFD49A5B)),
            onPressed: () {
              Get.back();
              if (Get.isRegistered<MainNavigationController>()) {
                Get.find<MainNavigationController>().openBarcodeScanner(forCashier: false);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar & Actions
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
                  onPressed: () => _showAddProductDialog(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Produk'),
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

          // Horizontal Category Filter Chips Bar
          Container(
            height: 48,
            color: Colors.white,
            child: Obx(() {
              final cats = ['Semua', ...homeController.categories];
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                itemCount: cats.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == cats.length) {
                    return ActionChip(
                      avatar: const Icon(Icons.settings_outlined, size: 14, color: Color(0xFFD49A5B)),
                      label: const Text(
                        'Kelola',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD49A5B)),
                      ),
                      backgroundColor: const Color(0xFFFAF1E8),
                      side: const BorderSide(color: Color(0xFFE5B582)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onPressed: () => _showManageCategoriesDialog(context),
                    );
                  }

                  final cat = cats[index];
                  final isSelected = homeController.selectedCategory.value == cat;
                  final count = cat == 'Semua'
                      ? homeController.products.length
                      : homeController.products
                          .where((p) => (p['category'] ?? 'Lainnya') == cat)
                          .length;

                  return FilterChip(
                    label: Text(
                      '$cat ($count)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : const Color(0xFF4A3D33),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFFD49A5B),
                    backgroundColor: const Color(0xFFF3F4F6),
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFFD49A5B) : Colors.transparent,
                      ),
                    ),
                    onSelected: (_) {
                      homeController.selectedCategory.value = cat;
                    },
                  );
                },
              );
            }),
          ),

          // Total Items Info Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(
                  () => Text(
                    'Menampilkan ${homeController.filteredProducts.length} dari ${homeController.products.length} Produk',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    homeController.fetchCategories();
                    homeController.fetchProducts(
                      search: homeController.searchController.text.trim(),
                    );
                  },
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

          // Products List (Grouped by Category)
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

              final grouped = homeController.productsGroupedByCategory;
              if (grouped.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () => homeController.fetchProducts(
                    search: homeController.searchController.text.trim(),
                  ),
                  child: ListView(
                    children: [
                      const SizedBox(height: 140),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              homeController.selectedCategory.value == 'Semua'
                                  ? 'Belum ada data produk terdaftar.'
                                  : 'Belum ada produk di kategori "${homeController.selectedCategory.value}".',
                              style: const TextStyle(color: Color(0xFF8E8E93)),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _showAddProductDialog(context),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Tambah Produk'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD49A5B),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
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
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: grouped.keys.length,
                  itemBuilder: (context, groupIndex) {
                    final categoryName = grouped.keys.elementAt(groupIndex);
                    final items = grouped[categoryName] ?? [];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Section Header
                        Padding(
                          padding: const EdgeInsets.only(top: 14, bottom: 8, left: 4, right: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD49A5B),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                categoryName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2B2118),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAE5E2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${items.length} produk',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6E6259),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Products in this Category
                        ...items.map(
                          (p) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildProductCard(context, p),
                          ),
                        ),
                      ],
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

class _QuickScannerDialog extends StatefulWidget {
  const _QuickScannerDialog();

  @override
  State<_QuickScannerDialog> createState() => _QuickScannerDialogState();
}

class _QuickScannerDialogState extends State<_QuickScannerDialog> {
  late final MobileScannerController _controller;
  bool _detected = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      formats: const [
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
      ],
      returnImage: false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.qr_code_scanner, color: Color(0xFFD49A5B)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Arahkan ke Barcode',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 300,
        height: 240,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(
                controller: _controller,
                fit: BoxFit.cover,
                onDetect: (capture) {
                  if (_detected) return;
                  for (final b in capture.barcodes) {
                    final val = (b.rawValue ?? b.displayValue)?.trim();
                    if (val != null && val.length >= 6) {
                      _detected = true;
                      Navigator.of(context).pop(val);
                      break;
                    }
                  }
                },
              ),
              Center(
                child: Container(
                  width: 200,
                  height: 110,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE5B582), width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
