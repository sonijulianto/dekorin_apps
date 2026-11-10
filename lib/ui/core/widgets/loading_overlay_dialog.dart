import 'package:flutter/material.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';

/// Helper untuk menampilkan dialog loading modal yang memblokir interaksi
/// agar pengguna tahu proses sedang berjalan dan tidak mengetuk berulang kali.
class DekorinLoadingDialog {
  DekorinLoadingDialog._();

  /// Menjalankan [task] sambil menampilkan overlay loading dengan [message].
  /// Dialog akan otomatis ditutup saat [task] selesai atau melempar error.
  static Future<T> run<T>(
    BuildContext context, {
    required Future<T> Function() task,
    String message = 'Memuat data...',
  }) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final route = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => PopScope(
        canPop: false,
        child: _LoadingDialogCard(message: message),
      ),
    );

    navigator.push(route);
    try {
      return await task();
    } finally {
      if (route.isActive && navigator.mounted) {
        navigator.removeRoute(route);
      }
    }
  }
}

class _LoadingDialogCard extends StatelessWidget {
  const _LoadingDialogCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(minWidth: 180, maxWidth: 280),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: AppColors.primaryGold,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog konfirmasi yang menjaga dialog tetap terbuka dengan indikator loading
/// selama [onConfirm] berjalan, sehingga mencegah ketukan ganda saat proses API.
class DekorinConfirmActionDialog {
  DekorinConfirmActionDialog._();

  /// Menampilkan dialog konfirmasi dan menjalankan [onConfirm] saat pengguna setuju.
  /// Mengembalikan `true` jika berhasil, `false` jika dibatalkan, atau melempar
  /// ulang exception dari [onConfirm] setelah dialog ditutup.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    Color confirmColor = AppColors.errorRed,
    String cancelLabel = 'Batal',
    required Future<void> Function() onConfirm,
  }) async {
    bool isProcessing = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return PopScope(
              canPop: !isProcessing,
              child: AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                content: Text(message, style: AppTypography.bodyMedium),
                actions: [
                  TextButton(
                    onPressed: isProcessing ? null : () => Navigator.pop(dialogCtx, false),
                    child: Text(
                      cancelLabel,
                      style: AppTypography.labelLarge.copyWith(
                        color: isProcessing ? AppColors.textMuted : AppColors.textLight,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: isProcessing
                        ? null
                        : () async {
                            setDialogState(() => isProcessing = true);
                            try {
                              await onConfirm();
                              if (dialogCtx.mounted) {
                                Navigator.pop(dialogCtx, true);
                              }
                            } catch (e) {
                              if (dialogCtx.mounted) {
                                Navigator.pop(dialogCtx, false);
                              }
                              rethrow;
                            }
                          },
                    child: isProcessing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(confirmLabel, style: AppTypography.button),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    return result == true;
  }
}
