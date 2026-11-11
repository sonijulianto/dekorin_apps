import 'package:flutter/widgets.dart';

/// Controller noop untuk platform non-web.
class VisualEditorWebIframeController {
  void loadUrl(String url) {}
  void applyPatch(Map<String, dynamic> patch) {}
  void setEditMode(bool enabled) {}
  void toggleGate(bool showGate) {}
  void setInteractionLocked(bool locked) {}
  void dispose() {}
}

Widget buildVisualEditorWebIframe({
  required String url,
  required VisualEditorWebIframeController controller,
  required void Function(Map<String, dynamic> message) onMessage,
  required VoidCallback onLoadFinished,
}) {
  return const SizedBox.shrink();
}
