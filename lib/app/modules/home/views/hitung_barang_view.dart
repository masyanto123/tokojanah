import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../main_navigation/controllers/main_navigation_controller.dart';
import '../controllers/home_controller.dart';

class HitungBarangView extends GetView<HomeController> {
  const HitungBarangView({super.key});

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

  void _showEditQuantityDialog(BuildContext context, Map<String, dynamic> product, int currentQty, int stock) {
    final id = (product['id'] as num?)?.toInt() ?? 0;
    final qtyCtrl = TextEditingController(text: currentQty.toString());

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Atur Jumlah: ${product['name']}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Maksimal stok tersedia: $stock',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: qtyCtrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Jumlah Beli (Qty)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                suffixText: 'pcs',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD49A5B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final newQ = int.tryParse(qtyCtrl.text.trim()) ?? 0;
              controller.setCartQuantity(id, newQ, stock);
              Get.back();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final payController = TextEditingController();

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
          'Hitung Barang',
          style: TextStyle(
            color: Color(0xFF1E1E1E),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          Obx(
            () => controller.cart.isNotEmpty
                ? IconButton(
                    tooltip: 'Kosongkan Keranjang',
                    icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
                    onPressed: () {
                      Get.defaultDialog(
                        title: 'Kosongkan Keranjang?',
                        middleText: 'Semua produk di keranjang belanja akan dihapus.',
                        textConfirm: 'Kosongkan',
                        textCancel: 'Batal',
                        confirmTextColor: Colors.white,
                        buttonColor: Colors.redAccent,
                        onConfirm: () {
                          controller.clearCart();
                          Get.back();
                          Get.snackbar('Keranjang Kosong', 'Semua item telah dihapus.');
                        },
                      );
                    },
                  )
                : const SizedBox.shrink(),
          ),
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
          // Banner Info Tambah Produk
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Keranjang Belanja Kasir',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Obx(
                        () => Text(
                          '${controller.cart.length} macam produk dipilih',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Get.back();
                    if (Get.isRegistered<MainNavigationController>()) {
                      Get.find<MainNavigationController>().openBarcodeScanner();
                    }
                  },
                  icon: const Icon(Icons.qr_code_scanner, size: 16),
                  label: const Text('Scan Produk'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD49A5B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Daftar Produk di Keranjang
          Expanded(
            child: Obx(() {
              if (controller.isLoadingProducts.value && controller.products.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final cartProducts = controller.products.where((p) {
                final id = (p['id'] as num?)?.toInt() ?? 0;
                return (controller.cart[id] ?? 0) > 0;
              }).toList();

              if (cartProducts.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF1E8),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const Icon(
                            Icons.shopping_cart_outlined,
                            size: 64,
                            color: Color(0xFFD49A5B),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Keranjang Masih Kosong',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2B2118),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Scan barcode produk pembeli untuk menambahkan\nke keranjang dan menghitung total harga.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            Get.back();
                            if (Get.isRegistered<MainNavigationController>()) {
                              Get.find<MainNavigationController>().openBarcodeScanner();
                            }
                          },
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Mulai Scan Barcode'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE5B582),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: cartProducts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final p = cartProducts[index];
                  final id = (p['id'] as num?)?.toInt() ?? 0;
                  final stock = (p['stock'] as num?)?.toInt() ?? 0;
                  final price = double.tryParse(p['sell_price']?.toString() ?? '0') ?? 0;

                  return Obx(() {
                    final qty = controller.cart[id] ?? 0;
                    final subtotal = price * qty;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p['name']?.toString() ?? '-',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF2B2118),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_formatRupiah(price)} /pcs • Sisa Stok: $stock',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Subtotal: ${_formatRupiah(subtotal)}',
                                  style: const TextStyle(
                                    color: Color(0xFFD49A5B),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF8F6),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 18),
                                  onPressed: () => controller.removeFromCart(id),
                                ),
                                GestureDetector(
                                  onTap: () => _showEditQuantityDialog(context, p, qty, stock),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Text(
                                      '$qty',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 18, color: Color(0xFFD49A5B)),
                                  onPressed: qty < stock
                                      ? () => controller.addToCart(id, stock)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  });
                },
              );
            }),
          ),

          // Bottom Bar Checkout / Pembayaran
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(
                    () => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Belanja',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          _formatRupiah(controller.cartTotal),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            color: Color(0xFFD49A5B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: payController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Nominal Bayar (Rp)',
                            filled: true,
                            fillColor: const Color(0xFFF3F4F6),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Obx(
                        () => ElevatedButton(
                          onPressed: controller.isSubmitting.value || controller.cart.isEmpty
                              ? null
                              : () {
                                  final pay = double.tryParse(payController.text.trim()) ?? 0;
                                  controller.checkout(pay);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE5B582),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: controller.isSubmitting.value
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Bayar',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

