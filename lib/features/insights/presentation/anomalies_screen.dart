import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/features/insights/providers/anomaly_provider.dart';
import 'package:hisabi/features/receipts/presentation/widgets/receipt_details_modal.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';
import 'package:intl/intl.dart';

class AnomaliesScreen extends ConsumerWidget {
  const AnomaliesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anomaliesAsync = ref.watch(anomalyProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final currency = settingsAsync.valueOrNull?.currency ?? Currency.USD;
    final formatter = NumberFormat.currency(symbol: currency.name, decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anomaly Detection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('About Anomaly Detection'),
                  content: const Text(
                    'Anomalies are detected based on:\n'
                    '• Unusually high or low amounts\n'
                    '• Unusual categories or stores\n'
                    '• Unusual transaction times\n\n'
                    'This helps identify potential errors or unexpected spending patterns.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: anomaliesAsync.when(
        data: (anomalies) {
          if (anomalies.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No anomalies detected',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your spending patterns look normal',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: anomalies.length,
            itemBuilder: (context, index) {
              final anomaly = anomalies[index];
              final receipt = anomaly.receipt;

              Color getAnomalyColor() {
                switch (anomaly.type) {
                  case AnomalyType.unusuallyHigh:
                    return Colors.red;
                  case AnomalyType.unusuallyLow:
                    return Colors.blue;
                  case AnomalyType.unusualCategory:
                    return Colors.orange;
                  case AnomalyType.unusualStore:
                    return Colors.purple;
                  case AnomalyType.unusualTime:
                    return Colors.teal;
                }
              }

              IconData getAnomalyIcon() {
                switch (anomaly.type) {
                  case AnomalyType.unusuallyHigh:
                    return Icons.trending_up;
                  case AnomalyType.unusuallyLow:
                    return Icons.trending_down;
                  case AnomalyType.unusualCategory:
                    return Icons.category;
                  case AnomalyType.unusualStore:
                    return Icons.store;
                  case AnomalyType.unusualTime:
                    return Icons.access_time;
                }
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => ReceiptDetailsModal(receiptId: receipt.id),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: getAnomalyColor().withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                getAnomalyIcon(),
                                color: getAnomalyColor(),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    receipt.store,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    DateFormat.yMMMd().format(receipt.date),
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              formatter.format(receipt.total),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: getAnomalyColor().withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: getAnomalyColor().withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: getAnomalyColor(),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  anomaly.reason,
                                  style: TextStyle(
                                    color: getAnomalyColor(),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

