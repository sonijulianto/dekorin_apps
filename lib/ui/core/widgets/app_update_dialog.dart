import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/data/models/app_version_info.dart';
import 'package:dekorin_apps/data/services/app_update_service.dart';

/// Dialog konfirmasi & proses In-App Update Dekorin
class AppUpdateDialog extends StatefulWidget {
  final AppVersionInfo info;
  final String currentVersion;
  final int currentBuildNumber;

  const AppUpdateDialog({
    super.key,
    required this.info,
    required this.currentVersion,
    required this.currentBuildNumber,
  });

  @override
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog> {
  StreamSubscription<OtaEvent>? _otaSubscription;
  double? _downloadProgress;
  String _statusText = '';
  bool _isDownloading = false;
  String? _errorMessage;

  bool get _isForce => widget.info.isForceRequired(widget.currentBuildNumber);

  @override
  void dispose() {
    _otaSubscription?.cancel();
    super.dispose();
  }

  void _startUpdate() {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
      _errorMessage = null;
      _statusText = 'Menghubungkan ke server...';
    });

    try {
      _otaSubscription = OtaUpdate()
          .execute(widget.info.downloadUrl, destinationFilename: 'dekorin_${widget.info.versionName}.apk')
          .listen(
            (OtaEvent event) {
              if (!mounted) return;
              switch (event.status) {
                case OtaStatus.DOWNLOADING:
                  final progress = double.tryParse(event.value ?? '0') ?? 0;
                  setState(() {
                    _downloadProgress = progress;
                    _statusText = 'Mengunduh pembaruan... ${progress.toInt()}%';
                  });
                  break;
                case OtaStatus.INSTALLING:
                  setState(() {
                    _statusText = 'Membuka installer...';
                    _downloadProgress = 100;
                  });
                  break;
                case OtaStatus.ALREADY_RUNNING_ERROR:
                  setState(() {
                    _isDownloading = false;
                    _errorMessage = 'Proses unduhan sudah sedang berjalan.';
                  });
                  break;
                case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
                  setState(() {
                    _isDownloading = false;
                    _errorMessage = 'Izin pemasangan aplikasi dari sumber ini tidak diberikan.';
                  });
                  break;
                case OtaStatus.DOWNLOAD_ERROR:
                case OtaStatus.INTERNAL_ERROR:
                case OtaStatus.CHECKSUM_ERROR:
                  setState(() {
                    _isDownloading = false;
                    _errorMessage = 'Gagal mengunduh APK (${event.status.name}). Silakan unduh langsung via browser.';
                  });
                  break;
                case OtaStatus.CANCELED:
                  setState(() {
                    _isDownloading = false;
                    _statusText = 'Unduhan dibatalkan.';
                  });
                  break;
                case OtaStatus.INSTALLATION_DONE:
                  break;
                default:
                  break;
              }
            },
            onError: (e) {
              if (!mounted) return;
              setState(() {
                _isDownloading = false;
                _errorMessage = 'Terjadi kendala saat update: $e. Anda dapat mengunduh langsung via browser.';
              });
            },
          );
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _errorMessage = 'Gagal memulai unduhan: $e';
      });
    }
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.tryParse(widget.info.downloadUrl);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isForce && !_isDownloading,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Icon & Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.goldLight, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.system_update_rounded, color: AppColors.primaryGold, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pembaruan Tersedia',
                          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'v${widget.currentVersion} ➔ v${widget.info.versionName}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.secondaryGold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description & Changelog
              Text(
                'Versi terbaru Dekorin telah tersedia. Segera perbarui untuk menikmati fitur dan perbaikan terbaru.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textDark, height: 1.4),
              ),
              const SizedBox(height: 12),

              if (widget.info.releaseNotes.isNotEmpty) ...[
                Text('Catatan Rilis:', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Container(
                  constraints: const BoxConstraints(maxHeight: 140),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      widget.info.releaseNotes,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textDark.withValues(alpha: 0.85),
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Download Progress / Error Message
              if (_isDownloading) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (_downloadProgress ?? 0) / 100,
                    minHeight: 8,
                    backgroundColor: AppColors.goldLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _statusText,
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
              ],

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_errorMessage!, style: AppTypography.caption.copyWith(color: AppColors.errorRed)),
                ),
                const SizedBox(height: 12),
              ],

              // Actions
              if (_isDownloading) ...[
                // Saat downloading, tidak menampilkan tombol aksi kecuali cancel (jika bukan force)
                if (!_isForce)
                  TextButton(
                    onPressed: () {
                      _otaSubscription?.cancel();
                      setState(() {
                        _isDownloading = false;
                      });
                    },
                    child: Text('Batal', style: AppTypography.bodySmall.copyWith(color: AppColors.textLight)),
                  ),
              ] else ...[
                Row(
                  children: [
                    if (!_isForce) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.borderLight),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Nanti',
                            style: AppTypography.button.copyWith(color: AppColors.textLight, fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _startUpdate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGold,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          _errorMessage != null ? 'Coba Lagi' : 'Perbarui Sekarang',
                          style: AppTypography.button.copyWith(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _openInBrowser,
                    icon: const Icon(Icons.open_in_browser, size: 18, color: AppColors.secondaryGold),
                    label: Text(
                      'Unduh Langsung Lewat Browser',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.secondaryGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper untuk memeriksa pembaruan aplikasi secara mudah dari screen manapun
class AppUpdateChecker {
  static bool _isChecking = false;

  /// Memeriksa apakah ada update baru
  /// [showToastIfLatest]: jika true, menampilkan feedback jika sudah versi terbaru (cocok untuk tombol manual di Profile)
  static Future<void> check(BuildContext context, {bool showToastIfLatest = false}) async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      final currentBuild = await AppUpdateService.getCurrentBuildNumber();
      final currentVersion = await AppUpdateService.getCurrentVersionName();
      final latest = await AppUpdateService.getLatestVersion();

      if (!context.mounted) {
        _isChecking = false;
        return;
      }

      if (latest != null && latest.isUpdateAvailable(currentBuild)) {
        // Tampilkan dialog update
        final isForce = latest.isForceRequired(currentBuild);
        showDialog(
          context: context,
          barrierDismissible: !isForce,
          builder: (dialogCtx) =>
              AppUpdateDialog(info: latest, currentVersion: currentVersion, currentBuildNumber: currentBuild),
        );
      } else if (showToastIfLatest) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryDark,
            content: Text(
              'Aplikasi Dekorin sudah menggunakan versi terbaru (v$currentVersion).',
              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
            ),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      debugPrint('AppUpdateChecker error: $e');
      if (showToastIfLatest && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.errorRed,
            content: Text(
              'Gagal memeriksa pembaruan. Silakan periksa koneksi internet Anda.',
              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      _isChecking = false;
    }
  }
}
