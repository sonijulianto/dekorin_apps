class AppVersionInfo {
  final String platform;
  final String versionName;
  final int versionCode;
  final int minVersionCode;
  final String downloadUrl;
  final String releaseNotes;
  final bool forceUpdate;

  const AppVersionInfo({
    required this.platform,
    required this.versionName,
    required this.versionCode,
    required this.minVersionCode,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.forceUpdate,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    return AppVersionInfo(
      platform: json['platform'] as String? ?? 'android',
      versionName: json['version_name'] as String? ?? '1.0.0',
      versionCode: json['version_code'] as int? ?? 1,
      minVersionCode: json['min_version_code'] as int? ?? 1,
      downloadUrl: json['download_url'] as String? ?? '',
      releaseNotes: json['release_notes'] as String? ?? '',
      forceUpdate: json['force_update'] as bool? ?? false,
    );
  }

  /// Cek apakah versi di server lebih tinggi dibanding versi aplikasi yang terpasang
  bool isUpdateAvailable(int currentBuildNumber) {
    return versionCode > currentBuildNumber;
  }

  /// Cek apakah update ini bersifat wajib (user tidak bisa menutup pop-up)
  bool isForceRequired(int currentBuildNumber) {
    return forceUpdate || (minVersionCode > currentBuildNumber);
  }
}
