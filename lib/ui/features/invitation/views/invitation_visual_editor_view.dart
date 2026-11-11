import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/data/datasources/remote/api_client.dart';
import 'package:dekorin_apps/data/datasources/remote/api_endpoint.dart';
import 'package:dekorin_apps/data/services/invitation_service.dart';
import 'package:dekorin_apps/domain/models/invitation.dart';
import 'package:dekorin_apps/domain/models/picked_image_data.dart';
import 'package:dekorin_apps/ui/core/widgets/dekorin_text_field.dart';
import 'package:dekorin_apps/ui/core/widgets/loading_overlay_dialog.dart';
import 'package:dekorin_apps/ui/core/widgets/portrait_crop_dialog.dart';
import 'package:dekorin_apps/ui/features/invitation/views/invitation_form_view.dart';
import 'package:dekorin_apps/ui/features/invitation/views/invitation_template_picker_view.dart';
import 'package:dekorin_apps/ui/features/invitation/views/visual_editor_web_iframe.dart';

/// Visual Click-to-Edit Editor untuk undangan digital.
///
/// Membuka undangan secara langsung di dalam WebView mode editor (`?preview=1&edit=1`).
/// Pengguna cukup mengetuk teks atau foto langsung di pratinjau undangan untuk
/// mengubah isi atau mengganti foto secara real-time sebelum menyimpan perubahan.
class InvitationVisualEditorView extends ConsumerStatefulWidget {
  const InvitationVisualEditorView({
    super.key,
    required this.invitation,
    this.onUpdateOverride,
  });

  final InvitationItem invitation;
  final Future<void> Function(String id, Map<String, dynamic> payload)?
      onUpdateOverride;

  @override
  ConsumerState<InvitationVisualEditorView> createState() =>
      _InvitationVisualEditorViewState();
}

class _InvitationVisualEditorViewState
    extends ConsumerState<InvitationVisualEditorView> {
  static const List<String> _indoDays = [
    'Minggu',
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
  ];
  static const List<String> _indoMonths = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  late Map<String, dynamic> _draft;
  WebViewController? _webViewController;
  final VisualEditorWebIframeController _webIframeController =
      VisualEditorWebIframeController();

  int _loadingProgress = 0;
  bool _hasLoadError = false;
  String _loadErrorMessage = '';
  bool _isBridgeReady = false;
  bool _bridgeCheckFailed = false;
  bool _isEditMode = true;
  bool _isGateVisible = false;
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;
  int _activeModalCount = 0;

  bool get _isModalOverlayActive => _activeModalCount > 0;

  bool get _supportsEmbeddedWebView =>
      !kIsWeb && WebViewPlatform.instance != null;

  String get _currentTemplate =>
      (_draft['template'] as String? ?? InvitationTemplate.ta17).trim();

  String get _currentEventType =>
      (_draft['event_type'] as String? ?? InvitationEventCategory.wedding)
          .trim();

  bool get _isSinglePersonEvent =>
      _currentEventType == InvitationEventCategory.khitan ||
      _currentEventType == InvitationEventCategory.birthday ||
      _currentEventType == 'aqiqah';

  String get _editorUrl => ApiEndpoint.getInvitationVisualEditorUrl(
        widget.invitation.slug,
        templateOverride: _currentTemplate,
      );

  @override
  void initState() {
    super.initState();
    _draft = Map<String, dynamic>.from(widget.invitation.toJson());
    if (_supportsEmbeddedWebView) {
      _initWebView();
    } else if (kIsWeb) {
      _loadingProgress = 50;
    } else {
      _loadingProgress = 100;
    }
  }

  @override
  void dispose() {
    _webIframeController.dispose();
    super.dispose();
  }

  void _setBackgroundInteractionLocked(bool locked) {
    if (kIsWeb) {
      _webIframeController.setInteractionLocked(locked);
      return;
    }
    if (_webViewController != null && _isBridgeReady) {
      _webViewController!.runJavaScript(
        'if (window.dekorinSetScrollLocked) { window.dekorinSetScrollLocked($locked); }',
      );
    }
  }

  Future<T> _withOverlayModal<T>(Future<T> Function() action) async {
    _activeModalCount++;
    if (_activeModalCount == 1) {
      _setBackgroundInteractionLocked(true);
      if (mounted) setState(() {});
    }
    try {
      return await action();
    } finally {
      _activeModalCount = (_activeModalCount - 1).clamp(0, 999);
      if (_activeModalCount == 0) {
        _setBackgroundInteractionLocked(false);
        if (mounted) setState(() {});
      }
    }
  }

  Future<T?> _showEditorModalSheet<T>({
    required WidgetBuilder builder,
    bool isScrollControlled = true,
  }) {
    return _withOverlayModal(
      () => showModalBottomSheet<T>(
        context: context,
        isScrollControlled: isScrollControlled,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: builder,
      ),
    );
  }

  void _onWebIframeLoaded() {
    if (!mounted) return;
    setState(() => _loadingProgress = 100);
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (mounted && !_isBridgeReady) {
        setState(() => _bridgeCheckFailed = true);
      }
    });
  }

  void _initWebView() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.backgroundLight)
      ..addJavaScriptChannel(
        'DekorinEditorChannel',
        onMessageReceived: _handleJsChannelMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _loadingProgress = progress);
          },
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _hasLoadError = false;
                _loadErrorMessage = '';
                _isBridgeReady = false;
                _bridgeCheckFailed = false;
              });
            }
          },
          onPageFinished: (_) => _verifyEditorBridge(),
          onWebResourceError: (error) {
            if (error.isForMainFrame == true && mounted) {
              setState(() {
                _hasLoadError = true;
                _loadErrorMessage = error.description.isNotEmpty
                    ? error.description
                    : 'Gagal memuat editor undangan';
              });
            }
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;
            if (!uri.host.contains('dekorin.my.id') &&
                uri.scheme.startsWith('http')) {
              if (!_isEditMode) {
                launchUrl(uri, mode: LaunchMode.externalApplication);
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    controller.loadRequest(Uri.parse(_editorUrl));
    _webViewController = controller;
  }

  Future<void> _verifyEditorBridge() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted || _webViewController == null) return;

    try {
      final result = await _webViewController!.runJavaScriptReturningResult(
        'Boolean(window.__DEKORIN_VISUAL_EDITOR_READY__)',
      );
      final ready = result == true || result.toString().toLowerCase() == 'true';
      if (!mounted) return;
      setState(() {
        _isBridgeReady = ready;
        _bridgeCheckFailed = !ready;
      });
      if (ready) {
        await _pushPatchToWebView(_draft);
        await _syncWebViewEditMode();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isBridgeReady = false;
          _bridgeCheckFailed = true;
        });
      }
    }
  }

  Future<void> _pushPatchToWebView(Map<String, dynamic> patch) async {
    if (!_isBridgeReady) return;
    if (kIsWeb) {
      _webIframeController.applyPatch(patch);
      return;
    }
    if (_webViewController == null) return;
    final encoded = jsonEncode(patch);
    await _webViewController!.runJavaScript(
      'if (window.dekorinApplyPatch) { window.dekorinApplyPatch($encoded); }',
    );
  }

  Future<void> _syncWebViewEditMode() async {
    if (!_isBridgeReady) return;
    if (kIsWeb) {
      _webIframeController.setEditMode(_isEditMode);
      return;
    }
    if (_webViewController == null) return;
    await _webViewController!.runJavaScript(
      'if (window.dekorinSetEditMode) { window.dekorinSetEditMode($_isEditMode); }',
    );
  }

  Future<void> _toggleGateInWebView() async {
    final next = !_isGateVisible;
    setState(() => _isGateVisible = next);
    if (!_isBridgeReady) return;
    if (kIsWeb) {
      _webIframeController.toggleGate(next);
      return;
    }
    if (_webViewController != null) {
      await _webViewController!.runJavaScript(
        'if (window.dekorinToggleGate) { window.dekorinToggleGate($next); }',
      );
    }
  }

  Future<void> _applyPatch(Map<String, dynamic> patch) async {
    if (patch.isEmpty) return;
    setState(() {
      _draft.addAll(patch);
      _hasUnsavedChanges = true;
    });
    await _pushPatchToWebView(patch);
  }

  void _handleJsChannelMessage(JavaScriptMessage message) {
    if (!mounted) return;
    try {
      final decoded = jsonDecode(message.message);
      if (decoded is Map<String, dynamic>) {
        _handleEditorMessage(decoded);
      }
    } catch (_) {}
  }

  void _handleEditorMessage(Map<String, dynamic> decoded) {
    if (!mounted) return;
    if (decoded['source'] != 'dekorin-visual-editor') return;

    final action = decoded['action'] as String? ?? '';
    switch (action) {
      case 'ready':
        setState(() {
          _loadingProgress = 100;
          _isBridgeReady = true;
          _bridgeCheckFailed = false;
        });
        _pushPatchToWebView(_draft);
        _syncWebViewEditMode();
        break;
      case 'gate_opened':
        setState(() => _isGateVisible = false);
        break;
      case 'edit_text':
        _showSingleFieldBottomSheet(
          field: decoded['field'] as String? ?? '',
          type: decoded['type'] as String? ?? 'text',
          label: decoded['label'] as String? ?? 'Edit Teks',
          fallbackValue: decoded['currentValue'] as String? ?? '',
        );
        break;
      case 'edit_couple_nick':
        _showCoupleNickBottomSheet();
        break;
      case 'edit_bank':
        final idx = (decoded['bankIndex'] as String? ?? '1') == '2' ? 2 : 1;
        _showBankBottomSheet(idx);
        break;
      case 'edit_love_story':
        _showLoveStoryBottomSheet();
        break;
      case 'edit_gallery':
        _showGalleryBottomSheet();
        break;
      case 'edit_photo':
        _showPhotoBottomSheet(
          field: decoded['field'] as String? ?? '',
          label: decoded['label'] as String? ?? 'Ganti Foto',
          aspect: decoded['aspect'] as String? ?? 'free',
        );
        break;
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // BOTTOM SHEETS: TEXT / DATE / TIME / MAPS / COUPLE / BANK / STORY / GALLERY
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _showSingleFieldBottomSheet({
    required String field,
    required String type,
    required String label,
    required String fallbackValue,
  }) async {
    if (field.isEmpty) return;
    final initial = (_draft[field] ?? fallbackValue).toString();
    final ctrl = TextEditingController(text: initial);
    final isMultiline =
        type == 'textarea' || field == 'quotes' || field == 'turut_mengundang';
    final isDate = type == 'date';
    final isTime = type == 'time';
    final isMaps = type == 'maps';
    final isInstagram = type == 'instagram';

    final result = await _showEditorModalSheet<String>(
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSheetHeader(
                    title: label,
                    subtitle: 'Ketuk Terapkan untuk langsung melihat hasil di undangan',
                    leading: isMaps
                        ? Image.asset('assets/icons/google-maps-icon.webp',
                            width: 24, height: 24)
                        : isDate
                            ? SvgPicture.asset('assets/icons/calendar.svg',
                                width: 20,
                                height: 20,
                                colorFilter: const ColorFilter.mode(
                                    AppColors.secondaryGold, BlendMode.srcIn))
                            : SvgPicture.asset('assets/icons/edit.svg',
                                width: 20,
                                height: 20,
                                colorFilter: const ColorFilter.mode(
                                    AppColors.secondaryGold, BlendMode.srcIn)),
                  ),
                  const SizedBox(height: 14),
                  DekorinTextField(
                    controller: ctrl,
                    label: label,
                    maxLines: isMultiline ? 5 : 1,
                    keyboardType: (isMaps || type == 'youtube')
                        ? TextInputType.url
                        : TextInputType.text,
                    hint: isMaps
                        ? 'https://maps.app.goo.gl/...'
                        : isDate
                            ? 'Contoh: Minggu, 25 Oktober 2026'
                            : isTime
                                ? 'Contoh: 08.00 - 10.00 WIB'
                                : isInstagram
                                    ? 'Username tanpa @'
                                    : null,
                  ),
                  if (field == 'turut_mengundang') ...[
                    const SizedBox(height: 8),
                    Text(
                      'Pisahkan setiap nama keluarga / instansi dengan baris baru.',
                      style: AppTypography.caption,
                    ),
                  ],
                  if (field == 'quotes') ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildPresetChip(
                          'QS. Ar-Rum 21',
                          () => ctrl.text =
                              '"Dan di antara tanda-tanda kekuasaan-Nya ialah Dia menciptakan pasangan-pasangan untukmu dari jenismu sendiri agar kamu merasa tenteram kepadanya..." (QS. Ar-Rum: 21)',
                        ),
                        _buildPresetChip(
                          'Matius 19:6',
                          () => ctrl.text =
                              '"Demikianlah mereka bukan lagi dua, melainkan satu. Karena itu, apa yang telah dipersatukan Allah, tidak boleh diceraikan manusia." (Matius 19:6)',
                        ),
                      ],
                    ),
                  ],
                  if (isDate) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          ctrl.text =
                              '${_indoDays[picked.weekday % 7]}, ${picked.day} ${_indoMonths[picked.month - 1]} ${picked.year}';
                          setSheetState(() {});
                        }
                      },
                      icon: SvgPicture.asset(
                        'assets/icons/calendar.svg',
                        width: 18,
                        height: 18,
                        colorFilter: const ColorFilter.mode(
                            AppColors.secondaryGold, BlendMode.srcIn),
                      ),
                      label: Text(
                        'Pilih Tanggal dari Kalender',
                        style: AppTypography.labelMedium
                            .copyWith(color: AppColors.secondaryGold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primaryGold),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                  if (isTime) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final preset in const [
                          '08.00 - 10.00 WIB',
                          '11.00 - 14.00 WIB',
                          '19.00 - Selesai',
                        ])
                          _buildPresetChip(preset, () => ctrl.text = preset),
                      ],
                    ),
                  ],
                  if (isMaps) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Salin tautan lokasi dari Google Maps (Bagikan -> Salin Link) lalu tempel di atas.',
                      style: AppTypography.caption,
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            'Batal',
                            style: AppTypography.labelMedium
                                .copyWith(color: AppColors.textDark),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGold,
                          ),
                          child: Text('Terapkan', style: AppTypography.button),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    ctrl.dispose();
    if (result != null) {
      final patch = <String, dynamic>{field: result};
      if (_isSinglePersonEvent && field == 'child_name') {
        patch['groom_name'] = result;
      } else if (_isSinglePersonEvent && field == 'child_nickname') {
        patch['groom_nickname'] = result;
      } else if (_isSinglePersonEvent && field == 'child_order') {
        patch['groom_child_order'] = result;
      }
      await _applyPatch(patch);
    }
  }

  Future<void> _showCoupleNickBottomSheet() async {
    final groomCtrl = TextEditingController(
      text: (_draft['groom_nickname'] ?? '').toString(),
    );
    final brideCtrl = TextEditingController(
      text: (_draft['bride_nickname'] ?? '').toString(),
    );
    final childCtrl = TextEditingController(
      text: ((_draft['child_nickname'] ?? '').toString().isNotEmpty
              ? _draft['child_nickname']
              : _draft['groom_nickname'] ?? '')
          .toString(),
    );
    final titleCtrl = TextEditingController(
      text: (_draft['title'] ?? '').toString(),
    );

    final applied = await _showEditorModalSheet<bool>(
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSheetHeader(
                title: _isSinglePersonEvent
                    ? 'Nama Panggilan & Judul Acara'
                    : 'Nama Panggilan Pasangan & Judul',
                subtitle: 'Tampil di sampul depan, header, dan penutup undangan',
                leading: SvgPicture.asset(
                  'assets/icons/user.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                      AppColors.secondaryGold, BlendMode.srcIn),
                ),
              ),
              const SizedBox(height: 14),
              if (_isSinglePersonEvent)
                DekorinTextField(
                  controller: childCtrl,
                  label: 'Nama Panggilan Utama',
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: DekorinTextField(
                        controller: groomCtrl,
                        label: 'Panggilan Pria',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DekorinTextField(
                        controller: brideCtrl,
                        label: 'Panggilan Wanita',
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              DekorinTextField(
                controller: titleCtrl,
                label: 'Judul Undangan (Tab Browser & Link WA)',
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold),
                child: Text('Terapkan Perubahan', style: AppTypography.button),
              ),
            ],
          ),
        );
      },
    );

    if (applied == true) {
      if (_isSinglePersonEvent) {
        await _applyPatch({
          'child_nickname': childCtrl.text.trim(),
          'groom_nickname': childCtrl.text.trim(),
          'title': titleCtrl.text.trim(),
        });
      } else {
        await _applyPatch({
          'groom_nickname': groomCtrl.text.trim(),
          'bride_nickname': brideCtrl.text.trim(),
          'title': titleCtrl.text.trim(),
        });
      }
    }

    groomCtrl.dispose();
    brideCtrl.dispose();
    childCtrl.dispose();
    titleCtrl.dispose();
  }

  Future<void> _showBankBottomSheet(int bankIndex) async {
    final nameCtrl = TextEditingController(
      text: (_draft['bank_name_$bankIndex'] ?? '').toString(),
    );
    final accCtrl = TextEditingController(
      text: (_draft['bank_account_$bankIndex'] ?? '').toString(),
    );
    final holderCtrl = TextEditingController(
      text: (_draft['bank_holder_$bankIndex'] ?? '').toString(),
    );
    final giftAddrCtrl = TextEditingController(
      text: (_draft['gift_address'] ?? '').toString(),
    );

    final applied = await _showEditorModalSheet<bool>(
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSheetHeader(
                  title: 'Amplop Digital (Rekening #$bankIndex)',
                  subtitle: 'Pilih bank atau isi nomor e-wallet tujuan',
                  leading: SvgPicture.asset(
                    'assets/icons/wallet-income.svg',
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                        AppColors.secondaryGold, BlendMode.srcIn),
                  ),
                ),
                const SizedBox(height: 12),
                DekorinTextField(
                  controller: nameCtrl,
                  label: 'Nama Bank / E-Wallet',
                  hint: 'BCA, Mandiri, BRI, GoPay, Dana...',
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final b in const [
                      'BCA',
                      'BRI',
                      'BNI',
                      'Mandiri',
                      'BSI',
                      'GoPay',
                      'Dana',
                      'OVO',
                    ])
                      _buildPresetChip(b, () => nameCtrl.text = b),
                  ],
                ),
                const SizedBox(height: 12),
                DekorinTextField(
                  controller: accCtrl,
                  label: 'Nomor Rekening / No. HP E-Wallet',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DekorinTextField(
                  controller: holderCtrl,
                  label: 'Atas Nama Pemilik Rekening',
                ),
                if (bankIndex == 1) ...[
                  const SizedBox(height: 12),
                  DekorinTextField(
                    controller: giftAddrCtrl,
                    label: 'Alamat Kirim Kado Fisik (Opsional)',
                    maxLines: 2,
                    prefixWidget: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SvgPicture.asset(
                        'assets/icons/shipping-fast.svg',
                        width: 18,
                        height: 18,
                        colorFilter: const ColorFilter.mode(
                            AppColors.secondaryGold, BlendMode.srcIn),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold),
                  child: Text('Terapkan Rekening', style: AppTypography.button),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (applied == true) {
      final patch = <String, dynamic>{
        'bank_name_$bankIndex': nameCtrl.text.trim(),
        'bank_account_$bankIndex': accCtrl.text.trim(),
        'bank_holder_$bankIndex': holderCtrl.text.trim(),
      };
      if (bankIndex == 1) {
        patch['gift_address'] = giftAddrCtrl.text.trim();
      }
      await _applyPatch(patch);
    }

    nameCtrl.dispose();
    accCtrl.dispose();
    holderCtrl.dispose();
    giftAddrCtrl.dispose();
  }

  List<LoveStoryItem> _parseLoveStoryList(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return [LoveStoryItem()];
    if (trimmed.startsWith('[')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is List) {
          final parsed = decoded
              .whereType<Map>()
              .map((m) => LoveStoryItem(
                    date: (m['date'] ?? m['tanggal'] ?? '').toString(),
                    title: (m['title'] ?? m['judul'] ?? '').toString(),
                    description:
                        (m['description'] ?? m['desc'] ?? m['body'] ?? '')
                            .toString(),
                  ))
              .toList();
          if (parsed.isNotEmpty) return parsed;
        }
      } catch (_) {}
    }

    final blocks = trimmed
        .split(RegExp(r'\n\s*\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);
    final items = <LoveStoryItem>[];
    for (final blk in blocks) {
      final colonIdx = blk.indexOf(':');
      if (colonIdx > 0 && colonIdx < 32) {
        final left = blk.substring(0, colonIdx).trim();
        final right = blk.substring(colonIdx + 1).trim();
        final dashSplit = left.split(RegExp(r'\s*[-–]\s*'));
        if (dashSplit.length >= 2) {
          items.add(LoveStoryItem(
            date: dashSplit.first.trim(),
            title: dashSplit.sublist(1).join(' - ').trim(),
            description: right,
          ));
          continue;
        }
        items.add(LoveStoryItem(date: left, description: right));
      } else {
        items.add(LoveStoryItem(description: blk));
      }
    }
    return items.isNotEmpty ? items : [LoveStoryItem()];
  }

  Future<void> _showLoveStoryBottomSheet() async {
    final items = _parseLoveStoryList((_draft['love_story'] ?? '').toString());

    final applied = await _showEditorModalSheet<bool>(
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.78,
              maxChildSize: 0.92,
              minChildSize: 0.5,
              builder: (_, scrollController) {
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    MediaQuery.of(ctx).viewInsets.bottom + 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSheetHeader(
                        title: 'Kisah Cinta (Love Story)',
                        subtitle: 'Tambah atau ubah urutan perjalanan momen',
                        leading: SvgPicture.asset(
                          'assets/icons/ai-magic.svg',
                          width: 20,
                          height: 20,
                          colorFilter: const ColorFilter.mode(
                              AppColors.secondaryGold, BlendMode.srcIn),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, idx) {
                            final item = items[idx];
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.goldLight.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.primaryGold
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Momen #${idx + 1}',
                                        style: AppTypography.labelLarge
                                            .copyWith(
                                                color: AppColors.secondaryGold),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          setSheetState(() {
                                            items[idx].dispose();
                                            items.removeAt(idx);
                                          });
                                        },
                                        child: Text(
                                          'Hapus',
                                          style: AppTypography.caption.copyWith(
                                              color: AppColors.errorRed,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  DekorinTextField(
                                    controller: item.dateController,
                                    label: 'Waktu / Tanggal Momen',
                                    hint: 'Contoh: Juli 2023',
                                  ),
                                  const SizedBox(height: 8),
                                  DekorinTextField(
                                    controller: item.titleController,
                                    label: 'Judul Momen',
                                    hint: 'Contoh: Awal Bertemu',
                                  ),
                                  const SizedBox(height: 8),
                                  DekorinTextField(
                                    controller: item.descriptionController,
                                    label: 'Cerita Singkat',
                                    maxLines: 3,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () {
                          setSheetState(() => items.add(LoveStoryItem()));
                        },
                        icon: const Icon(Icons.add,
                            size: 18, color: AppColors.secondaryGold),
                        label: Text(
                          'Tambah Momen',
                          style: AppTypography.labelMedium
                              .copyWith(color: AppColors.secondaryGold),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primaryGold),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGold),
                        child: Text('Terapkan Kisah Cinta',
                            style: AppTypography.button),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );

    if (applied == true) {
      final list = items
          .map((e) => e.toMap())
          .where((m) =>
              m['date']!.isNotEmpty ||
              m['title']!.isNotEmpty ||
              m['description']!.isNotEmpty)
          .toList();
      await _applyPatch({'love_story': list.isEmpty ? '' : jsonEncode(list)});
    }
    for (final item in items) {
      item.dispose();
    }
  }

  List<String> _splitGallery(String raw) {
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _showGalleryBottomSheet() async {
    var urls = _splitGallery((_draft['gallery_images'] ?? '').toString());

    await _showEditorModalSheet<void>(
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSheetHeader(
                    title: 'Kelola Galeri Foto',
                    subtitle: '${urls.length} foto terpilih di album momen',
                    leading: const Icon(Icons.collections_outlined,
                        color: AppColors.secondaryGold),
                  ),
                  const SizedBox(height: 12),
                  if (urls.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Belum ada foto galeri. Ketuk tombol di bawah untuk mengunggah.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall,
                      ),
                    )
                  else
                    SizedBox(
                      height: 220,
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemCount: urls.length,
                        itemBuilder: (_, idx) {
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  urls[idx],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    color: AppColors.borderLight,
                                    child: const Icon(Icons.broken_image),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: InkWell(
                                  onTap: () async {
                                    urls.removeAt(idx);
                                    setSheetState(() {});
                                    await _applyPatch({
                                      'gallery_images': urls.join(','),
                                    });
                                  },
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: const BoxDecoration(
                                      color: Colors.black87,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close,
                                        size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickMultiImage(
                        imageQuality: 85,
                        maxWidth: 2048,
                        maxHeight: 2048,
                      );
                      if (picked.isEmpty || !mounted) return;
                      await DekorinLoadingDialog.run(
                        context,
                        message: 'Mengunggah ${picked.length} foto galeri...',
                        task: () async {
                          for (final file in picked) {
                            final data = await PickedImageData.fromXFile(file);
                            final uploaded = await ApiClient.uploadImage(data);
                            urls.add(uploaded);
                          }
                        },
                      );
                      setSheetState(() {});
                      await _applyPatch({'gallery_images': urls.join(',')});
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold),
                    icon: const Icon(Icons.add_photo_alternate_outlined,
                        color: Colors.white, size: 18),
                    label: Text('Tambah Foto Galeri',
                        style: AppTypography.button),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Selesai',
                      style: AppTypography.labelLarge
                          .copyWith(color: AppColors.textDark),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showPhotoBottomSheet({
    required String field,
    required String label,
    required String aspect,
  }) async {
    if (field.isEmpty) return;
    if (field == 'cover_image' &&
        (_currentTemplate == InvitationTemplate.jawa3 ||
            _currentTemplate == 'art-jawa-coklat-3' ||
            _currentTemplate == 'jawa-coklat-3')) {
      _showSnack(
        'Cover Art Jawa Coklat 3 terkunci menggunakan gunungan wayang bawaan.',
      );
      return;
    }

    final currentUrl = (_draft[field] ?? '').toString();
    double? cropRatio;
    if (aspect == '3:4') cropRatio = 3 / 4;
    if (aspect == '1:1') cropRatio = 1.0;
    if (aspect == '4:3') cropRatio = 4 / 3;

    final sheetAction = await _withOverlayModal<String?>(() async {
      final selected = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: false,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSheetHeader(
                  title: label,
                  subtitle: 'Pilih foto baru atau kembalikan ke default tema',
                  leading: const Icon(Icons.photo_camera_outlined,
                      color: AppColors.secondaryGold),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: currentUrl.isNotEmpty
                        ? Image.network(
                            currentUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Center(
                              child: Text('Foto tersimpan',
                                  style: AppTypography.caption),
                            ),
                          )
                        : Center(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                'Menggunakan foto bawaan tema',
                                textAlign: TextAlign.center,
                                style: AppTypography.caption,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx, 'pick'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold),
                  icon: const Icon(Icons.photo_library_outlined,
                      color: Colors.white, size: 18),
                  label: Text('Pilih & Upload Foto Baru',
                      style: AppTypography.button),
                ),
                if (currentUrl.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, 'reset'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.errorRed),
                    ),
                    child: Text(
                      'Kembalikan ke Bawaan Tema',
                      style: AppTypography.labelMedium
                          .copyWith(color: AppColors.errorRed),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      );

      if (selected == 'pick' && mounted) {
        await _pickCropUploadPhoto(
          field: field,
          cropRatio: cropRatio,
        );
      }
      return selected;
    });

    if (sheetAction == 'reset') {
      final patch = <String, dynamic>{field: ''};
      if (field == 'groom_photo' && _isSinglePersonEvent) {
        patch['child_photo'] = '';
      }
      await _applyPatch(patch);
      _showSnack('Foto dikembalikan ke bawaan tema.');
    }
  }

  Future<void> _pickCropUploadPhoto({
    required String field,
    double? cropRatio,
  }) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (picked == null || !mounted) return;

      PickedImageData imgData = await PickedImageData.fromXFile(picked);
      if (cropRatio != null && mounted) {
        final cropped = await _withOverlayModal(
          () => PortraitCropDialog.show(
            context,
            image: imgData,
            aspectRatio: cropRatio,
            title: 'Sesuaikan Bingkai Foto',
            subtitle:
                'Geser dan zoom agar posisi wajah pas di frame undangan',
          ),
        );
        if (cropped == null) return;
        imgData = cropped;
      }

      if (!mounted) return;
      final uploadedUrl = await _withOverlayModal(
        () => DekorinLoadingDialog.run(
          context,
          message: 'Mengunggah foto...',
          task: () => ApiClient.uploadImage(imgData),
        ),
      );

      final patch = <String, dynamic>{field: uploadedUrl};
      if (field == 'groom_photo' && _isSinglePersonEvent) {
        patch['child_photo'] = uploadedUrl;
      }
      await _applyPatch(patch);
      _showSnack('Foto berhasil diganti!');
    } catch (e) {
      _showSnack('Gagal mengunggah foto: $e', isError: true);
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SETTINGS SHEET (TEMPLATE PICKER, SLUG, AUDIO, YOUTUBE, WA, MODE FORM)
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _showSettingsBottomSheet() async {
    String selectedTpl = _currentTemplate;
    String selectedCat = _currentEventType;
    bool isActive = (_draft['is_active'] as bool?) ?? true;
    final titleCtrl =
        TextEditingController(text: (_draft['title'] ?? '').toString());
    final slugCtrl =
        TextEditingController(text: (_draft['slug'] ?? '').toString());
    final audioCtrl =
        TextEditingController(text: (_draft['audio_url'] ?? '').toString());
    final youtubeCtrl =
        TextEditingController(text: (_draft['youtube_url'] ?? '').toString());
    final waCtrl = TextEditingController(
        text: (_draft['wa_confirmation'] ?? '').toString());

    final applied = await _showEditorModalSheet<bool>(
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final tplName =
                (InvitationTemplate.getById(selectedTpl)['name'] as String?) ??
                    selectedTpl;
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.85,
              maxChildSize: 0.94,
              minChildSize: 0.5,
              builder: (_, scrollController) {
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    MediaQuery.of(ctx).viewInsets.bottom + 20,
                  ),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      _buildSheetHeader(
                        title: 'Pengaturan Undangan',
                        subtitle:
                            'Tema, tautan URL, musik latar, video, dan mode form',
                        leading: const Icon(Icons.tune_rounded,
                            color: AppColors.secondaryGold),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.goldLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primaryGold.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Desain Template',
                                      style: AppTypography.caption),
                                  const SizedBox(height: 2),
                                  Text(tplName,
                                      style: AppTypography.titleSmall),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final pickedTpl = await Navigator.push<String>(
                                  ctx,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        InvitationTemplatePickerView(
                                      initialTemplateId: selectedTpl,
                                    ),
                                  ),
                                );
                                if (pickedTpl != null && pickedTpl.isNotEmpty) {
                                  setSheetState(() => selectedTpl = pickedTpl);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGold,
                                minimumSize: const Size(0, 40),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                              ),
                              child: Text('Ganti Tema',
                                  style: AppTypography.button
                                      .copyWith(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text('Kategori Acara', style: AppTypography.labelMedium),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final cat in const [
                            ('wedding', 'Pernikahan'),
                            ('khitan', 'Khitanan'),
                            ('birthday', 'Ulang Tahun'),
                          ])
                            ChoiceChip(
                              label: Text(
                                cat.$2,
                                style: AppTypography.labelMedium.copyWith(
                                  color: selectedCat == cat.$1
                                      ? Colors.white
                                      : AppColors.textDark,
                                ),
                              ),
                              selected: selectedCat == cat.$1,
                              selectedColor: AppColors.primaryGold,
                              onSelected: (_) =>
                                  setSheetState(() => selectedCat = cat.$1),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      DekorinTextField(
                        controller: titleCtrl,
                        label: 'Judul Undangan',
                      ),
                      const SizedBox(height: 12),
                      DekorinTextField(
                        controller: slugCtrl,
                        label: 'Kode Link (Slug URL)',
                        helperText:
                            'Hindari mengubah slug jika tautan sudah disebar ke tamu.',
                      ),
                      const SizedBox(height: 12),
                      DekorinTextField(
                        controller: audioCtrl,
                        label: 'Link Musik Latar (.mp3 URL)',
                        hint: 'Kosongkan untuk musik default tema',
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 12),
                      DekorinTextField(
                        controller: youtubeCtrl,
                        label: 'Link Video / Live Streaming YouTube',
                        hint: 'https://youtu.be/...',
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 12),
                      DekorinTextField(
                        controller: waCtrl,
                        label: 'No. WhatsApp Konfirmasi Hadiah',
                        hint: '081234567890',
                        keyboardType: TextInputType.phone,
                        prefixWidget: Padding(
                          padding: const EdgeInsets.all(12),
                          child: SvgPicture.asset(
                            'assets/icons/wa.svg',
                            width: 18,
                            height: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Undangan Aktif (Publik)',
                            style: AppTypography.titleSmall),
                        subtitle: Text(
                          isActive
                              ? 'Tamu dapat membuka tautan undangan'
                              : 'Mode Draft sementara disembunyikan',
                          style: AppTypography.caption,
                        ),
                        activeThumbColor: AppColors.primaryGold,
                        value: isActive,
                        onChanged: (v) => setSheetState(() => isActive = v),
                      ),
                      const Divider(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGold),
                        child: Text('Terapkan Pengaturan',
                            style: AppTypography.button),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx, false);
                          _switchToClassicFormMode();
                        },
                        icon: SvgPicture.asset(
                          'assets/icons/edit.svg',
                          width: 16,
                          height: 16,
                          colorFilter: const ColorFilter.mode(
                              AppColors.textDark, BlendMode.srcIn),
                        ),
                        label: Text(
                          'Buka Mode Form (Klasik)',
                          style: AppTypography.labelMedium
                              .copyWith(color: AppColors.textDark),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );

    if (applied == true) {
      final templateChanged = selectedTpl != _currentTemplate;
      await _applyPatch({
        'template': selectedTpl,
        'event_type': selectedCat,
        'title': titleCtrl.text.trim(),
        'slug': slugCtrl.text.trim().toLowerCase().replaceAll(' ', '-'),
        'audio_url': audioCtrl.text.trim(),
        'youtube_url': youtubeCtrl.text.trim(),
        'wa_confirmation': waCtrl.text.trim(),
        'is_active': isActive,
      });
      if (templateChanged) {
        if (kIsWeb) {
          setState(() {
            _isBridgeReady = false;
            _bridgeCheckFailed = false;
            _loadingProgress = 50;
          });
          _webIframeController.loadUrl(_editorUrl);
        } else if (_webViewController != null) {
          _webViewController!.loadRequest(Uri.parse(_editorUrl));
        }
      }
    }

    titleCtrl.dispose();
    slugCtrl.dispose();
    audioCtrl.dispose();
    youtubeCtrl.dispose();
    waCtrl.dispose();
  }

  void _switchToClassicFormMode() {
    final mergedMap = Map<String, dynamic>.from(_draft)
      ..['id'] = widget.invitation.id
      ..['edit_token'] = widget.invitation.editToken
      ..['edit_pin'] = widget.invitation.editPin;
    final mergedInvitation = InvitationItem.fromJson(mergedMap);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => InvitationFormView(
          invitation: mergedInvitation,
          onUpdateOverride: widget.onUpdateOverride,
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SAVE PAYLOAD
  // ───────────────────────────────────────────────────────────────────────────

  String? _validateBeforeSave() {
    final slug = (_draft['slug'] ?? '').toString().trim();
    if (slug.isEmpty) {
      return 'Kode link (slug) tidak boleh kosong. Atur di Pengaturan.';
    }
    if (_currentTemplate == InvitationTemplate.pn4) {
      if ((_draft['cover_image'] ?? '').toString().trim().isEmpty) {
        return 'Foto Sampul Utama wajib diunggah untuk tema Monochrome (*Mandatory)';
      }
      if (!_isSinglePersonEvent &&
          (_draft['bride_photo'] ?? '').toString().trim().isEmpty) {
        return 'Foto Mempelai Wanita wajib diunggah untuk tema Monochrome (*Mandatory)';
      }
      if ((_draft['groom_photo'] ?? '').toString().trim().isEmpty) {
        return 'Foto Mempelai Pria / Anak wajib diunggah untuk tema Monochrome (*Mandatory)';
      }
      if ((_draft['sec1_photo'] ?? '').toString().trim().isEmpty) {
        return 'Foto Pembuka / Section 1 wajib diunggah untuk tema Monochrome (*Mandatory)';
      }
      if ((_draft['event_photo'] ?? '').toString().trim().isEmpty) {
        return 'Foto Countdown Acara wajib diunggah untuk tema Monochrome (*Mandatory)';
      }
      if ((_draft['closing_photo'] ?? '').toString().trim().isEmpty) {
        return 'Foto Penutup wajib diunggah untuk tema Monochrome (*Mandatory)';
      }
      if (_splitGallery((_draft['gallery_images'] ?? '').toString()).isEmpty) {
        return 'Minimal unggah 1 foto galeri untuk tema Monochrome (*Mandatory)';
      }
    }
    return null;
  }

  Future<void> _saveInvitation() async {
    final validationErr = _validateBeforeSave();
    if (validationErr != null) {
      _showSnack(validationErr, isError: true);
      return;
    }

    setState(() => _isSaving = true);
    final payload = Map<String, dynamic>.from(_draft)..remove('id');
    if (_currentTemplate == InvitationTemplate.jawa3 ||
        _currentTemplate == 'art-jawa-coklat-3' ||
        _currentTemplate == 'jawa-coklat-3') {
      payload['cover_image'] = '/assets/templates/jawa3/bg-cover.jpg';
    }

    try {
      if (widget.onUpdateOverride != null) {
        await widget.onUpdateOverride!(widget.invitation.id, payload);
      } else {
        await ref
            .read(invitationServiceProvider)
            .updateInvitation(widget.invitation.id, payload);
      }
      if (!mounted) return;
      _hasUnsavedChanges = false;
      Navigator.pop(context, true);
      _showSnack('Perubahan undangan berhasil disimpan!');
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnack('Gagal menyimpan undangan: $e', isError: true);
      }
    }
  }

  Future<bool> _confirmDiscardIfNeeded() async {
    if (!_hasUnsavedChanges) return true;
    final discard = await _withOverlayModal(
      () => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
        title: Text('Buang Perubahan?', style: AppTypography.titleMedium),
        content: Text(
          'Anda memiliki perubahan yang belum disimpan. Yakin ingin keluar dari Visual Editor?',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Lanjut Edit',
              style: AppTypography.labelLarge
                  .copyWith(color: AppColors.secondaryGold),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
            child: Text('Keluar', style: AppTypography.button),
          ),
        ],
      ),
    ),
    );
    return discard ?? false;
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(msg, style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
        backgroundColor: isError ? AppColors.errorRed : AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // BUILD UI
  // ───────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final canLeave = await _confirmDiscardIfNeeded();
        if (canLeave && context.mounted) {
          Navigator.of(context).pop(false);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Visual Editor Undangan',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleMedium,
              ),
              Text(
                _hasUnsavedChanges
                    ? 'Ada perubahan belum disimpan'
                    : 'Ketuk tulisan atau foto langsung untuk edit',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: _hasUnsavedChanges
                      ? AppColors.warningAmber
                      : AppColors.textLight,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Pengaturan & Mode Form',
              onPressed: _showSettingsBottomSheet,
              icon: const Icon(Icons.tune_rounded, color: AppColors.textDark),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveInvitation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  minimumSize: const Size(74, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text('Simpan',
                        style: AppTypography.button.copyWith(fontSize: 13)),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: _loadingProgress < 100
                ? LinearProgressIndicator(
                    value: _loadingProgress / 100.0,
                    minHeight: 3,
                    backgroundColor: AppColors.goldLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primaryGold),
                  )
                : const SizedBox(height: 1),
          ),
        ),
        body: Column(
          children: [
            _buildQuickActionBar(),
            if (_bridgeCheckFailed) _buildBridgeWarningBanner(),
            Expanded(
              child: AbsorbPointer(
                absorbing: _isModalOverlayActive,
                child: _buildMainViewport(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.dividerColor),
          bottom: BorderSide(color: AppColors.dividerColor),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildToolbarPill(
              icon: _isEditMode
                  ? Icons.visibility_outlined
                  : Icons.edit_outlined,
              label: _isEditMode ? 'Pratinjau Bersih' : 'Aktifkan Edit',
              isHighlighted: !_isEditMode,
              onTap: () async {
                setState(() => _isEditMode = !_isEditMode);
                await _syncWebViewEditMode();
              },
            ),
            const SizedBox(width: 8),
            _buildToolbarPill(
              icon: _isGateVisible
                  ? Icons.menu_open_rounded
                  : Icons.door_front_door_outlined,
              label: _isGateVisible ? 'Buka Isi' : 'Lihat Sampul',
              onTap: _toggleGateInWebView,
            ),
            const SizedBox(width: 8),
            _buildToolbarPill(
              icon: Icons.collections_outlined,
              label: 'Galeri',
              onTap: _showGalleryBottomSheet,
            ),
            const SizedBox(width: 8),
            _buildToolbarPill(
              icon: Icons.article_outlined,
              label: 'Mode Form',
              onTap: _switchToClassicFormMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarPill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isHighlighted ? AppColors.successGreen : AppColors.goldLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isHighlighted
                ? AppColors.successGreen
                : AppColors.primaryGold.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isHighlighted ? Colors.white : AppColors.secondaryGold,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                fontSize: 12,
                color: isHighlighted ? Colors.white : AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBridgeWarningBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: AppColors.goldLight,
      child: Row(
        children: [
          const Icon(Icons.info_outline,
              size: 18, color: AppColors.secondaryGold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Server belum mengaktifkan mode Visual Editor langsung. Gunakan Mode Form untuk mengedit seluruh data.',
              style: AppTypography.caption.copyWith(color: AppColors.textDark),
            ),
          ),
          TextButton(
            onPressed: _switchToClassicFormMode,
            child: Text(
              'Mode Form',
              style: AppTypography.labelMedium.copyWith(
                  color: AppColors.secondaryGold, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainViewport() {
    if (kIsWeb) {
      return buildVisualEditorWebIframe(
        url: _editorUrl,
        controller: _webIframeController,
        onMessage: _handleEditorMessage,
        onLoadFinished: _onWebIframeLoaded,
      );
    }

    if (!_supportsEmbeddedWebView) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/icons/edit.svg',
                  width: 36,
                  height: 36,
                  colorFilter: const ColorFilter.mode(
                      AppColors.secondaryGold, BlendMode.srcIn),
                ),
                const SizedBox(height: 14),
                Text(
                  'Visual Editor WebView tersedia penuh di aplikasi Android & iOS',
                  textAlign: TextAlign.center,
                  style: AppTypography.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Anda dapat mengedit menggunakan Mode Form atau membuka Portal Pengantin di browser.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: _switchToClassicFormMode,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold),
                  child: Text('Buka Mode Form', style: AppTypography.button),
                ),
                if (widget.invitation.editToken.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      final url = ApiEndpoint.getInvitationPortalManageUrl(
                          widget.invitation.editToken);
                      launchUrl(Uri.parse(url),
                          mode: LaunchMode.externalApplication);
                    },
                    child: Text(
                      'Buka Visual Editor Web Portal',
                      style: AppTypography.labelMedium
                          .copyWith(color: AppColors.secondaryGold),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    if (_hasLoadError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 44, color: AppColors.textLight),
              const SizedBox(height: 12),
              Text('Gagal Memuat Undangan', style: AppTypography.titleMedium),
              const SizedBox(height: 6),
              Text(_loadErrorMessage,
                  textAlign: TextAlign.center, style: AppTypography.bodySmall),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: _switchToClassicFormMode,
                    child: Text(
                      'Mode Form',
                      style: AppTypography.labelMedium
                          .copyWith(color: AppColors.textDark),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () =>
                        _webViewController?.loadRequest(Uri.parse(_editorUrl)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                    ),
                    child: Text('Muat Ulang', style: AppTypography.button),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return WebViewWidget(controller: _webViewController!);
  }

  Widget _buildSheetHeader({
    required String title,
    required String subtitle,
    required Widget leading,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.goldLight,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: leading,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.titleSmall),
              Text(subtitle, style: AppTypography.caption),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: AppColors.secondaryGold,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: AppColors.goldLight,
      side: BorderSide(color: AppColors.primaryGold.withValues(alpha: 0.35)),
      onPressed: onTap,
    );
  }
}
