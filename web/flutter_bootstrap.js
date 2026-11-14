{{flutter_js}}
{{flutter_build_config}}

// Cache-bust main.dart.js / main.dart.wasm dengan hash versi build agar
// Cloudflare CDN dan browser langsung mengambil bundle terbaru setiap rilis.
(function () {
  var ver = {{flutter_service_worker_version}};
  if (ver && window._flutter && _flutter.buildConfig && Array.isArray(_flutter.buildConfig.builds)) {
    _flutter.buildConfig.builds.forEach(function (b) {
      if (b && b.mainJsPath && b.mainJsPath.indexOf('?') === -1) {
        b.mainJsPath = b.mainJsPath + '?v=' + encodeURIComponent(ver);
      }
      if (b && b.mainWasmPath && b.mainWasmPath.indexOf('?') === -1) {
        b.mainWasmPath = b.mainWasmPath + '?v=' + encodeURIComponent(ver);
      }
    });
  }
})();

_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}}
  }
});
