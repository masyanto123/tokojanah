import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/main_navigation_controller.dart';

class HistoryView extends GetView<MainNavigationController> {
  const HistoryView({super.key});

  String _formatRupiah(dynamic value) {
    final num amount = num.tryParse(value?.toString() ?? '0') ?? 0;
    final int intVal = amount.round();
    final str = intVal.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return 'Rp ${buffer.toString()}';
  }

  Future<void> _showTransactionDetail(BuildContext context, int id) async {
    final detail = await controller.fetchTransactionDetail(id);
    if (detail == null || !context.mounted) return;

    final items = (detail['items'] as List?) ?? [];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              detail['invoice_number']?.toString() ?? 'Detail Transaksi',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Kasir: ${detail['cashier_name'] ?? '-'} • ${detail['created_at'] ?? ''}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const Divider(height: 24),
            if (items.isEmpty)
              const Text('Tidak ada item.')
            else
              ...items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item['product_name']} x${item['quantity']}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Text(
                          _formatRupiah(item['subtotal']),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  _formatRupiah(detail['total_amount']),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD49A5B),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Bayar'),
                Text(_formatRupiah(detail['pay_amount'])),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Kembalian'),
                Text(_formatRupiah(detail['change_amount'])),
              ],
            ),
          ],
        ),
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
          onPressed: navController.showHome,
        ),
        title: const Text(
          'Riwayat Penjualan',
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
      body: Obx(() {
        if (navController.isLoadingTransactions.value &&
            navController.transactions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (navController.transactionError.value != null &&
            navController.transactions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    navController.transactionError.value!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: navController.fetchTransactions,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          );
        }

        if (navController.transactions.isEmpty) {
          return RefreshIndicator(
            onRefresh: navController.fetchTransactions,
            child: ListView(
              children: const [
                SizedBox(height: 160),
                Center(
                  child: Text(
                    'Belum ada riwayat transaksi.',
                    style: TextStyle(color: Color(0xFF8E8E93)),
                  ),
                ),
              ],
            ),
          );
        }

        final filtered = navController.filteredTransactions;

        return RefreshIndicator(
          onRefresh: navController.fetchTransactions,
          child: Column(
            children: [
              // 1. Filter Kasir (Horizontal Scroll Chips)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: navController.cashierList.map((cashier) {
                      final isSelected =
                          navController.selectedCashier.value.toLowerCase() ==
                              cashier.toLowerCase();
                      final count = navController.getTransactionCountFor(cashier);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                cashier == 'Semua'
                                    ? Icons.people_outline
                                    : Icons.person_outline,
                                size: 15,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF6E6259),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '$cashier ($count)',
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 12.5,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF2C2C2E),
                                ),
                              ),
                            ],
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFFD49A5B),
                          backgroundColor: const Color(0xFFF8F9FA),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFFD49A5B)
                                : Colors.grey.shade300,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          onSelected: (_) =>
                              navController.selectCashier(cashier),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // 2. Summary Card per Kasir
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFBF8F4), Color(0xFFF3ECE4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8DCCF)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          navController.selectedCashier.value == 'Semua'
                              ? 'Semua Kasir'
                              : 'Kasir: ${navController.selectedCashier.value}',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C2C2E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${navController.selectedCashierTransactionCount} Transaksi Tercatat',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Total Omset',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFF8C7E74)),
                        ),
                        Text(
                          _formatRupiah(navController.selectedCashierTotalSales),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB57E42),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 3. Daftar Transaksi
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_outlined,
                                  size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 10),
                              Text(
                                'Belum ada transaksi untuk kasir ${navController.selectedCashier.value}.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final trx = filtered[index];
                          final trxId = (trx['id'] as num?)?.toInt();
                          final cashierName =
                              trx['cashier_name']?.toString() ?? '-';

                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: trxId == null
                                ? null
                                : () => _showTransactionDetail(context, trxId),
                            child: Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          trx['invoice_number']?.toString() ??
                                              '-',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2C2C2E),
                                            fontSize: 14,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade50,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            'Berhasil',
                                            style: TextStyle(
                                              color: Colors.green.shade700,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 11.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Baris Info Kasir & Tanggal
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF7F1EB),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.person,
                                                  size: 13,
                                                  color: Color(0xFFB57E42)),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Kasir: $cashierName',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 11.5,
                                                  color: Color(0xFF7A5833),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          trx['created_at']?.toString() ?? '',
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const Divider(height: 18),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Total Penjualan',
                                          style: TextStyle(
                                            color: Color(0xFF6B7280),
                                            fontSize: 12.5,
                                          ),
                                        ),
                                        Text(
                                          _formatRupiah(trx['total_amount']),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFD49A5B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
