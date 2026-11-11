import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// Controller komunikasi postMessage antara PWA Flutter Web dan iframe Visual Editor.
class VisualEditorWebIframeController {
  web.HTMLIFrameElement? _iframe;
  web.EventListener? _messageListener;
  web.EventListener? _loadListener;

  void _attach(
    web.HTMLIFrameElement iframe,
    void Function(Map<String, dynamic> message) onMessage,
    VoidCallback onLoadFinished,
  ) {
    _detachListeners();
    _iframe = iframe;

    _messageListener = ((web.Event event) {
      final msgEvent = event as web.MessageEvent;
      final dynamic raw = msgEvent.data?.dartify();
      if (raw is Map) {
        final normalized = _normalizeMap(raw);
        if (normalized['source'] == 'dekorin-visual-editor') {
          onMessage(normalized);
        }
      }
    }).toJS;
    web.window.addEventListener('message', _messageListener!);

    _loadListener = ((web.Event _) {
      onLoadFinished();
    }).toJS;
    iframe.addEventListener('load', _loadListener!);
  }

  void loadUrl(String url) {
    final iframe = _iframe;
    if (iframe == null || iframe.src == url) return;
    iframe.src = url;
  }

  void applyPatch(Map<String, dynamic> patch) {
    _postToIframe({
      'source': 'dekorin-portal-parent',
      'action': 'apply_patch',
      'patch': patch,
    });
  }

  void setEditMode(bool enabled) {
    _postToIframe({
      'source': 'dekorin-portal-parent',
      'action': 'set_edit_mode',
      'enabled': enabled,
    });
  }

  void toggleGate(bool showGate) {
    _postToIframe({
      'source': 'dekorin-portal-parent',
      'action': 'toggle_gate',
      'showGate': showGate,
    });
  }

  void setInteractionLocked(bool locked) {
    final iframe = _iframe;
    if (iframe != null) {
      iframe.style.pointerEvents = locked ? 'none' : 'auto';
      iframe.style.touchAction = locked ? 'none' : 'auto';
    }
    _postToIframe({
      'source': 'dekorin-portal-parent',
      'action': 'lock_scroll',
      'locked': locked,
    });
  }

  void _postToIframe(Map<String, dynamic> payload) {
    final win = _iframe?.contentWindow;
    if (win == null) return;
    win.postMessage(payload.jsify(), '*'.toJS);
  }

  void _detachListeners() {
    if (_messageListener != null) {
      web.window.removeEventListener('message', _messageListener!);
      _messageListener = null;
    }
    if (_loadListener != null && _iframe != null) {
      _iframe!.removeEventListener('load', _loadListener!);
      _loadListener = null;
    }
  }

  void dispose() {
    _detachListeners();
    _iframe = null;
  }
}

Map<String, dynamic> _normalizeMap(Map raw) {
  final out = <String, dynamic>{};
  raw.forEach((key, value) {
    out[key.toString()] = _normalizeValue(value);
  });
  return out;
}

dynamic _normalizeValue(dynamic value) {
  if (value is Map) return _normalizeMap(value);
  if (value is List) return value.map(_normalizeValue).toList();
  return value;
}

Widget buildVisualEditorWebIframe({
  required String url,
  required VisualEditorWebIframeController controller,
  required void Function(Map<String, dynamic> message) onMessage,
  required VoidCallback onLoadFinished,
}) {
  return SizedBox.expand(
    child: HtmlElementView.fromTagName(
      key: const ValueKey('dekorin_ve_iframe'),
      tagName: 'iframe',
      onElementCreated: (Object element) {
        final iframe = element as web.HTMLIFrameElement;
        iframe.src = url;
        iframe.style.border = 'none';
        iframe.style.width = '100%';
        iframe.style.height = '100%';
        iframe.style.backgroundColor = '#FAF7F2';
        iframe.setAttribute('allow', 'clipboard-write; autoplay');
        controller._attach(iframe, onMessage, onLoadFinished);
      },
    ),
  );
}
