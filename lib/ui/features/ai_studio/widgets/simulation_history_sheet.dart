import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/data/models/ai_decor_simulation_model.dart';
import 'package:dekorin_apps/data/services/ai_decor_service.dart';

class SimulationHistorySheet extends ConsumerWidget {
  const SimulationHistorySheet({super.key});

  String _formatDate(String isoStr) {
    if (isoStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoStr).toLocal();
      return DateFormat('dd MMM yyyy, HH:mm').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(aiDecorHistoryProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Riwayat Simulasi AI', style: AppTypography.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        'Ketuk item untuk membuka kembali hasil simulasi klien',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
                if (history.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      ref.read(aiDecorHistoryProvider.notifier).clearAll();
                    },
                    child: Text(
                      'Hapus Semua',
                      style: AppTypography.labelMedium.copyWith(color: AppColors.errorRed),
                    ),
                  ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textDark),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.dividerColor),
          Expanded(
            child: history.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.history_rounded, size: 46, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada riwayat simulasi warna.',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: history.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = history[index];
                      return _buildHistoryCard(context, ref, item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    WidgetRef ref,
    AiDecorSimulationModel item,
  ) {
    final summaryParts = <String>[
      if (item.fabricColor.isNotEmpty) 'Kain: ${item.fabricColor}',
      if (item.flowerColor.isNotEmpty) 'Bunga: ${item.flowerColor}',
      if (item.nuance.isNotEmpty) item.nuance,
    ];
    final summaryText = summaryParts.isNotEmpty
        ? summaryParts.join(' • ')
        : (item.notes.isNotEmpty ? item.notes : 'Simulasi Kustomisasi AI');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pop(context, item),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 68,
                  height: 68,
                  child: Image.network(
                    item.resultUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: AppColors.goldLight,
                      child: const Icon(Icons.image_outlined, color: AppColors.primaryGold),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.modelName.isNotEmpty ? item.modelName : 'Dekorasi Kustom',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleSmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      summaryText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(color: AppColors.textDark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(item.createdAt),
                      style: AppTypography.caption.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  ref.read(aiDecorHistoryProvider.notifier).removeSimulation(item.id);
                },
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textLight, size: 20),
                tooltip: 'Hapus',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
