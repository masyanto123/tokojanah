import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/api_service.dart';
import '../../main_navigation/controllers/main_navigation_controller.dart';

class HomeController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final searchController = TextEditingController();
  final recentSearches = <String>['Beras', 'Kopi', 'Gula'].obs;
  final products = <Map<String, dynamic>>[].obs;
  final isLoadingProducts = false.obs;
  final errorMessage = RxnString();
  final isSubmitting = false.obs;

  // Cart untuk Hitung Barang: productId -> quantity
  final cart = <int, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
  }

  Future<void> fetchProducts({String search = ''}) async {
    isLoadingProducts.value = true;
    errorMessage.value = null;
    try {
      final result = await _apiService.getProducts(search: search);
      if (result.success) {
        products.assignAll(result.data ?? []);
      } else {
        errorMessage.value = result.message;
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoadingProducts.value = false;
    }
  }

  Future<void> onSearchSubmitted(String query) async {
    final trimmed = query.trim();
    if (trimmed.isNotEmpty && !recentSearches.contains(trimmed)) {
      recentSearches.insert(0, trimmed);
      if (recentSearches.length > 5) {
        recentSearches.removeLast();
      }
    }
    await fetchProducts(search: trimmed);
  }

  void clearRecentSearches() {
    recentSearches.clear();
    searchController.clear();
    fetchProducts();
  }

  void addToCart(int productId, int maxStock, {int quantity = 1}) {
    final currentQty = cart[productId] ?? 0;
    if (currentQty + quantity <= maxStock) {
      cart[productId] = currentQty + quantity;
    } else {
      cart[productId] = maxStock;
      Get.snackbar(
        'Stok Maksimal',
        'Stok maksimal tercapai ($maxStock).',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.9),
        colorText: Colors.white,
      );
    }
  }

  void setCartQuantity(int productId, int qty, int maxStock) {
    if (qty <= 0) {
      cart.remove(productId);
    } else if (qty > maxStock) {
      cart[productId] = maxStock;
      Get.snackbar(
        'Stok Maksimal',
        'Hanya tersedia $maxStock stok.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.9),
        colorText: Colors.white,
      );
    } else {
      cart[productId] = qty;
    }
  }

  void clearCart() {
    cart.clear();
  }

  void removeFromCart(int productId) {
    final currentQty = cart[productId] ?? 0;
    if (currentQty > 1) {
      cart[productId] = currentQty - 1;
    } else {
      cart.remove(productId);
    }
  }

  double get cartTotal {
    double total = 0;
    for (final entry in cart.entries) {
      final prod = products.firstWhereOrNull((p) => (p['id'] as num?)?.toInt() == entry.key);
      if (prod != null) {
        final price = double.tryParse(prod['sell_price']?.toString() ?? '0') ?? 0;
        total += price * entry.value;
      }
    }
    return total;
  }

  Future<bool> checkout(double payAmount) async {
    if (cart.isEmpty) {
      Get.snackbar('Info', 'Pilih barang terlebih dahulu.', snackPosition: SnackPosition.BOTTOM);
      return false;
    }
    isSubmitting.value = true;
    try {
      final items = cart.entries
          .map((e) => {'product_id': e.key, 'quantity': e.value})
          .toList();
      final result = await _apiService.createTransaction(
        items: items,
        payAmount: payAmount,
      );
      if (result.success) {
        cart.clear();
        await fetchProducts();
        if (Get.isRegistered<MainNavigationController>()) {
          Get.find<MainNavigationController>().fetchTransactions();
        }
        Get.back();
        final kembalian = result.data?['change_amount'] ?? 0;
        Get.snackbar(
          'Transaksi Berhasil',
          '${result.message} Kembalian: Rp $kembalian',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.9),
          colorText: Colors.white,
        );
        return true;
      } else {
        Get.snackbar(
          'Checkout Gagal',
          result.message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent.withOpacity(0.9),
          colorText: Colors.white,
        );
        return false;
      }
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> addProduct({
    required String name,
    String? barcode,
    required String category,
    required num buyPrice,
    required num sellPrice,
    required int stock,
  }) async {
    isSubmitting.value = true;
    try {
      final result = await _apiService.addProduct(
        name: name,
        barcode: barcode,
        category: category,
        buyPrice: buyPrice,
        sellPrice: sellPrice,
        stock: stock,
      );
      if (result.success) {
        await fetchProducts();
        Get.back();
        Get.snackbar(
          'Berhasil',
          result.message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.9),
          colorText: Colors.white,
        );
        return true;
      } else {
        Get.snackbar(
          'Gagal',
          result.message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent.withOpacity(0.9),
          colorText: Colors.white,
        );
        return false;
      }
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> updateProduct({
    required int id,
    required String name,
    String? barcode,
    required String category,
    required num buyPrice,
    required num sellPrice,
    required int stock,
  }) async {
    isSubmitting.value = true;
    try {
      final result = await _apiService.updateProduct(
        id: id,
        name: name,
        barcode: barcode,
        category: category,
        buyPrice: buyPrice,
        sellPrice: sellPrice,
        stock: stock,
      );
      if (result.success) {
        await fetchProducts();
        Get.snackbar(
          'Berhasil',
          result.message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.9),
          colorText: Colors.white,
        );
        return true;
      } else {
        Get.snackbar(
          'Gagal',
          result.message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent.withOpacity(0.9),
          colorText: Colors.white,
        );
        return false;
      }
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> deleteProduct(int id, String productName) async {
    isSubmitting.value = true;
    try {
      final result = await _apiService.deleteProduct(id);
      if (result.success) {
        await fetchProducts();
        cart.remove(id);
        Get.snackbar(
          'Dihapus',
          'Produk "$productName" berhasil dihapus.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.9),
          colorText: Colors.white,
        );
        return true;
      } else {
        Get.snackbar(
          'Gagal',
          result.message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent.withOpacity(0.9),
          colorText: Colors.white,
        );
        return false;
      }
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
