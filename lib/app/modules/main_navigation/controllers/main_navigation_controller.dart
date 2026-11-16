import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/api_service.dart';
import '../../../routes/app_pages.dart';

class MainNavigationController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final currentIndex = 0.obs;
  final isHomeActive = true.obs;
  final isCashierScan = false.obs;
  final autoScanTrigger = 0.obs;
  final isLoadingTransactions = false.obs;
  final transactions = <Map<String, dynamic>>[].obs;
  final transactionError = RxnString();
  final selectedCashier = 'Semua'.obs;

  List<String> get cashierList {
    final cashiers = <String>{};
    for (final t in transactions) {
      final name = t['cashier_name']?.toString().trim();
      if (name != null && name.isNotEmpty) {
        cashiers.add(name);
      }
    }
    final sorted = cashiers.toList()..sort();
    return ['Semua', ...sorted];
  }

  List<Map<String, dynamic>> get filteredTransactions {
    if (selectedCashier.value == 'Semua') {
      return transactions;
    }
    return transactions.where((t) {
      final name = t['cashier_name']?.toString().trim().toLowerCase();
      return name == selectedCashier.value.toLowerCase();
    }).toList();
  }

  int get selectedCashierTransactionCount => filteredTransactions.length;

  num get selectedCashierTotalSales {
    return filteredTransactions.fold(0, (sum, t) {
      final amount = num.tryParse(t['total_amount']?.toString() ?? '0') ?? 0;
      return sum + amount;
    });
  }

  int getTransactionCountFor(String cashier) {
    if (cashier == 'Semua') return transactions.length;
    return transactions.where((t) {
      final name = t['cashier_name']?.toString().trim().toLowerCase();
      return name == cashier.toLowerCase();
    }).length;
  }

  void selectCashier(String cashier) {
    selectedCashier.value = cashier;
  }

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
    if (index != 1) {
      isCashierScan.value = false;
    }
    isHomeActive.value = false;
    currentIndex.value = index;
  }

  void showHome() {
    isCashierScan.value = false;
    isHomeActive.value = true;
  }

  void openBarcodeScanner({bool forCashier = false}) {
    isCashierScan.value = forCashier;
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

