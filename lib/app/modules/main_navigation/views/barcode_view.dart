import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../data/services/api_service.dart';
import '../../../routes/app_pages.dart';
import '../../home/controllers/home_controller.dart';
import '../controllers/main_navigation_controller.dart';

class BarcodeView extends StatefulWidget {
  final bool isCashierMode;
  const BarcodeView({super.key, this.isCashierMode = false});

  @override
  State<BarcodeView> createState() => _BarcodeViewState();
}

class _BarcodeViewState extends State<BarcodeView> {
  final ApiService _apiService = Get.find<ApiService>();
  final MainNavigationController _navController =
      Get.find<MainNavigationController>();

  bool get _isCashier =>
      widget.isCashierMode || _navController.isCashierScan.value;

  bool get _isActiveTab =>
      widget.isCashierMode ||
      (!_navController.isHomeActive.value &&
          _navController.currentIndex.value == 1);

  MobileScannerController? _scannerController;
  Worker? _scanTriggerWorker;
  Worker? _activeTabWorker;
  bool _isScanning = false;
  bool _isHandlingResult = false;
  String? _lastScannedCode;

  @override
  void initState() {
    super.initState();
    _scanTriggerWorker = ever(_navController.autoScanTrigger, (_) {
      if (mounted && _isActiveTab && !_isScanning) {
        _startScanner();
      }
    });

    _activeTabWorker = everAll(
      [_navController.currentIndex, _navController.isHomeActive],
      (_) {
        if (!mounted) return;
        if (!_isActiveTab && _isScanning) {
          _stopScanner();
        } else if (_isActiveTab && !_isScanning && !_isHandlingResult) {
          _startScanner();
        }
      },
    );

    if (_isActiveTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isScanning) {
          _startScanner();
        }
      });
    }
  }

  @override
  void dispose() {
    _scanTriggerWorker?.dispose();
    _activeTabWorker?.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  void _startScanner() {
    _scannerController?.dispose();
    _scannerController = MobileScannerController(
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
    setState(() {
      _isScanning = true;
      _isHandlingResult = false;
    });
  }

  void _stopScanner() {
    _scannerController?.dispose();
    _scannerController = null;
    if (mounted) {
      setState(() {
        _isScanning = false;
      });
    }
  }

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

  void _openManualInputDialog() {
    final codeCtrl = TextEditingController(text: _lastScannedCode ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Input Barcode Manual'),
        content: TextField(
          controller: codeCtrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Kode Barcode / Angka',
            hintText: 'Contoh: 8991234567890',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE5B582),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final code = codeCtrl.text.trim();
              if (code.isEmpty) return;
              Navigator.pop(context);
              _handleBarcodeScanned(code);
            },
            child: const Text('Cari'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBarcodeScanned(String code) async {
    if (!_isActiveTab) return;
    setState(() {
      _isHandlingResult = true;
      _lastScannedCode = code;
    });
    _stopScanner();

    final result = await _apiService.getProductByBarcode(code);
    if (!mounted || !_isActiveTab) return;

    if (result.success && result.data != null) {
      if (_isCashier) {
        _showCashierAddToCartDialog(result.data!, code);
      } else {
        _showProductConfirmationDialog(result.data!, code);
      }
    } else {
      _showProductNotFoundSheet(code, result.message);
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    debugPrint('MobileScanner _onDetect: detected ${capture.barcodes.length} barcodes');
    if (!_isActiveTab || _isHandlingResult) return;

    for (final barcode in capture.barcodes) {
      final code = (barcode.rawValue ?? barcode.displayValue)?.trim();
      debugPrint('MobileScanner detected code: $code, format: ${barcode.format}');
      if (code != null && code.isNotEmpty) {
        // Filter out false positives / noise dari pantulan cahaya & parsial garis (< 6 karakter)
        if (code.length < 6) {
          debugPrint('MobileScanner ignored noise/short code: $code');
          continue;
        }
        _handleBarcodeScanned(code);
        break;
      }
    }
  }

  void _showProductFoundSheet(Map<String, dynamic> product, String code) {
    final id = (product['id'] as num?)?.toInt() ?? 0;
    final stock = (product['stock'] as num?)?.toInt() ?? 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCE6DF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Produk Ditemukan',
                    style: TextStyle(
                      color: Color(0xFF2E5A3E),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  code,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              product['name']?.toString() ?? '-',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2B2118),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Kategori: ${product['category'] ?? 'Umum'} • Stok: $stock',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              _formatRupiah(product['sell_price']),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD49A5B),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditProductDialog(product);
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit Produk'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showAddStockDialog(product);
                    },
                    icon: const Icon(Icons.add_box_outlined, size: 18),
                    label: const Text('Tambah Stok'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD49A5B),
                      side: const BorderSide(color: Color(0xFFD49A5B)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: stock > 0
                        ? () {
                            Navigator.pop(context);
                            _showProductConfirmationDialog(product, code);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE5B582),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Keranjang'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showProductConfirmationDialog(Map<String, dynamic> product, String code) {
    final stock = (product['stock'] as num?)?.toInt() ?? 0;
    final price = double.tryParse(product['sell_price']?.toString() ?? '0') ?? 0;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Color(0xFF2E5A3E)),
            SizedBox(width: 8),
            Text('Konfirmasi Produk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product['name']?.toString() ?? '-',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2B2118),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Barcode: $code',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
            ),
            Text(
              'Kategori: ${product['category'] ?? 'Umum'}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
            ),
            Text(
              'Stok tersedia: $stock',
              style: TextStyle(
                color: stock > 0 ? const Color(0xFF2E5A3E) : Colors.red.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Harga Satuan:', style: TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  _formatRupiah(price),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD49A5B),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: const Text(
              'Kembali',
              style: TextStyle(
                color: Color(0xFF8C7E74),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE5B582),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text(
              'Ulang',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              Get.back();
              _startScanner();
            },
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _showCashierAddToCartDialog(Map<String, dynamic> product, String code) {
    final id = (product['id'] as num?)?.toInt() ?? 0;
    final stock = (product['stock'] as num?)?.toInt() ?? 0;
    final price = double.tryParse(product['sell_price']?.toString() ?? '0') ?? 0;

    final homeController = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController());

    // Pastikan produk masuk di list homeController jika belum ada
    final existingIndex = homeController.products.indexWhere(
      (p) => (p['id'] as num?)?.toInt() == id,
    );
    if (existingIndex == -1) {
      homeController.products.add(product);
    }

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Color(0xFF2E5A3E)),
            SizedBox(width: 8),
            Text(
              'Konfirmasi Produk',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product['name']?.toString() ?? '-',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2B2118),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Barcode: $code',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
            ),
            Text(
              'Kategori: ${product['category'] ?? 'Umum'}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
            ),
            Text(
              'Stok tersedia: $stock',
              style: TextStyle(
                color: stock > 0 ? const Color(0xFF2E5A3E) : Colors.red.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Harga Satuan:', style: TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  _formatRupiah(price),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD49A5B),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              _startScanner();
            },
            child: const Text(
              'Batal',
              style: TextStyle(
                color: Color(0xFF8C7E74),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE5B582),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add_shopping_cart, size: 18),
            label: const Text(
              'Masukkan ke Keranjang',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: stock > 0
                ? () {
                    final currentQty = homeController.cart[id] ?? 0;
                    if (currentQty == 0) {
                      homeController.addToCart(id, stock, quantity: 1);
                    }
                    Get.back(); // Tutup dialog konfirmasi
                    _navController.isCashierScan.value = false;
                    if (widget.isCashierMode) {
                      Get.back(); // Kembali ke halaman Hitung Barang
                    } else {
                      Get.toNamed(Routes.HITUNG_BARANG);
                    }
                    Get.snackbar(
                      'Masuk Keranjang',
                      '${product['name']} berhasil dimasukkan ke keranjang.',
                      snackPosition: SnackPosition.BOTTOM,
                      duration: const Duration(seconds: 2),
                    );
                  }
                : null,
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _showAddStockDialog(Map<String, dynamic> product) {
    final qtyCtrl = TextEditingController(text: '10');
    final id = (product['id'] as num?)?.toInt() ?? 0;
    final currentStock = (product['stock'] as num?)?.toInt() ?? 0;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Tambah Stok: ${product['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stok saat ini: $currentStock',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qtyCtrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah Tambahan Stok',
                hintText: 'Contoh: 10',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD49A5B),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
              if (qty <= 0) {
                Get.snackbar('Warning', 'Jumlah tambahan stok harus lebih dari 0.');
                return;
              }
              Get.back();
              final result = await _apiService.addProductStock(
                id: id,
                additionalStock: qty,
              );
              if (result.success) {
                if (Get.isRegistered<HomeController>()) {
                  Get.find<HomeController>().fetchProducts();
                }
                Get.snackbar(
                  'Berhasil',
                  result.message,
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green.withOpacity(0.9),
                  colorText: Colors.white,
                );
              } else {
                Get.snackbar(
                  'Gagal',
                  result.message,
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.redAccent.withOpacity(0.9),
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showEditProductDialog(Map<String, dynamic> product) {
    final id = (product['id'] as num?)?.toInt() ?? 0;
    final nameCtrl = TextEditingController(text: product['name']?.toString() ?? '');
    final barcodeCtrl = TextEditingController(text: product['barcode']?.toString() ?? '');
    final buyCtrl = TextEditingController(text: product['buy_price']?.toString() ?? '0');
    final sellCtrl = TextEditingController(text: product['sell_price']?.toString() ?? '0');
    final stockCtrl = TextEditingController(text: product['stock']?.toString() ?? '0');
    final homeController = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController());

    String currentCat = product['category']?.toString().trim() ?? 'Lainnya';
    if (currentCat.isEmpty) currentCat = 'Lainnya';
    if (!homeController.categories.contains(currentCat)) {
      homeController.categories.add(currentCat);
    }
    String selectedCat = currentCat;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Edit Produk'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nama Produk'),
                  ),
                  const SizedBox(height: 10),
                  const Text('Kategori:', style: TextStyle(fontSize: 12, color: Color(0xFF8C7E74), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: homeController.categories.contains(selectedCat) ? selectedCat : homeController.categories.first,
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: homeController.categories.map((c) {
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
                    decoration: const InputDecoration(labelText: 'Barcode'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: buyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Harga Beli'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: sellCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Harga Jual'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: stockCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Stok'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD49A5B),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final sell = num.tryParse(sellCtrl.text.trim()) ?? 0;
                  if (name.isEmpty || sell <= 0) {
                    Get.snackbar('Warning', 'Nama dan harga jual wajib diisi.');
                    return;
                  }
                  Get.back();
                  final result = await _apiService.updateProduct(
                    id: id,
                    name: name,
                    barcode: barcodeCtrl.text.trim().isEmpty ? null : barcodeCtrl.text.trim(),
                    category: selectedCat,
                    buyPrice: num.tryParse(buyCtrl.text.trim()) ?? 0,
                    sellPrice: sell,
                    stock: int.tryParse(stockCtrl.text.trim()) ?? 0,
                  );
                  if (result.success) {
                    homeController.fetchProducts();
                    Get.snackbar(
                      'Berhasil',
                      result.message,
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.green.withOpacity(0.9),
                      colorText: Colors.white,
                    );
                  } else {
                    Get.snackbar(
                      'Gagal',
                      result.message,
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.redAccent.withOpacity(0.9),
                      colorText: Colors.white,
                    );
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showProductNotFoundSheet(String code, String message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Produk Belum Terdaftar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2B2118),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Barcode: $code',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFFD49A5B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _startScanner();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Scan Lagi'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showAddProductWithBarcodeDialog(code);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE5B582),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Tambah Produk'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProductWithBarcodeDialog(String barcode) {
    final nameCtrl = TextEditingController();
    final buyCtrl = TextEditingController(text: '0');
    final sellCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '10');
    final homeController = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController());

    String selectedCat = homeController.categories.isNotEmpty
        ? homeController.categories.first
        : 'Sembako & Bahan Pokok';

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Tambah Produk Baru'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Barcode: $barcode',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFD49A5B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nama Produk'),
                  ),
                  const SizedBox(height: 10),
                  const Text('Kategori:', style: TextStyle(fontSize: 12, color: Color(0xFF8C7E74), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: homeController.categories.contains(selectedCat) ? selectedCat : homeController.categories.first,
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: homeController.categories.map((c) {
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
                    controller: buyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Harga Beli'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: sellCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Harga Jual'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: stockCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Stok'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
              Obx(
                () => ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD49A5B),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: homeController.isSubmitting.value
                      ? null
                      : () {
                          final name = nameCtrl.text.trim();
                          final sell = num.tryParse(sellCtrl.text.trim()) ?? 0;
                          if (name.isEmpty || sell <= 0) {
                            Get.snackbar('Warning', 'Nama dan harga jual wajib diisi.');
                            return;
                          }
                          homeController.addProduct(
                            name: name,
                            barcode: barcode,
                            category: selectedCat,
                            buyPrice: num.tryParse(buyCtrl.text.trim()) ?? 0,
                            sellPrice: sell,
                            stock: int.tryParse(stockCtrl.text.trim()) ?? 0,
                          );
                        },
                  child: const Text('Simpan'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navController = Get.find<MainNavigationController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E1E1E)),
          onPressed: () {
            _stopScanner();
            if (widget.isCashierMode) {
              Get.back();
            } else if (navController.isCashierScan.value) {
              navController.isCashierScan.value = false;
              Get.toNamed(Routes.HITUNG_BARANG);
            } else {
              navController.showHome();
            }
          },
        ),
        title: Text(
          _isCashier ? 'Scan Kasir' : 'Scan Barcode',
          style: const TextStyle(
            color: Color(0xFF1E1E1E),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        actions: [
          if (_isScanning && _scannerController != null) ...[
            IconButton(
              icon: const Icon(Icons.flash_on, color: Color(0xFF1E1E1E)),
              onPressed: () => _scannerController?.toggleTorch(),
            ),
            IconButton(
              icon: const Icon(Icons.cameraswitch, color: Color(0xFF1E1E1E)),
              onPressed: () => _scannerController?.switchCamera(),
            ),
          ],
          if (_isCashier)
            Obx(() {
              final homeCtrl = Get.isRegistered<HomeController>()
                  ? Get.find<HomeController>()
                  : Get.put(HomeController());
              return TextButton.icon(
                onPressed: () {
                  _stopScanner();
                  if (widget.isCashierMode) {
                    Get.back();
                  } else {
                    navController.isCashierScan.value = false;
                    Get.toNamed(Routes.HITUNG_BARANG);
                  }
                },
                icon: const Icon(Icons.shopping_cart, size: 18, color: Color(0xFFD49A5B)),
                label: Text(
                  '${homeCtrl.cart.length}',
                  style: const TextStyle(
                    color: Color(0xFFD49A5B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isCashier)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF7F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5B582).withOpacity(0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.point_of_sale, size: 16, color: Color(0xFFD49A5B)),
                      SizedBox(width: 8),
                      Text(
                        'Mode Kasir: Hasil scan masuk ke keranjang',
                        style: TextStyle(
                          color: Color(0xFF8C531B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                width: 300,
                height: 300,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFE5B582),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _isScanning && _scannerController != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          MobileScanner(
                            controller: _scannerController!,
                            fit: BoxFit.cover,
                            onDetect: _onDetect,
                            errorBuilder: (context, error) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 36),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Error Kamera: ${error.errorCode.name}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 12, color: Colors.redAccent),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          Center(
                            child: Container(
                              width: 220,
                              height: 140,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFFE5B582),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code_scanner,
                              size: 96,
                              color: Colors.brown.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _lastScannedCode != null
                                  ? 'Terakhir: $_lastScannedCode'
                                  : 'Arahkan kamera ke Barcode',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF8E8E93),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 36),
              ElevatedButton.icon(
                onPressed: _isScanning ? _stopScanner : _startScanner,
                icon: Icon(
                  _isScanning ? Icons.stop_circle_outlined : Icons.camera_alt_outlined,
                ),
                label: Text(
                  _isScanning ? 'Tutup Kamera' : 'Buka Kamera Pemindai',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isScanning
                      ? Colors.redAccent
                      : const Color(0xFFE5B582),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _openManualInputDialog,
                icon: const Icon(Icons.keyboard_alt_outlined, color: Color(0xFF8C7E74)),
                label: const Text(
                  'Input Barcode Manual',
                  style: TextStyle(color: Color(0xFF2B2118)),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
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
