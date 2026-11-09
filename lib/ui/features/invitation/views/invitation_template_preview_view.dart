import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/data/datasources/remote/api_endpoint.dart';

/// Screen In-App Live Interactive Preview untuk Desain Template Undangan Digital.
///
/// Memungkinkan vendor maupun calon pengantin melihat dan berinteraksi langsung
/// dengan animasi, countdown, musik, galeri, rsvp, dan layout template
/// tanpa keluar dari aplikasi Dekorin.
class InvitationTemplatePreviewView extends StatefulWidget {
  const InvitationTemplatePreviewView({
    super.key,
    required this.templateId,
    required this.templateName,
    this.slug,
  });

  final String templateId;
  final String templateName;
  final String? slug;

  @override
  State<InvitationTemplatePreviewView> createState() =>
      _InvitationTemplatePreviewViewState();
}

class _InvitationTemplatePreviewViewState
    extends State<InvitationTemplatePreviewView> {
  late final WebViewController _webViewController;
  int _loadingProgress = 0;
  bool _hasError = false;
  String _errorMessage = '';

  String get _previewUrl => ApiEndpoint.getInvitationTemplatePreviewUrl(
        widget.templateId,
        widget.slug,
      );

  @override
  void initState() {
    super.initState();
    _initWebViewController();
  }

  void _initWebViewController() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress;
              });
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _hasError = false;
                _loadingProgress = 15;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _loadingProgress = 100;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            // Abaikan error pada sub-resources non-kritis (mis. favicon atau analytics)
            if (error.isForMainFrame == true) {
              if (mounted) {
                setState(() {
                  _hasError = true;
                  _errorMessage = error.description;
                });
              }
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(_previewUrl));
  }

  void _reloadPreview() {
    setState(() {
      _hasError = false;
      _loadingProgress = 10;
    });
    _webViewController.loadRequest(Uri.parse(_previewUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textDark),
          tooltip: 'Kembali',
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.templateName,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            Text(
              'Live In-App Preview Template',
              style: AppTypography.caption.copyWith(
                color: AppColors.secondaryGold,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryGold, size: 22),
            tooltip: 'Muat Ulang',
            onPressed: _reloadPreview,
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: _loadingProgress < 100 && !_hasError
              ? LinearProgressIndicator(
                  value: _loadingProgress / 100.0,
                  backgroundColor: AppColors.goldLight,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
                  minHeight: 3,
                )
              : const SizedBox(height: 3),
        ),
      ),
      body: Stack(
        children: [
          // Native WebView
          if (!_hasError)
            WebViewWidget(controller: _webViewController),

          // Loading Overlay saat progress awal
          if (_loadingProgress < 60 && !_hasError)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: AppColors.goldLight,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Menyiapkan Preview Template...',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Memuat tampilan interaktif & animasi desain',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Error State jika koneksi gagal atau timeout
          if (_hasError)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.goldLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.wifi_off_outlined,
                        size: 32,
                        color: AppColors.primaryGold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal Memuat Preview',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _errorMessage.isNotEmpty
                          ? 'Terjadi kendala saat memuat preview template ($_errorMessage). Pastikan koneksi internet stabil.'
                          : 'Tidak dapat terhubung ke server preview. Silakan coba lagi.',
                      textAlign: TextAlign.center,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textLight,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onPressed: _reloadPreview,
                      icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                      label: Text(
                        'Coba Lagi',
                        style: AppTypography.button.copyWith(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
