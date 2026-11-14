import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiResult<T> {
  final bool success;
  final String message;
  final T? data;

  ApiResult({
    required this.success,
    required this.message,
    this.data,
  });
}

class ApiService extends GetConnect {
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get defaultBaseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://192.168.18.177:5000';
    }
    return 'http://127.0.0.1:5000';
  }

  final RxnString token = RxnString();
  final Rxn<Map<String, dynamic>> currentUser = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    httpClient.baseUrl = defaultBaseUrl;
    httpClient.timeout = const Duration(seconds: 15);
    httpClient.addRequestModifier<dynamic>((request) {
      request.headers['Accept'] = 'application/json';
      final currentToken = token.value;
      if (currentToken != null && currentToken.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $currentToken';
      }
      return request;
    });
    _restoreToken();
    super.onInit();
  }

  Future<void> _restoreToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('jwt_token');
      if (savedToken != null && savedToken.isNotEmpty) {
        token.value = savedToken;
      }
    } catch (_) {}
  }

  Future<void> _saveToken(String? val) async {
    token.value = val;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (val != null && val.isNotEmpty) {
        await prefs.setString('jwt_token', val);
      } else {
        await prefs.remove('jwt_token');
      }
    } catch (_) {}
  }

  Map<String, dynamic>? _asMap(dynamic body) {
    if (body is Map<String, dynamic>) return body;
    if (body is Map) return Map<String, dynamic>.from(body);
    return null;
  }

  String _extractError(Response response, String fallback) {
    if (response.statusCode == null) {
      return 'Tidak dapat terhubung ke server (${httpClient.baseUrl}). Pastikan backend Flask berjalan.';
    }
    final map = _asMap(response.body);
    if (map != null) {
      final msg = map['message'] ?? map['msg'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    return '$fallback (HTTP ${response.statusCode})';
  }

  // ==========================================================
  // 1. AUTHENTICATION
  // ==========================================================

  Future<ApiResult<void>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await post('/api/register', {
      'name': name,
      'email': email,
      'password': password,
    });

    final map = _asMap(response.body);
    if (response.isOk && map?['success'] == true) {
      return ApiResult(
        success: true,
        message: (map?['message'] as String?) ?? 'Registrasi berhasil!',
      );
    }
    return ApiResult(
      success: false,
      message: _extractError(response, 'Registrasi gagal'),
    );
  }

  Future<ApiResult<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    final response = await post('/api/login', {
      'email': email,
      'password': password,
    });

    final map = _asMap(response.body);
    if (response.isOk && map?['success'] == true) {
      final receivedToken = map?['token'] as String?;
      final userMap = _asMap(map?['user']);
      await _saveToken(receivedToken);
      currentUser.value = userMap;
      return ApiResult(
        success: true,
        message: (map?['message'] as String?) ?? 'Login berhasil!',
        data: userMap,
      );
    }
    return ApiResult(
      success: false,
      message: _extractError(response, 'Login gagal'),
    );
  }

  void logout() {
    _saveToken(null);
    currentUser.value = null;
  }

  Future<ApiResult<Map<String, dynamic>>> getProfile() async {
    final response = await get('/api/profile');
    final map = _asMap(response.body);
    if (response.isOk && map?['success'] == true) {
      final userMap = _asMap(map?['user']);
      if (userMap != null) {
        currentUser.value = userMap;
      }
      return ApiResult(
        success: true,
        message: 'Profil berhasil dimuat',
        data: userMap,
      );
    }
    return ApiResult(
      success: false,
      message: _extractError(response, 'Gagal memuat profil'),
    );
  }

  // ==========================================================
  // 2. PRODUK / BARANG (CRUD)
  // ==========================================================

  Future<ApiResult<List<Map<String, dynamic>>>> getProducts({
    String search = '',
  }) async {
    final query = search.isNotEmpty ? {'search': search} : null;
    final response = await get('/api/products', query: query);
    final map = _asMap(response.body);
    if (response.isOk && map?['success'] == true) {
      final rawList = map?['data'] as List? ?? [];
      final products = rawList
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      return ApiResult(
        success: true,
        message: 'Produk berhasil dimuat',
        data: products,
      );
    }
    return ApiResult(
      success: false,
      message: _extractError(response, 'Gagal memuat produk'),
    );
  }

  Future<ApiResult<Map<String, dynamic>>> getProductByBarcode(
    String barcode,
  ) async {
    final encoded = Uri.encodeComponent(barcode);
    final response = await get('/api/products/barcode/$encoded');
    final map = _asMap(response.body);
    if (response.isOk && map?['success'] == true) {
      return ApiResult(
        success: true,
        message: 'Produk ditemukan',
        data: _asMap(map?['data']),
      );
    }
    return ApiResult(
      success: false,
      message: _extractError(response, 'Produk tidak ditemukan'),
    );
  }

  Future<ApiResult<int>> addProduct({
    required String name,
    String? barcode,
    String category = 'Umum',
    num buyPrice = 0,
    required num sellPrice,
    int stock = 0,
  }) async {
    final response = await post('/api/products', {
      'name': name,
      if (barcode != null && barcode.isNotEmpty) 'barcode': barcode,
      'category': category,
      'buy_price': buyPrice,
      'sell_price': sellPrice,
      'stock': stock,
    });
    final map = _asMap(response.body);
    if (response.isOk && map?['success'] == true) {
      return ApiResult(
        success: true,
        message: (map?['message'] as String?) ?? 'Produk berhasil ditambahkan!',
        data: (map?['product_id'] as num?)?.toInt(),
      );
    }
    return ApiResult(
      success: false,
      message: _extractError(response, 'Gagal menambah produk'),
    );
  }

  Future<ApiResult<int>> addProductStock({
    required int id,
    required int additionalStock,
  }) async {
    final response = await post('/api/products/$id/add-stock', {
      'additional_stock': additionalStock,
    });
    final map = _asMap(response.body);
    if (response.isOk && map?['success'] == true) {
      return ApiResult(
        success: true,
        message: (map?['message'] as String?) ?? 'Stok berhasil ditambah!',
        data: (map?['new_stock'] as num?)?.toInt(),
      );
    }
    return ApiResult(
      success: false,
      message: _extractError(response, 'Gagal menambah stok'),
    );
  }

  Future<ApiResult<void>> updateProduct({
    required int id,
    required String name,
    String? barcode,
    required String category,
    required num buyPrice,
    required num sellPrice,
    required int stock,
  }) async {
    final response = await put('/api/products/$id', {
      'name': name,
      if (barcode != null && barcode.isNotEmpty) 'barcode': barcode,
      'category': category,
      'buy_price': buyPrice,
      'sell_price': sellPrice,
      'stock': stock,
    });
    final map = _asMap(response.body);
    if (response.isOk && map?['success'] == true) {
      return ApiResult(
        success: true,
        message: (map?['message'] as String?) ?? 'Produk berhasil diperbarui!',
      );
    }
    return ApiResult(
      success: false,
      message: _extractError(response, 'Gagal memperbarui produk'),
    );
  }

  Future<ApiResult<void>> deleteProduct(int id) async {
    final response = await delete('/api/products/$id');
    final map = _asMap(response.body);
    if (response.isOk && map?['success'] == true) {
      return ApiResult(
        success: true,
        message: (map?['message'] as String?) ?? 'Produk berhasil dihapus!',
      );
    }
    return ApiResult(
      success: false,
      message: _extractError(response, 'Gagal menghapus produk'),
    );
  }

  // ==========================================================
  // 3. TRANSAKSI KASIR (CHECKOUT & RIWAYAT)
  // ==========================================================

  Future<ApiResult<Map<String, dynamic>>> createTransaction({
    required List<Map<String, dynamic>> items,
    required double payAmount,
  }) async {
    final response = await post('/api/transactions', {
      'items': items,
      'pay_amount': payAmount,
    });
    final map = _asMap(response.body);
    if (response.isOk && map?['success'] == true) {
      return ApiResult(
        success: true,
        message: (map?['message'] as String?) ?? 'Transaksi berhasil disimpan!',
        data: _asMap(map?['data']),
      );
    }
    return ApiResult(
      success: false,
      message: _extractError(response, 'Gagal menyimpan transaksi'),
    );
  }

  Future<ApiResult<List<Map<String, dynamic>>>> getTransactions() async {
    final response = await get('/api/transactions');
    final map = _asMap(response.body);
    if (response.isOk && map?['success'] == true) {
      final rawList = map?['data'] as List? ?? [];
      final transactions = rawList
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      return ApiResult(
        success: true,
        message: 'Riwayat transaksi berhasil dimuat',
        data: transactions,
      );
    }
    return ApiResult(
      success: false,
      message: _extractError(response, 'Gagal memuat riwayat transaksi'),
    );
  }

  Future<ApiResult<Map<String, dynamic>>> getTransactionDetail(int id) async {
    final response = await get('/api/transactions/$id');
    final map = _asMap(response.body);
    if (response.isOk && map?['success'] == true) {
      return ApiResult(
        success: true,
        message: 'Detail transaksi berhasil dimuat',
        data: _asMap(map?['data']),
      );
    }
    return ApiResult(
      success: false,
      message: _extractError(response, 'Gagal memuat detail transaksi'),
    );
  }
}

