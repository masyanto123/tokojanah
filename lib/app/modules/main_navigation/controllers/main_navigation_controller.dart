import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/api_service.dart';
import '../../../routes/app_pages.dart';

class MainNavigationController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final currentIndex = 0.obs;
  final isHomeActive = true.obs;
  final autoScanTrigger = 0.obs;
  final isLoadingTransactions = false.obs;
  final transactions = <Map<String, dynamic>>[].obs;
  final transactionError = RxnString();

  final isLoadingProducts = false.obs;
  final products = <Map<String, dynamic>>[].obs;

  Map<String, dynamic>? get user => _apiService.currentUser.value;

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    await Future.wait([
      fetchProfile(),
      fetchTransactions(),
      fetchProducts(),
    ]);
  }

  void changePage(int index) {
    isHomeActive.value = false;
    currentIndex.value = index;
  }

  void showHome() {
    isHomeActive.value = true;
  }

  void openBarcodeScanner() {
    isHomeActive.value = false;
    currentIndex.value = 1;
    autoScanTrigger.value++;
  }

  Future<void> fetchProfile() async {
    await _apiService.getProfile();
  }

  Future<void> fetchTransactions() async {
    isLoadingTransactions.value = true;
    transactionError.value = null;
    try {
      final result = await _apiService.getTransactions();
      if (result.success) {
        transactions.assignAll(result.data ?? []);
      } else {
        transactionError.value = result.message;
      }
    } finally {
      isLoadingTransactions.value = false;
    }
  }

  Future<void> fetchProducts({String search = ''}) async {
    isLoadingProducts.value = true;
    try {
      final result = await _apiService.getProducts(search: search);
      if (result.success) {
        products.assignAll(result.data ?? []);
      }
    } finally {
      isLoadingProducts.value = false;
    }
  }

  Future<Map<String, dynamic>?> fetchTransactionDetail(int id) async {
    final result = await _apiService.getTransactionDetail(id);
    if (result.success) {
      return result.data;
    }
    Get.snackbar(
      'Error',
      result.message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent.withOpacity(0.9),
      colorText: Colors.white,
    );
    return null;
  }

  void logout() {
    _apiService.logout();
    Get.offAllNamed(Routes.LOGIN);
  }
}

