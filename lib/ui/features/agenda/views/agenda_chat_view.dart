import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/data/datasources/local/data_preferences.dart';
import 'package:dekorin_apps/data/services/chat_service.dart';
import 'package:dekorin_apps/domain/models/chat_message.dart';
import 'package:dekorin_apps/domain/models/picked_image_data.dart';

class AgendaChatView extends ConsumerStatefulWidget {
  final String agendaId;
  final String? initialClientName;

  const AgendaChatView({
    super.key,
    required this.agendaId,
    this.initialClientName,
  });

  @override
  ConsumerState<AgendaChatView> createState() => _AgendaChatViewState();
}

class _AgendaChatViewState extends ConsumerState<AgendaChatView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  ChatRoomInfo? _room;
  final List<ChatMessage> _messages = [];
  final Map<String, GlobalKey> _messageKeys = {};

  bool _isLoading = true;
  bool _isSending = false;
  bool _isUploadingAttachment = false;
  String? _errorMessage;
  String _currentUserId = '';

  ChatMessage? _replyingTo;
  String? _highlightedMessageId;
  String? _mentionQuery;
  final Set<String> _pendingMentionIds = {};

  final Map<String, ChatReadReceipt> _readReceipts = {};
  final Map<String, String> _typingUsers = {}; // userId -> display label
  final Map<String, Timer> _typingExpireTimers = {};
  Timer? _typingIdleTimer;
  DateTime? _lastTypingSentAt;

  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSub;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  bool _disposed = false;
  bool _wsConnected = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _textController.addListener(_onTextChanged);
    _loadInitialMessages();
  }

  void _loadCurrentUserId() {
    try {
      final raw = DataPreferences.getUser();
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        _currentUserId = (decoded['id'] as String?) ?? '';
      }
    } catch (_) {}
  }

  void _onTextChanged() {
    final text = _textController.text;
    final selection = _textController.selection;
    final cursor = selection.baseOffset;
    if (cursor < 0 || cursor > text.length) {
      if (_mentionQuery != null) setState(() => _mentionQuery = null);
      return;
    }
    final beforeCursor = text.substring(0, cursor);
    final match = RegExp(r'(?:^|\s)@([^\s@]*)$').firstMatch(beforeCursor);
    final nextQuery = match?.group(1)?.toLowerCase();
    if (nextQuery != _mentionQuery) {
      setState(() => _mentionQuery = nextQuery);
    }

    if (text.trim().isNotEmpty) {
      _notifyTyping();
    } else {
      _sendTypingState(false);
    }
  }

  void _notifyTyping() {
    final now = DateTime.now();
    if (_lastTypingSentAt == null ||
        now.difference(_lastTypingSentAt!) > const Duration(milliseconds: 1500)) {
      _lastTypingSentAt = now;
      _sendTypingState(true);
    }
    _typingIdleTimer?.cancel();
    _typingIdleTimer = Timer(const Duration(seconds: 2), () {
      _sendTypingState(false);
    });
  }

  void _sendTypingState(bool isTyping) {
    if (!_wsConnected) return;
    try {
      _wsChannel?.sink.add(jsonEncode({
        'event': 'typing',
        'is_typing': isTyping,
      }));
    } catch (_) {}
  }

  void _insertMention({required String label, required String companyId}) {
    final text = _textController.text;
    final cursor = _textController.selection.baseOffset;
    if (cursor < 0 || cursor > text.length) return;

    final beforeCursor = text.substring(0, cursor);
    final afterCursor = text.substring(cursor);
    final atIndex = beforeCursor.lastIndexOf('@');
    if (atIndex < 0) return;

    final inserted = '@$label ';
    final updated = beforeCursor.substring(0, atIndex) + inserted + afterCursor;
    final newCursor = atIndex + inserted.length;

    _pendingMentionIds.add(companyId);
    _textController.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: newCursor),
    );
    setState(() => _mentionQuery = null);
    _inputFocusNode.requestFocus();
  }

  Future<void> _loadInitialMessages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final res =
          await ref.read(chatServiceProvider).getMessages(widget.agendaId);
      if (!mounted) return;
      setState(() {
        _room = res.room;
        _messages
          ..clear()
          ..addAll(res.messages);
        _readReceipts.clear();
        for (final r in res.readReceipts) {
          _readReceipts[r.userId] = r;
        }
        _isLoading = false;
      });
      _scrollToBottom(jump: true);
      ref.invalidate(chatUnreadSummaryProvider);
      ref.invalidate(chatRoomsProvider);
      _connectWebSocket();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _connectWebSocket() {
    if (_disposed) return;
    _wsSub?.cancel();
    _wsChannel?.sink.close();
    _pingTimer?.cancel();

    try {
      final channel =
          ref.read(chatServiceProvider).connectWebSocket(widget.agendaId);
      _wsChannel = channel;
      _wsSub = channel.stream.listen(
        (raw) {
          if (_disposed) return;
          try {
            final decoded = jsonDecode(raw.toString()) as Map<String, dynamic>;
            final event = decoded['event'] as String?;
            if (event == 'connected') {
              if (mounted) setState(() => _wsConnected = true);
            } else if (event == 'new_message') {
              final data = decoded['data'];
              if (data is Map<String, dynamic>) {
                final msg = ChatMessage.fromJson(data);
                _appendMessageIfNew(msg);
                if (msg.senderUserId != _currentUserId) {
                  try {
                    _wsChannel?.sink.add(jsonEncode({'event': 'mark_read'}));
                  } catch (_) {
                    ref.read(chatServiceProvider).markAsRead(widget.agendaId);
                  }
                }
              }
            } else if (event == 'typing') {
              final data = decoded['data'];
              if (data is Map<String, dynamic>) {
                final uid = (data['user_id'] as String?) ?? '';
                if (uid.isNotEmpty && uid != _currentUserId) {
                  final isTyping = data['is_typing'] == true;
                  final uname = (data['user_name'] as String?) ?? 'Seseorang';
                  final cname = (data['company_name'] as String?) ?? '';
                  final label = cname.isNotEmpty ? '$uname · $cname' : uname;
                  _typingExpireTimers[uid]?.cancel();
                  if (mounted) {
                    setState(() {
                      if (isTyping) {
                        _typingUsers[uid] = label;
                        _typingExpireTimers[uid] =
                            Timer(const Duration(seconds: 4), () {
                          if (mounted) {
                            setState(() => _typingUsers.remove(uid));
                          }
                        });
                      } else {
                        _typingUsers.remove(uid);
                      }
                    });
                  }
                }
              }
            } else if (event == 'read_updated') {
              final data = decoded['data'];
              if (data is Map<String, dynamic>) {
                final receipt = ChatReadReceipt.fromJson(data);
                if (receipt.userId.isNotEmpty && mounted) {
                  setState(() {
                    _readReceipts[receipt.userId] = receipt;
                  });
                }
              }
            }
          } catch (_) {}
        },
        onError: (_) => _scheduleReconnect(),
        onDone: () => _scheduleReconnect(),
      );

      _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
        try {
          _wsChannel?.sink.add(jsonEncode({'event': 'ping'}));
        } catch (_) {}
      });
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    if (mounted && _wsConnected) {
      setState(() => _wsConnected = false);
    }
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (!_disposed) _connectWebSocket();
    });
  }

  void _appendMessageIfNew(ChatMessage msg) {
    if (_messages.any((m) => m.id == msg.id)) return;
    if (!mounted) return;
    setState(() {
      _messages.add(msg);
    });
    _scrollToBottom();
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (jump) {
        _scrollController.jumpTo(target);
      } else {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _scrollToMessage(String messageId) {
    final key = _messageKeys[messageId];
    final targetCtx = key?.currentContext;
    if (targetCtx == null) return;

    Scrollable.ensureVisible(
      targetCtx,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0.35,
    );
    setState(() => _highlightedMessageId = messageId);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted && _highlightedMessageId == messageId) {
        setState(() => _highlightedMessageId = null);
      }
    });
  }

  void _setReplyTarget(ChatMessage msg) {
    setState(() => _replyingTo = msg);
    if (!_inputFocusNode.hasFocus) {
      _inputFocusNode.requestFocus();
    }
  }

  Future<void> _sendTextMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    final replyId = _replyingTo?.id ?? '';
    final mentions = _pendingMentionIds.toList();

    _textController.clear();
    _pendingMentionIds.clear();
    setState(() {
      _isSending = true;
      _replyingTo = null;
      _mentionQuery = null;
    });

    try {
      final sent = await ref.read(chatServiceProvider).sendMessage(
            widget.agendaId,
            messageType: 'text',
            content: text,
            replyToId: replyId,
            mentionedCompanyIds: mentions,
          );
      _appendMessageIfNew(sent);
    } catch (e) {
      if (mounted) {
        _textController.text = text;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
              style: AppTypography.bodySmall.copyWith(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<String?> _showAttachmentCaptionDialog({
    PickedImageData? imageData,
    String? pdfFilename,
    int? pdfSize,
  }) async {
    final captionCtrl = TextEditingController(
      text: _textController.text.trim(),
    );
    return showDialog<String?>(
      context: context,
      builder: (ctx) {
        final maxImgHeight =
            (MediaQuery.of(ctx).size.height * 0.26).clamp(120.0, 220.0);
        return Dialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        imageData != null ? 'Kirim Foto' : 'Kirim Dokumen PDF',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx, null),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (imageData != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: maxImgHeight),
                      child: Image.memory(
                        imageData.bytes,
                        fit: BoxFit.contain,
                      ),
                    ),
                  )
              else
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.goldLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryGold.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.picture_as_pdf_rounded,
                        color: Colors.redAccent,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pdfFilename ?? 'Dokumen.pdf',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _formatFileSize(pdfSize ?? 0),
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: captionCtrl,
                style: AppTypography.bodyMedium,
                maxLines: 3,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => Navigator.pop(ctx, captionCtrl.text.trim()),
                decoration: InputDecoration(
                  hintText: 'Tambahkan keterangan / pesan...',
                  hintStyle: AppTypography.bodySmall,
                  filled: true,
                  fillColor: const Color(0xFFF7F5F2),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx, null),
                      child: Text(
                        'Batal',
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () =>
                          Navigator.pop(ctx, captionCtrl.text.trim()),
                      child: Text('Kirim', style: AppTypography.button),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      },
    );
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    if (_isUploadingAttachment) return;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1600,
      );
      if (picked == null) return;

      final imageData = await PickedImageData.fromXFile(picked);
      if (!mounted) return;
      final caption = await _showAttachmentCaptionDialog(imageData: imageData);
      if (caption == null || !mounted) return;

      final replyId = _replyingTo?.id ?? '';
      final mentions = _pendingMentionIds.toList();
      _textController.clear();
      _pendingMentionIds.clear();
      setState(() {
        _isUploadingAttachment = true;
        _replyingTo = null;
        _mentionQuery = null;
      });

      final chatSvc = ref.read(chatServiceProvider);
      final imageUrl = await chatSvc.uploadChatImage(widget.agendaId, imageData);
      if (imageUrl.isEmpty) {
        throw Exception('URL gambar gagal diperoleh');
      }
      final sent = await chatSvc.sendMessage(
        widget.agendaId,
        messageType: 'image',
        content: caption,
        attachmentUrl: imageUrl,
        replyToId: replyId,
        mentionedCompanyIds: mentions,
      );
      _appendMessageIfNew(sent);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
              style: AppTypography.bodySmall.copyWith(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAttachment = false);
    }
  }

  Future<void> _pickAndSendPdf() async {
    if (_isUploadingAttachment) return;
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (files.isEmpty) return;

      final file = files.first;
      final Uint8List bytes = await file.xFile.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('File PDF gagal dibaca');
      }
      if (bytes.lengthInBytes > 10 * 1024 * 1024) {
        throw Exception('Ukuran file PDF maksimal 10MB');
      }

      if (!mounted) return;
      final caption = await _showAttachmentCaptionDialog(
        pdfFilename: file.name,
        pdfSize: bytes.lengthInBytes,
      );
      if (caption == null || !mounted) return;

      final replyId = _replyingTo?.id ?? '';
      final mentions = _pendingMentionIds.toList();
      _textController.clear();
      _pendingMentionIds.clear();
      setState(() {
        _isUploadingAttachment = true;
        _replyingTo = null;
        _mentionQuery = null;
      });

      final chatSvc = ref.read(chatServiceProvider);
      final uploaded = await chatSvc.uploadChatPdf(
        widget.agendaId,
        bytes: bytes,
        filename: file.name,
      );
      final pdfUrl = (uploaded['url'] as String?) ?? '';
      if (pdfUrl.isEmpty) {
        throw Exception('URL PDF gagal diperoleh');
      }

      final sent = await chatSvc.sendMessage(
        widget.agendaId,
        messageType: 'file',
        content: caption,
        attachmentUrl: pdfUrl,
        attachmentName: file.name,
        attachmentSize: bytes.lengthInBytes,
        replyToId: replyId,
        mentionedCompanyIds: mentions,
      );
      _appendMessageIfNew(sent);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
              style: AppTypography.bodySmall.copyWith(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAttachment = false);
    }
  }

  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.primaryGold,
                ),
                title: Text('Pilih Foto dari Galeri', style: AppTypography.bodyMedium),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndSendImage(ImageSource.gallery);
                },
              ),
              if (!kIsWeb)
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                    color: AppColors.primaryGold,
                  ),
                  title: Text('Ambil Foto Kamera', style: AppTypography.bodyMedium),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndSendImage(ImageSource.camera);
                  },
                ),
              ListTile(
                leading: const Icon(
                  Icons.picture_as_pdf_outlined,
                  color: AppColors.primaryGold,
                ),
                title: Text('Kirim Dokumen PDF (Maks 10MB)', style: AppTypography.bodyMedium),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndSendPdf();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCrewAssignmentSheet() async {
    try {
      final options =
          await ref.read(chatServiceProvider).getCrewOptions(widget.agendaId);
      if (!mounted) return;

      final selected = options
          .where((o) => o.isAssigned)
          .map((o) => o.userId)
          .toSet();
      bool saving = false;

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setModalState) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assign Tim / Crew ke Diskusi',
                    style: AppTypography.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Owner & Admin otomatis masuk. Pilih Crew yang bertugas pada acara ini agar bisa ikut berdiskusi.',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  if (options.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'Belum ada akun Crew/Staff di perusahaan Anda.',
                          style: AppTypography.bodySmall,
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 320),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (_, idx) {
                          final item = options[idx];
                          final checked = selected.contains(item.userId);
                          return CheckboxListTile(
                            value: checked,
                            activeColor: AppColors.primaryGold,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              item.name,
                              style: AppTypography.bodyMedium,
                            ),
                            subtitle: Text(
                              item.phone.isNotEmpty
                                  ? '${item.role.toUpperCase()} · ${item.phone}'
                                  : item.role.toUpperCase(),
                              style: AppTypography.caption,
                            ),
                            onChanged: (val) {
                              setModalState(() {
                                if (val == true) {
                                  selected.add(item.userId);
                                } else {
                                  selected.remove(item.userId);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: saving || options.isEmpty
                          ? null
                          : () async {
                              setModalState(() => saving = true);
                              try {
                                await ref
                                    .read(chatServiceProvider)
                                    .updateCrewAssignments(
                                      widget.agendaId,
                                      selected.toList(),
                                    );
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Anggota tim diskusi diperbarui',
                                        style: AppTypography.bodySmall
                                            .copyWith(color: Colors.white),
                                      ),
                                      backgroundColor: AppColors.primaryGold,
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModalState(() => saving = false);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        e
                                            .toString()
                                            .replaceFirst('Exception: ', ''),
                                        style: AppTypography.bodySmall
                                            .copyWith(color: Colors.white),
                                      ),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              }
                            },
                      child: Text(
                        saving ? 'Menyimpan...' : 'Simpan Tim',
                        style: AppTypography.button,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
            style: AppTypography.bodySmall.copyWith(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openImagePreview(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 36,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return 'PDF';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  void dispose() {
    _disposed = true;
    _sendTypingState(false);
    _typingIdleTimer?.cancel();
    for (final t in _typingExpireTimers.values) {
      t.cancel();
    }
    _typingExpireTimers.clear();
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _wsSub?.cancel();
    _wsChannel?.sink.close();
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  String _typingSubtitleText() {
    if (_typingUsers.isEmpty) {
      return _wsConnected ? 'Terhubung real-time' : 'Menghubungkan...';
    }
    if (_typingUsers.length == 1) {
      return '${_typingUsers.values.first} sedang mengetik...';
    }
    return '${_typingUsers.length} orang sedang mengetik...';
  }

  List<ChatReadReceipt> _readersForMessage(ChatMessage msg) {
    return _readReceipts.values
        .where((r) =>
            r.userId != _currentUserId &&
            r.userId != msg.senderUserId &&
            !r.lastReadAt.isBefore(msg.createdAt))
        .toList();
  }

  void _showMessageOptionsSheet(ChatMessage msg) {
    final readers = _readersForMessage(msg);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.reply_rounded,
                  color: AppColors.primaryGold,
                ),
                title: Text('Balas Pesan', style: AppTypography.bodyMedium),
                onTap: () {
                  Navigator.pop(ctx);
                  _setReplyTarget(msg);
                },
              ),
              if (msg.senderUserId == _currentUserId) ...[
                const Divider(height: 16),
                Text(
                  'Dibaca Oleh (${readers.length})',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (readers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Belum dibaca oleh vendor atau tim lain.',
                      style: AppTypography.bodySmall,
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: readers.length,
                      itemBuilder: (_, idx) {
                        final r = readers[idx];
                        final readTime = DateFormat('dd/MM HH:mm')
                            .format(r.lastReadAt.toLocal());
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.done_all_rounded,
                                size: 16,
                                color: AppColors.primaryGold,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  r.companyName.isNotEmpty
                                      ? '${r.userName} · ${r.companyName}'
                                      : r.userName,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                              Text(
                                readTime,
                                style: AppTypography.caption.copyWith(
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleName = _room?.clientName.isNotEmpty == true
        ? _room!.clientName
        : (widget.initialClientName ?? 'Diskusi Kolaborasi');

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Diskusi · $titleName',
              style: AppTypography.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: [
                if (_typingUsers.isEmpty) ...[
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _wsConnected ? Colors.green : Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
                Expanded(
                  child: Text(
                    _typingSubtitleText(),
                    style: AppTypography.caption.copyWith(
                      fontSize: 10,
                      color: _typingUsers.isNotEmpty
                          ? AppColors.primaryGold
                          : null,
                      fontWeight: _typingUsers.isNotEmpty
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (_room?.canManageCrew == true)
            IconButton(
              tooltip: 'Assign Crew ke Diskusi',
              icon: const Icon(Icons.group_add_outlined,
                  color: AppColors.primaryGold),
              onPressed: _showCrewAssignmentSheet,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGold),
            )
          : _errorMessage != null
              ? _buildErrorState()
              : Column(
                  children: [
                    if (_room != null) _buildPinnedEventHeader(_room!),
                    Expanded(
                      child: _messages.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  'Belum ada pesan. Mulai koordinasi tim & vendor di sini!',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodySmall,
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              itemCount: _messages.length,
                              itemBuilder: (_, idx) =>
                                  _buildMessageItem(_messages[idx]),
                            ),
                    ),
                    if (_mentionQuery != null && _room != null)
                      _buildMentionSuggestions(_room!),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => ClipRect(
                        child: SizeTransition(
                          sizeFactor: animation,
                          alignment: Alignment.topCenter,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        ),
                      ),
                      child: _replyingTo != null
                          ? KeyedSubtree(
                              key: ValueKey('reply_${_replyingTo!.id}'),
                              child: _buildReplyPreviewBar(_replyingTo!),
                            )
                          : const SizedBox.shrink(key: ValueKey('reply_empty')),
                    ),
                    _buildComposerBar(),
                  ],
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 44, color: AppColors.primaryGold),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Gagal memuat diskusi',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
              ),
              onPressed: _loadInitialMessages,
              child: Text('Coba Lagi', style: AppTypography.button),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinnedEventHeader(ChatRoomInfo room) {
    final dateStr = room.eventDateTime != null
        ? DateFormat('dd MMM yyyy · HH:mm', 'id_ID')
            .format(room.eventDateTime!.toLocal())
        : '-';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.goldLight,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE9DCCD)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Acara: $dateStr',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (room.mapsUrl.isNotEmpty)
                InkWell(
                  onTap: () => _openExternalUrl(room.mapsUrl),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE3D5C5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/icons/google-maps-icon.webp',
                          width: 14,
                          height: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Maps',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (room.eventAddress.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              room.eventAddress,
              style: AppTypography.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (room.participants.isNotEmpty) ...[
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: room.participants.map((p) {
                  return Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: p.isLead
                          ? AppColors.primaryGold.withValues(alpha: 0.16)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: p.isLead
                            ? AppColors.primaryGold
                            : const Color(0xFFE3D5C5),
                      ),
                    ),
                    child: Text(
                      p.category.isNotEmpty
                          ? '${p.companyName} · ${p.category}'
                          : p.companyName,
                      style: AppTypography.caption.copyWith(
                        fontSize: 10,
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMentionSuggestions(ChatRoomInfo room) {
    final q = _mentionQuery ?? '';
    final options = <Map<String, String>>[
      if ('semua'.contains(q))
        {'label': 'Semua', 'sub': 'Notifikasi seluruh vendor', 'id': 'all'},
      ...room.participants
          .where((p) => p.companyName.toLowerCase().contains(q))
          .map((p) => {
                'label': p.companyName,
                'sub': p.category,
                'id': p.companyId,
              }),
    ];

    if (options.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxHeight: 170),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8E2DA))),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: options.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, color: Color(0xFFF0ECE6)),
        itemBuilder: (_, idx) {
          final opt = options[idx];
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.goldLight,
              child: Text(
                '@',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              opt['label'] ?? '',
              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: (opt['sub'] ?? '').isNotEmpty
                ? Text(opt['sub']!, style: AppTypography.caption)
                : null,
            onTap: () => _insertMention(
              label: opt['label'] ?? '',
              companyId: opt['id'] ?? '',
            ),
          );
        },
      ),
    );
  }

  Widget _buildReplyPreviewBar(ChatMessage target) {
    final previewText = target.content.isNotEmpty
        ? target.content
        : (target.isImage
            ? '[Foto]'
            : (target.isFile ? '[PDF] ${target.attachmentName}' : ''));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFFDFBF8),
        border: Border(top: BorderSide(color: Color(0xFFE8E2DA))),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primaryGold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Membalas ${target.senderName.isNotEmpty ? target.senderName : "Sistem"}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primaryGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  previewText,
                  style: AppTypography.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.grey),
            onPressed: () => setState(() => _replyingTo = null),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedContent(String content) {
    final matches = RegExp(r'@[^\s]+').allMatches(content).toList();
    if (matches.isEmpty) {
      return Text(
        content,
        style: AppTypography.bodyMedium.copyWith(color: AppColors.textDark),
      );
    }

    final spans = <TextSpan>[];
    int lastEnd = 0;
    for (final m in matches) {
      if (m.start > lastEnd) {
        spans.add(TextSpan(
          text: content.substring(lastEnd, m.start),
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textDark),
        ));
      }
      spans.add(TextSpan(
        text: m.group(0),
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.secondaryGold,
          fontWeight: FontWeight.bold,
        ),
      ));
      lastEnd = m.end;
    }
    if (lastEnd < content.length) {
      spans.add(TextSpan(
        text: content.substring(lastEnd),
        style: AppTypography.bodyMedium.copyWith(color: AppColors.textDark),
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildMessageItem(ChatMessage msg) {
    final key = _messageKeys.putIfAbsent(msg.id, () => GlobalKey());

    if (msg.isSystem) {
      return Center(
        key: key,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFEAE5DE),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            msg.content,
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: AppColors.textDark,
              fontSize: 11,
            ),
          ),
        ),
      );
    }

    final isMe = _currentUserId.isNotEmpty && msg.senderUserId == _currentUserId;
    final isHighlighted = _highlightedMessageId == msg.id;
    final timeStr = DateFormat('HH:mm').format(msg.createdAt.toLocal());
    final vendorBadge = [
      if (msg.senderCompanyName.isNotEmpty) msg.senderCompanyName,
      if (msg.senderCategory.isNotEmpty) msg.senderCategory,
    ].join(' · ');

    return _SwipeToReplyWrapper(
      key: ValueKey('swipe_${msg.id}'),
      onReply: () => _setReplyTarget(msg),
      child: GestureDetector(
        key: key,
        onLongPress: () => _showMessageOptionsSheet(msg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: isHighlighted
                ? AppColors.primaryGold.withValues(alpha: 0.16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe ? AppColors.goldLight : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isMe ? 14 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 14),
                ),
                border: Border.all(
                  color: isMe
                      ? AppColors.primaryGold.withValues(alpha: 0.45)
                      : const Color(0xFFE8E2DA),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe) ...[
                    Text(
                      msg.senderName,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.secondaryGold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (vendorBadge.isNotEmpty)
                      Text(
                        vendorBadge,
                        style: AppTypography.caption.copyWith(fontSize: 10),
                      ),
                    const SizedBox(height: 4),
                  ],
                  if (msg.replyToId.isNotEmpty) ...[
                    InkWell(
                      onTap: () => _scrollToMessage(msg.replyToId),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.white.withValues(alpha: 0.75)
                              : const Color(0xFFF7F5F2),
                          borderRadius: BorderRadius.circular(8),
                          border: const Border(
                            left: BorderSide(
                              color: AppColors.primaryGold,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.replySenderName,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.primaryGold,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              msg.replyPreview,
                              style: AppTypography.caption.copyWith(fontSize: 11),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (msg.isImage && msg.attachmentUrl.isNotEmpty) ...[
                    GestureDetector(
                      onTap: () => _openImagePreview(msg.attachmentUrl),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          msg.attachmentUrl,
                          width: 220,
                          height: 180,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 220,
                            height: 100,
                            color: const Color(0xFFF0ECE6),
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                    ),
                    if (msg.content.isNotEmpty) const SizedBox(height: 6),
                  ],
                  if (msg.isFile && msg.attachmentUrl.isNotEmpty) ...[
                    InkWell(
                      onTap: () => _openExternalUrl(msg.attachmentUrl),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.white.withValues(alpha: 0.85)
                              : const Color(0xFFF7F5F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE3D5C5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.picture_as_pdf_rounded,
                              color: Colors.redAccent,
                              size: 28,
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg.attachmentName.isNotEmpty
                                        ? msg.attachmentName
                                        : 'Dokumen.pdf',
                                    style: AppTypography.labelMedium.copyWith(
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${_formatFileSize(msg.attachmentSize)} · Tap untuk buka',
                                    style: AppTypography.caption.copyWith(
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (msg.content.isNotEmpty) const SizedBox(height: 6),
                  ],
                  if (msg.content.isNotEmpty) _buildFormattedContent(msg.content),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        timeStr,
                        style: AppTypography.caption.copyWith(fontSize: 10),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        _ReadReceiptTicks(
                          isRead: _readersForMessage(msg).isNotEmpty,
                          isDelivered: _readReceipts.values
                              .any((r) => r.userId != _currentUserId),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComposerBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE8E2DA))),
        ),
        child: Row(
          children: [
            InkWell(
              onTap: _isUploadingAttachment ? null : _showAttachmentSheet,
              borderRadius: BorderRadius.circular(21),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.goldLight,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: _isUploadingAttachment
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryGold,
                          ),
                        )
                      : Text(
                          '+',
                          style: AppTypography.titleLarge.copyWith(
                            color: AppColors.primaryGold,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _textController,
                focusNode: _inputFocusNode,
                style: AppTypography.bodyMedium,
                textInputAction: TextInputAction.send,
                maxLines: 4,
                minLines: 1,
                onSubmitted: (_) => _sendTextMessage(),
                decoration: InputDecoration(
                  hintText: 'Tulis pesan...',
                  hintStyle: AppTypography.bodySmall,
                  filled: true,
                  fillColor: const Color(0xFFF7F5F2),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: _isSending ? null : _sendTextMessage,
              borderRadius: BorderRadius.circular(22),
              child: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.primaryGold,
                  shape: BoxShape.circle,
                ),
                child: _isSending
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeToReplyWrapper extends StatefulWidget {
  final VoidCallback onReply;
  final Widget child;

  const _SwipeToReplyWrapper({
    super.key,
    required this.onReply,
    required this.child,
  });

  @override
  State<_SwipeToReplyWrapper> createState() => _SwipeToReplyWrapperState();
}

class _SwipeToReplyWrapperState extends State<_SwipeToReplyWrapper>
    with SingleTickerProviderStateMixin {
  static const double _maxDrag = 150.0;
  static const double _triggerThreshold = 48.0;

  late final AnimationController _resetController;
  Animation<double>? _resetAnimation;
  double _dragOffset = 0.0;
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..addListener(() {
        if (mounted && _resetAnimation != null) {
          setState(() {
            _dragOffset = _resetAnimation!.value;
          });
        }
      });
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails _) {
    _resetController.stop();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (details.delta.dx == 0) return;
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dx).clamp(0.0, _maxDrag);
    });
    if (!_triggered && _dragOffset >= _triggerThreshold) {
      _triggered = true;
    }
  }

  void _onDragEnd([DragEndDetails? _]) {
    if (_triggered) {
      widget.onReply();
    }
    _triggered = false;
    if (_dragOffset <= 0) return;
    _resetAnimation = Tween<double>(begin: _dragOffset, end: 0.0).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOutCubic),
    );
    _resetController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_dragOffset / _triggerThreshold).clamp(0.0, 1.0);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      onHorizontalDragCancel: () => _onDragEnd(),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          if (_dragOffset > 2)
            Positioned(
              left: 8,
              child: Opacity(
                opacity: progress,
                child: Transform.scale(
                  scale: 0.7 + (0.3 * progress),
                  child: const Icon(
                    Icons.reply_rounded,
                    color: AppColors.primaryGold,
                    size: 22,
                  ),
                ),
              ),
            ),
          Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

class _ReadReceiptTicks extends StatelessWidget {
  final bool isRead;
  final bool isDelivered;

  const _ReadReceiptTicks({
    required this.isRead,
    required this.isDelivered,
  });

  @override
  Widget build(BuildContext context) {
    final color = isRead ? AppColors.primaryGold : Colors.grey.shade500;
    final showDouble = isRead || isDelivered;
    return CustomPaint(
      size: Size(showDouble ? 16 : 11, 11),
      painter: _TicksPainter(color: color, showDouble: showDouble),
    );
  }
}

class _TicksPainter extends CustomPainter {
  final Color color;
  final bool showDouble;

  _TicksPainter({required this.color, required this.showDouble});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final first = Path()
      ..moveTo(1, size.height * 0.55)
      ..lineTo(3.8, size.height * 0.85)
      ..lineTo(9.2, size.height * 0.2);
    canvas.drawPath(first, paint);

    if (showDouble) {
      final second = Path()
        ..moveTo(5.6, size.height * 0.55)
        ..lineTo(8.4, size.height * 0.85)
        ..lineTo(14.0, size.height * 0.2);
      canvas.drawPath(second, paint);
    }
  }

  @override
  bool shouldRepaint(_TicksPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.showDouble != showDouble;
}
